import SwiftUI
import AppKit
import CoreImage

// MARK: - Data (PLACEHOLDER values — wire to real account/telemetry later)
struct PsiCredits {
    var held: Double      = 60_508      // total $PSI credited
    var used: Double      = 12_308      // consumed this cycle
    var usage7d: [Double] = [3200, 5800, 4100, 9200, 7300, 8800, 12308]
    var remaining: Double { max(0, held - used) }
    var fracLeft: Double  { held <= 0 ? 0 : max(0, min(1, remaining / held)) }
    static let demo = PsiCredits()
}

enum PsiConfig {
    // SAFE receive address = TREASURY, never the token CA (tokens sent to the CA are unrecoverable).
    static let treasury   = "0x602f39f7afab6ed6d0f5bbd233e7c98dbe956443"
    static let network    = "Send $LEDGER (ERC-20, Ethereum). Credited to your balance automatically."
    // Stripe top-up checkout — set this to the live $PSI-credit Payment Link when confirmed.
    static let stripeURL  = "https://preorder.auravision.co"
    static let usdPerPsi  = 0.001       // placeholder rate: $ per 1 $PSI (confirm)
}

private func psiFmt(_ v: Double) -> String {
    let f = NumberFormatter(); f.numberStyle = .decimal; f.maximumFractionDigits = 0
    return f.string(from: NSNumber(value: v)) ?? "\(Int(v))"
}
private func copyToPasteboard(_ s: String) {
    NSPasteboard.general.clearContents(); NSPasteboard.general.setString(s, forType: .string)
}
private func openURL(_ s: String) {
    if let u = URL(string: s) { NSWorkspace.shared.open(u) }
}
private func qrImage(_ string: String) -> NSImage? {
    guard let data = string.data(using: .ascii),
          let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
    filter.setValue(data, forKey: "inputMessage")
    filter.setValue("M", forKey: "inputCorrectionLevel")
    guard let out = filter.outputImage?.transformed(by: CGAffineTransform(scaleX: 9, y: 9)) else { return nil }
    let rep = NSCIImageRep(ciImage: out)
    let img = NSImage(size: rep.size); img.addRepresentation(rep)
    return img
}

// MARK: - Ring gauge (trimmed Circle — no Canvas, compile-safe)
struct PsiGauge: View {
    var frac: Double
    var lineWidth: CGFloat = 14
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.06), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            Circle()
                .trim(from: 0, to: max(0.001, frac))
                .stroke(
                    AngularGradient(gradient: Gradient(colors: [AuraTheme.auraBlueDeep, AuraTheme.auraBlue, AuraTheme.warnAmber]),
                                    center: .center, startAngle: .degrees(-90), endAngle: .degrees(270)),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(color: AuraTheme.auraBlue.opacity(0.5), radius: 8)
        }
    }
}

// MARK: - Sparkline
private struct Sparkline: View {
    var values: [Double]
    var body: some View {
        GeometryReader { geo in
            let maxV = max(1, values.max() ?? 1)
            Path { p in
                for (i, v) in values.enumerated() {
                    let x = geo.size.width * CGFloat(i) / CGFloat(max(1, values.count - 1))
                    let y = geo.size.height * (1 - CGFloat(v / maxV))
                    if i == 0 { p.move(to: CGPoint(x: x, y: y)) } else { p.addLine(to: CGPoint(x: x, y: y)) }
                }
            }
            .stroke(AuraTheme.auraBlue, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
        }
    }
}

// MARK: - Collapsed tile (grid state) — hover expands
struct PsiCollapsedTile: View {
    var credits: PsiCredits
    var onHover: (Bool) -> Void
    @State private var hovering = false
    var body: some View {
        HStack(spacing: 22) {
            ZStack {
                PsiGauge(frac: credits.fracLeft, lineWidth: 11).frame(width: 118, height: 118)
                VStack(spacing: 2) {
                    Text(psiFmt(credits.remaining)).font(AuraFont.semi(24)).foregroundStyle(AuraTheme.textPrimary)
                    Text("$PSI LEFT").auraLabel(9).foregroundStyle(AuraTheme.textDim)
                }
            }
            VStack(alignment: .leading, spacing: 10) {
                Text("$PSI CREDITS").auraLabel(11).foregroundStyle(AuraTheme.auraBlue)
                HStack(spacing: 26) {
                    stat("USED THIS CYCLE", psiFmt(credits.used))
                    stat("BALANCE", psiFmt(credits.held))
                }
                Sparkline(values: credits.usage7d).frame(height: 30).opacity(0.9)
                Text(hovering ? "release to top up" : "hover to top up")
                    .auraBody(11).foregroundStyle(AuraTheme.textFaint)
            }
            Spacer()
        }
        .auraGlass(corner: 18)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AuraTheme.auraBlue.opacity(hovering ? 0.45 : 0), lineWidth: 1)
        )
        .scaleEffect(hovering ? 1.012 : 1.0)
        .onHover { h in
            hovering = h
            onHover(h)
        }
    }
    private func stat(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label).auraLabel(9).foregroundStyle(AuraTheme.textDim)
            Text(value).font(AuraFont.semi(20)).foregroundStyle(AuraTheme.textPrimary)
        }
    }
}

