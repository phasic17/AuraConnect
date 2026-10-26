import SwiftUI

struct AIModulesView: View {
    @State private var modules: [Module] = [
        .init(name: "Conversation Core",  desc: "Qwen2.5-7B Q4_K_M — primary chat + reasoning.",   enabled: true),
        .init(name: "Speech to Text",     desc: "faster-whisper int8 GPU.",                         enabled: true),
        .init(name: "Voice (Piper)",      desc: "Trained Piper ONNX voice model.",                  enabled: true),
        .init(name: "Memory Index",       desc: "FAISS semantic store with daily ruminations.",     enabled: true),
        .init(name: "News Poller",        desc: "23-category RSS aggregator, 5-minute cadence.",    enabled: true),
        .init(name: "Telegram Socialite", desc: "Group bot interjections (RTX-side).",              enabled: false)
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
        VStack(alignment: .leading, spacing: 6) {
            Text("AI Modules")
                .auraSectionTitle()
                .foregroundStyle(AuraTheme.textPrimary)
            Text("Toggle the cognitive subsystems running on the puck.")
                .auraBody(12)
                .foregroundStyle(AuraTheme.textDim)
        }
    }

    private var list: some View {
        VStack(spacing: 8) {
            ForEach($modules) { $m in
                ModuleRow(module: $m)
            }
        }
        .auraGlass(corner: 18)
    }

    struct Module: Identifiable {
        let id = UUID()
        let name: String
        let desc: String
        var enabled: Bool
    }
}

private struct ModuleRow: View {
    @Binding var module: AIModulesView.Module

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: "cpu")
                .font(.system(size: 16))
                .foregroundStyle(module.enabled ? AuraTheme.auraBlue : AuraTheme.textFaint)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(module.name.uppercased())
                    .auraLabel(12)
                    .foregroundStyle(AuraTheme.textPrimary)
                Text(module.desc)
                    .auraBody(11)
                    .foregroundStyle(AuraTheme.textDim)
            }

            Spacer()

            Toggle("", isOn: $module.enabled)
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
