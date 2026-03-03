import SwiftUI
import Combine

struct AuraHeaderBar: View {
    let title: String
    let subtitle: String

    @State private var t: Double = 0

    var body: some View {
        ZStack {
            // Base glass
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(AuraTheme.panelTint)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(AuraTheme.auraBlue.opacity(0.22), lineWidth: 1)
                )

            // Animated “scan sweep”
            LinearGradient(
                colors: [
                    .clear,
                    AuraTheme.auraBlue.opacity(0.18),
                    .clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .rotationEffect(.degrees(18))
            .offset(x: CGFloat(sin(t * 0.6) * 260))
            .blendMode(.screen)
            .mask(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
            )

            // Content
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title.uppercased())
                        .auraTitle()
                        .foregroundStyle(AuraTheme.auraBlue)
                        .shadow(color: AuraTheme.auraBlue.opacity(0.65), radius: 16)

                    Text(subtitle)
                        .auraBody(12)
                        .foregroundStyle(AuraTheme.textDim)
                        .lineLimit(1)
                }

                Spacer()

                // Tiny “status glyph” placeholder (future: connected/sending)
                Image(systemName: "sparkles")
                    .foregroundStyle(AuraTheme.auraCyan.opacity(0.9))
                    .shadow(color: AuraTheme.auraCyan.opacity(0.5), radius: 12)
            }
            .padding(.horizontal, 18)
        }
        .frame(height: 68)
        .onReceive(Timer.publish(every: 1/30, on: .main, in: .common).autoconnect()) { _ in
            t += 1/30
        }
    }
}
