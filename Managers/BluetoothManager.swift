import Foundation
import CoreBluetooth
import Combine
import CryptoKit
import SwiftUI

// MARK: - Aura BLE UUIDs (must match puck)

private let AURA_SERVICE_UUID: CBUUID = {
    let s = "E7810A71-73AE-499D-8C15-FAA9AEF0C3F2"
    if let u = UUID(uuidString: s) { return CBUUID(nsuuid: u) }
    return CBUUID(string: "180F")
}()

private let AURA_CTRL_UUID: CBUUID = {
    let s = "E7810A71-73AE-499D-8C15-FAA9AEF0C3F3"
    if let u = UUID(uuidString: s) { return CBUUID(nsuuid: u) }
    return CBUUID(string: "2A19")
}()

private let AURA_DATA_UUID: CBUUID = {
    let s = "E7810A71-73AE-499D-8C15-FAA9AEF0C3F4"
    if let u = UUID(uuidString: s) { return CBUUID(nsuuid: u) }
    return CBUUID(string: "2A19")
}()

// MARK: - Models

struct AuraDevice: Identifiable {
    let id: UUID
    let name: String
    let rssi: Int
    let peripheral: CBPeripheral
}

struct QueuedFile: Identifiable {
    let id: String
    let url: URL
    let name: String
    let size: Int
    let sha256: String

    var sentBytes: Int
    var status: String

    var progress: Double {
        guard size > 0 else { return 0 }
        return Double(min(sentBytes, size)) / Double(size)
    }
}

// MARK: - BluetoothManager

@MainActor
final class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {

    // UI state
    @Published var status: String = "Ready."
    @Published var devices: [AuraDevice] = []
    @Published var selectedID: UUID? = nil
    @Published var isConnected: Bool = false
    @Published var isScanning: Bool = false

    // Transfer queue state
    @Published var queue: [QueuedFile] = []
    @Published var overallProgress: Double = 0.0
    @Published var isSending: Bool = false

    private var central: CBCentralManager!
    private var connectedPeripheral: CBPeripheral?

    private var ctrlChar: CBCharacteristic?
    private var dataChar: CBCharacteristic?

    private var sendTask: Task<Void, Never>?

    // Write-without-response pacing
    private var canSendWoR: Bool = true
    private var woRContinuation: CheckedContinuation<Void, Never>?

