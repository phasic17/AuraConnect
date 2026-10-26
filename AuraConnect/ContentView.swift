import SwiftUI
import Combine

enum AuraSection: String, CaseIterable, Identifiable {
    case live          = "Live"
    case console       = "Console"
    case transfer      = "Transfer"
    case updates       = "Updates"
    case modules       = "AI Modules"
    case account       = "Account"
    case usage         = "Ledger Usage"
    case security      = "Data Security"

    var id: String { rawValue }
    var systemImage: String {
        switch self {
        case .live:     return "waveform.path.ecg"
        case .console:  return "terminal"
        case .transfer: return "arrow.up.doc.on.clipboard"
        case .updates:  return "arrow.down.circle"
        case .modules:  return "cpu"
        case .account:  return "person.crop.circle"
        case .usage:    return "chart.bar.xaxis"
        case .security: return "lock.shield"
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var bt: BluetoothManager
    @State private var section: AuraSection = .live
    @State private var showStartup = true
    @StateObject private var voice = VoiceManager()
    @State private var showVault = false

    var body: some View {
        ZStack {
            AuraBackground(energy: bt.isConnected ? 1.1 : 0.5)

            HStack(spacing: 0) {
                Sidebar(section: $section)
                    .frame(width: 230)

                detail
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            if showStartup {
                StartupReveal(onDone: { withAnimation(.easeInOut(duration: 0.9)) { showStartup = false }; voice.activate() })
                    .transition(.opacity)
                    .zIndex(100)
            }
            VStack {
                HStack(spacing: 10) {
                    Spacer()
                    ListeningPill(voice: voice)
                    LockButton { withAnimation { voice.lock() } }
                    SeverButton { withAnimation { showVault = true } }
                }
                .padding(16)
                Spacer()
            }
            .zIndex(50)
            if showVault {
                DisconnectVault(onClosed: {
                    bt.disconnect()
                    withAnimation(.easeInOut(duration: 0.8)) { showVault = false }
                })
                .zIndex(200)
            }
            if voice.locked {
                LockScreen(onUnlock: { withAnimation { voice.unlock() } })
                    .zIndex(300)
            }
        }
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private var detail: some View {
        VStack(spacing: 0) {
            HeaderBar()
                .frame(height: 64)

            Group {
                switch section {
                case .live:     LiveView()
                case .console:  ConsoleView()
                case .transfer: TransferView()
                case .updates:  UpdatesView()
                case .modules:  AIModulesView()
                case .account:  AccountView()
                case .usage:    LedgerUsageView()
                case .security: DataSecurityView()
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 18)
        }
    }
}

// MARK: Sidebar

private struct Sidebar: View {
    @Binding var section: AuraSection
    @EnvironmentObject var bt: BluetoothManager

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            brandHeader
                .padding(.top, 22)
                .padding(.horizontal, 18)
                .padding(.bottom, 14)

            AuraDivider().padding(.horizontal, 14)

            ScrollView {
                VStack(spacing: 4) {
                    ForEach(AuraSection.allCases) { s in
                        SidebarRow(section: s, selected: section == s) {
                            section = s
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.top, 14)
            }

            Spacer()

            footer
                .padding(.horizontal, 16)
                .padding(.bottom, 18)
        }
        .background(.ultraThinMaterial)
        .overlay(alignment: .trailing) {
            Rectangle().fill(AuraTheme.panelStroke).frame(width: 1)
        }
    }

    private var brandHeader: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle().stroke(AuraTheme.auraBlue.opacity(0.6), lineWidth: 1)
                    .frame(width: 32, height: 32)
                Circle().fill(AuraTheme.auraBlue.opacity(0.15))
                    .frame(width: 22, height: 22)
                Circle().fill(AuraTheme.auraBlue)
                    .frame(width: 6, height: 6)
                    .shadow(color: AuraTheme.auraBlue, radius: 6)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("AURA")
                    .auraLabel(13)
                    .foregroundStyle(.white)
                Text("CONNECT")
                    .auraLabel(11)
                    .foregroundStyle(AuraTheme.auraBlue)
            }
            Spacer()
        }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                AuraStatusDot(color: bt.isConnected ? AuraTheme.okGreen
                              : (bt.state == .scanning ? AuraTheme.warnAmber : AuraTheme.textFaint),
                              pulses: bt.isConnected || bt.state == .scanning)
                Text(bt.state.summary)
                    .auraBody(11)
                    .foregroundStyle(AuraTheme.textDim)
                    .lineLimit(2)
            }
            if !bt.lastEvent.isEmpty {
                Text(bt.lastEvent)
                    .font(AuraFont.mono(10))
                    .foregroundStyle(AuraTheme.textFaint)
                    .lineLimit(2)
                    .truncationMode(.head)
            }
        }
    }
}

private struct SidebarRow: View {
    let section: AuraSection
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: section.systemImage)
                    .font(.system(size: 15, weight: .medium))
                    .frame(width: 22)
                Text(section.rawValue)
                    .font(AuraFont.medium(13))
                    .tracking(0.4)
                Spacer()
                if selected {
                    Capsule().fill(AuraTheme.auraBlue)
                        .frame(width: 3, height: 14)
                        .shadow(color: AuraTheme.auraBlue, radius: 4)
                }
            }
            .foregroundStyle(selected ? AuraTheme.textPrimary : AuraTheme.textDim)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(selected ? AuraTheme.auraBlue.opacity(0.10) : .clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: Header bar

private struct HeaderBar: View {
    @EnvironmentObject var bt: BluetoothManager
    // Tick once a second so the "Xs ago" string updates while idle.
    @State private var nowTick: Date = Date()
    private let tickTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var statusColor: Color {
        if bt.isConnected { return AuraTheme.okGreen }
        if bt.isRecentlyConnected { return AuraTheme.warnAmber }
        return AuraTheme.textFaint
    }

    private var statusLabel: String {
        if let name = bt.connectedDeviceName { return name }
        if bt.isRecentlyConnected,
           let name = bt.lastConnectedDevice?.name,
           let seen = bt.lastSeenText {
            return "\(name) — idle \(seen)"
        }
        return "No puck connected"
    }

    private var statusEmphasis: Bool {
        bt.isConnected || bt.isRecentlyConnected
    }

    var body: some View {
        HStack(spacing: 14) {
            Spacer()
            HStack(spacing: 10) {
                AuraStatusDot(color: statusColor, pulses: bt.isConnected)
                Text(statusLabel)
                    .auraBody(12)
                    .foregroundStyle(statusEmphasis ? AuraTheme.textPrimary : AuraTheme.textDim)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(.white.opacity(0.05))
            )
            .overlay(Capsule().stroke(AuraTheme.panelStroke, lineWidth: 1))
            .id(Int(nowTick.timeIntervalSince1970))   // re-render each second so "Xs ago" stays fresh
            .onReceive(tickTimer) { nowTick = $0 }
        }
        .padding(.horizontal, 24)
    }
}
