import SwiftUI
import AppKit

private func shopImage(_ name: String) -> Image {
    if let u = Bundle.main.url(forResource: name, withExtension: "png"), let ns = NSImage(contentsOf: u) {
        return Image(nsImage: ns)
    }
    return Image(systemName: "shippingbox.fill")
}
private func shopCopy(_ s: String) { NSPasteboard.general.clearContents(); NSPasteboard.general.setString(s, forType: .string) }
private func shopOpen(_ s: String) { if let u = URL(string: s) { NSWorkspace.shared.open(u) } }

struct ShopItem {
    let name: String
    let tagline: String
    let price: String
    let image: String
    static let demo: [ShopItem] = [
        .init(name: "Aura Puck", tagline: "Add another room \u{00B7} Onyx or Pearl", price: "$2,399", image: "puck_onyx"),
        .init(name: "Cellular Bridge", tagline: "Private wireless \u{00B7} any carrier", price: "$299", image: "shop_bridge"),
        .init(name: "RTX Appliance", tagline: "Claude-class, on-prem in your rack", price: "from $26,999", image: "shop_rtx"),
        .init(name: "Continuum+", tagline: "Enhanced abilities \u{00B7} more on-device compute", price: "$49/mo", image: "continuum_hq"),
    ]
}

private let SHOP_AC = Color(red: 1.0, green: 0.69, blue: 0.28)

struct ShopTile: View {
    var h: CGFloat
    var onOpen: () -> Void
    @State private var hovering = false
    var body: some View {
        Button { onOpen() } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("SHOP \u{00B7} UPGRADE").font(.brand(9)).tracking(1.8).foregroundStyle(SHOP_AC)
                    Spacer()
                    Image(systemName: "cart.fill").font(.system(size: 10)).foregroundStyle(SHOP_AC)
                }
                let cols = [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)]
                LazyVGrid(columns: cols, spacing: 8) {
                    ForEach(0..<ShopItem.demo.count, id: \.self) { i in
                        let it = ShopItem.demo[i]
                        VStack(spacing: 4) {
                            shopImage(it.image).resizable().scaledToFit().frame(height: 42)
                            Text(it.name).font(.system(size: 8.5, weight: .medium)).foregroundStyle(.white.opacity(0.8)).lineLimit(1)
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 7)
                        .background(RoundedRectangle(cornerRadius: 9).fill(Color.white.opacity(0.04)))
                    }
                }
                Text("tap to purchase \u{2014} $PSI or card").font(.system(size: 9)).tracking(0.5)
                    .foregroundStyle(hovering ? SHOP_AC : .white.opacity(0.4))
                    .frame(maxWidth: .infinity, alignment: .center)
                Spacer(minLength: 0)
            }
            .padding(13).frame(maxWidth: .infinity).frame(height: h, alignment: .top)
            .background(Color(red: 0.04, green: 0.032, blue: 0.02).opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(SHOP_AC.opacity(hovering ? 0.6 : 0.4), lineWidth: 1))
            .overlay(CornerTicks(accent: SHOP_AC))
            .shadow(color: SHOP_AC.opacity(0.22), radius: 12)
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}

struct ShopExpandedPanel: View {
    var close: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("SHOP \u{00B7} UPGRADE").font(.brand(11)).tracking(1.8).foregroundStyle(SHOP_AC)
                Spacer()
                Text("pay with $PSI or card \u{2014} both one tap").font(.system(size: 11)).foregroundStyle(.white.opacity(0.45))
                Button { close() } label: { Image(systemName: "xmark").font(.system(size: 12, weight: .bold)).foregroundStyle(.white.opacity(0.5)) }.buttonStyle(.plain)
            }
            let cols = [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]
            LazyVGrid(columns: cols, spacing: 16) {
                ForEach(0..<ShopItem.demo.count, id: \.self) { i in ProductCard(item: ShopItem.demo[i]) }
            }
        }
        .padding(26)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(red: 0.03, green: 0.025, blue: 0.02).opacity(0.99))
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(SHOP_AC.opacity(0.4), lineWidth: 1))
        )
        .shadow(color: .black.opacity(0.6), radius: 40, x: 0, y: 18)
    }
}

private struct ProductCard: View {
    var item: ShopItem
    @State private var copied = false
    var body: some View {
        VStack(spacing: 10) {
            shopImage(item.image).resizable().scaledToFit().frame(height: 86)
            Text(item.name).font(.system(size: 15, weight: .semibold)).foregroundStyle(.white)
            Text(item.tagline).font(.system(size: 10.5)).foregroundStyle(.white.opacity(0.55)).multilineTextAlignment(.center).lineLimit(2)
                .frame(height: 28)
            Text(item.price).font(.system(size: 16, weight: .bold, design: .rounded)).foregroundStyle(SHOP_AC)
            HStack(spacing: 8) {
                Button {
                    shopCopy(PsiConfig.treasury); copied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { copied = false }
                } label: {
                    Text(copied ? "COPIED \u{2713}" : "$PSI").font(.brand(11)).tracking(1).foregroundStyle(SHOP_AC)
                        .frame(maxWidth: .infinity).padding(.vertical, 9)
                        .overlay(RoundedRectangle(cornerRadius: 9).stroke(SHOP_AC.opacity(0.55), lineWidth: 1))
                }.buttonStyle(.plain)
                Button { shopOpen(PsiConfig.stripeURL) } label: {
                    Text("CARD").font(.brand(11)).tracking(1).foregroundStyle(.black)
                        .frame(maxWidth: .infinity).padding(.vertical, 9)
                        .background(RoundedRectangle(cornerRadius: 9).fill(SHOP_AC))
                }.buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.03)))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }
}
