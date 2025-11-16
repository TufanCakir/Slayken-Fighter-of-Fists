//
//  EquipmentSlotView.swift
//

import SwiftUI

struct EquipmentSlotView: View {

    let slot: String
    let equippedItem: EventShopItem?
    let tapAction: () -> Void

    var body: some View {
        Button(action: tapAction) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 80, height: 80)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(borderColor, lineWidth: 2)
                    )

                if let item = equippedItem {
                    Image(item.id)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 45, height: 45)
                        .shadow(color: rarityColor(item.rarity), radius: 8)
                } else {
                    Text(slotIcon(slot))
                        .font(.system(size: 32))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var borderColor: Color {
        equippedItem == nil ? .gray.opacity(0.3) : rarityColor(equippedItem!.rarity)
    }

    private func slotIcon(_ slot: String) -> String {
        switch slot {
        case "weapon": return "🗡"
        case "head": return "⛑"
        case "shoulder": return "🛡"
        case "chest": return "👕"
        case "hands": return "🧤"
        case "legs": return "👖"
        case "feet": return "🥾"
        case "ring": return "💍"
        case "neck": return "📿"
        default: return "❔"
        }
    }

    private func rarityColor(_ rarity: String) -> Color {
        switch rarity {
        case "legendary": return .yellow
        case "epic": return .purple
        case "rare": return .blue
        case "common": return .gray
        default: return .white
        }
    }
}

#Preview {
    EquipmentSlotView(
        slot: "weapon",
        equippedItem: nil,
        tapAction: {}
    )
    .padding()
    .background(.black)
}
