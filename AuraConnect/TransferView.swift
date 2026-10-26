import SwiftUI
import UniformTypeIdentifiers

struct TransferView: View {
    @EnvironmentObject var bt: BluetoothManager
    @State private var isTargeted = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            puckList
            dropBox
            statusLine
            footer
        }
        .padding(.top, 6)
        .onAppear { bt.startScan() }
    }

    private var statusLine: some View {
        HStack(spacing: 10) {
            AuraStatusDot(color: dotColor, pulses: bt.isSending || bt.state == .scanning)
            Text(bt.state.summary)
                .auraBody(12)
                .foregroundStyle(AuraTheme.textPrimary)
            if !bt.lastEvent.isEmpty {
                Text("·")
                    .foregroundStyle(AuraTheme.textFaint)
                Text(bt.lastEvent)
                    .font(AuraFont.mono(11))
                    .foregroundStyle(AuraTheme.textDim)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.white.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(AuraTheme.panelStroke, lineWidth: 1)
        )
    }

    private var dotColor: Color {
        if bt.isSending { return AuraTheme.auraBlue }
        if bt.isConnected { return AuraTheme.okGreen }
        if bt.state == .scanning { return AuraTheme.warnAmber }
        return AuraTheme.textFaint
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Transfer")
                .auraSectionTitle()
                .foregroundStyle(AuraTheme.textPrimary)
            Text("Pick a puck, drop files, hit upload.")
                .auraBody(12)
                .foregroundStyle(AuraTheme.textDim)
        }
    }

    // MARK: Pucks discovered

    private var puckList: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Pucks nearby")
                    .auraLabel(11)
                    .foregroundStyle(AuraTheme.textDim)
                Spacer()
                if case .scanning = bt.state {
                    HStack(spacing: 6) {
                        AuraStatusDot(color: AuraTheme.warnAmber, pulses: true)
                        Text("Scanning")
                            .auraBody(11)
                            .foregroundStyle(AuraTheme.textDim)
                    }
                }
                Button {
                    bt.startScan()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11, weight: .medium))
                }
                .buttonStyle(.plain)
                .foregroundStyle(AuraTheme.textDim)
                .help("Rescan")
            }

            if bt.devices.isEmpty {
                emptyPucksHint
            } else {
                VStack(spacing: 8) {
                    ForEach(bt.devices) { d in
                        PuckRow(device: d,
                                selected: bt.selectedID == d.id,
                                live: bt.connectedDeviceName == d.name && bt.isConnected) {
                            bt.select(d)
                        }
                    }
                }
            }
        }
        .auraGlass(corner: 18)
    }

    private var emptyPucksHint: some View {
        HStack(spacing: 10) {
            Image(systemName: "wave.3.right")
                .foregroundStyle(AuraTheme.textFaint)
            Text("No pucks visible. Toggle Transfer Mode on the puck's settings watchface.")
                .auraBody(12)
                .foregroundStyle(AuraTheme.textDim)
            Spacer()
        }
        .padding(.vertical, 10)
    }

    // MARK: Drop box (files stay here)

    private var dropBox: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AuraTheme.panelBase)
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(style: StrokeStyle(lineWidth: 1.4,
                                           dash: bt.queue.isEmpty ? [6, 5] : []))
                .foregroundStyle(isTargeted
                                 ? AuraTheme.auraBlue
                                 : (bt.queue.isEmpty ? AuraTheme.panelStroke : AuraTheme.auraBlue.opacity(0.35)))

            if bt.queue.isEmpty {
                emptyDropPrompt
            } else {
                filesGrid
            }
        }
        .frame(minHeight: 200, maxHeight: 360)
        .onDrop(of: [UTType.fileURL], isTargeted: $isTargeted) { providers in
            handleDrop(providers)
        }
    }

    private var emptyDropPrompt: some View {
        VStack(spacing: 10) {
            Image(systemName: isTargeted ? "tray.and.arrow.down.fill" : "tray.and.arrow.down")
                .font(.system(size: 32))
                .foregroundStyle(isTargeted ? AuraTheme.auraBlue : AuraTheme.textFaint)
                .shadow(color: isTargeted ? AuraTheme.auraBlue : .clear, radius: 10)
            Text(isTargeted ? "Release to add" : "Drop files here")
                .auraLabel(13)
                .foregroundStyle(isTargeted ? AuraTheme.textPrimary : AuraTheme.textDim)
        }
    }

    private var filesGrid: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 170), spacing: 10)],
                      alignment: .leading, spacing: 10) {
                ForEach(bt.queue) { f in
                    FileChip(file: f) { bt.removeQueueItem(f.id) }
                }
            }
            .padding(14)
        }
    }

    // MARK: Footer — overall progress + upload button

    private var footer: some View {
        HStack(spacing: 14) {
            if bt.isSending {
                ProgressView(value: bt.overallProgress)
                    .progressViewStyle(.linear)
                    .tint(AuraTheme.auraBlue)
                    .frame(maxWidth: 280)
                Text("\(Int(bt.overallProgress * 100))%")
                    .font(AuraFont.mono(11))
                    .foregroundStyle(AuraTheme.textDim)
            }

            Spacer()

            if !bt.queue.isEmpty {
                Button("CLEAR") { bt.clearQueue() }
                    .auraLabel(12)
                    .buttonStyle(.bordered)
                    .disabled(bt.isSending)
            }

            Button {
                bt.uploadToSelected()
            } label: {
                Label(uploadLabel, systemImage: "arrow.up.circle.fill")
                    .auraLabel(13)
            }
            .buttonStyle(.borderedProminent)
            .tint(AuraTheme.auraBlue)
            .disabled(!canUpload)
            .keyboardShortcut(.return, modifiers: [.command])
        }
    }

    private var uploadLabel: String {
        if bt.isSending { return "UPLOADING…" }
        if let name = bt.selectedDeviceName { return "UPLOAD TO \(name.uppercased())" }
        return "UPLOAD"
    }

    private var canUpload: Bool {
        !bt.isSending
            && !bt.queue.isEmpty
            && bt.selectedID != nil
            && !pendingFiles.isEmpty
    }

    private var pendingFiles: [QueuedFile] {
        bt.queue.filter { !$0.status.isTerminal }
    }

    // MARK: Drop handler

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        var collected: [URL] = []
        let group = DispatchGroup()
        for p in providers {
            group.enter()
            p.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                defer { group.leave() }
                if let url = item as? URL {
                    collected.append(url)
                } else if let data = item as? Data,
                          let url = URL(dataRepresentation: data, relativeTo: nil) {
                    collected.append(url)
                }
            }
        }
        group.notify(queue: .main) {
            bt.enqueue(urls: collected)
        }
        return true
    }
}

