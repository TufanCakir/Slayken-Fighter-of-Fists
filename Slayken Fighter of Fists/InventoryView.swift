import SwiftUI

struct InventoryView: View {

    @EnvironmentObject var inventory: InventoryManager

    // ORB Animation
    @State private var orbGlow = false
    @State private var orbRotation = 0.0

    private let columns = [
        GridItem(.adaptive(minimum: 120), spacing: 20)
    ]

    var body: some View {
        ZStack {

            // Hintergrund ORB + RING + ICON
            RotatingOrbView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
            VStack(spacing: 20) {

                // TITLE
                Text("Inventar")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
                    .shadow(color: .cyan.opacity(0.6), radius: 12)

                // INVENTORY GRID
                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: columns, spacing: 24) {

                        if inventory.ownedEquipment.isEmpty {
                            emptyState
                        } else {
                            ForEach(inventory.ownedEquipment) { item in
                                inventoryCard(for: item)
                            }
                        }

                    }
                    .padding(.horizontal)
                }
            }
            .padding()
        }
        .onAppear {
            inventory.debugInventory()
        }
    }
}

//
// MARK: - ITEM CARD
//
private extension InventoryView {

    func inventoryCard(for item: EventShopItem) -> some View {
        VStack(spacing: 10) {

            // ICON BOX
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial)
                .frame(height: 120)
                .overlay(
                    Text(iconForSlot(item.slot))
                        .font(.system(size: 44))
                        .shadow(color: .black.opacity(0.6), radius: 10)
                )
                .shadow(color: rarityColor(item.rarity).opacity(0.8), radius: 12)

            // NAME
            Text(item.name)
                .font(.headline.bold())
                .foregroundColor(.white)
                .shadow(radius: 3)

            // DESCRIPTION
            Text(item.description)
                .font(.caption)
                .foregroundColor(.white.opacity(0.75))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.05))
        )
        .shadow(color: rarityColor(item.rarity).opacity(0.4), radius: 10)
    }

    // ICON SYSTEM
    func iconForSlot(_ slot: String) -> String {
        switch slot {
        case "weapon": return "🗡️"
        case "armor": return "🛡️"
        case "ring": return "💍"
        case "helmet": return "🪖"
        default: return "❓"
        }
    }

    // RARITY COLORS
    func rarityColor(_ rarity: String) -> Color {
        switch rarity {
        case "common": return .gray
        case "rare": return .blue
        case "epic": return .purple
        case "legendary": return .orange
        default: return .white
        }
    }

    // EMPTY STATE
    var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "shippingbox.fill")
                .font(.system(size: 50))
                .foregroundColor(.white.opacity(0.5))

            Text("Keine Ausrüstung vorhanden")
                .font(.headline)
                .foregroundColor(.white.opacity(0.8))

            Text("Du kannst Items im Event Shop kaufen!")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(.top, 40)
    }
}

//
// MARK: - PREVIEW
//
#Preview {
    InventoryView()
        .environmentObject(InventoryManager.shared)
        .preferredColorScheme(.dark)
}
