import SwiftUI
import Combine

struct AuraBackground: View {
    var energy: Double = 0.6

    @State private var t: Double = 0.0
    private let timer = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common).autoconnect()

    var body: some View {
        let e = max(0.0, min(2.0, energy))
        let drift  = 0.10 + 0.06 * e
        let blur: Double = 22 - 4 * e
        let alphaA = 0.26 + 0.10 * e
        let alphaB = 0.20 + 0.08 * e
        let sweepOpacity = 0.08 + 0.06 * e
        let sweepSpeed   = 0.30 + 0.20 * e
        let sweepAmp: Double = 140 + 100 * e

        return Canvas { ctx, size in
            ctx.fill(Path(CGRect(origin: .zero, size: size)),
                     with: .color(AuraTheme.bgBase))

            let a = 0.5 + 0.5 * sin(t * (0.10 + 0.06 * e))
            let b = 0.5 + 0.5 * cos(t * (0.07 + 0.05 * e))

            let cA = Color(red: 0.06 + 0.06 * a,
                           green: 0.30 + 0.55 * b,
                           blue: 1.00)
            let cB = Color(red: 0.04 + 0.05 * b,
                           green: 0.55 + 0.35 * a,
                           blue: 1.00)

            func blob(_ center: CGPoint, _ r: CGFloat, _ color: Color, _ alpha: Double) {
                let g = GraphicsContext.Shading.radialGradient(
                    Gradient(colors: [color.opacity(alpha), .clear]),
                    center: center, startRadius: 0, endRadius: r
                )
                ctx.fill(
                    Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r,
                                           width: 2*r, height: 2*r)),
                    with: g
                )
            }

            let c1 = CGPoint(
                x: size.width  * (0.28 + drift * sin(t * (0.28 + 0.10 * e))),
                y: size.height * (0.36 + drift * cos(t * (0.22 + 0.10 * e)))
            )
            let c2 = CGPoint(
                x: size.width  * (0.74 + drift * cos(t * (0.20 + 0.10 * e))),
                y: size.height * (0.62 + drift * sin(t * (0.26 + 0.12 * e)))
            )

            let r1 = max(size.width, size.height) * (0.66 + 0.06 * sin(t * 0.18))
            let r2 = max(size.width, size.height) * (0.84 + 0.06 * cos(t * 0.16))

            blob(c1, r1, cA, alphaA)
            blob(c2, r2, cB, alphaB)
        }
        .blur(radius: blur)
        .overlay {
            LinearGradient(colors: [.clear,
                                    AuraTheme.auraBlue.opacity(sweepOpacity),
                                    .clear],
                           startPoint: .top, endPoint: .bottom)
                .rotationEffect(.degrees(16))
                .offset(y: CGFloat(sin(t * sweepSpeed) * sweepAmp))
                .blendMode(.screen)
        }
        .overlay(
            RadialGradient(colors: [.clear, .black.opacity(0.62)],
                           center: .center,
                           startRadius: 80,
                           endRadius: 900)
                .blendMode(.multiply)
        )
        .ignoresSafeArea()
        .onReceive(timer) { _ in t += 1.0 / 30.0 }
    }
}
