import SwiftUI
import Foundation
import AVFoundation
import AppKit

private let CR_AMBER = Color(red: 1.0, green: 0.72, blue: 0.34)
private let CR_OK = Color(red: 0.24, green: 0.90, blue: 0.69)
private let CR_CY = Color(red: 0.35, green: 0.82, blue: 1.0)
private func continuumImage() -> Image? {
    if let u = Bundle.main.url(forResource: "continuum_hq", withExtension: "png"), let ns = NSImage(contentsOf: u) { return Image(nsImage: ns) }
    return nil
}
private func puckImageNamed(_ pearl: Bool) -> Image {
    let name = pearl ? "puck_pearl" : "puck_onyx"
    if let u = Bundle.main.url(forResource: name, withExtension: "png"), let ns = NSImage(contentsOf: u) { return Image(nsImage: ns) }
    return Image(systemName: "circle.fill")
}
struct DetectedPuck: Identifiable { let id: Int; let name: String; let rssi: String; let pearl: Bool }

struct PuckCard: View {
    var puck: DetectedPuck
    var state: Int
    var tap: () -> Void
    var body: some View {
        let ac = puck.pearl ? Color.white : CR_AMBER
        Button(action: tap) {
            VStack(spacing: 6) {
                puckImageNamed(puck.pearl).resizable().scaledToFit().frame(width: 110, height: 110)
                    .shadow(color: ac.opacity(state == 2 ? 0 : 0.5), radius: 18)
                    .opacity(state == 2 ? 0.4 : 1)
                Text(puck.name).font(.brand(11)).foregroundStyle(.white.opacity(state == 2 ? 0.5 : 0.95))
                Text(state == 1 ? "SYNCING\u{2026}" : "\u{25CF} " + puck.rssi)
                    .font(.brand(8)).tracking(1.5).foregroundStyle(state == 1 ? CR_OK : ac.opacity(0.85))
            }
        }
        .buttonStyle(.plain)
    }
}

struct StartupReveal: View {
    @ObservedObject var bt: BluetoothManager
    var onDone: () -> Void
    @State private var started = Date()
    @State private var phase = 0          // 0 init, 1 detect, 2 connect, 3 voiceprint, 4 welcome
    @State private var phaseStart = Date()
    @State private var selected: Int? = nil
    @State private var fadingOut = false
    @State private var music: AVAudioPlayer?
    @State private var voice: AVAudioPlayer?
    private var liveDevices: [AuraDevice] { Array(bt.devices.prefix(3)) }
    private let PHRASE = "PAUL CHOU   \u{00B7}   ALPHA   ALPHA   BRAVO"

    private func typed(_ s: String, _ el: Double, _ start: Double, _ rate: Double) -> String {
        if el < start { return "" }
        return String(s.prefix(min(s.count, Int((el - start) / rate))))
    }
    private func ringReveal(_ e: Double) -> Double { phase == 0 ? min(max((e - 0.8) / 9.0, 0), 1) : 1 }
    private func ringOpacity() -> Double { (phase == 1 || phase == 2) ? 0.5 : 1.0 }
    private func header(_ e: Double, _ pe: Double) -> String {
        switch phase {
        case 0: return typed("initializing... standby for puck detection", e, 1.2, 0.08)
        case 1: return typed(liveDevices.isEmpty ? "scanning for your puck..." : "\(liveDevices.count) puck\(liveDevices.count == 1 ? "" : "s") detected \u{2014} select", pe, 0.2, 0.05)
        case 2: return typed("connecting & syncing now...", pe, 0.1, 0.05)
        case 3: return typed("voice authentication", pe, 0.2, 0.05)
        default: return "identity confirmed \u{00B7} welcome back"
        }
    }

