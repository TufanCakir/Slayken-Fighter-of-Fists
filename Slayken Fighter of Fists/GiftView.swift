//
//  GiftView.swift
//  Slayken Fighter of Fists
//

import SwiftUI

struct GiftView: View {

    @EnvironmentObject var giftManager: GiftManager

    // Beispiel-Geschenke
    private let gifts: [GiftItem] = [
        GiftItem(
            id: "daily_1",
            title: "Tägliches Geschenk",
            description: "+50 Coins",
            image: "gift_icon_1",
            reward: GiftItem.Reward(coins: 50, crystals: nil)
        ),
        GiftItem(
            id: "daily_2",
            title: "Bonus Geschenk",
            description: "+5 Crystals",
            image: "gift_icon_2",
            reward: GiftItem.Reward(coins: nil, crystals: 5)
        )
    ]

    @State private var showPopup = false
    @State private var popupText = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {

                        Text("Geschenke")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.top, 10)

                        ForEach(gifts) { gift in
                            giftCard(for: gift)
                        }
                    }
                    .padding(.bottom, 40)
                }

                if showPopup {
                    VStack {
                        Text(popupText)
                            .font(.headline.bold())
                            .foregroundColor(.black)
                            .padding()
                            .background(.white)
                            .cornerRadius(12)
                            .shadow(radius: 10)
                    }
                    .padding(.top, 40)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
    }

    private func giftCard(for gift: GiftItem) -> some View {
        let iconKey = gift.reward.coins != nil ? "coin" : "crystal"
        let hudIcon = HudIconManager.shared.icon(for: iconKey)

        return ZStack {
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(.cyan.opacity(0.4), lineWidth: 1.5)
                )
                .shadow(color: .cyan.opacity(0.3), radius: 10, y: 4)

            HStack(spacing: 14) {

                // ⭐ HUD ICON statt Bild
                if let h = hudIcon {
                    Image(systemName: h.symbol)
                        .font(.system(size: 40))
                        .foregroundColor(Color(hex: h.color))
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(gift.title)
                        .font(.headline.bold())
                        .foregroundColor(.white)

                    Text(gift.description)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()

                if giftManager.isClaimed(gift.id) {
                    Text("Abgeholt")
                        .font(.caption.bold())
                        .foregroundColor(.green)
                } else {
                    claimButton(for: gift)
                }
            }
            .padding()
        }
        .padding(.horizontal)
    }

    private func claimButton(for gift: GiftItem) -> some View {
        Button {
            if giftManager.claim(gift) {
                popupText = "🎉 Geschenk erhalten!"
                showPopup = true
                hidePopup()
            } else {
                popupText = "⚠️ Bereits abgeholt"
                showPopup = true
                hidePopup()
            }
        } label: {
            Text("Abholen")
                .font(.subheadline.bold())
                .foregroundColor(.black)
                .padding(.vertical, 8)
                .padding(.horizontal, 18)
                .background(
                    LinearGradient(colors: [.cyan, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .cornerRadius(10)
                .shadow(color: .cyan.opacity(0.6), radius: 8, y: 3)
        }
    }

    private func hidePopup() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showPopup = false
            }
        }
    }
}

#Preview {
    GiftView()
        .environmentObject(GiftManager.shared)
        .preferredColorScheme(.dark)
}
