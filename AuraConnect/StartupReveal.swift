import SwiftUI

// PROJECT OMICRON — app-launch reveal. The canonical continuum ring, highly rendered:
// a luminous gold circle pixelating counter-clockwise with a bright leading edge and a
// glowing core, then dissolving into the app. Slow, cinematic — it breathes.

private let CEMBER = Color(red: 1, green: 0.69, blue: 0.28)

private func drawContinuum(_ ctx: GraphicsContext, _ size: CGSize, _ e: Double) {
    let cx = size.width / 2
    let cy = size.height / 2
    let R = min(size.width, size.height) * 0.20
    let prog = min(max((e - 0.35) / 2.6, 0), 1)   // ring fills 0..1 over ~2.6s
    let N = 176
    for i in 0..<N {
        let frac = Double(i) / Double(N)
        if frac > prog { continue }
        let ang = -Double.pi / 2 - frac * .pi * 2    // start at top, pixelate COUNTER-CLOCKWISE
        let lead = max(0, 1 - (prog - frac) / 0.16)  // 1 at the leading edge, fading behind
        let bright = 0.30 + 0.70 * lead
        let jr = R + sin(frac * 90 + e * 2) * 1.4     // faint radial shimmer (pixelating feel)
        let x = cx + cos(ang) * jr
        let y = cy + sin(ang) * jr
        let hs = 10.0 + 11.0 * lead                   // glow halo
        let haloRect = CGRect(x: x - hs, y: y - hs, width: hs * 2, height: hs * 2)
        ctx.fill(Path(ellipseIn: haloRect), with: .color(Color(red: 1, green: 0.72, blue: 0.32).opacity(0.05 + 0.11 * lead)))
        let s = 2.6 + 3.2 * lead                      // bright pixel
        let col = Color(red: 1, green: 0.80 + 0.2 * lead, blue: 0.45 + 0.45 * lead)
        ctx.fill(Path(ellipseIn: CGRect(x: x - s / 2, y: y - s / 2, width: s, height: s)), with: .color(col.opacity(bright)))
    }
    if prog > 0.03 {
        ctx.stroke(Path(ellipseIn: CGRect(x: cx - R, y: cy - R, width: R * 2, height: R * 2)),
                   with: .color(CEMBER.opacity(0.08 * prog)), lineWidth: 1)
    }
    let pulse = 4 + 2 * sin(e * 3)
    for k in stride(from: 5, through: 1, by: -1) {
        let cr = Double(k) * pulse
        ctx.fill(Path(ellipseIn: CGRect(x: cx - cr, y: cy - cr, width: cr * 2, height: cr * 2)),
                 with: .color(Color(red: 1, green: 0.86, blue: 0.56).opacity(0.09)))
    }
    ctx.fill(Path(ellipseIn: CGRect(x: cx - 4, y: cy - 4, width: 8, height: 8)), with: .color(.white))
}

struct StartupReveal: View {
    var onDone: () -> Void
    @State private var started = Date()

    @ViewBuilder private func wordmark(_ e: Double) -> some View {
        if e > 2.9 {
            Text("A U R A   C O N N E C T")
                .font(.system(size: 14, weight: .semibold))
                .tracking(4)
                .foregroundStyle(.white.opacity(min((e - 2.9) / 0.9, 1) * 0.85))
                .padding(.bottom, 90)
        }
    }

    var body: some View {
        TimelineView(.animation) { tl in
            let e = tl.date.timeIntervalSince(started)
            ZStack {
                Color(red: 0.02, green: 0.016, blue: 0.04)
                Canvas { ctx, size in drawContinuum(ctx, size, e) }
                VStack { Spacer(); wordmark(e) }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            started = Date()
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) { onDone() }
        }
    }
}