    override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: .main)
    }

    // MARK: Scan / Connect

    func startScan() {
        devices.removeAll()
        selectedID = nil
        isScanning = true
        status = "Scanning… (puck must be in Transfer Mode)"
        central.scanForPeripherals(withServices: [AURA_SERVICE_UUID],
                                   options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
    }

    func stopScan() {
        central.stopScan()
        isScanning = false
        status = devices.isEmpty ? "No Aura Pucks found." : "Select a puck to connect."
    }

    func connectSelected() {
        guard let id = selectedID,
              let d = devices.first(where: { $0.id == id }) else {
            status = "Select a puck first."
            return
        }

        stopScan()
        status = "Connecting to \(d.name)…"

        ctrlChar = nil
        dataChar = nil
        connectedPeripheral = d.peripheral
        d.peripheral.delegate = self
        central.connect(d.peripheral, options: nil)
    }

    func disconnect() {
        stopSending()

        if let p = connectedPeripheral {
            central.cancelPeripheralConnection(p)
        }
        connectedPeripheral = nil
        ctrlChar = nil
        dataChar = nil
        isConnected = false
        status = "Disconnected."
    }

    func lockNow() {
        // Send ABORT best-effort, then disconnect.
        sendControl(["cmd": "ABORT"])
        disconnect()
    }

    // MARK: Queue (Drag & Drop entry point)

    func addDroppedProviders(_ providers: [NSItemProvider]) {
        Task { @MainActor in
            let urls = await loadDroppedFileURLs(providers)
            enqueueFiles(urls)
        }
    }

    func clearQueue() {
        queue.removeAll()
        overallProgress = 0
        status = "Queue cleared."
    }

    // MARK: Sending

    func sendQueuedFiles() {
        guard isConnected else { status = "Not connected."; return }
        guard !queue.isEmpty else { status = "Queue empty."; return }
        guard ctrlChar != nil, dataChar != nil else { status = "GATT not ready."; return }
        guard !isSending else { return }

        isSending = true
        status = "Starting transfer…"

        sendTask = Task { [weak self] in
            guard let self else { return }
            await self.runQueue()
        }
    }

    func stopSending() {
        sendTask?.cancel()
        sendTask = nil
        isSending = false
        woRContinuation?.resume()
        woRContinuation = nil
    }

    private func runQueue() async {
        defer {
            Task { @MainActor in
                self.isSending = false
                self.recomputeOverallProgress()
            }
        }

        for idx in queue.indices {
            if Task.isCancelled { return }
            if queue[idx].status == "Done" { continue }

            queue[idx].status = "Preparing…"
            status = "Preparing \(queue[idx].name)…"

            guard let p = connectedPeripheral, let ctrl = ctrlChar, let data = dataChar else {
                status = "Disconnected."
                return
            }

            // BEGIN
            let begin: [String: Any] = [
                "cmd": "BEGIN",
                "id": queue[idx].id,
                "name": queue[idx].name,
                "size": queue[idx].size,
                "sha256": queue[idx].sha256
            ]
            if !writeControlJSON(begin, peripheral: p, characteristic: ctrl) {
                queue[idx].status = "Failed (BEGIN)"
                continue
            }

            // Small delay: allow puck to open file / reset state
            try? await Task.sleep(nanoseconds: 120_000_000)

            // Send data chunks
            do {
                queue[idx].status = "Sending…"
                status = "Sending \(queue[idx].name)…"
                try await streamFile(idx: idx, peripheral: p, dataChar: data)
            } catch {
                queue[idx].status = "Failed (data)"
                status = "Transfer failed: \(queue[idx].name)"
                continue
            }

            // END
            let end: [String: Any] = [
                "cmd": "END",
                "id": queue[idx].id
            ]
            _ = writeControlJSON(end, peripheral: p, characteristic: ctrl)

            queue[idx].status = "Done"
            queue[idx].sentBytes = queue[idx].size
            recomputeOverallProgress()

            // brief gap between files
            try? await Task.sleep(nanoseconds: 120_000_000)
        }

        status = "All transfers complete."
    }

    private func streamFile(idx: Int, peripheral: CBPeripheral, dataChar: CBCharacteristic) async throws {
        let url = queue[idx].url
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }

        // Determine max payload size for write-without-response
        let maxWrite = peripheral.maximumWriteValueLength(for: .withoutResponse)
        // Frame = 4-byte length prefix + payload
        let payloadMax = max(64, maxWrite - 4)

        queue[idx].sentBytes = 0
        recomputeOverallProgress()

        while true {
            if Task.isCancelled { throw CancellationError() }

            let chunk = try handle.read(upToCount: payloadMax) ?? Data()
            if chunk.isEmpty { break }

            // Frame: [uint32_le_len][payload]
            var frame = Data()
            var len = UInt32(chunk.count).littleEndian
            withUnsafeBytes(of: &len) { frame.append(contentsOf: $0) }
            frame.append(chunk)

            // Pace write-without-response
            await waitForWoRReady(peripheral: peripheral)

            peripheral.writeValue(frame, for: dataChar, type: .withoutResponse)

            queue[idx].sentBytes = min(queue[idx].sentBytes + chunk.count, queue[idx].size)
            recomputeOverallProgress()
        }
    }

    private func waitForWoRReady(peripheral: CBPeripheral) async {
        // If CoreBluetooth says we're ready, continue immediately.
        if peripheral.canSendWriteWithoutResponse {
            return
        }

        // Otherwise wait for peripheralIsReady(toSendWriteWithoutResponse:)
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            woRContinuation = cont
        }
    }

    // MARK: Control channel

    private func sendControl(_ obj: [String: Any]) {
        guard let p = connectedPeripheral, let c = ctrlChar else { return }
        _ = writeControlJSON(obj, peripheral: p, characteristic: c)
    }

    private func writeControlJSON(_ obj: [String: Any], peripheral: CBPeripheral, characteristic: CBCharacteristic) -> Bool {
        guard let data = try? JSONSerialization.data(withJSONObject: obj, options: []) else { return false }
        peripheral.writeValue(data, for: characteristic, type: .withResponse)
        return true
    }

    // MARK: Queue building helpers

    private func enqueueFiles(_ urls: [URL]) {
        for url in urls {
            guard url.isFileURL else { continue }

            // Security-scoped access needed for files from drag-and-drop
            let accessing = url.startAccessingSecurityScopedResource()

            let name = url.lastPathComponent
            let size = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? NSNumber)?.intValue ?? 0
            if size <= 0 {
                print("[AuraConnect] Skipping \(name): size=0 (access denied?)")
                if accessing { url.stopAccessingSecurityScopedResource() }
                continue
            }

            let sha = (try? sha256Hex(of: url)) ?? ""
            let fileID = UUID().uuidString.lowercased()

            queue.append(QueuedFile(
                id: fileID,
                url: url,
                name: name,
                size: size,
                sha256: sha,
                sentBytes: 0,
                status: "Queued"
            ))
            // Note: don't stop accessing yet — we need it for sending
        }
        recomputeOverallProgress()
        status = "Queued \(queue.count) file(s)."
    }

    private func recomputeOverallProgress() {
        let total = queue.reduce(0) { $0 + $1.size }
        guard total > 0 else { overallProgress = 0; return }
        let sent = queue.reduce(0) { $0 + min($1.sentBytes, $1.size) }
        overallProgress = Double(sent) / Double(total)
    }

    private func sha256Hex(of url: URL) throws -> String {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }

        var hasher = SHA256()
        while true {
            let chunk = try handle.read(upToCount: 1024 * 1024) ?? Data()
            if chunk.isEmpty { break }
            hasher.update(data: chunk)
        }
        let digest = hasher.finalize()
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private func loadDroppedFileURLs(_ providers: [NSItemProvider]) async -> [URL] {
        var urls: [URL] = []
        for p in providers {
            // Try loading as file URL
            if p.hasItemConformingToTypeIdentifier("public.file-url") {
                do {
                    let item = try await p.loadItem(forTypeIdentifier: "public.file-url")
                    if let data = item as? Data {
                        // macOS returns URL as UTF-8 path data or bookmark data
                        if let url = URL(dataRepresentation: data, relativeTo: nil) {
                            urls.append(url)
                            continue
                        }
                        // Try as UTF-8 path string
                        if let path = String(data: data, encoding: .utf8),
                           let url = URL(string: path) ?? URL(fileURLWithPath: path) as URL? {
                            urls.append(url)
                            continue
                        }
                    } else if let url = item as? URL {
                        urls.append(url)
                        continue
                    }
                } catch {
                    print("[AuraConnect] Drop load error: \(error)")
                }
            }
        }
        print("[AuraConnect] Resolved \(urls.count) URLs from \(providers.count) providers")
        return urls
    }

    // MARK: CBCentralManagerDelegate

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            status = "Ready."
        case .poweredOff:
            status = "Bluetooth is off."
        default:
            status = "Bluetooth unavailable."
        }
    }

    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber) {

        let name = (advertisementData[CBAdvertisementDataLocalNameKey] as? String)
            ?? peripheral.name
            ?? "Aura Puck"

        let d = AuraDevice(id: peripheral.identifier, name: name, rssi: RSSI.intValue, peripheral: peripheral)

        if let i = devices.firstIndex(where: { $0.id == d.id }) {
            devices[i] = d
        } else {
            devices.append(d)
        }

        devices.sort { $0.rssi > $1.rssi }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        isConnected = true
        status = "Connected. Discovering services…"

        // Discover our service
        peripheral.discoverServices([AURA_SERVICE_UUID])
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        isConnected = false
        status = "Connect failed: \(error?.localizedDescription ?? "unknown")"
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        isConnected = false
        ctrlChar = nil
        dataChar = nil
        connectedPeripheral = nil
        status = "Disconnected."
    }

    // MARK: CBPeripheralDelegate (GATT)

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            status = "Service discovery error: \(error.localizedDescription)"
            return
        }
        guard let services = peripheral.services else {
            status = "No services."
            return
        }

        guard let svc = services.first(where: { $0.uuid == AURA_SERVICE_UUID }) else {
            status = "Aura service not found."
            return
        }

        status = "Service found. Discovering characteristics…"
        peripheral.discoverCharacteristics([AURA_CTRL_UUID, AURA_DATA_UUID], for: svc)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            status = "Characteristic discovery error: \(error.localizedDescription)"
            return
        }

        guard let chars = service.characteristics else {
            status = "No characteristics."
            return
        }

        // Reset (optional but helps during reconnects)
        ctrlChar = nil
        dataChar = nil

        for c in chars {
            if c.uuid == AURA_CTRL_UUID { ctrlChar = c }
            if c.uuid == AURA_DATA_UUID { dataChar = c }
        }

        // Subscribe to control notify if available
        if let ctrl = ctrlChar, ctrl.properties.contains(.notify) {
            peripheral.setNotifyValue(true, for: ctrl)
        }

        // 🔍 Explicit visibility into discovery state
        status = "Chars discovered: ctrl=\(ctrlChar != nil) data=\(dataChar != nil)"

        // ✅ DATA_PING test (proves DATA writes are reaching the puck)
        if let d = dataChar {
            let supportsWoR = d.properties.contains(.writeWithoutResponse)
            let supportsWrite = d.properties.contains(.write)

            // Frame: [uint32_le_len][payload]
            let payload = Data("DATA_PING".utf8)
            var frame = Data()
            var n = UInt32(payload.count).littleEndian
            withUnsafeBytes(of: &n) { frame.append(contentsOf: $0) }
            frame.append(payload)

            if supportsWoR {
                peripheral.writeValue(frame, for: d, type: .withoutResponse)
                status = "Sent DATA_PING (WoR)."
            } else if supportsWrite {
                peripheral.writeValue(frame, for: d, type: .withResponse)
                status = "Sent DATA_PING (withResponse)."
            } else {
                status = "Data char not writable."
            }
        }

        if ctrlChar != nil && dataChar != nil {
            status = "Connected. Ready to send."
        } else {
            status = "Missing ctrl/data characteristic on puck."
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            status = "Notify error: \(error.localizedDescription)"
            return
        }
        if characteristic.uuid == AURA_CTRL_UUID {
            // notify state updated
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else { return }
        guard characteristic.uuid == AURA_CTRL_UUID else { return }
        guard let data = characteristic.value else { return }

        // CTRL notify contains JSON status
        if let s = String(data: data, encoding: .utf8) {
            // best-effort: show status message
            status = s
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            status = "CTRL write failed: \(error.localizedDescription)"
        }
    }

    func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
        // Resume any waiting task
        woRContinuation?.resume()
        woRContinuation = nil
    }
}

