import SwiftUI
import Foundation
import AVFoundation
import AppKit

private let CR_AMBER = Color(red: 1.0, green: 0.72, blue: 0.34)
private let CR_OK = Color(red: 0.24, green: 0.90, blue: 0.69)

private func continuumImage() -> Image? {
    if let u = Bundle.main.url(forResource: "continuum_hq", withExtension: "png"), let ns = NSImage(contentsOf: u) {
        return Image(nsImage: ns)
    }
    return nil
}

struct StartupReveal: View {
    var onDone: () -> Void
    @State private var started = Date()
    @State private var music: AVAudioPlayer?
    @State private var voice: AVAudioPlayer?
    private let WELCOME = "welcome, let's get started"

    private func ringP(_ e: Double) -> Double { min(max((e - 0.8) / 11.0, 0), 1) }
    private func welcomeShown(_ e: Double) -> String {
        let L = WELCOME.count
        var n = 0
        if e < 2.5 { n = 0 }
        else if e < 2.5 + Double(L) * 0.18 { n = Int((e - 2.5) / 0.18) }
        else if e < 12.0 { n = L }
        else { n = max(0, L - Int((e - 12.0) / 0.18)) }
        return String(WELCOME.prefix(min(max(n, 0), L)))
    }
    private func pct(_ e: Double) -> Int { Int(min(max((e - 12.0) / 4.4, 0), 1) * 100) }
    private func sceneOpacity(_ e: Double) -> Double { min(min(e / 1.4, 1), max(0, (22.5 - e) / 2.0)) }

    var body: some View {
        TimelineView(.animation) { tl in
            let e = tl.date.timeIntervalSince(started)
            ZStack {
                Color.black
                GeometryReader { g in
                    let D = min(g.size.width, g.size.height) * 0.58
                    ZStack {
                        if let img = continuumImage() {
                            img.resizable().interpolation(.high).scaledToFit().frame(width: D, height: D)
                        }
                    }
                    .frame(width: g.size.width, height: g.size.height)
                    .mask(
                        Canvas { ctx, size in
                            let c = CGPoint(x: size.width / 2, y: size.height / 2)
                            let bigR = max(size.width, size.height)
                            var p = Path(); p.move(to: c)
                            let steps = max(1, Int(ringP(e) * 360))
                            for i in 0...steps {
                                let frac = Double(i) / 360.0
                                let ang = -Double.pi / 2 - frac * 2 * Double.pi
                                p.addLine(to: CGPoint(x: c.x + CGFloat(cos(ang)) * bigR, y: c.y + CGFloat(sin(ang)) * bigR))
                            }
                            p.closeSubpath()
                            ctx.fill(p, with: .color(.white))
                        }
                    )
                }
                centerContent(e)
            }
            .overlay(alignment: .bottom) {
                if e >= 7.6 && e < 12.2 {
                    VStack(spacing: 8) {
                        Text("VOICE AUTHENTICATION").font(.brand(11)).tracking(5).foregroundStyle(CR_AMBER.opacity(0.9))
                        Text("PAUL CHOU   \u{00B7}   ALPHA  ALPHA  BRAVO").font(.brand(16)).tracking(2).foregroundStyle(.white.opacity(0.95))
                        authWave(e)
                    }
                    .padding(.bottom, 70)
                    .opacity(min((e - 7.6) / 0.8, 1) * min((12.2 - e) / 0.8, 1))
                }
            }
            .overlay(alignment: .bottomTrailing) {
                Text("BUILD " + BUILD_TAG).font(.brand(9)).tracking(2).foregroundStyle(.white.opacity(0.28)).padding(16)
            }
            .overlay(alignment: .topLeading) {
                let w = welcomeShown(e)
                if !w.isEmpty {
                    HStack(spacing: 1) {
                        Text(w).font(.brand(19)).foregroundStyle(.white.opacity(0.95))
                        if e < 16.6 { Text("\u{2588}").font(.brand(17)).foregroundStyle(CR_AMBER.opacity(0.4 + 0.5 * sin(e * 6))) }
                    }
                    .padding(.leading, 36).padding(.top, 32)
                }
            }
            .opacity(sceneOpacity(e))
        }
        .ignoresSafeArea()
        .onAppear { runSequence() }
    }

    @ViewBuilder private func centerContent(_ e: Double) -> some View {
        if e >= 12.0 && e < 16.8 {
            Text("\(pct(e))%").font(.brand(36)).foregroundStyle(.white.opacity(0.92))
        } else if e >= 16.8 {
            VStack(spacing: 8) {
                Image(systemName: "checkmark.seal.fill").font(.system(size: 30)).foregroundStyle(CR_OK)
                Text("IDENTITY CONFIRMED").font(.brand(12)).tracking(3).foregroundStyle(CR_OK.opacity(0.9))
            }
            .opacity(min((e - 16.8) / 0.8, 1))
        }
    }
    @ViewBuilder private func authWave(_ e: Double) -> some View {
        HStack(spacing: 4) {
            ForEach(0..<9, id: \.self) { i in
                Capsule().fill(CR_AMBER.opacity(0.8))
                    .frame(width: 3, height: 6 + 15 * abs(sin(e * 3 + Double(i) * 0.7)))
            }
        }.frame(height: 24)
    }

    private func play(_ res: String) {
        guard let u = Bundle.main.url(forResource: res, withExtension: "m4a"), let p = try? AVAudioPlayer(contentsOf: u) else { return }
        p.prepareToPlay(); p.play(); voice = p
    }
    private func runSequence() {
        started = Date()
        if let u = Bundle.main.url(forResource: "loading_music", withExtension: "m4a"), let p = try? AVAudioPlayer(contentsOf: u) {
            p.numberOfLoops = -1; p.prepareToPlay(); p.volume = 0; music = p; p.play()
            for i in 0...8 { let vv = Double(i) / 8 * 0.85; DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.14) { self.music?.volume = Float(vv) } }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) { self.play("aura_auth") }
        DispatchQueue.main.asyncAfter(deadline: .now() + 17.3) { self.play("aura_welcomeback") }
        for i in 0...8 { let vv = 0.85 * (1 - Double(i) / 8); DispatchQueue.main.asyncAfter(deadline: .now() + 20.5 + Double(i) * 0.22) { self.music?.volume = Float(vv) } }
        DispatchQueue.main.asyncAfter(deadline: .now() + 22.5) { self.music?.stop(); onDone() }
    }
}
