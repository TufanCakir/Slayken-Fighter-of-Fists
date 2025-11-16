//
//  DailyLoginView.swift
//

import SwiftUI

struct DailyLoginView: View {

    @EnvironmentObject var loginManager: DailyLoginManager

    // ORB Animation
    @State private var orbGlow = false
    @State private var orbRotation = 0.0

    private let rewards: [DailyReward] = [
        DailyReward(day: 1, title: "+300 Coins", coins: 300, crystals: nil),
        DailyReward(day: 2, title: "+30 Crystals", coins: nil, crystals: 30),
        DailyReward(day: 3, title: "+300 Coins", coins: 300, crystals: nil),
        DailyReward(day: 4, title: "+30 Crystals", coins: nil, crystals: 30),
        DailyReward(day: 5, title: "+300 Coins", coins: 300, crystals: nil),
        DailyReward(day: 6, title: "Mega Gift: +100 Crystals", coins: nil, crystals: 100),
        DailyReward(day: 7, title: "Weekly Super Reward: +300 Crystals", coins: nil, crystals: 300)
    ]

    @State private var popupText = ""
    @State private var showPopup = false

    var body: some View {
        NavigationStack {
            ZStack {
                
                backgroundLayer
                    .ignoresSafeArea()

                VStack(spacing: 22) {

                    Text("Täglicher Login Bonus")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 10)

                    Text("Tag \(loginManager.currentDay) von 7")
                        .font(.headline)
                        .foregroundColor(.cyan)

                    rewardCard

                    Spacer()
                }

                if showPopup {
                    popup
                }
            }
        }
    }

    // MARK: - REWARD CARD
    private var rewardCard: some View {
        let reward = rewards[loginManager.currentDay - 1]

        return VStack(spacing: 16) {
            Text(reward.title)
                .font(.title3.bold())
                .foregroundColor(.white)

            if loginManager.claimedToday {
                Text("Heute bereits abgeholt ✓")
                    .foregroundColor(.green)
                    .font(.headline)
            } else {
                Button {
                    claimReward(reward)
                } label: {
                    Text("Abholen")
                        .font(.headline.bold())
                        .foregroundColor(.black)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 30)
                        .background(
                            LinearGradient(colors: [.cyan, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(20)
        .shadow(color: .cyan.opacity(0.4), radius: 10, y: 4)
        .padding(.horizontal)
    }

    // MARK: - CLAIM HANDLER
    private func claimReward(_ reward: DailyReward) {
        if loginManager.claim(reward: reward) {
            popupText = "🎉 Belohnung erhalten!"
        } else {
            popupText = "⚠️ Heute bereits abgeholt"
        }
        showPopup = true
        hidePopup()
    }

    // MARK: - POPUP
    private var popup: some View {
        VStack {
            Text(popupText)
                .font(.headline.bold())
                .foregroundColor(.black)
                .padding()
                .background(.white)
                .cornerRadius(12)
        }
        .padding(.top, 40)
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    private func hidePopup() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { showPopup = false }
        }
    }

    // MARK: - Background Layer
        var backgroundLayer: some View {
            ZStack {

                // 🌑 DARK → BLUE → DARK Gradient
                LinearGradient(
                    colors: [
                        .black,
                        Color.white.opacity(0.3),
                        .black
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

            }
        }
    }

#Preview {
    DailyLoginView()
        .environmentObject(DailyLoginManager.shared)
        .preferredColorScheme(.dark)
}
