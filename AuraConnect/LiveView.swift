import SwiftUI
import Combine

// PROJECT OMICRON — the Reveal. Floating, context-reactive glass tiles over the world-map
// backdrop. The Mind (live cognition) is the hero; the room map lives in the background now.
// Telemetry is a labelled DEMO STREAM until the puck GATT characteristic ships (P1).

final class LiveTelemetry: ObservableObject {
    struct Vital: Identifiable { let id = UUID(); var name: String; var frac: Double; var value: String }
    struct StreamLine: Identifiable { let id = UUID(); var kind: String; var text: String }

    @Published var stream: [StreamLine] = []
    @Published var vitals: [Vital] = [
        .init(name: "on-device models", frac: 1.00, value: "3 resident"),
        .init(name: "puck temp",        frac: 0.62, value: "71\u{00B0}C"),
        .init(name: "memory",           frac: 0.48, value: "7.6 / 16 GB"),
        .init(name: "AES link",         frac: 0.99, value: "encrypted")
    ]
    @Published var eventsProcessed: Int = 0
    @Published var mindEnergy: Double = 0.45
    @Published var sysEnergy: Double = 0.5
    let isSimulated = true

    private let lines: [(String, String)] = [
        ("q", "Paul: \"what's on my plate this morning?\""),
        ("j", "interject? 0.91 \u{2014} addressed, answer"),
        ("m", "on-device \u{00B7} glm-air \u{00B7} 240ms"),
        ("r", "guest speech \u{2014} unverified voice, not retained"),
        ("q", "\"...remind me to call the printer guy\""),
        ("j", "interject? 0.88 \u{2014} capture task"),
        ("m", "intent \u{2192} reminder \u{00B7} local store"),
        ("r", "TV audio \u{2014} ambient, ignored"),
        ("j", "interject? 0.12 \u{2014} stay quiet"),
        ("q", "\"Aura, keep it down for now\""),
        ("j", "mute \u{00B7} persistent \u{00B7} acknowledged")
    ]
    private var idx = 0
    private var timer: Timer?
    func start() {
        stop()
        timer = Timer.scheduledTimer(withTimeInterval: 1.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let l = self.lines[self.idx % self.lines.count]
            self.stream.append(StreamLine(kind: l.0, text: l.1))
            if self.stream.count > 11 { self.stream.removeFirst() }
            self.idx += 1
            self.eventsProcessed += Int.random(in: 10...60)
            withAnimation(.easeOut(duration: 1.0)) {
                self.mindEnergy *= 0.5
                if l.0 == "j" || l.0 == "m" || l.0 == "q" { self.mindEnergy = 1.0 }
                self.sysEnergy = 0.5 + 0.12 * sin(Double(self.idx) * 0.7)
            }
        }
    }
    func stop() { timer?.invalidate(); timer = nil }
}

private let EMBER = Color(red: 1, green: 0.69, blue: 0.28)
private let OKGREEN = Color(red: 0.24, green: 0.90, blue: 0.69)

private func drawReveal(_ ctx: GraphicsContext, _ size: CGSize, _ e: Double) {
    let a = min(e / 2.4, 1)
    let cols = Int(size.width / 16)
    let glyphs = ["0", "1", "\u{03A8}", "\u{0394}", "\u{25C7}", "\u{25B3}"]
    if cols > 0 {
        for i in 0..<cols {
            let seed = Double((i * 131) % 97)
            let y = (e * 520 + seed * 40).truncatingRemainder(dividingBy: size.height + 120) - 60
            let gl = glyphs[(i + Int(e * 8)) % 6]
            let lit = (i % 23) == (Int(e * 5) % 23)
            let col: Color = lit ? EMBER : Color(red: 1, green: 0.72, blue: 0.34).opacity(0.18 + 0.4 * a)
            ctx.draw(Text(gl).font(.system(size: 14)).foregroundStyle(col), at: CGPoint(x: Double(i) * 16 + 8, y: y))
        }
    }
    let cx = size.width / 2, cy = size.height / 2
    let p = min(e / 2.2, 1)
    let segs = 64
    for i in 0..<segs {
        let frac = Double(i) / Double(segs)
        if frac >= p { continue }
        let ang = -Double.pi / 2 - frac * .pi * 2
        let x = cx + cos(ang) * 92
        let y = cy + sin(ang) * 92
        let s = 3 + sin(frac * 30 + p * 10) * 1.5
        let col: Color = (i % 9 == 0) ? EMBER : Color(red: 1, green: 0.81, blue: 0.54)
        ctx.fill(Path(CGRect(x: x - s / 2, y: y - s / 2, width: s, height: s)), with: .color(col))
    }
    let core = 10 + 6 * sin(p * 8)
    ctx.fill(Path(ellipseIn: CGRect(x: cx - core, y: cy - core, width: core * 2, height: core * 2)), with: .color(EMBER))
}

struct FloatingTile<Content: View>: View {
    var title: String
    var energy: Double
    var phase: Double
    var accent: Color = EMBER
    var hardened: Bool = true
    @ViewBuilder var content: () -> Content
    var body: some View {
        TimelineView(.animation) { tl in
            let t = tl.date.timeIntervalSinceReferenceDate
            let dy = sin(t * 0.55 + phase) * 4
            let dx = cos(t * 0.4 + phase) * 3
            content()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(alignment: .topLeading) {
                    Text(title).font(.brand(11)).tracking(2.4)
                        .foregroundStyle(accent.opacity(0.5 + 0.5 * energy)).padding(14)
                }
                .background(.ultraThinMaterial)
                .background(accent.opacity(0.04 + 0.08 * energy))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(accent.opacity(0.18 + 0.42 * energy), lineWidth: 1))
                .overlay(CornerTicks(accent: accent))
                .shadow(color: accent.opacity(0.12 + 0.24 * energy), radius: 13 + 11 * energy)
                .opacity(hardened ? (0.55 + 0.30 * energy) : (0.24 + 0.12 * energy))
                .scaleEffect(1 + 0.012 * energy)
                .offset(x: dx, y: dy)
        }
    }
}