// MARK: - Top-up panel (send $PSI / card)
private struct PsiTopUp: View {
    enum Tab { case send, card }
    @State private var tab: Tab = .send
    @State private var copied = false
    @State private var amount = 50
    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 8) {
                tabButton("SEND $PSI", .send)
                tabButton("CARD", .card)
            }
            if tab == .send { sendView } else { cardView }
        }
        .frame(maxWidth: .infinity)
        .auraGlass(corner: 16)
    }
    private func tabButton(_ title: String, _ t: Tab) -> some View {
        Button { withAnimation(.easeInOut(duration: 0.25)) { tab = t } } label: {
            Text(title).auraLabel(11)
                .foregroundStyle(tab == t ? AuraTheme.auraBlue : AuraTheme.textDim)
                .frame(maxWidth: .infinity).padding(.vertical, 9)
                .background(RoundedRectangle(cornerRadius: 9).fill(tab == t ? AuraTheme.auraBlue.opacity(0.14) : .clear))
                .overlay(RoundedRectangle(cornerRadius: 9).stroke(tab == t ? AuraTheme.auraBlue.opacity(0.5) : .clear, lineWidth: 1))
        }.buttonStyle(.plain)
    }
    private var sendView: some View {
        VStack(spacing: 12) {
            if let qr = qrImage(PsiConfig.treasury) {
                Image(nsImage: qr).interpolation(.none).resizable()
                    .frame(width: 150, height: 150).padding(8)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.white))
            }
            Text("\(String(PsiConfig.treasury.prefix(6)))…\(String(PsiConfig.treasury.suffix(6)))  ·  Treasury")
                .font(AuraFont.mono(12)).foregroundStyle(AuraTheme.textPrimary)
            Button {
                copyToPasteboard(PsiConfig.treasury)
                copied = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { copied = false }
            } label: {
                Text(copied ? "COPIED ✓" : "COPY ADDRESS").auraLabel(11)
                    .foregroundStyle(AuraTheme.auraBlue).padding(.horizontal, 20).padding(.vertical, 9)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(AuraTheme.auraBlue.opacity(0.5), lineWidth: 1))
            }.buttonStyle(.plain)
            Text(PsiConfig.network).auraBody(11).multilineTextAlignment(.center)
                .foregroundStyle(AuraTheme.textDim).frame(maxWidth: 300)
        }
    }
    private var cardView: some View {
        VStack(spacing: 14) {
            Text("Top up with a card — billed securely via Stripe.")
                .auraBody(12).multilineTextAlignment(.center).foregroundStyle(AuraTheme.textDim)
            HStack(spacing: 10) {
                ForEach([25, 50, 100], id: \.self) { a in
                    Button { amount = a } label: {
                        Text("$\(a)").font(AuraFont.semi(16))
                            .foregroundStyle(amount == a ? Color.black : AuraTheme.textPrimary)
                            .frame(width: 72, height: 46)
                            .background(RoundedRectangle(cornerRadius: 10).fill(amount == a ? AuraTheme.auraBlue : Color.white.opacity(0.05)))
                    }.buttonStyle(.plain)
                }
            }
            Text("≈ \(psiFmt(Double(amount) / PsiConfig.usdPerPsi)) $PSI")
                .auraBody(12).foregroundStyle(AuraTheme.textFaint)
            Button { openURL(PsiConfig.stripeURL) } label: {
                Text("PAY $\(amount) WITH CARD  →").auraLabel(12).foregroundStyle(.black)
                    .frame(maxWidth: .infinity).padding(.vertical, 13)
                    .background(RoundedRectangle(cornerRadius: 11).fill(AuraTheme.auraBlue))
            }.buttonStyle(.plain)
        }
    }
}

// MARK: - Expanded panel (shown over the blurred console)
struct PsiExpandedPanel: View {
    var credits: PsiCredits
    var close: () -> Void
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("$PSI CREDITS").auraLabel(13).foregroundStyle(AuraTheme.auraBlue)
                Spacer()
                Button { close() } label: {
                    Image(systemName: "xmark").font(.system(size: 12, weight: .bold)).foregroundStyle(AuraTheme.textDim)
                }.buttonStyle(.plain)
            }.padding(.bottom, 18)
            HStack(alignment: .top, spacing: 26) {
                VStack(spacing: 16) {
                    ZStack {
                        PsiGauge(frac: credits.fracLeft, lineWidth: 18).frame(width: 220, height: 220)
                        VStack(spacing: 4) {
                            Text(psiFmt(credits.remaining)).font(AuraFont.semi(44)).foregroundStyle(AuraTheme.textPrimary)
                            Text("$PSI REMAINING").auraLabel(11).foregroundStyle(AuraTheme.textDim)
                        }
                    }
                    HStack(spacing: 30) {
                        bigStat("USED THIS CYCLE", psiFmt(credits.used))
                        bigStat("BALANCE", psiFmt(credits.held))
                    }
                    Sparkline(values: credits.usage7d).frame(height: 38)
                }
                .frame(width: 300)
                PsiTopUp()
            }
        }
        .padding(26)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(AuraTheme.bgBase.opacity(0.98))
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(AuraTheme.auraBlue.opacity(0.35), lineWidth: 1))
        )
        .shadow(color: .black.opacity(0.6), radius: 40, x: 0, y: 18)
    }
    private func bigStat(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).auraLabel(9).foregroundStyle(AuraTheme.textDim)
            Text(value).font(AuraFont.semi(22)).foregroundStyle(AuraTheme.textPrimary)
        }
    }
}
