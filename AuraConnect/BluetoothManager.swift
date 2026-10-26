import Foundation
import CoreBluetooth
import Combine
import CryptoKit
import SwiftUI

private let AURA_SERVICE_UUID = CBUUID(string: "E7810A71-73AE-499D-8C15-FAA9AEF0C3F2")
private let AURA_CTRL_UUID    = CBUUID(string: "E7810A71-73AE-499D-8C15-FAA9AEF0C3F3")
private let AURA_DATA_UUID    = CBUUID(string: "E7810A71-73AE-499D-8C15-FAA9AEF0C3F4")
private let AURA_TELE_UUID    = CBUUID(string: "E7810A71-73AE-499D-8C15-FAA9AEF0C3F5")

enum LinkState: Equatable {
    case idle
    case bluetoothOff
    case bluetoothUnavailable
    case scanning
    case selected(AuraDevice)
    case connecting(AuraDevice)
    case discovering(AuraDevice)
    case connected(AuraDevice)
    case disconnecting

    var deviceName: String? {
        switch self {
        case .selected(let d), .connecting(let d), .discovering(let d), .connected(let d):
            return d.name
        default: return nil
        }
    }

    var isConnected: Bool {
        if case .connected = self { return true }
        return false
    }

    var summary: String {
        switch self {
        case .idle: return "Ready."
        case .bluetoothOff: return "Bluetooth is off."
        case .bluetoothUnavailable: return "Bluetooth unavailable."
        case .scanning: return "Scanning…"
        case .selected(let d): return "Selected \(d.name)"
        case .connecting(let d): return "Connecting to \(d.name)…"
        case .discovering(let d): return "Discovering services on \(d.name)…"
        case .connected(let d): return "Connected to \(d.name)"
        case .disconnecting: return "Disconnecting…"
        }
    }
}

struct AuraDevice: Identifiable, Equatable {
    let id: UUID
    let name: String
    let rssi: Int
    let peripheral: CBPeripheral

    static func == (a: AuraDevice, b: AuraDevice) -> Bool { a.id == b.id }
}

struct QueuedFile: Identifiable, Equatable {
    let id: String
    let url: URL
    let name: String
    let size: Int
    let sha256: String

    var sentBytes: Int = 0
    var status: TransferStatus = .pending

    var progress: Double {
        guard size > 0 else { return 0 }
        return Double(min(sentBytes, size)) / Double(size)
    }
}

enum TransferStatus: Equatable {
    case pending
    case sending
    case finalizing
    case done
    case failed(String)

    var label: String {
        switch self {
        case .pending: return "Queued"
        case .sending: return "Sending"
        case .finalizing: return "Finalizing"
        case .done: return "Done"
        case .failed(let m): return "Failed — \(m)"
        }
    }

    var isTerminal: Bool {
        if case .done = self { return true }
        if case .failed = self { return true }
        return false
    }
}

@MainActor
struct PuckTelemetry {
    var temp: Double?
    var memUsed: Double?
    var memTotal: Double?
    var models: Int?
    var uptime: Int?
    var load: Double?
    var egress: Int
    var chat: [(who: String, text: String)]
}

final class BluetoothManager: NSObject, ObservableObject {
    @Published var state: LinkState = .idle
    @Published var devices: [AuraDevice] = []
    @Published var selectedID: UUID? = nil
    @Published var queue: [QueuedFile] = []
    @Published var overallProgress: Double = 0.0
    @Published var isSending: Bool = false
    @Published var lastEvent: String = ""
    @Published var telemetry: PuckTelemetry? = nil

    // Last successful connection — used to distinguish "never paired" from
    // "session ended cleanly N seconds ago" so the status indicator can show
    // a soft "Idle — last seen 12s ago" instead of a stark "Not connected".
    @Published var lastConnectedDevice: AuraDevice? = nil
    @Published var lastConnectedAt: Date? = nil

    var isConnected: Bool { state.isConnected }
    var connectedDeviceName: String? { state.deviceName }
    var selectedDeviceName: String? {
        guard let id = selectedID else { return nil }
        return devices.first(where: { $0.id == id })?.name
    }

