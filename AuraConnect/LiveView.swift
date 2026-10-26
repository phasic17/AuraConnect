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
            if self.stream.count > 6 { self.stream.removeFirst() }
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
private let CY = Color(red: 0.35, green: 0.82, blue: 1.0)
private let GN = Color(red: 0.30, green: 0.92, blue: 0.60)
private let MG = Color(red: 1.0, green: 0.38, blue: 0.72)
private let VI = Color(red: 0.62, green: 0.48, blue: 1.0)
private let OR = Color(red: 1.0, green: 0.52, blue: 0.22)

private func drawTileChart(_ ctx: GraphicsContext, _ size: CGSize, _ kind: String, _ t: Double, _ ac: Color) {
    let W = size.width, H = size.height
    if kind == "spark" {
        var line = Path(); var area = Path()
        let n = 26
        for i in 0...n {
            let x = W * CGFloat(i) / CGFloat(n)
            let v = 0.5 + 0.34 * sin(Double(i) * 0.5 + t * 0.6) + 0.12 * sin(Double(i) * 1.3 + t)
            let y = H * (1 - CGFloat(max(0.05, min(0.95, v))))
            let pt = CGPoint(x: x, y: y)
            if i == 0 { line.move(to: pt); area.move(to: CGPoint(x: x, y: H)); area.addLine(to: pt) }
            else { line.addLine(to: pt); area.addLine(to: pt) }
        }
        area.addLine(to: CGPoint(x: W, y: H)); area.closeSubpath()
        ctx.fill(area, with: .linearGradient(Gradient(colors: [ac.opacity(0.28), .clear]), startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: 0, y: H)))
        ctx.stroke(line, with: .color(ac), style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round))
    } else if kind == "bars" {
        let vals: [CGFloat] = [0.5, 0.82, 0.4, 0.95, 0.62, 0.74]
        let bw = W / CGFloat(vals.count) * 0.55
        let gap = W / CGFloat(vals.count)
        for (i, v) in vals.enumerated() {
            let vv = v * (0.82 + 0.18 * CGFloat(sin(t * 1.4 + Double(i))))
            let x = CGFloat(i) * gap + (gap - bw) / 2
            let bh = H * vv
            ctx.fill(Path(roundedRect: CGRect(x: x, y: H - bh, width: bw, height: bh), cornerRadius: 2),
                     with: .color(ac.opacity(0.4 + 0.5 * Double(v))))
        }
    } else if kind == "ring" {
        let cx = W / 2, cy = H / 2, r = min(W, H) * 0.40
        ctx.stroke(Path(ellipseIn: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2)), with: .color(ac.opacity(0.18)), lineWidth: 6)
        var arc = Path()
        arc.addArc(center: CGPoint(x: cx, y: cy), radius: r, startAngle: .degrees(-90), endAngle: .degrees(-90 + 360 * 0.42), clockwise: false)
        ctx.stroke(arc, with: .color(ac), style: StrokeStyle(lineWidth: 6, lineCap: .round))
    } else if kind == "dots" {
        let n = 4, gap = W / CGFloat(n + 1)
        for i in 0..<n {
            let x = gap * CGFloat(i + 1)
            let pulse = 0.55 + 0.45 * sin(t * 2 + Double(i) * 0.9)
            ctx.fill(Path(ellipseIn: CGRect(x: x - 7, y: H / 2 - 7, width: 14, height: 14)), with: .color(ac.opacity(0.4 + 0.5 * pulse)))
        }
    }
}

