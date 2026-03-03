import SwiftUI
import UniformTypeIdentifiers

struct TransferView: View {
    @ObservedObject var bt: BluetoothManager
    @State private var isTargeted = false

    var body: some View {
        VStack(spacing: 16) {
            AuraHeaderBar(
                title: "SECURE TRANSFER",
                subtitle: "Secure local transfer • no cloud • no Wi-Fi"
            )

            topBar
            transferPanel
            Spacer(minLength: 0)
        }
        .padding(18)
    }

    private var topBar: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("TRANSFER")
                    .auraSectionTitle()
                    .foregroundStyle(.white)

                if bt.devices.isEmpty {
                    Text("No pucks discovered yet. Go to DEVICES → SCAN first.")
                        .auraBody(12)
                        .foregroundStyle(AuraTheme.textDim)
                } else {
                    Text("Choose a puck, connect, then send your queue.")
                        .auraBody(12)
                        .foregroundStyle(AuraTheme.textDim)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 10) {
                // Device dropdown
                Picker("Target", selection: $bt.selectedID) {
                    Text("Select puck…").tag(UUID?.none)

                    ForEach(bt.devices) { d in
                        Text("\(d.name)  (RSSI \(d.rssi))")
                            .tag(Optional(d.id))
                    }
                }
                .pickerStyle(.menu)
                .frame(minWidth: 260)

                HStack(spacing: 10) {
                    if bt.isConnected {
                        Button { bt.disconnect() } label: {
                            Label("DISCONNECT", systemImage: "xmark.circle")
                                .auraLabel(13)
                        }
                        .buttonStyle(.bordered)
                    } else {
                        Button { bt.connectSelected() } label: {
                            Label("CONNECT", systemImage: "link")
                                .auraLabel(13)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(bt.selectedID == nil)
                    }

                    Button { bt.lockNow() } label: {
                        Label("LOCK NOW", systemImage: "lock.fill")
                            .auraLabel(13)
                    }
                    .buttonStyle(.bordered)
                    .disabled(!bt.isConnected)
                }
            }
        }
        .auraGlass(corner: 18, glow: bt.isConnected)
    }

    private var transferPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("QUEUE")
                    .font(AuraFont.semibold(16))
                    .tracking(1.0)
                    .foregroundStyle(.white)

                Spacer()

                ProgressView(value: bt.overallProgress)
                    .frame(width: 240)
            }

            dropZone

            HStack {
                Button { bt.sendQueuedFiles() } label: {
                    Label("SEND QUEUE", systemImage: "paperplane.fill")
                        .frame(maxWidth: .infinity)
                        .auraLabel(13)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!bt.isConnected || bt.queue.isEmpty || bt.isSending)

                Button { bt.clearQueue() } label: {
                    Label("CLEAR", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                        .auraLabel(13)
                }
                .buttonStyle(.bordered)
                .disabled(bt.queue.isEmpty)
            }

            queueList
        }
        .auraGlass(corner: 18, glow: bt.isSending)
        .frame(maxWidth: 920)
    }

    private var dropZone: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white.opacity(isTargeted ? 0.12 : 0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(AuraTheme.auraBlue.opacity(isTargeted ? 0.55 : 0.25),
                                style: StrokeStyle(lineWidth: 1, dash: [6]))
                )

            VStack(spacing: 10) {
                Image(systemName: "tray.and.arrow.down.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(AuraTheme.auraBlue)
                    .shadow(color: AuraTheme.auraBlue.opacity(0.65), radius: 16)

                Text("DROP FILES HERE")
                    .font(AuraFont.semibold(14))
                    .tracking(1.2)
                    .foregroundStyle(.white)

                Text("PDF • WORD • POWERPOINT • EXCEL • TEXT")
                    .font(AuraFont.regular(12))
                    .tracking(0.7)
                    .foregroundStyle(.white.opacity(0.55))
            }
            .padding(.vertical, 18)
        }
        .frame(height: 150)
        .onDrop(of: [UTType.fileURL], isTargeted: $isTargeted) { providers in
            bt.addDroppedProviders(providers)
            return true
        }
    }

    private var queueList: some View {
        VStack(alignment: .leading, spacing: 8) {
            if bt.queue.isEmpty {
                Text("NO FILES QUEUED.")
                    .font(AuraFont.regular(12))
                    .tracking(0.8)
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.top, 6)
            } else {
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(bt.queue) { item in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(item.name)
                                        .font(AuraFont.medium(13))
                                        .tracking(0.4)
                                        .foregroundStyle(.white)
                                        .lineLimit(1)
                                    Spacer()
                                    Text(item.status.uppercased())
                                        .font(AuraFont.regular(11))
                                        .tracking(0.8)
                                        .foregroundStyle(.white.opacity(0.7))
                                }

                                ProgressView(value: item.progress)
                                    .opacity(0.95)

                                HStack {
                                    Text("\(formatBytes(item.sentBytes)) / \(formatBytes(item.size))")
                                        .font(AuraFont.regular(11))
                                        .tracking(0.2)
                                        .foregroundStyle(.white.opacity(0.65))
                                    Spacer()
                                    Text("SHA \(item.sha256.prefix(10))…")
                                        .font(AuraFont.regular(11))
                                        .tracking(0.2)
                                        .foregroundStyle(.white.opacity(0.45))
                                }
                            }
                            .padding(12)
                            .background(.white.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(AuraTheme.auraBlue.opacity(0.14), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private func formatBytes(_ n: Int) -> String {
        let f = ByteCountFormatter()
        f.countStyle = .file
        return f.string(fromByteCount: Int64(n))
    }
}

