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

    // MARK: - BACKGROUND ORB LAYER
    var backgroundLayer: some View {
        ZStack {

            // Glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.black, .white, .black],
                        center: .center,
                        startRadius: 15,
                        endRadius: 140
                    )
                )
                .scaleEffect(orbGlow ? 1.1 : 0.9)
                .blur(radius: 40)
                .animation(.easeInOut(duration: 1.3).repeatForever(), value: orbGlow)

            // Main Orb
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 180, height: 180)
                .shadow(color: .white, radius: 20)

            // Rotating Energy Ring (FIXED)
            Circle()
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [.black, .white, .black]),
                        center: .center
                    ),
                    lineWidth: 10
                )
                .frame(width: 230, height: 230)
                .blur(radius: 2)
                .rotationEffect(.degrees(orbRotation))
                .animation(.linear(duration: 3).repeatForever(autoreverses: false), value: orbRotation)

            Image(systemName: "sparkles")
                .font(.system(size: 55))
                .foregroundStyle(.white)
        }
        .onAppear {
            orbGlow = true
            orbRotation = 360
        }
    }
}

#Preview {
    DailyLoginView()
        .environmentObject(DailyLoginManager.shared)
        .preferredColorScheme(.dark)
}