struct ActionTile: View {
    var t: String; var accent: Color; var big: String; var sub: String; var kind: String; var h: CGFloat; var ph: Double
    @State private var hovering = false
    var body: some View {
        TimelineView(.animation) { tl in
            let tt = tl.date.timeIntervalSinceReferenceDate
            let dy = sin(tt * 0.5 + ph) * 1.3
            let throb = hovering ? (0.45 + 0.45 * (0.5 + 0.5 * sin(tt * 4))) : 0.5
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(t).font(.brand(9)).tracking(1.8).foregroundStyle(accent)
                    Spacer()
                    Circle().fill(accent).frame(width: 6, height: 6).shadow(color: accent, radius: 4)
                }
                Text(big).font(.brand(17)).foregroundStyle(.white)
                Text(sub).font(.system(size: 10)).foregroundStyle(.white.opacity(0.6)).lineLimit(2).fixedSize(horizontal: false, vertical: true)
                Canvas { ctx, size in drawTileChart(ctx, size, kind, tt, accent) }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(13).frame(maxWidth: .infinity).frame(height: h)
            .background(Color(red: 0.03, green: 0.028, blue: 0.05).opacity(0.3))
            .background(accent.opacity(hovering ? 0.12 : 0.07))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(accent.opacity(throb), lineWidth: hovering ? 1.7 : 1))
            .overlay(CornerTicks(accent: accent))
            .shadow(color: accent.opacity(hovering ? 0.35 : 0.22), radius: hovering ? 16 : 12)
            .offset(y: dy)
            .onHover { hovering = $0 }
        }
    }
}

private let DOTFONT: [Character: [String]] = [
    "0": ["01110","10001","10011","10101","11001","10001","01110"],
    "1": ["00100","01100","00100","00100","00100","00100","01110"],
    "2": ["01110","10001","00001","00010","00100","01000","11111"],
    "3": ["11111","00010","00100","00010","00001","10001","01110"],
    "4": ["00010","00110","01010","10010","11111","00010","00010"],
    "5": ["11111","10000","11110","00001","00001","10001","01110"],
    "6": ["00110","01000","10000","11110","10001","10001","01110"],
    "7": ["11111","00001","00010","00100","01000","01000","01000"],
    "8": ["01110","10001","10001","01110","10001","10001","01110"],
    "9": ["01110","10001","10001","01111","00001","00010","01100"],
    ":": ["00000","00100","00100","00000","00000","00100","00100"]
]
private func drawDotTime(_ ctx: GraphicsContext, _ size: CGSize, _ s: String, _ col: Color) {
    let px = 2.0, spacing = 2.0
    let totalW = Double(s.count) * (5 * px + spacing) - spacing
    let startX = (Double(size.width) - totalW) / 2
    let startY = (Double(size.height) - 7 * px) / 2
    for (ci, ch) in s.enumerated() {
        guard let rows = DOTFONT[ch] else { continue }
        for (r, row) in rows.enumerated() {
            for (cc, bit) in row.enumerated() {
                if bit == "1" {
                    let dx = startX + Double(ci) * (5 * px + spacing) + Double(cc) * px
                    let dy = startY + Double(r) * px
                    ctx.fill(Path(CGRect(x: dx, y: dy, width: px - 0.4, height: px - 0.4)), with: .color(col))
                }
            }
        }
    }
}

struct ClockCell: View {
    var city: String
    var tz: String
    var now: Date
    var body: some View {
        let f = DateFormatter(); f.timeZone = TimeZone(identifier: tz); f.locale = Locale(identifier: "en_US_POSIX"); f.dateFormat = "HH:mm:ss"
        return VStack(spacing: 4) {
            Text(city).font(.brand(7)).tracking(1.3).lineLimit(1).foregroundStyle(Color(red: 0.35, green: 0.82, blue: 1.0).opacity(0.8))
            Canvas { ctx, size in drawDotTime(ctx, size, f.string(from: now), Color(red: 1, green: 0.69, blue: 0.28)) }
                .frame(width: 96, height: 15)
        }
        .frame(width: 112, height: 44)
        .background(Color(red: 0.03, green: 0.028, blue: 0.05).opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(red: 1, green: 0.69, blue: 0.28).opacity(0.32), lineWidth: 1))
    }
}

