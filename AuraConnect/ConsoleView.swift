import SwiftUI
import Combine

struct ConsoleLine: Identifiable { let id = UUID(); var text: String; var kind: String }

final class Console: ObservableObject {
    @Published var lines: [ConsoleLine] = [ConsoleLine(text: "AURA CONNECT // console ready. type `help`.", kind: "sys")]
    func run(_ raw: String, bt: BluetoothManager) {
        let c = raw.trimmingCharacters(in: .whitespaces)
        if c.isEmpty { return }
        lines.append(ConsoleLine(text: "> " + c, kind: "in"))
        let parts = c.split(separator: " ").map(String.init)
        let head = parts.first?.lowercased() ?? ""
        func out(_ s: String, _ k: String = "out") { lines.append(ConsoleLine(text: s, kind: k)) }
        switch head {
        case "help":   out("commands: status \u{00B7} scan \u{00B7} whoami \u{00B7} say <text> \u{00B7} clear")
        case "status": out(bt.isConnected ? "LINK: secure \u{00B7} AES-CCM \u{00B7} 0 bytes egress" : "LINK: idle")
        case "scan":   out("scanning BLE\u{2026} (demo) found: onyx-7f3a")
        case "whoami": out("Aura \u{2014} Chief Artificial Intelligence. I run ops; the human signs.", "aura")
        case "say":    out("Aura: " + parts.dropFirst().joined(separator: " "), "aura")
        case "clear":  lines = []
        default:       out("unknown: " + head + " \u{2014} try `help`", "err")
        }
        if lines.count > 200 { lines.removeFirst(lines.count - 200) }
    }
}

struct ConsoleView: View {
    @EnvironmentObject var bt: BluetoothManager
    @StateObject private var con = Console()
    @State private var input = ""
    private func color(_ k: String) -> Color {
        switch k {
        case "in":   return .white
        case "aura": return Aura.ember
        case "err":  return Aura.danger
        case "sys":  return Aura.cyan
        default:     return .white.opacity(0.8)
        }
    }
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("CONSOLE").font(.brand(11)).tracking(2.6).foregroundStyle(Aura.ember.opacity(0.8))
                Spacer()
            }.padding(.horizontal, 14).padding(.top, 12)
            ScrollViewReader { sp in
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(con.lines) { l in
                            Text(l.text)
                                .font(.system(size: 12.5, design: .monospaced))
                                .foregroundStyle(color(l.kind))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .id(l.id)
                        }
                    }
                    .padding(14)
                }
                .onChange(of: con.lines.count) { _, _ in
                    if let last = con.lines.last { withAnimation { sp.scrollTo(last.id, anchor: .bottom) } }
                }
            }
            HStack(spacing: 8) {
                Text(">").font(.system(size: 13, design: .monospaced)).foregroundStyle(Aura.ember)
                TextField("type a command\u{2026}", text: $input)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(.white)
                    .onSubmit { con.run(input, bt: bt); input = "" }
            }
            .padding(12)
            .background(Color.white.opacity(0.03))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .glass(Aura.ember)
        .padding(16)
    }
}
