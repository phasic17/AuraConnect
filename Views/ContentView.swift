import SwiftUI

enum AuraSection: String, CaseIterable, Identifiable {
    case devices = "Devices"
    case transfer = "Transfer Data"
    case updates = "Software Updates"
    case auraModules = "Aura AI Modules"
    case identity = "Identity"
    case logs = "Logs"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .devices: return "dot.radiowaves.left.and.right"
        case .transfer: return "tray.and.arrow.down.fill"
        case .updates: return "arrow.triangle.2.circlepath.circle.fill"
        case .auraModules: return "cube.transparent"
        case .identity: return "person.text.rectangle"
        case .logs: return "doc.text.magnifyingglass"
        }
    }
}

struct ContentView: View {
    @StateObject private var bt = BluetoothManager()
    @State private var selection: AuraSection = .devices

    private var bgEnergy: Double {
        bt.isSending ? 2.0 : (bt.isConnected ? 1.0 : 0.0)
    }

    var body: some View {
        NavigationStack {
            HStack(spacing: 0) {
                // LEFT: Sidebar we fully control
                ZStack(alignment: .trailing) {
                    sidebar
                    AuraRailDivider(energy: bgEnergy)
                }
                .frame(width: 300)                 // tweak width here
                .background(AuraRailBackground(energy: bgEnergy))

                // RIGHT: Detail
                detail
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(AuraTheme.bg0)
            .toolbar {
                ToolbarItem(placement: .automatic) { Spacer() }

                ToolbarItem(placement: .automatic) {
                    Image("ledgerai_logo")
                        .resizable()
                        .interpolation(.high)
                        .antialiased(true)
                        .scaledToFit()
                        .frame(height: 30)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(.ultraThinMaterial)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.20),
                                            AuraTheme.auraBlue.opacity(0.30),
                                            Color.white.opacity(0.08)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .shadow(color: AuraTheme.auraBlue.opacity(0.35), radius: 14, y: 6)
                        .padding(.trailing, 5)
                        .padding(.top, 25)
                        .scaleEffect(0.9)
                }
            }
        }
    }

    // MARK: - Sidebar
    private var sidebar: some View {
        ZStack {
            // DEBUG / FORCED BACKGROUND (this MUST be visible)
            LinearGradient(
                colors: [
                    Color(red: 0.15, green: 0.15, blue: 0.18),
                    Color(red: 0.05, green: 0.05, blue: 0.06),
                    Color(red: 0.12, green: 0.12, blue: 0.14)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 14) {
                header

                railMenu
                    .padding(.top, 4)

                Spacer(minLength: 0)

                footer
            }
            .padding(14)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var railMenu: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(AuraSection.allCases) { item in
                Button {
                    selection = item
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: item.icon)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white.opacity(selection == item ? 0.95 : 0.70))
                            .frame(width: 18)

                        Text(item.rawValue.uppercased())
                            .auraLabel(13)
                            .foregroundStyle(.white.opacity(selection == item ? 0.95 : 0.74))

                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .overlay(alignment: .leading) {
                    if selection == item {
                        Rectangle()
                            .fill(AuraTheme.auraBlue.opacity(0.55))
                            .frame(width: 2)
                            .padding(.vertical, 4)
                    }
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("AuraConnect")
                .auraTitle()
                .foregroundStyle(AuraTheme.auraBlue)
                .shadow(color: AuraTheme.auraBlue.opacity(0.65), radius: 16)

            Text(bt.status)
                .auraBody(14)
                .foregroundStyle(AuraTheme.textDim)
                .lineLimit(2)
        }
        .auraGlass(corner: 18, glow: true)
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Circle()
                    .fill(bt.isConnected ? AuraTheme.auraCyan.opacity(0.95) : Color.orange.opacity(0.9))
                    .frame(width: 8, height: 8)

                Text(bt.isConnected ? "CONNECTED" : "NOT CONNECTED")
                    .font(AuraFont.medium(12))
                    .tracking(1.0)
                    .foregroundStyle(.white.opacity(0.85))
            }

            Text("LOCAL-ONLY • SECURE TRANSFER • SIGNED UPDATES")
                .font(AuraFont.regular(11))
                .tracking(0.9)
                .foregroundStyle(.white.opacity(0.45))
        }
        .auraGlass(corner: 18, glow: bt.isSending)
    }

    // MARK: - Detail

    @ViewBuilder
    private var detail: some View {
        ZStack {
            AuraBackground(energy: bgEnergy)

            switch selection {
            case .devices:  DevicesView(bt: bt)
            case .transfer: TransferView(bt: bt)
            case .updates:  UpdatesView(bt: bt)
            case .auraModules: AuraAIModulesView()
            case .identity: IdentityView()
            case .logs:     LogsView()
            }
        }
    }
}

// MARK: - Rail Divider / Background (Patek)

private struct AuraRailDivider: View {
    let energy: Double

    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.white.opacity(0.10))
                .frame(width: 1)

            Rectangle()
                .fill(AuraTheme.auraBlue.opacity(0.12 + 0.10 * min(energy, 2.0)))
                .frame(width: 10)
                .blur(radius: 8)
        }
    }
}

private struct AuraRailBackground: View {
    let energy: Double

    var body: some View {
        ZStack {
            // Deep lacquer base
            LinearGradient(
                colors: [
                    Color(red: 0.02, green: 0.02, blue: 0.025),
                    Color(red: 0.035, green: 0.035, blue: 0.045),
                    Color(red: 0.02, green: 0.02, blue: 0.025)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Guilloché (forced-visible; we’ll tune down after you confirm)
            AuraGuilloche(ringCount: 84, opacity: 0.42, lineWidth: 0.55)
                .blendMode(.softLight)

            // Brushed sheen
            LinearGradient(
                colors: [
                    Color.white.opacity(0.00),
                    Color.white.opacity(0.10),
                    Color.white.opacity(0.00)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .blendMode(.softLight)
            .opacity(0.55)

            // Controlled aura bloom
            RadialGradient(
                colors: [
                    AuraTheme.auraBlue.opacity(0.10 + 0.08 * min(energy, 2.0)),
                    Color.clear
                ],
                center: .topLeading,
                startRadius: 10,
                endRadius: 260
            )
            .blendMode(.screen)

            // Vignette
            Rectangle()
                .fill(
                    RadialGradient(
                        colors: [Color.clear, Color.black.opacity(0.85)],
                        center: .center,
                        startRadius: 110,
                        endRadius: 480
                    )
                )
                .blendMode(.multiply)
                .opacity(0.75)
        }
        .ignoresSafeArea()
    }
}

