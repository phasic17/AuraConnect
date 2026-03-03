import SwiftUI

struct UpdatesView: View {
    @ObservedObject var bt: BluetoothManager

    struct Patch: Identifiable {
        let id = UUID()
        let name: String
        let version: String
        let size: String
        let summary: String
        let signed: Bool
    }

    private let patches: [Patch] = [
        .init(name: "Aura Core Firmware", version: "1.1.2", size: "18 MB",
              summary: "Security hardening + BLE transfer stability.", signed: true),
        .init(name: "Speech Model Pack", version: "v3", size: "92 MB",
              summary: "Improved diarization and noise robustness.", signed: true),
        .init(name: "RAG Index Optimizer", version: "0.9.7", size: "7 MB",
              summary: "Faster ingestion and lower memory footprint.", signed: true),
    ]

    var body: some View {
        VStack(spacing: 16) {
            topBar
            listPanel
            Spacer()
        }
        .padding(18)
    }

    private var topBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("Software Updates")
                    .auraSectionTitle()
                    .foregroundStyle(.white)

                Text("Find signed official patches. Install locally via Bluetooth.")
                    .auraBody(12)
                    .foregroundStyle(AuraTheme.textDim)
            }

            Spacer()

            Button { } label: {
                Label("CHECK", systemImage: "arrow.clockwise")
                    .auraLabel(13)
            }
            .buttonStyle(.borderedProminent)
        }
        .auraGlass(corner: 18)
    }

    private var listPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(patches) { p in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: p.signed ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(p.signed ? AuraTheme.auraBlue : .orange)
                        .font(.system(size: 18))
                        .shadow(color: AuraTheme.auraBlue.opacity(0.35), radius: 10)

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("\(p.name.uppercased())  \(p.version)")
                                .font(AuraFont.medium(13))
                                .tracking(0.8)
                                .foregroundStyle(.white)

                            Spacer()

                            Text(p.size)
                                .font(AuraFont.regular(11))
                                .tracking(0.2)
                                .foregroundStyle(.white.opacity(0.6))
                        }

                        Text(p.summary)
                            .font(AuraFont.regular(12))
                            .tracking(0.2)
                            .foregroundStyle(.white.opacity(0.7))

                        HStack(spacing: 10) {
                            Button("INSTALL VIA BLUETOOTH") { }
                                .font(AuraFont.medium(12))
                                .tracking(0.8)
                                .buttonStyle(.borderedProminent)
                                .disabled(!bt.isConnected)

                            Button("DETAILS") { }
                                .font(AuraFont.medium(12))
                                .tracking(0.8)
                                .buttonStyle(.bordered)
                        }
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
        .auraGlass(corner: 18)
        .frame(maxWidth: 920)
    }
}

