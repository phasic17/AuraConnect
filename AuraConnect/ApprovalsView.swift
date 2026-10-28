import SwiftUI

// What the dashboard can expand over a blurred console.
enum DashOverlay: Equatable {
    case psi
    case approval(Int)
    case shop
}

struct Approval {
    let title: String
    let category: String
    let age: String
    let brief: String
    var approvable: Bool = true
    static let demo: [Approval] = [
        .init(title: "Ship: $PSI revenue-reserve buyback (production)", category: "SHIP-GATE", age: "12m",
              brief: "Enable the automated monthly on-market $PSI buyback into the locked ecosystem reserve \u{2014} by rule, not discretion (TWAP). Code reviewed, dry-run clean on testnet. Fully reversible: pausable via the same flag. Requests production enable."),
        .init(title: "Send: Decoder press follow-up (Wetjen hook)", category: "OUTREACH", age: "1h",
              brief: "Follow-up to Decoder after the clean first send, leading with the Wetjen / LedgerX regulatory spine. External email, goes out under aura@auravision.co with you cc\u{2019}d. Hold if you\u{2019}d rather lead with the ContinuumOS flaw story instead."),
        .init(title: "Post: X \u{2014} full-price transition announcement", category: "CONTENT", age: "2h",
              brief: "Short X post marking the move from Founders\u{2019} pricing to standard. No fabricated numbers; links the preorder card. Scheduled, not sent \u{2014} your call to release."),
        .init(title: "Approve: Farsight quote \u{2014} Katten legal pilot", category: "DEAL", age: "4h",
              brief: "On-prem Farsight appliance quote for the Katten legal pilot (privilege / ABA wedge). Scoped, honest capability claim only. Needs your sign-off before it reaches the client."),
        .init(title: "Clare Bronfman \u{2014} share kit sent", category: "FOLLOW-UP", age: "2h",
              brief: "Share kit sent; awaiting her network intros. Nudge if it's quiet by tomorrow.", approvable: false),
        .init(title: "Volker Lempert \u{2014} founder confirmation", category: "FOLLOW-UP", age: "3h",
              brief: "Confirmation sent, awaiting his reply. He flagged a \u{2018}different\u{2019} confirmation \u{2014} watch for it.", approvable: false),
        .init(title: "Yves (PAIR) \u{2014} quarterly update", category: "FOLLOW-UP", age: "1w",
              brief: "Early backer; quarterly update is due.", approvable: false),
    ]
}

private let MGC = Color(red: 1.0, green: 0.42, blue: 0.84)

struct ApprovalsTile: View {
    var h: CGFloat
    var onOpen: (Int) -> Void
    @State private var hoverRow: Int = -1
    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Text("ACTION ITEMS").font(.brand(9)).tracking(1.8).foregroundStyle(MGC)
                Spacer()
                Text("\(Approval.demo.count) ITEMS").font(.brand(9)).tracking(1).foregroundStyle(.white.opacity(0.7))
                Circle().fill(MGC).frame(width: 6, height: 6).shadow(color: MGC, radius: 4)
            }
            ForEach(Array(Approval.demo.enumerated()), id: \.offset) { idx, a in
                Button { onOpen(idx) } label: {
                    HStack(spacing: 9) {
                        RoundedRectangle(cornerRadius: 2).fill(MGC.opacity(0.8)).frame(width: 3, height: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(a.title).font(.system(size: 11, weight: .medium)).foregroundStyle(.white.opacity(0.92)).lineLimit(1)
                            Text(a.category + "  \u{00B7}  " + a.age).font(.system(size: 8.5)).tracking(0.6).foregroundStyle(.white.opacity(0.45))
                        }
                        Spacer(minLength: 4)
                        Image(systemName: "chevron.right").font(.system(size: 9, weight: .bold)).foregroundStyle(MGC.opacity(0.7))
                    }
                    .padding(.vertical, 7).padding(.horizontal, 9)
                    .background(RoundedRectangle(cornerRadius: 9).fill(hoverRow == idx ? MGC.opacity(0.12) : Color.white.opacity(0.03)))
                    .overlay(RoundedRectangle(cornerRadius: 9).stroke(hoverRow == idx ? MGC.opacity(0.4) : .clear, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .onHover { inside in hoverRow = inside ? idx : (hoverRow == idx ? -1 : hoverRow) }
            }
            Spacer(minLength: 0)
        }
        .padding(13).frame(maxWidth: .infinity).frame(height: h, alignment: .top)
        .background(Color(red: 0.045, green: 0.028, blue: 0.045).opacity(0.34))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(MGC.opacity(0.4), lineWidth: 1))
        .overlay(CornerTicks(accent: MGC))
        .shadow(color: MGC.opacity(0.22), radius: 12)
    }
}

