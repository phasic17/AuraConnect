import SwiftUI

struct DataSecurityView: View {
    @State private var localOnly = true
    @State private var encryptAtRest = true
    @State private var allowTelemetry = false
    @State private var requirePIN = true

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            posture
            policies
            Spacer()
        }
        .padding(.top, 6)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Data Security")
                .auraSectionTitle()
                .foregroundStyle(AuraTheme.textPrimary)
            Text("Where your data lives, and who can touch it.")
                .auraBody(12)
                .foregroundStyle(AuraTheme.textDim)
        }
    }

    private var posture: some View {
        HStack(spacing: 14) {
            PostureCard(icon: "lock.shield.fill",
                        title: "Local Only",
                        detail: "All inference, audio, and memory stay on the puck.",
                        accent: AuraTheme.okGreen)
            PostureCard(icon: "key.horizontal.fill",
                        title: "Encrypted Storage",
                        detail: "FileVault-backed volumes; per-key envelope.",
                        accent: AuraTheme.auraBlue)
            PostureCard(icon: "antenna.radiowaves.left.and.right.slash",
                        title: "Zero Telemetry",
                        detail: "No external phone-home. Logs stay device-local.",
                        accent: AuraTheme.warnAmber)
        }
    }

    private var policies: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Policies")
                .auraLabel(11)
                .foregroundStyle(AuraTheme.textDim)

            PolicyRow(label: "Local-only inference",
                      detail: "Disable cloud fallback for chat and STT.",
                      isOn: $localOnly)
            PolicyRow(label: "Encrypt at rest",
                      detail: "AES-256 on /data, transparent.",
                      isOn: $encryptAtRest)
            PolicyRow(label: "Anonymous telemetry",
                      detail: "Crash + perf counters only. No content.",
                      isOn: $allowTelemetry)
            PolicyRow(label: "Require PIN to pair",
                      detail: "BLE pairing prompts for puck PIN.",
                      isOn: $requirePIN)
        }
        .auraGlass(corner: 18)
    }
}

private struct PostureCard: View {
    let icon: String
    let title: String
    let detail: String
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(accent)
                .shadow(color: accent.opacity(0.45), radius: 8)
            Text(title.uppercased())
                .auraLabel(11)
                .foregroundStyle(AuraTheme.textPrimary)
            Text(detail)
                .auraBody(11)
                .foregroundStyle(AuraTheme.textDim)
                .lineLimit(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .auraGlass(corner: 16)
    }
}

private struct PolicyRow: View {
    let label: String
    let detail: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text(label.uppercased())
                    .auraLabel(11)
                    .foregroundStyle(AuraTheme.textPrimary)
                Text(detail)
                    .auraBody(11)
                    .foregroundStyle(AuraTheme.textDim)
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .toggleStyle(.switch)
                .tint(AuraTheme.auraBlue)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.white.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(AuraTheme.panelStroke, lineWidth: 1)
        )
    }
}