    /// True if we connected within the last 5 minutes but aren't currently
    /// connected. Lets the UI show a softer "recently disconnected" state.
    var isRecentlyConnected: Bool {
        guard !isConnected, let ts = lastConnectedAt else { return false }
        return Date().timeIntervalSince(ts) < 300
    }

    /// Human-readable "last seen" string, e.g. "12s ago" or "3 min ago".
    var lastSeenText: String? {
        guard let ts = lastConnectedAt else { return nil }
        let secs = Int(Date().timeIntervalSince(ts))
        if secs < 60 { return "\(secs)s ago" }
        let mins = secs / 60
        if mins < 60 { return "\(mins) min ago" }
        let hrs = mins / 60
        return "\(hrs)h ago"
    }

    private var central: CBCentralManager!
    private var peripheral: CBPeripheral?
    private var ctrlChar: CBCharacteristic?
    private var dataChar: CBCharacteristic?
    private var teleChar: CBCharacteristic?

    private var sendTask: Task<Void, Never>?
    private var pendingAck: CheckedContinuation<Result<Void, Error>, Never>?
    private var pendingDataWriteAck: CheckedContinuation<Result<Void, Error>, Never>?
    private var woRWaiters: [CheckedContinuation<Void, Never>] = []

    override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: .main)
    }

    // MARK: Scan / connect

    func startScan() {
        guard central.state == .poweredOn else {
            log("Bluetooth not powered on (state=\(central.state.rawValue))")
            return
        }
        devices.removeAll()
        selectedID = nil
        state = .scanning
        log("Scanning (unfiltered, will match by name + UUID)")
        // Pass nil services so we see all advertisements. We filter to Aura
        // pucks in didDiscoverPeripheral by name OR service UUID, so a puck
        // whose service UUID landed in the scan response (or got truncated
        // out of the primary adv packet) is still discoverable.
        central.scanForPeripherals(withServices: nil,
                                   options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
    }

    func stopScan() {
        if central.isScanning { central.stopScan() }
        if case .scanning = state { state = .idle }
    }

    func select(_ d: AuraDevice) {
        selectedID = d.id
        if !state.isConnected, case .connecting = state {} else if case .discovering = state {} else {
            state = .selected(d)
        }
    }

    func connectSelected() {
        guard let id = selectedID,
              let d = devices.first(where: { $0.id == id }) else {
            log("No device selected")
            return
        }
        stopScan()
        state = .connecting(d)
        peripheral = d.peripheral
        d.peripheral.delegate = self
        central.connect(d.peripheral, options: nil)
    }

    func disconnect() {
        stopSending()
        if let p = peripheral {
            state = .disconnecting
            central.cancelPeripheralConnection(p)
        } else {
            state = .idle
        }
    }

    // MARK: Queue management

    func enqueue(urls: [URL]) {
        for url in urls where url.isFileURL {
            let acquired = url.startAccessingSecurityScopedResource()
            defer { if acquired { url.stopAccessingSecurityScopedResource() } }

            guard let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
                  let size = attrs[.size] as? Int else {
                continue
            }
            let sha = sha256OfFile(url) ?? ""
            let f = QueuedFile(id: UUID().uuidString,
                               url: url,
                               name: url.lastPathComponent,
                               size: size,
                               sha256: sha)
            queue.append(f)
        }
        recomputeOverallProgress()
    }

    func clearQueue() {
        queue.removeAll { $0.status.isTerminal || $0.status == .pending }
        recomputeOverallProgress()
    }

    func removeQueueItem(_ id: String) {
        queue.removeAll { $0.id == id }
        recomputeOverallProgress()
    }

    func sendQueuedFiles() {
        guard sendTask == nil, isConnected else { return }
        sendTask = Task { [weak self] in
            await self?.runSendLoop()
            await MainActor.run { self?.sendTask = nil }
        }
    }

    /// One-shot: connect to selected puck (if not already), send all pending files, disconnect.
    /// Caller doesn't think about connection state.
    func uploadToSelected() {
        log("Upload tapped")
        if sendTask != nil {
            log("Upload already in progress — ignoring tap")
            return
        }
        guard let id = selectedID else {
            log("No puck selected — pick a row first")
            return
        }
        guard let d = devices.first(where: { $0.id == id }) else {
            log("Selected puck \(id.uuidString.prefix(8)) is no longer in scan list")
            return
        }
        log("Starting upload flow → \(d.name) (\(d.id.uuidString.prefix(8)))")
        isSending = true
        sendTask = Task { [weak self] in
            await self?.runUploadFlow(device: d)
            await MainActor.run {
                self?.sendTask = nil
                self?.isSending = false
            }
        }
    }

    private func runUploadFlow(device: AuraDevice) async {
        // Connect if needed
        if !isConnected {
            stopScan()
            state = .connecting(device)
            peripheral = device.peripheral
            device.peripheral.delegate = self
            log("Calling central.connect on \(device.name)")
            central.connect(device.peripheral, options: nil)

            // Wait until characteristics are ready or we time out
            let timeout: TimeInterval = 12
            let deadline = Date().addingTimeInterval(timeout)
            var lastTick = Date()
            while Date() < deadline {
                if isConnected, ctrlChar != nil, dataChar != nil {
                    log("Link ready (connected + characteristics)")
                    break
                }
                if Date().timeIntervalSince(lastTick) >= 1.5 {
                    log("Waiting for connect… state=\(state.summary)")
                    lastTick = Date()
                }
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
            if !isConnected || ctrlChar == nil || dataChar == nil {
                log("Connect timed out after \(Int(timeout))s — peripheral never reached characteristic discovery")
                if let p = peripheral { central.cancelPeripheralConnection(p) }
                state = .idle
                // Mark all pending files as failed so user sees something
                for i in queue.indices where !queue[i].status.isTerminal {
                    queue[i].status = .failed("Connect timed out")
                }
                return
            }
        }

        // Send everything that's not already done
        log("Beginning send loop (\(queue.filter { !$0.status.isTerminal }.count) files)")
        await runSendLoop()

        // Disconnect when finished — UX-wise the puck reverts to "available"
        try? await Task.sleep(nanoseconds: 250_000_000)
        if let p = peripheral {
            log("Disconnecting after upload")
            central.cancelPeripheralConnection(p)
        }
    }

    func stopSending() {
        sendTask?.cancel()
        sendTask = nil
        if let cont = pendingAck {
            cont.resume(returning: .failure(CancellationError()))
            pendingAck = nil
        }
        woRWaiters.forEach { $0.resume() }
        woRWaiters.removeAll()
    }

    // MARK: Internal — send loop

    private func runSendLoop() async {
        await MainActor.run { isSending = true }
        defer {
            Task { @MainActor in
                self.isSending = false
                self.recomputeOverallProgress()
            }
        }

        for idx in queue.indices {
            if Task.isCancelled { return }
            if queue[idx].status.isTerminal { continue }

            guard let p = peripheral, let ctrl = ctrlChar, let data = dataChar else {
                queue[idx].status = .failed("No connection")
                continue
            }

            queue[idx].sentBytes = 0
            queue[idx].status = .sending
            recomputeOverallProgress()

            // BEGIN — write-with-response, then wait for puck ACK on CTRL notify
            let begin: [String: Any] = [
                "cmd": "BEGIN",
                "id": queue[idx].id,
                "name": queue[idx].name,
                "size": queue[idx].size,
                "sha256": queue[idx].sha256
            ]
            let beginAck = await writeControlWithAck(begin, peripheral: p, char: ctrl, timeout: 4)
            if case .failure(let e) = beginAck {
                queue[idx].status = .failed("BEGIN: \(e.localizedDescription)")
                continue
            }

            // Stream chunks
            do {
                try await streamFile(idx: idx, peripheral: p, dataChar: data)
            } catch is CancellationError {
                queue[idx].status = .failed("Cancelled")
                return
            } catch {
                queue[idx].status = .failed("Stream: \(error.localizedDescription)")
                continue
            }

            // END — wait for puck ACK confirming SHA match
            queue[idx].status = .finalizing
            let end: [String: Any] = ["cmd": "END", "id": queue[idx].id]
            let endAck = await writeControlWithAck(end, peripheral: p, char: ctrl, timeout: 8)
            switch endAck {
            case .success:
                queue[idx].sentBytes = queue[idx].size
                queue[idx].status = .done
            case .failure(let e):
                queue[idx].status = .failed("END: \(e.localizedDescription)")
            }
            recomputeOverallProgress()

            try? await Task.sleep(nanoseconds: 120_000_000)
        }
    }

    private func streamFile(idx: Int, peripheral: CBPeripheral, dataChar: CBCharacteristic) async throws {
        let url = queue[idx].url
        let acquired = url.startAccessingSecurityScopedResource()
        defer { if acquired { url.stopAccessingSecurityScopedResource() } }

        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }

        // Use .withResponse for reliable delivery (Realtek controllers drop
        // .withoutResponse writes silently). Hard-cap chunk size at 180 bytes:
        //  - .withResponse MTU returns 512 (long-write max), too large for single ATT_WRITE_REQ
        //  - .withoutResponse MTU may return the LL data length (244+), larger than negotiated ATT MTU
        // 180 fits inside the smallest plausible negotiated ATT MTU (185-ish), so a single
        // chunk is always one ATT_WRITE_REQ regardless of which MTU CoreBluetooth reports.
        let payloadMax = 180

        while true {
            if Task.isCancelled { throw CancellationError() }
            guard let chunk = try handle.read(upToCount: payloadMax), !chunk.isEmpty else { break }

            let result: Result<Void, Error> = await withCheckedContinuation { cont in
                self.pendingDataWriteAck = cont
                peripheral.writeValue(chunk, for: dataChar, type: .withResponse)
            }
            if case .failure(let e) = result { throw e }

            queue[idx].sentBytes = min(queue[idx].sentBytes + chunk.count, queue[idx].size)
            recomputeOverallProgress()
        }
    }

    private func waitForWoRReady(peripheral: CBPeripheral) async {
        if peripheral.canSendWriteWithoutResponse { return }
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            woRWaiters.append(cont)
        }
    }

    // MARK: Control channel + ACK protocol

    private func writeControlWithAck(_ obj: [String: Any],
                                     peripheral: CBPeripheral,
                                     char: CBCharacteristic,
                                     timeout: TimeInterval) async -> Result<Void, Error> {
        guard let payload = try? JSONSerialization.data(withJSONObject: obj, options: []) else {
            return .failure(NSError(domain: "AuraConnect", code: 1,
                                    userInfo: [NSLocalizedDescriptionKey: "Bad JSON"]))
        }

        let result: Result<Void, Error> = await withCheckedContinuation { cont in
            self.pendingAck = cont
            peripheral.writeValue(payload, for: char, type: .withResponse)
            Task {
                try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                if let pending = self.pendingAck {
                    self.pendingAck = nil
                    pending.resume(returning: .failure(NSError(
                        domain: "AuraConnect", code: 2,
                        userInfo: [NSLocalizedDescriptionKey: "ACK timeout"])))
                }
            }
        }
        return result
    }

    private func handleCtrlNotify(_ data: Data) {
        guard let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            log("CTRL notify (non-JSON, \(data.count)B)")
            return
        }
        let resp = (obj["resp"] as? String) ?? ""
        let okFlag = (obj["ok"] as? Bool) ?? (resp == "ok")
        let msg = (obj["msg"] as? String) ?? ""
        log("CTRL ack \(resp) ok=\(okFlag) \(msg)")

        if let cont = pendingAck {
            pendingAck = nil
            if okFlag {
                cont.resume(returning: .success(()))
            } else {
                cont.resume(returning: .failure(NSError(
                    domain: "AuraConnect", code: 3,
                    userInfo: [NSLocalizedDescriptionKey: msg.isEmpty ? "puck error" : msg])))
            }
        }
    }

    // MARK: Helpers

    private func recomputeOverallProgress() {
        let total = queue.reduce(0) { $0 + $1.size }
        let sent  = queue.reduce(0) { $0 + min($1.sentBytes, $1.size) }
        overallProgress = total > 0 ? Double(sent) / Double(total) : 0
    }

    private func sha256OfFile(_ url: URL) -> String? {
        guard let h = try? FileHandle(forReadingFrom: url) else { return nil }
        defer { try? h.close() }
        var hasher = SHA256()
        while autoreleasepool(invoking: { () -> Bool in
            let chunk = h.readData(ofLength: 64 * 1024)
            if chunk.isEmpty { return false }
            hasher.update(data: chunk)
            return true
        }) {}
        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }

    private func log(_ s: String) {
        print("[BT] \(s)")
        Task { @MainActor in self.lastEvent = s }
    }
}