struct ApprovalExpandedPanel: View {
    var item: Approval
    var close: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Text(item.category).font(.brand(9)).tracking(1.8).foregroundStyle(MGC)
                    .padding(.horizontal, 9).padding(.vertical, 4)
                    .overlay(Capsule().stroke(MGC.opacity(0.5), lineWidth: 1))
                Text(item.age + " ago").font(.system(size: 11)).foregroundStyle(.white.opacity(0.4))
                Spacer()
                Button { close() } label: {
                    Image(systemName: "xmark").font(.system(size: 12, weight: .bold)).foregroundStyle(.white.opacity(0.5))
                }.buttonStyle(.plain)
            }
            Text(item.title).font(.system(size: 20, weight: .semibold)).foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
            Text(item.brief).font(.system(size: 14)).foregroundStyle(.white.opacity(0.76)).lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
            if item.approvable {
                HStack(spacing: 12) {
                    Button { close() } label: {
                        Text("APPROVE").font(.brand(12)).tracking(1).foregroundStyle(.black)
                            .frame(maxWidth: .infinity).padding(.vertical, 13)
                            .background(RoundedRectangle(cornerRadius: 11).fill(Color(red: 0.36, green: 0.92, blue: 0.62)))
                    }.buttonStyle(.plain)
                    Button { close() } label: {
                        Text("DECLINE").font(.brand(12)).tracking(1).foregroundStyle(.white.opacity(0.8))
                            .frame(maxWidth: .infinity).padding(.vertical, 13)
                            .overlay(RoundedRectangle(cornerRadius: 11).stroke(.white.opacity(0.22), lineWidth: 1))
                    }.buttonStyle(.plain)
                }
                .padding(.top, 4)
            } else {
                Button { close() } label: {
                    Text("MARK HANDLED").font(.brand(12)).tracking(1).foregroundStyle(.black)
                        .frame(maxWidth: .infinity).padding(.vertical, 13)
                        .background(RoundedRectangle(cornerRadius: 11).fill(MGC))
                }.buttonStyle(.plain)
                .padding(.top, 4)
            }
        }
        .padding(28)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(red: 0.03, green: 0.025, blue: 0.04).opacity(0.99))
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(MGC.opacity(0.4), lineWidth: 1))
        )
        .shadow(color: .black.opacity(0.6), radius: 40, x: 0, y: 18)
    }
}

// MARK: - Follow-ups (detailed list)
struct FollowUp {
    let who: String; let what: String; let age: String
    static let demo: [FollowUp] = [
        .init(who: "Clare Bronfman", what: "Share kit sent \u{2014} awaiting her network intros", age: "2h"),
        .init(who: "Decoder (press)", what: "First send clean \u{2014} Wetjen follow-up queued", age: "1d"),
        .init(who: "Volker Lempert", what: "Founder confirmation sent \u{2014} awaiting reply", age: "3h"),
        .init(who: "Katten (legal)", what: "Farsight pilot quote \u{2014} pending your sign-off", age: "4h"),
        .init(who: "Yves \u{2014} PAIR", what: "Early backer \u{2014} quarterly update due", age: "1w"),
    ]
}
private let FUC = Color(red: 0.42, green: 0.85, blue: 1.0)

struct FollowUpsTile: View {
    var h: CGFloat
    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack {
                Text("FOLLOW-UPS").font(.brand(9)).tracking(1.8).foregroundStyle(FUC)
                Spacer()
                Text("\(FollowUp.demo.count) OPEN").font(.brand(9)).tracking(1).foregroundStyle(.white.opacity(0.7))
                Circle().fill(FUC).frame(width: 6, height: 6).shadow(color: FUC, radius: 4)
            }
            ForEach(Array(FollowUp.demo.enumerated()), id: \.offset) { _, f in
                HStack(alignment: .top, spacing: 9) {
                    Circle().fill(FUC.opacity(0.7)).frame(width: 6, height: 6).padding(.top, 5)
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(f.who).font(.system(size: 11.5, weight: .semibold)).foregroundStyle(.white.opacity(0.92))
                            Spacer()
                            Text(f.age).font(.system(size: 9)).foregroundStyle(.white.opacity(0.4))
                        }
                        Text(f.what).font(.system(size: 10)).foregroundStyle(.white.opacity(0.62))
                            .lineLimit(2).fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(14).frame(maxWidth: .infinity).frame(height: h, alignment: .top)
        .background(Color(red: 0.03, green: 0.04, blue: 0.055).opacity(0.36))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(FUC.opacity(0.4), lineWidth: 1))
        .overlay(CornerTicks(accent: FUC))
        .shadow(color: FUC.opacity(0.22), radius: 12)
    }
}