struct WorldClocks: View {
    private let zones: [(String, String)] = [("SF", "America/Los_Angeles"), ("NEW YORK", "America/New_York"), ("LONDON", "Europe/London"), ("DUBAI", "Asia/Dubai"), ("TOKYO", "Asia/Tokyo")]
    var body: some View {
        TimelineView(.periodic(from: Date(), by: 1)) { ctx in
            HStack(spacing: 8) {
                ForEach(zones, id: \.0) { z in ClockCell(city: z.0, tz: z.1, now: ctx.date) }
            }
        }
    }
}

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
            let dy = sin(t * 0.55 + phase) * 1.4
            let dx = cos(t * 0.4 + phase) * 1.1
            content()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(alignment: .topLeading) {
                    Text(title).font(.brand(11)).tracking(2.4)
                        .foregroundStyle(accent.opacity(0.5 + 0.5 * energy)).padding(14)
                }
                .background(Color(red: 0.03, green: 0.027, blue: 0.05).opacity(hardened ? 0.30 : 0.08))
                .background(accent.opacity(0.03 + 0.06 * energy))
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
            ScrollView { dashboard }
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 11.0) {
            withAnimation(.easeInOut(duration: 2.2)) { hardened = true }
        }
    }
    private func teleTemp(_ t: PuckTelemetry?) -> String { if let v = t?.temp { return "\(Int(v))\u{00B0}C" }; return "\u{2014}" }
    private func teleMem(_ t: PuckTelemetry?) -> String { if let u = t?.memUsed, let m = t?.memTotal { return "\(String(format: "%.1f", u)) / \(Int(m)) GB" }; return "\u{2014}" }
    private var dashboard: some View {
        let tm = bt.telemetry
        return VStack(spacing: 16) {
            FloatingTile(title: "THE MIND \u{2014} LIVE CONVERSATION", energy: tel.mindEnergy, phase: 0, hardened: hardened) {
                MindLive(chat: tm?.chat ?? [], demo: tel.stream)
            }
            .frame(height: 162)
            .clipped()
            .assemble(0, 8, assembleToken)
            HStack(alignment: .top, spacing: 16) {
                VStack(spacing: 16) {
                    ActionTile(t: "SIGNALS", accent: CY, big: "3 NEW", sub: "2 flagged for you \u{00B7} Decoder replied", kind: "spark", h: 146, ph: 0.3).assemble(1, 8, assembleToken)
                    ActionTile(t: "MODEL WATCH", accent: VI, big: "\(tm?.models ?? 0) RESIDENT", sub: "glm-air \u{00B7} on-device \u{00B7} 0 errors", kind: "spark", h: 246, ph: 0.9).assemble(2, 8, assembleToken)
                }
                VStack(spacing: 16) {
                    ActionTile(t: "PUCK FLEET", accent: GN, big: bt.isConnected ? "1 / 1 ONLINE" : "0 / 1", sub: bt.isConnected ? "Aura Puck \u{00B7} secure link" : "scanning\u{2026}", kind: "dots", h: 228, ph: 1.5).assemble(3, 8, assembleToken)
                    ActionTile(t: "APPROVALS", accent: MG, big: "2 PENDING", sub: "ship-gate review \u{00B7} your call", kind: "ring", h: 116, ph: 2.1).assemble(4, 8, assembleToken)
                }
                VStack(spacing: 16) {
                    ActionTile(t: "ON-DEVICE", accent: OKGREEN, big: teleMem(tm), sub: "\(tm?.models ?? 0) models \u{00B7} AES link \u{00B7} encrypted", kind: "bars", h: 204, ph: 2.7).assemble(5, 8, assembleToken)
                    ActionTile(t: "THERMAL", accent: OR, big: teleTemp(tm), sub: "puck core temperature", kind: "ring", h: 150, ph: 3.3).assemble(6, 8, assembleToken)
                }
            }
            BackupTile(bt: bt)
                .assemble(7, 8, assembleToken)
        }
        .padding(16)
    }
}

struct MindLive: View {
    var chat: [(who: String, text: String)]
    var demo: [LiveTelemetry.StreamLine]
    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Spacer(minLength: 28)
            if !chat.isEmpty {
                ForEach(Array(chat.enumerated()), id: \.offset) { pair in
                    let isAura = pair.element.who.lowercased() == "aura"
                    (Text(isAura ? "Aura: " : (pair.element.who + ": ")).foregroundColor(isAura ? EMBER : .white.opacity(0.92))
                        + Text(pair.element.text).foregroundColor(.white.opacity(0.78)))
                        .font(.system(size: 13, design: .monospaced))
                }
            } else {
                ForEach(demo) { l in
                    Text(l.text).font(.system(size: 13, design: .monospaced)).foregroundStyle(.secondary).italic()
                }
            }
        }
        .padding(.horizontal, 16).padding(.bottom, 14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
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
        .background(Color(red: 0.02, green: 0.04, blue: 0.03).opacity(0.42))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(OKGREEN.opacity(0.22)))
        .overlay(CornerTicks(accent: OKGREEN))
    }
}