// MARK: CBCentralManagerDelegate

extension BluetoothManager: CBCentralManagerDelegate {
    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        Task { @MainActor in
            switch central.state {
            case .poweredOn:
                if case .bluetoothOff = self.state { self.state = .idle }
                else if case .bluetoothUnavailable = self.state { self.state = .idle }
                self.log("Bluetooth powered on")
                self.startScan()
            case .poweredOff:
                self.state = .bluetoothOff
            default:
                self.state = .bluetoothUnavailable
            }
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager,
                                    didDiscover peripheral: CBPeripheral,
                                    advertisementData: [String : Any],
                                    rssi RSSI: NSNumber) {
        let advName = advertisementData[CBAdvertisementDataLocalNameKey] as? String
        let name = advName ?? peripheral.name ?? ""
        let advUUIDs = (advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID]) ?? []
        let overflowUUIDs = (advertisementData[CBAdvertisementDataOverflowServiceUUIDsKey] as? [CBUUID]) ?? []
        let solicitedUUIDs = (advertisementData[CBAdvertisementDataSolicitedServiceUUIDsKey] as? [CBUUID]) ?? []
        let allUUIDs = advUUIDs + overflowUUIDs + solicitedUUIDs

        let nameMatches = name.contains("Aura Puck")
        let uuidMatches = allUUIDs.contains(AURA_SERVICE_UUID)

