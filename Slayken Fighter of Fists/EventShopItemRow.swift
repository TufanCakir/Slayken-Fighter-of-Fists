import SwiftUI

struct EventShopItemRow: View {

    let item: EventShopItem
    let onBuy: () -> Void

    @State private var pressed = false

    var body: some View {
        HStack(spacing: 16) {

            // MARK: - ITEM ICON BOX
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(rarityColor.opacity(0.8), lineWidth: 2)
                    )
                    .shadow(color: rarityColor.opacity(0.5), radius: 10, y: 4)

                itemIcon
            }
            .frame(width: 70, height: 70)

            // MARK: - TEXT CONTENT
            VStack(alignment: .leading, spacing: 6) {

                Text(item.name)
                    .font(.headline.bold())
                    .foregroundColor(.white)
                    .shadow(color: rarityColor.opacity(0.8), radius: 8)

                Text(item.description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.75))
            }

            Spacer()

            // MARK: - PRICE + BUTTON
            VStack(alignment: .trailing, spacing: 8) {

                HStack(spacing: 6) {
                    Image(systemName: currencyIcon(item.shop.currency))
                        .foregroundColor(.cyan)

                    Text("\(item.shop.price)")
                        .foregroundColor(.white)
                        .font(.headline.bold())
                }

                Button {
                    pressed = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        pressed = false
                        onBuy()
                    }
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                LinearGradient(colors: [.blue, .cyan],
                                               startPoint: .topLeading,
                                               endPoint: .bottomTrailing)
                            )
                            .shadow(color: .cyan.opacity(0.4), radius: 6, y: 3)

                        Text("Kaufen")
                            .font(.subheadline.bold())
                            .foregroundColor(.black)
                    }
                    .frame(width: 90, height: 32)
                    .scaleEffect(pressed ? 0.95 : 1.0)
                    .animation(.spring(response: 0.35, dampingFraction: 0.7), value: pressed)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.05))
                .shadow(color: .black.opacity(0.4), radius: 8, y: 4)
        )
    }
}

//
// MARK: - ICON SYSTEM
//
private extension EventShopItemRow {

    /// Automatischer Bild-Lader + Fallback Icon
    @ViewBuilder
    var itemIcon: some View {

        // 1. Versuch: Lokales Bild aus Assets (z.B. berserker_schwert.png)
        if UIImage(named: item.id) != nil {
            Image(item.id)
                .resizable()
                .scaledToFit()
                .frame(width: 46, height: 46)
        }
        else {
            // 2. Fallback: Slot Emoji
            Text(iconForSlot(item.slot))
                .font(.system(size: 34))
        }
    }

    func iconForSlot(_ slot: String) -> String {
        switch slot {
        case "weapon": return "🗡"
        case "armor": return "🛡"
        case "helmet": return "⛑"
        case "boots": return "🥾"
        case "gloves": return "🧤"
        case "ring": return "💍"
        default: return "🎁"
        }
    }

    func currencyIcon(_ currency: String) -> String {
        switch currency {
        case "event_crystal": return "diamond.fill"
        case "coin": return "circle.grid.cross.left.filled"
        case "crystal": return "sparkles"
        default: return "questionmark"
        }
    }

    var rarityColor: Color {
        switch item.rarity.lowercased() {
        case "common": return .gray
        case "rare": return .blue
        case "epic": return .purple
        case "legendary": return .yellow
        default: return .white
        }
    }
}