struct LiveView: View {
    var assembleToken: Int = 0
    @EnvironmentObject var bt: BluetoothManager
    @StateObject private var tel = LiveTelemetry()
    @State private var revealing = false
    @State private var revealStart = Date()
    @State private var hardened = false

    var body: some View {
        ZStack {
            dashboard
            if revealing { RevealOverlay(start: revealStart).transition(.opacity).zIndex(10) }
        }
        .onAppear { tel.start(); scheduleHarden(); if bt.isConnected { fire() } }
        .onDisappear { tel.stop() }
        .onChange(of: bt.isConnected) { _, now in if now { fire() } }
        .onChange(of: assembleToken) { _, _ in scheduleHarden() }
    }
    private func fire() {
        revealStart = Date()
        withAnimation(.easeOut(duration: 0.4)) { revealing = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.3) {
            withAnimation(.easeInOut(duration: 1.0)) { revealing = false }
        }
    }
    private func scheduleHarden() {
        hardened = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 11.5) {
            withAnimation(.easeInOut(duration: 2.2)) { hardened = true }
        }
    }
    private var dashboard: some View {
        VStack(spacing: 14) {
            FloatingTile(title: "THE MIND \u{2014} LIVE COGNITION", energy: tel.mindEnergy, phase: 0, hardened: hardened) {
                MindStream(lines: tel.stream)
            }
            .assemble(0, 3, 0, 185, assembleToken)
            FloatingTile(title: "ON-DEVICE SYSTEM", energy: tel.sysEnergy, phase: 1.6, accent: OKGREEN, hardened: hardened) {
                VitalsView(vitals: tel.vitals)
            }
            .frame(height: 150)
            .assemble(1, 3, 0, 15, assembleToken)
            EgressBar(events: tel.eventsProcessed)
                .assemble(2, 3, 0, -195, assembleToken)
            if tel.isSimulated {
                Text("DEMO STREAM \u{2014} live puck telemetry lands in P1")
                    .font(.brand(10)).tracking(2).foregroundStyle(EMBER.opacity(0.5))
            }
        }
        .padding(16)
    }
}

struct MindStream: View {
    var lines: [LiveTelemetry.StreamLine]
    private func color(_ k: String) -> Color {
        switch k {
        case "q": return .white
        case "j": return EMBER
        case "m": return Color(red: 1, green: 0.78, blue: 0.5)
        default:  return .secondary
        }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Spacer(minLength: 30)
            ForEach(lines) { l in
                Text((l.kind == "r" ? "\u{00B7} " : "") + l.text)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(color(l.kind))
                    .italic(l.kind == "r")
            }
        }
        .padding(.horizontal, 16).padding(.bottom, 14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
    }
}

struct VitalsView: View {
    var vitals: [LiveTelemetry.Vital]
    var body: some View {
        VStack(spacing: 10) {
            Spacer(minLength: 24)
            ForEach(vitals) { v in
                HStack(spacing: 10) {
                    Text(v.name).font(.system(size: 12)).foregroundStyle(.white.opacity(0.8)).frame(width: 118, alignment: .leading)
                    GeometryReader { g in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.08))
                            Capsule().fill(LinearGradient(colors: [EMBER, Color(red: 1, green: 0.48, blue: 0.42)], startPoint: .leading, endPoint: .trailing))
                                .frame(width: g.size.width * min(v.frac, 1))
                        }
                    }.frame(height: 7)
                    Text(v.value).font(.system(size: 12)).foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 16).padding(.bottom, 16)
    }
}

struct EgressBar: View {
    var events: Int
    var body: some View {
        HStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 3) {
                Text("0 BYTES").font(.brand(32)).foregroundStyle(OKGREEN)
                    .shadow(color: OKGREEN.opacity(0.4), radius: 14)
                Text("SENT TO THE CLOUD \u{00B7} THIS SESSION").font(.brand(11)).tracking(1.6).foregroundStyle(OKGREEN.opacity(0.7))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(events) events processed \u{2014} all in this room.").font(.system(size: 12)).foregroundStyle(OKGREEN.opacity(0.75))
                Text("nothing left it. that is the product.").font(.system(size: 12)).foregroundStyle(OKGREEN.opacity(0.75))
            }
        }
        .padding(.horizontal, 26).frame(height: 88)
        .background(.ultraThinMaterial)
        .background(OKGREEN.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(OKGREEN.opacity(0.22)))
        .overlay(CornerTicks(accent: OKGREEN))
    }
}

struct RevealOverlay: View {
    var start: Date
    @ViewBuilder private func caption(_ e: Double) -> some View {
        if e > 1.4 {
            Text("BLE SECURE LINK ESTABLISHED \u{00B7} REVEALING YOUR ROOM")
                .font(.brand(13)).tracking(2.5).foregroundStyle(EMBER.opacity(0.7)).padding(.bottom, 60)
        }
    }
    var body: some View {
        TimelineView(.animation) { tl in
            let e = tl.date.timeIntervalSince(start)
            Canvas { ctx, size in drawReveal(ctx, size, e) }
                .background(Color(red: 0.02, green: 0.016, blue: 0.04))
                .overlay(alignment: .bottom) { caption(e) }
        }
        .ignoresSafeArea()
    }
}
