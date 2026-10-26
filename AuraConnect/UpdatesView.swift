import SwiftUI

struct UpdatesView: View {
    @EnvironmentObject var bt: BluetoothManager

    struct Patch: Identifiable {
        let id = UUID()
        let name: String
        let version: String
        let size: String
        let summary: String
    }

    private let patches: [Patch] = [
        .init(name: "Aura Core",      version: "1.1.2", size: "18 MB",
              summary: "BLE transfer stability and discovery hardening."),
        .init(name: "Speech Models",  version: "v3",    size: "92 MB",
              summary: "Improved diarization and noise robustness."),
        .init(name: "RAG Index",      version: "0.9.7", size: "7 MB",
              summary: "Faster ingestion, lower memory footprint.")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            list
            Spacer()
        }
        .padding(.top, 6)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("Updates")
                    .auraSectionTitle()
                    .foregroundStyle(AuraTheme.textPrimary)
                Text("Signed software patches. Pushed to the puck over BLE.")
                    .auraBody(12)
                    .foregroundStyle(AuraTheme.textDim)
            }
            Spacer()
            Button {
            } label: {
                Label("CHECK", systemImage: "arrow.clockwise")
                    .auraLabel(12)
            }
            .buttonStyle(.borderedProminent)
            .tint(AuraTheme.auraBlue)
        }
    }

    private var list: some View {
        VStack(spacing: 10) {
            ForEach(patches) { p in
                PatchRow(patch: p, canInstall: bt.isConnected)
            }
        }
        .auraGlass(corner: 18)
    }
}

private struct PatchRow: View {
    let patch: UpdatesView.Patch
    let canInstall: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 18))
                .foregroundStyle(AuraTheme.auraBlue)
                .shadow(color: AuraTheme.auraBlue.opacity(0.4), radius: 8)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("\(patch.name.uppercased())  \(patch.version)")
                        .font(AuraFont.medium(13))
                        .tracking(0.6)
                        .foregroundStyle(AuraTheme.textPrimary)
                    Spacer()
                    Text(patch.size)
                        .font(AuraFont.mono(11))
                        .foregroundStyle(AuraTheme.textFaint)
                }
                Text(patch.summary)
                    .auraBody(12)
                    .foregroundStyle(AuraTheme.textDim)

                HStack(spacing: 8) {
                    Button("INSTALL VIA BLUETOOTH") { }
                        .auraLabel(11)
                        .buttonStyle(.borderedProminent)
                        .tint(AuraTheme.auraBlue)
                        .disabled(!canInstall)
                    Button("RELEASE NOTES") { }
                        .auraLabel(11)
                        .buttonStyle(.bordered)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.white.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(AuraTheme.panelStroke, lineWidth: 1)
        )
    }
}
