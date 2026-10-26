import SwiftUI
import Foundation
import AVFoundation

// Authentic Continuum mark (port of continuum_mark.py): a bright ring CONTINUOUS/solid at
// the top, DISSOLVING into pixels as it travels counter-clockwise. We draw it on slowly.
private let C_HOT   = (r: 1.0, g: 0.910, b: 0.804)
private let C_EMBER = (r: 0.949, g: 0.635, b: 0.361)
private func thash(_ i: Int, _ s: Double) -> Double { let v = sin(Double(i) * s) * 43758.5453; return v - v.rounded(.down) }

private func drawMark(_ ctx: GraphicsContext, _ size: CGSize, _ reveal: Double) {
    let cx = Double(size.width) / 2
    let cy = Double(size.height) / 2
    let R = min(Double(size.width), Double(size.height)) * 0.185
    var ang = 0.0
    var i = 0
    while ang < 360 {
        let p = ang / 360.0
        if p <= reveal {
            let a = (90.0 + ang) * Double.pi / 180.0
            let x = cx + R * cos(a)
            let y = cy - R * sin(a)
            var ps = R * 0.085 * (1 - 0.5 * p)
            let jr = pow(p, 1.6) * R * 0.16
            let jx = (thash(i, 12.9898) - 0.5) * jr
            let jy = (thash(i, 78.233) - 0.5) * jr
            let drop = p > 0.30 && thash(i, 3.37) < (p - 0.30) * 0.85
            if p > 0.55 && thash(i, 5.71) < 0.35 { ps *= 0.6 }
            if !drop {
                let tt = min(p * 2.0, 1.0)
                let col = Color(red: C_HOT.r + (C_EMBER.r - C_HOT.r) * tt,
                                green: C_HOT.g + (C_EMBER.g - C_HOT.g) * tt,
                                blue: C_HOT.b + (C_EMBER.b - C_HOT.b) * tt)
                let alpha = 1 - 0.22 * p
                ctx.fill(Path(CGRect(x: x + jx - ps, y: y + jy - ps, width: ps * 2, height: ps * 2)), with: .color(col.opacity(alpha * 0.16)))
                ctx.fill(Path(CGRect(x: x + jx - ps / 2, y: y + jy - ps / 2, width: ps, height: ps)), with: .color(col.opacity(alpha)))
            }
        }
        ang += 0.42 + pow(p, 2) * 3.4
        i += 1
    }
}

struct StartupReveal: View {
    var onDone: () -> Void
    @State private var started = Date()
    @State private var player: AVAudioPlayer?
    var body: some View {
        TimelineView(.animation) { tl in
            let e = tl.date.timeIntervalSince(started)
            let reveal = min(max((e - 0.8) / 12.4, 0), 1)
            ZStack {
                Color(red: 0.031, green: 0.027, blue: 0.039)
                Canvas { ctx, size in drawMark(ctx, size, reveal) }
                VStack(spacing: 8) {
                    Text("\(Int(reveal * 100))%").font(.brand(34)).foregroundStyle(.white.opacity(0.92))
                    Text("LOADING").font(.brand(10)).tracking(6).foregroundStyle(Color(red: 0.95, green: 0.64, blue: 0.36).opacity(0.75))
                    Text("ESTABLISHING SECURE LINK").font(.brand(8)).tracking(3).foregroundStyle(.white.opacity(0.3))
                }
                if e > 13.0 {
                    VStack { Spacer()
                        Text("A U R A   C O N N E C T").font(.brand(14)).tracking(4)
                            .foregroundStyle(.white.opacity(min((e - 13.0) / 1.2, 1) * 0.9)).padding(.bottom, 90)
                    }
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            started = Date()
            if let u = Bundle.main.url(forResource: "loading_music", withExtension: "m4a"),
               let p = try? AVAudioPlayer(contentsOf: u) {
                p.prepareToPlay(); p.volume = 0; player = p; p.play()
                for i in 0...6 { let vv = Double(i) / 6 * 0.9; DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.1) { self.player?.volume = Float(vv) } }
            }
            for i in 0...8 { let vv = 0.9 * (1 - Double(i) / 8); DispatchQueue.main.asyncAfter(deadline: .now() + 13.6 + Double(i) * 0.15) { self.player?.volume = Float(vv) } }
            DispatchQueue.main.asyncAfter(deadline: .now() + 15.0) { self.player?.stop(); onDone() }
        }
    }
}
