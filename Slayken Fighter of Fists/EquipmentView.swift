//
//  EquipmentView.swift
//

import SwiftUI

struct EquipmentView: View {

    @EnvironmentObject private var inventory: InventoryManager

    @State private var selectedItem: EventShopItem? = nil
    @State private var showDetail = false

    private let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 22)
    ]

    private var items: [EventShopItem] {
        inventory.ownedEquipment
    }

    var body: some View {
        ZStack {
            backgroundLayer

            VStack(spacing: 24) {

                Text("Ausrüstung")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .cyan.opacity(0.5), radius: 12)
                    .padding(.top)

                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: columns, spacing: 26) {

                        ForEach(items) { item in
                            equipmentCard(item)
                                .onTapGesture {
                                    selectedItem = item
                                    withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                                        showDetail = true
                                    }
                                }
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 50)
                }
            }

            if showDetail, let item = selectedItem {
                detailPopup(item)
                    .transition(.scale.combined(with: .opacity))
                    .zIndex(20)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: showDetail)
    }
}




//
// MARK: - BACKGROUND
//
private extension EquipmentView {


        var backgroundLayer: some View {
            ZStack {
                LinearGradient(
                    colors: [.black, .blue.opacity(0.25), .black],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.clear, .blue.opacity(0.4), .clear],
                            center: .center,
                            startRadius: 30,
                            endRadius: 380
                        )
                    )
                    .blur(radius: 70)
                    .opacity(0.6)

                Image(systemName: "sparkles")
                    .font(.system(size: 240))
                    .foregroundColor(.blue.opacity(0.25))
                    .blur(radius: 50)
                    .offset(y: -160)
            }
        }
    }


//
// MARK: - CARD
//
private extension EquipmentView {

    func equipmentCard(_ item: EventShopItem) -> some View {
        ZStack(alignment: .bottom) {

            RoundedRectangle(cornerRadius: 22)
                .fill(cardGradient(for: item))
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(rarityColor(for: item).opacity(0.8), lineWidth: 2)
                )
                .shadow(color: rarityColor(for: item).opacity(0.4), radius: 16)

            VStack(spacing: 12) {

                itemIcon(for: item)
                    .frame(width: 60, height: 60)

                Text(item.name)
                    .font(.headline.bold())
                    .foregroundColor(.white)
            }
            .padding(.bottom, 20)
        }
        .frame(height: 190)
    }
}


//
// MARK: - DETAIL POPUP
//
private extension EquipmentView {

    func detailPopup(_ item: EventShopItem) -> some View {

        ZStack {

            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture { withAnimation { showDetail = false } }

            VStack(spacing: 20) {

                itemIcon(for: item)
                    .frame(width: 90, height: 90)

                Text(item.name)
                    .font(.title.bold())
                    .foregroundColor(.white)

                Text(item.description)
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.horizontal, 10)

                Divider().background(.white.opacity(0.3))

                statsSection(item)

                Divider().background(.white.opacity(0.3))

                Button {
                    withAnimation { showDetail = false }
                } label: {
                    Text("Schließen")
                        .font(.headline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(.white)
                        .foregroundColor(.black)
                        .cornerRadius(16)
                }
            }
            .padding(30)
            .background(.ultraThinMaterial)
            .cornerRadius(26)
            .shadow(color: .black.opacity(0.6), radius: 25)
            .padding(.horizontal, 40)
        }
    }
}


//
// MARK: - STATS
//
private extension EquipmentView {

    @ViewBuilder
    func statsSection(_ item: EventShopItem) -> some View {

        VStack(alignment: .leading, spacing: 10) {

            if let dmg = item.stats.damageMultiplier {
                statLine("Schaden", "+\(Int((dmg - 1) * 100))%")
            }

            if let atk = item.stats.attackMultiplier {
                statLine("Angriff", "+\(Int((atk - 1) * 100))%")
            }

            if let duration = item.stats.duration {
                statLine("Dauer", "\(duration / 60) min")
            }
        }
    }

    func statLine(_ title: String, _ value: String, color: Color = .white) -> some View {
        HStack {
            Text(title).foregroundColor(.white.opacity(0.7))
            Spacer()
            Text(value).foregroundColor(color)
        }
    }
}



//
// MARK: - HELPERS
//
private extension EquipmentView {

    @ViewBuilder
    func itemIcon(for item: EventShopItem) -> some View {
        // Lokales Bild vorhanden?
        if let imageName = item.image, !imageName.isEmpty {
            Image(imageName)
                .resizable()
                .scaledToFit()
        } else {
            // Fallback: Emoji-Slot
            Text(icon(for: item.slot))
                .font(.system(size: 54))
        }
    }

    func icon(for slot: String) -> String {
        switch slot {
        case "weapon": return "🗡️"
        case "armor": return "🛡️"
        case "amulet": return "🧿"
        case "ring": return "💍"
        default: return "🎁"
        }
    }

    func rarityColor(for item: EventShopItem) -> Color {
        switch item.rarity.lowercased() {
        case "common": return .gray
        case "rare": return .blue
        case "epic": return .purple
        case "legendary": return .yellow
        default: return .white
        }
    }

    func cardGradient(for item: EventShopItem) -> LinearGradient {
        LinearGradient(
            colors: [
                rarityColor(for: item).opacity(0.55),
                .black.opacity(0.8)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}


#Preview {
    EquipmentView()
        .environmentObject(InventoryManager.shared)
        .preferredColorScheme(.dark)
}