        guard nameMatches || uuidMatches else { return }

        let displayName = name.isEmpty ? "Aura Puck" : name
        let rssi = RSSI.intValue
        let id = peripheral.identifier
        Task { @MainActor in
            let d = AuraDevice(id: id, name: displayName, rssi: rssi, peripheral: peripheral)
            if let i = self.devices.firstIndex(where: { $0.id == d.id }) {
                self.devices[i] = d
            } else {
                self.devices.append(d)
                self.log("Discovered \(displayName) RSSI=\(rssi) (uuidMatch=\(uuidMatches), nameMatch=\(nameMatches))")
            }
            self.devices.sort { $0.rssi > $1.rssi }
            if self.selectedID == nil, let first = self.devices.first {
                self.selectedID = first.id
            }
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        let name = peripheral.name ?? "Aura Puck"
        let id = peripheral.identifier
        Task { @MainActor in
            let d = AuraDevice(id: id, name: name, rssi: 0, peripheral: peripheral)
            self.state = .discovering(d)
            self.log("Connected, discovering services")
            peripheral.discoverServices([AURA_SERVICE_UUID])
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager,
                                    didFailToConnect peripheral: CBPeripheral,
                                    error: Error?) {
        let msg = error?.localizedDescription ?? "unknown"
        Task { @MainActor in
            self.log("Connect failed: \(msg)")
            self.state = .idle
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager,
                                    didDisconnectPeripheral peripheral: CBPeripheral,
                                    error: Error?) {
        let msg = error?.localizedDescription ?? ""
        Task { @MainActor in
            self.log("Disconnected\(msg.isEmpty ? "" : ": \(msg)")")
            self.peripheral = nil
            self.ctrlChar = nil
            self.dataChar = nil
            self.state = .idle
        }
    }
}

// MARK: CBPeripheralDelegate

extension BluetoothManager: CBPeripheralDelegate {
    nonisolated func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            Task { @MainActor in self.log("Service discovery error: \(error.localizedDescription)") }
            return
        }
        guard let svc = peripheral.services?.first(where: { $0.uuid == AURA_SERVICE_UUID }) else {
            Task { @MainActor in self.log("Aura service not found") }
            return
        }
        peripheral.discoverCharacteristics([AURA_CTRL_UUID, AURA_DATA_UUID, AURA_TELE_UUID], for: svc)
    }

