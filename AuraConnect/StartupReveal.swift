import SwiftUI
import Foundation

// PROJECT OMICRON — app-launch reveal. The canonical continuum ring, high quality:
// one clean luminous circle drawn on counter-clockwise with a bright hot leading edge
// and a soft bloom, slow and deliberate, then held. No scatter, no flares.

private let CR_AMBER = Color(red: 1.0, green: 0.72, blue: 0.34)
private let CR_WARM  = Color(red: 1.0, green: 0.82, blue: 0.50)
private let CR_HOT   = Color(red: 1.0, green: 0.92, blue: 0.72)

private func drawContinuum(_ ctx: GraphicsContext, _ size: CGSize, _ e: Double) {
    let cx = Double(size.width) / 2
    let cy = Double(size.height) / 2
    let R = min(Double(size.width), Double(size.height)) * 0.20
    let prog = min(max((e - 0.6) / 4.2, 0), 1)       // slow draw-on over ~4.2s
    let startA = -Double.pi / 2                        // top
    let N = 260

    var arc = Path()
    var placed = 0
    for i in 0...N {
        let frac = Double(i) / Double(N)
        if frac > prog { break }
        let ang = startA - frac * 2 * Double.pi        // counter-clockwise
        let pt = CGPoint(x: cx + cos(ang) * R, y: cy + sin(ang) * R)
        if placed == 0 { arc.move(to: pt) } else { arc.addLine(to: pt) }
        placed += 1
    }
    if placed > 1 {
        ctx.stroke(arc, with: .color(CR_AMBER.opacity(0.10)), style: StrokeStyle(lineWidth: 18, lineCap: .round, lineJoin: .round))
        ctx.stroke(arc, with: .color(CR_WARM.opacity(0.24)),  style: StrokeStyle(lineWidth: 8,  lineCap: .round, lineJoin: .round))
        ctx.stroke(arc, with: .color(CR_HOT),                 style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))
    }

    if prog > 0.001 && prog < 0.999 {
        let tipA = startA - prog * 2 * Double.pi
        for j in 0..<9 {
            let ang = tipA + Double(j) * 0.016 * 2 * Double.pi
            let jr = R + (Double((j * 37) % 9) - 4) * 0.6
            let s = 4.2 - Double(j) * 0.35
            let x = cx + cos(ang) * jr
            let y = cy + sin(ang) * jr
            ctx.fill(Path(CGRect(x: x - s / 2, y: y - s / 2, width: s, height: s)),
                     with: .color(CR_WARM.opacity(1 - Double(j) / 9.0)))
        }
        let hx = cx + cos(tipA) * R
        let hy = cy + sin(tipA) * R
        ctx.fill(Path(ellipseIn: CGRect(x: hx - 7, y: hy - 7, width: 14, height: 14)), with: .color(CR_HOT.opacity(0.5)))
        ctx.fill(Path(ellipseIn: CGRect(x: hx - 3.5, y: hy - 3.5, width: 7, height: 7)), with: .color(.white))
    }

    let pulse = 5.0 + 2.0 * sin(e * 2)
    for k in stride(from: 4, through: 1, by: -1) {
        let cr = Double(k) * pulse
        ctx.fill(Path(ellipseIn: CGRect(x: cx - cr, y: cy - cr, width: cr * 2, height: cr * 2)),
                 with: .color(Color(red: 1, green: 0.86, blue: 0.56).opacity(0.07)))
    }
    ctx.fill(Path(ellipseIn: CGRect(x: cx - 3.5, y: cy - 3.5, width: 7, height: 7)), with: .color(.white))

    if prog >= 0.999 {
        let full = Path(ellipseIn: CGRect(x: cx - R, y: cy - R, width: R * 2, height: R * 2))
        ctx.stroke(full, with: .color(CR_WARM.opacity(0.28)), style: StrokeStyle(lineWidth: 8))
        ctx.stroke(full, with: .color(CR_HOT), style: StrokeStyle(lineWidth: 2.4))
    }
}

struct StartupReveal: View {
    var onDone: () -> Void
    @State private var started = Date()

    @ViewBuilder private func wordmark(_ e: Double) -> some View {
        if e > 4.9 {
            Text("A U R A   C O N N E C T")
                .font(.brand(14)).tracking(4)
                .foregroundStyle(.white.opacity(min((e - 4.9) / 1.0, 1) * 0.9))
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
        .onAppear { started = Date(); DispatchQueue.main.asyncAfter(deadline: .now() + 6.4) { onDone() } }
    }
}