    var body: some View {
        TimelineView(.animation) { tl in
            let e = tl.date.timeIntervalSince(started)
            let pe = tl.date.timeIntervalSince(phaseStart)
            GeometryReader { g in
                let D = min(g.size.width, g.size.height) * 0.52
                let cx = g.size.width / 2, cy = g.size.height / 2
                ZStack {
                    Color.black
                    ringLayer(g.size, D, ringReveal(e)).opacity(ringOpacity())
                    centerLayer(e, pe, cx, cy, D)
                    if phase == 1 || phase == 2 {
                        Canvas { ctx, _ in
                            for i in 0..<liveDevices.count {
                                let ang = (-90.0 + Double(i) * 120.0) * Double.pi / 180.0
                                let edge = CGPoint(x: cx + cos(ang) * (D / 2), y: cy + sin(ang) * (D / 2))
                                let pos = CGPoint(x: cx + cos(ang) * (D * 0.80), y: cy + sin(ang) * (D * 0.80))
                                let sel = (phase == 2 && selected == i)
                                let dim = (phase == 2 && selected != i)
                                var line = Path(); line.move(to: edge); line.addLine(to: pos)
                                let col: Color = sel ? CR_OK : CR_AMBER.opacity(dim ? 0.12 : 0.6)
                                ctx.stroke(line, with: .color(col), style: StrokeStyle(lineWidth: sel ? 2.0 : 1.3, dash: [7, 7], dashPhase: -e * 10))
                            }
                        }
                        .opacity(min(pe / 0.6, 1))
                        ForEach(Array(liveDevices.enumerated()), id: \.element.id) { pair in
                            let ang = (-90.0 + Double(pair.offset) * 120.0) * Double.pi / 180.0
                            let dev = pair.element
                            PuckCard(puck: DetectedPuck(id: pair.offset, name: dev.name, rssi: "\(dev.rssi) dBm", pearl: dev.name.lowercased().contains("pearl")),
                                     state: cardState(pair.offset),
                                     tap: { if phase == 1 { goConnect(dev, pair.offset) } })
                                .position(x: cx + cos(ang) * (D * 0.80), y: cy + sin(ang) * (D * 0.80))
                                .opacity(min(pe / 0.8, 1))
                        }
                        if liveDevices.isEmpty && phase == 1 {
                            VStack(spacing: 12) {
                                ProgressView().tint(CR_AMBER)
                                Text("SCANNING FOR PUCKS\u{2026}").font(.brand(11)).tracking(3).foregroundStyle(CR_AMBER.opacity(0.8))
                            }.position(x: cx, y: cy)
                        }
                    }
                }
                .overlay(alignment: .topLeading) {
                    HStack(spacing: 1) {
                        Text(header(e, pe)).font(.brand(18)).foregroundStyle(.white.opacity(0.95))
                        Text("\u{2588}").font(.brand(16)).foregroundStyle(CR_AMBER.opacity(0.4 + 0.5 * sin(e * 5)))
                    }.padding(.leading, 40).padding(.top, 36)
                }
                .overlay(alignment: .bottomTrailing) {
                    Text("BUILD " + BUILD_TAG).font(.brand(9)).tracking(2).foregroundStyle(.white.opacity(0.3)).padding(18)
                }
            }
            .opacity(fadingOut ? 0 : min(e / 1.4, 1))
        }
        .ignoresSafeArea()
        .onAppear { runSequence() }
        .onChange(of: bt.isConnected) { _, now in if now && phase == 2 { goVoiceprint() } }
    }