    nonisolated func peripheral(_ peripheral: CBPeripheral,
                                didDiscoverCharacteristicsFor service: CBService,
                                error: Error?) {
        if let error = error {
            Task { @MainActor in self.log("Char discovery error: \(error.localizedDescription)") }
            return
        }

        var ctrl: CBCharacteristic?
        var data: CBCharacteristic?
        var tele: CBCharacteristic?
        for c in service.characteristics ?? [] {
            if c.uuid == AURA_CTRL_UUID { ctrl = c }
            if c.uuid == AURA_DATA_UUID { data = c }
            if c.uuid == AURA_TELE_UUID { tele = c }
        }
        let name = peripheral.name ?? "Aura Puck"
        let id = peripheral.identifier
        Task { @MainActor in
            self.ctrlChar = ctrl
            self.dataChar = data
            self.teleChar = tele
            if let c = ctrl, c.properties.contains(.notify) {
                peripheral.setNotifyValue(true, for: c)
            }
            if let t = tele { peripheral.setNotifyValue(true, for: t) }
            let d = AuraDevice(id: id, name: name, rssi: 0, peripheral: peripheral)
            self.state = .connected(d)
            self.lastConnectedDevice = d
            self.lastConnectedAt = Date()
            self.log("Characteristics ready (ctrl=\(ctrl != nil) data=\(data != nil))")
        }
    }

