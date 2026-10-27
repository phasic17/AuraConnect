import SwiftUI

struct LedgerUsageView: View {
    @State private var psiExpanded = false
    private let credits = PsiCredits.demo
    private var expandAnim: Animation { .spring(response: 0.6, dampingFraction: 0.84) }

    var body: some View {
        ZStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 16) {
                header
                PsiCollapsedTile(credits: credits) { hovering in
                    if hovering { withAnimation(expandAnim) { psiExpanded = true } }
                }
                tilesRow
                historyPanel
                Spacer()
            }
            .padding(.top, 6)
            .blur(radius: psiExpanded ? 16 : 0)
            .opacity(psiExpanded ? 0.5 : 1)
            .allowsHitTesting(!psiExpanded)

            if psiExpanded {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture { withAnimation(expandAnim) { psiExpanded = false } }
                PsiExpandedPanel(credits: credits) { withAnimation(expandAnim) { psiExpanded = false } }
                    .frame(maxWidth: 740)
                    .padding(.top, 48)
                    .onHover { inside in if !inside { withAnimation(expandAnim) { psiExpanded = false } } }
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.92, anchor: .top).combined(with: .opacity),
                        removal: .scale(scale: 0.96, anchor: .top).combined(with: .opacity)))
            }
        }
        .animation(expandAnim, value: psiExpanded)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Ledger Usage")
                .auraSectionTitle()
                .foregroundStyle(AuraTheme.textPrimary)
            Text("Tokens consumed, files ingested, queries served.")
                .auraBody(12)
                .foregroundStyle(AuraTheme.textDim)
        }
    }

    private var tilesRow: some View {
        HStack(spacing: 14) {
            Tile(label: "Today",     value: "12,308", unit: "tokens",
                 trend: .up, delta: "+18%")
            Tile(label: "This week", value: "84,217", unit: "tokens",
                 trend: .up, delta: "+6%")
            Tile(label: "Files RAG", value: "326",    unit: "ingested",
                 trend: .flat, delta: "—")
            Tile(label: "Queries",   value: "1,402",  unit: "answered",
                 trend: .up, delta: "+22%")
        }
    }

    private var historyPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("7-day usage")
                .auraLabel(11)
                .foregroundStyle(AuraTheme.textDim)
            BarChart(values: [3200, 5800, 4100, 9200, 7300, 8800, 12308])
                .frame(height: 130)
        }
        .auraGlass(corner: 18)
    }
}

private struct Tile: View {
    enum Trend { case up, down, flat }
    let label: String
    let value: String
    let unit: String
    let trend: Trend
    let delta: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .auraLabel(10)
                .foregroundStyle(AuraTheme.textDim)
            Text(value)
                .font(AuraFont.semi(28))
                .foregroundStyle(AuraTheme.textPrimary)
            HStack(spacing: 6) {
                Text(unit)
                    .auraBody(11)
                    .foregroundStyle(AuraTheme.textFaint)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: arrow)
                        .font(.system(size: 9, weight: .bold))
                    Text(delta)
                        .font(AuraFont.mono(10))
                }
                .foregroundStyle(arrowColor)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .auraGlass(corner: 16)
    }

    private var arrow: String {
        switch trend {
        case .up: return "arrow.up.right"
        case .down: return "arrow.down.right"
        case .flat: return "arrow.right"
        }
    }
    private var arrowColor: Color {
        switch trend {
        case .up: return AuraTheme.okGreen
        case .down: return AuraTheme.errRed
        case .flat: return AuraTheme.textFaint
        }
    }
}

private struct BarChart: View {
    let values: [Int]

    var body: some View {
        GeometryReader { geo in
            let maxV = max(1, values.max() ?? 1)
            let gap: CGFloat = 8
            let bw = (geo.size.width - gap * CGFloat(values.count - 1)) / CGFloat(values.count)
            HStack(alignment: .bottom, spacing: gap) {
                ForEach(values.indices, id: \.self) { i in
                    let h = max(2, geo.size.height * CGFloat(values[i]) / CGFloat(maxV))
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(LinearGradient(colors: [AuraTheme.auraBlue,
                                                       AuraTheme.auraBlueDeep],
                                             startPoint: .top, endPoint: .bottom))
                        .frame(width: bw, height: h)
                        .shadow(color: AuraTheme.auraBlue.opacity(0.4), radius: 6, y: 2)
                }
            }
        }
    }
}