struct BackupTile: View {
    @ObservedObject var bt: BluetoothManager
    var body: some View {
        let backing = bt.backupStatus == "backing"
        let done = bt.backupStatus == "done"
        return HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Image(systemName: "externaldrive.badge.checkmark").font(.system(size: 14)).foregroundStyle(OKGREEN)
                    Text("ENCRYPTED BACKUP").font(.brand(13)).tracking(2).foregroundStyle(OKGREEN)
                }
                Text(done ? "Backed up \u{00B7} your puck's config is safe on this Mac"
                          : (bt.isConnected ? "Pull your puck's encrypted config & state to this device"
                                            : "connect your puck to back it up"))
                    .font(.system(size: 11)).foregroundStyle(OKGREEN.opacity(0.72))
                if backing { ProgressView(value: bt.backupProgress).frame(width: 240).tint(OKGREEN) }
            }
            Spacer()
            Button(action: { bt.requestBackup() }) {
                HStack(spacing: 8) {
                    Image(systemName: backing ? "arrow.triangle.2.circlepath" : "arrow.down.circle.fill").font(.system(size: 14))
                    Text(backing ? "BACKING UP\u{2026}" : "BACK UP NOW").font(.brand(12)).tracking(2)
                }
                .foregroundStyle(bt.isConnected ? OKGREEN : .white.opacity(0.4))
                .padding(.horizontal, 18).frame(height: 42)
                .background((bt.isConnected ? OKGREEN : Color.white).opacity(0.12), in: Capsule())
                .overlay(Capsule().stroke(OKGREEN.opacity(bt.isConnected ? 0.5 : 0.2), lineWidth: 1))
            }
            .buttonStyle(.plain).disabled(!bt.isConnected || backing)
        }
        .padding(.horizontal, 26).frame(height: 84)
        .background(Color(red: 0.02, green: 0.04, blue: 0.03).opacity(0.42))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(OKGREEN.opacity(0.3), lineWidth: 1))
        .overlay(CornerTicks(accent: OKGREEN))
    }
}

struct LinkStatusBar: View {
    var tm: PuckTelemetry?
    var connected: Bool
    private func up(_ s: Int?) -> String {
        guard let s = s else { return "\u{2014}" }
        if s >= 86400 { return "\(s / 86400)d \(s % 86400 / 3600)h" }
        if s >= 3600 { return "\(s / 3600)h \(s % 3600 / 60)m" }
        return "\(max(s / 60, 0))m"
    }
    @ViewBuilder private func stat(_ k: String, _ v: String) -> some View {
        VStack(spacing: 2) {
            Text(v).font(.brand(16)).foregroundStyle(.white)
            Text(k).font(.brand(9)).tracking(1.5).foregroundStyle(OKGREEN.opacity(0.6))
        }
    }
    var body: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: "lock.fill").font(.system(size: 13)).foregroundStyle(OKGREEN)
                    Text("ENCRYPTED \u{00B7} ON-DEVICE").font(.brand(13)).tracking(2).foregroundStyle(OKGREEN)
                }
                Text(connected ? "Aura Puck \u{00B7} AES-CCM secure link \u{00B7} running on your device"
                               : "awaiting secure link\u{2026}")
                    .font(.system(size: 11)).foregroundStyle(OKGREEN.opacity(0.72))
            }
            Spacer()
            HStack(spacing: 24) {
                stat("UPTIME", up(tm?.uptime))
                stat("LOAD", tm?.load.map { String(format: "%.2f", $0) } ?? "\u{2014}")
                stat("MODELS", "\(tm?.models ?? 0)")
            }
        }
        .padding(.horizontal, 26).frame(height: 78)
        .background(Color(red: 0.02, green: 0.04, blue: 0.03).opacity(0.42))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(OKGREEN.opacity(0.3), lineWidth: 1))
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