    private func cardState(_ id: Int) -> Int {
        if phase == 2 { return selected == id ? 1 : 2 }
        return 0
    }
    @ViewBuilder private func ringLayer(_ size: CGSize, _ D: Double, _ reveal: Double) -> some View {
        ZStack {
            if let img = continuumImage() { img.resizable().interpolation(.high).scaledToFit().frame(width: D, height: D) }
        }
        .frame(width: size.width, height: size.height)
        .mask(Canvas { ctx, sz in
            let c = CGPoint(x: sz.width / 2, y: sz.height / 2)
            let bigR = max(sz.width, sz.height)
            var p = Path(); p.move(to: c)
            let steps = max(1, Int(reveal * 360))
            for i in 0...steps {
                let frac = Double(i) / 360.0
                let ang = -Double.pi / 2 - frac * 2 * Double.pi
                p.addLine(to: CGPoint(x: c.x + CGFloat(cos(ang)) * bigR, y: c.y + CGFloat(sin(ang)) * bigR))
            }
            p.closeSubpath(); ctx.fill(p, with: .color(.white))
        })
    }
    @ViewBuilder private func centerLayer(_ e: Double, _ pe: Double, _ cx: Double, _ cy: Double, _ D: Double) -> some View {
        if phase == 2 {
            VStack(spacing: 10) {
                ProgressView(value: min(pe / 3.4, 1)).frame(width: 220).tint(CR_OK)
                Text("SECURE LINK \u{00B7} AES-CCM").font(.brand(10)).tracking(3).foregroundStyle(CR_OK.opacity(0.8))
            }.position(x: cx, y: cy + D / 2 + 60)
        } else if phase == 3 {
            VStack(spacing: 9) {
                Text("VOICE AUTHENTICATION").font(.brand(11)).tracking(5).foregroundStyle(CR_AMBER.opacity(0.9))
                Text(typed(PHRASE, pe, 0.6, 0.11)).font(.brand(17)).tracking(2).foregroundStyle(.white.opacity(0.95))
                HStack(spacing: 4) {
                    ForEach(0..<9, id: \.self) { i in
                        Capsule().fill(CR_AMBER.opacity(0.8)).frame(width: 3, height: 6 + 14 * abs(sin(pe * 3 + Double(i) * 0.7)))
                    }
                }.frame(height: 22)
            }.position(x: cx, y: cy + D / 2 + 60)
        } else if phase == 4 {
            VStack(spacing: 8) {
                Image(systemName: "checkmark.seal.fill").font(.system(size: 30)).foregroundStyle(CR_OK)
                Text("IDENTITY CONFIRMED").font(.brand(12)).tracking(3).foregroundStyle(CR_OK.opacity(0.9))
            }.position(x: cx, y: cy)
        }
    }

    private func play(_ res: String) {
        guard let u = Bundle.main.url(forResource: res, withExtension: "m4a"), let p = try? AVAudioPlayer(contentsOf: u) else { return }
        p.prepareToPlay(); p.play(); voice = p
    }
    private func runSequence() {
        started = Date(); phaseStart = Date(); phase = 0
        if let u = Bundle.main.url(forResource: "loading_music", withExtension: "m4a"), let p = try? AVAudioPlayer(contentsOf: u) {
            p.numberOfLoops = -1; p.prepareToPlay(); p.volume = 0; music = p; p.play()
            for i in 0...8 { let vv = Double(i) / 8 * 0.85; DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.16) { self.music?.volume = Float(vv) } }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.5) { if self.phase == 0 { self.phase = 1; self.phaseStart = Date() } }
    }
    private func goConnect(_ dev: AuraDevice, _ i: Int) {
        selected = i; phase = 2; phaseStart = Date()
        bt.select(dev); bt.connectSelected()
        DispatchQueue.main.asyncAfter(deadline: .now() + 12.0) { if self.phase == 2 { self.goVoiceprint() } }
    }
    private func goVoiceprint() {
        guard phase == 2 else { return }
        phase = 3; phaseStart = Date(); play("aura_auth")
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.6) { self.afterVoiceprint() }
    }
    private func goWelcomeSoon() {}
    private func scheduleFromVoiceprint() {}
    private func finishOut() {
        // Gently fade the loading music to silence rather than letting it cut off
        // abruptly when the reveal view (and its player) is torn down on login.
        if let m = music {
            let steps = 28, dur = 2.0, v0 = m.volume
            for i in 1...steps {
                DispatchQueue.main.asyncAfter(deadline: .now() + dur * Double(i) / Double(steps)) {
                    self.music?.volume = v0 * Float(1.0 - Double(i) / Double(steps))
                    if i == steps { self.music?.stop(); self.music = nil }
                }
            }
        }
        withAnimation(.easeInOut(duration: 1.3)) { fadingOut = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { onDone() }
    }
    private func afterVoiceprint() {
        phase = 4; phaseStart = Date(); play("aura_welcomeback")
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.6) { finishOut() }
    }
    private func armVoiceprintTimer() {}
}