    nonisolated func peripheral(_ peripheral: CBPeripheral,
                                didUpdateValueFor characteristic: CBCharacteristic,
                                error: Error?) {
        guard let v = characteristic.value else { return }
        if characteristic.uuid == AURA_TELE_UUID {
            Task { @MainActor in self.handleTelemetry(v) }
            return
        }
        guard characteristic.uuid == AURA_CTRL_UUID else { return }
        Task { @MainActor in self.handleCtrlNotify(v) }
    }

    nonisolated func peripheral(_ peripheral: CBPeripheral,
                                didWriteValueFor characteristic: CBCharacteristic,
                                error: Error?) {
        // Only DATA-channel writes use this completion; CTRL writes are
        // confirmed by app-level notify in handleCtrlNotify.
        guard characteristic.uuid == AURA_DATA_UUID else { return }
        Task { @MainActor in
            guard let cont = self.pendingDataWriteAck else { return }
            self.pendingDataWriteAck = nil
            if let e = error {
                cont.resume(returning: .failure(e))
            } else {
                cont.resume(returning: .success(()))
            }
        }
    }

    nonisolated func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
        Task { @MainActor in
            let waiters = self.woRWaiters
            self.woRWaiters.removeAll()
            waiters.forEach { $0.resume() }
        }
    }
}

extension BluetoothManager {
    func handleTelemetry(_ data: Data) {
        guard let obj = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else { return }
        func dbl(_ k: String) -> Double? { if let d = obj[k] as? Double { return d }; if let i = obj[k] as? Int { return Double(i) }; return nil }
        func int(_ k: String) -> Int? { if let i = obj[k] as? Int { return i }; if let d = obj[k] as? Double { return Int(d) }; return nil }
        var chat: [(who: String, text: String)] = []
        if let arr = obj["chat"] as? [[String: Any]] {
            for e in arr {
                let w = (e["w"] as? String) ?? "?"
                let t = (e["t"] as? String) ?? ""
                if !t.isEmpty { chat.append((who: w, text: t)) }
            }
        }
        self.telemetry = PuckTelemetry(temp: dbl("t"), memUsed: dbl("mu"), memTotal: dbl("mt"),
                                       models: int("mdl"), uptime: int("up"), load: dbl("load"),
                                       egress: int("eg") ?? 0, chat: chat)
    }
}