// MARK: Puck row

private struct PuckRow: View {
    let device: AuraDevice
    let selected: Bool
    let live: Bool
    let pick: () -> Void

    var body: some View {
        Button(action: pick) {
            HStack(spacing: 12) {
                AuraStatusDot(color: live ? AuraTheme.okGreen : AuraTheme.auraBlue, pulses: live)
                VStack(alignment: .leading, spacing: 2) {
                    Text(device.name)
                        .font(AuraFont.medium(14))
                        .foregroundStyle(AuraTheme.textPrimary)
                    Text("\(device.rssi) dBm  ·  \(device.id.uuidString.prefix(8))")
                        .font(AuraFont.mono(10))
                        .foregroundStyle(AuraTheme.textFaint)
                }
                Spacer()
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AuraTheme.auraBlue)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(selected ? AuraTheme.auraBlue.opacity(0.10) : .white.opacity(0.03))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(selected ? AuraTheme.auraBlue.opacity(0.5) : AuraTheme.panelStroke,
                            lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: File chip (lives in the drop box)

private struct FileChip: View {
    let file: QueuedFile
    let onRemove: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(iconColor)
                VStack(alignment: .leading, spacing: 1) {
                    Text(file.name)
                        .font(AuraFont.medium(12))
                        .foregroundStyle(AuraTheme.textPrimary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Text(formatSize(file.size))
                        .font(AuraFont.mono(10))
                        .foregroundStyle(AuraTheme.textFaint)
                }
                Spacer(minLength: 0)
                Button(action: onRemove) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(AuraTheme.textFaint)
                        .frame(width: 14, height: 14)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .opacity(file.status == .pending ? 1 : 0.4)
                .disabled(file.status == .sending || file.status == .finalizing)
            }

            ProgressView(value: file.progress)
                .progressViewStyle(.linear)
                .tint(progressTint)
                .frame(height: 2)
                .opacity(file.status == .pending ? 0.18 : 1)

            Text(file.status.label)
                .font(AuraFont.regular(10))
                .foregroundStyle(statusColor)
                .lineLimit(1)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.white.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(AuraTheme.panelStroke, lineWidth: 1)
        )
    }

    private var icon: String {
        switch file.status {
        case .done: return "checkmark.circle.fill"
        case .failed: return "exclamationmark.triangle.fill"
        case .sending, .finalizing: return "arrow.up.circle.fill"
        case .pending: return "doc.fill"
        }
    }
    private var iconColor: Color {
        switch file.status {
        case .done: return AuraTheme.okGreen
        case .failed: return AuraTheme.errRed
        case .sending, .finalizing: return AuraTheme.auraBlue
        case .pending: return AuraTheme.textDim
        }
    }
    private var statusColor: Color {
        switch file.status {
        case .done: return AuraTheme.okGreen
        case .failed: return AuraTheme.errRed
        case .sending, .finalizing: return AuraTheme.auraBlue
        case .pending: return AuraTheme.textFaint
        }
    }
    private var progressTint: Color {
        switch file.status {
        case .done: return AuraTheme.okGreen
        case .failed: return AuraTheme.errRed
        default: return AuraTheme.auraBlue
        }
    }
    private func formatSize(_ bytes: Int) -> String {
        let units = ["B", "KB", "MB", "GB"]
        var v = Double(bytes)
        var i = 0
        while v >= 1024 && i < units.count - 1 { v /= 1024; i += 1 }
        return String(format: i == 0 ? "%.0f %@" : "%.1f %@", v, units[i])
    }
}
