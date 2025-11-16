//
//  EventView.swift
//  Slayken Fighter of Fists
//
//  Created by Tufan Cakir on 2025-10-30.
//

import SwiftUI

@MainActor
struct EventView: View {

    // MARK: JSON Data
    @State private var events: [Event] = Bundle.main.decodeSafe("events.json")
    @State private var bosses: [Boss] = Bundle.main.decodeSafe("eventBosses.json")

    // MARK: States
    @State private var selectedEvent: Event?
    @State private var showBattle = false
    @State private var showVictoryOverlay = false
    @State private var victoryMessage: String = ""
    @State private var fadeBackground = false
    // ORB Animation
     @State private var orbGlow = false
     @State private var orbRotation = 0.0

    // MARK: Environment
    @EnvironmentObject private var coinManager: CoinManager
    @EnvironmentObject private var crystalManager: CrystalManager
    @EnvironmentObject private var accountManager: AccountLevelManager
    @EnvironmentObject private var characterManager: CharacterManager
    @EnvironmentObject private var skillManager: SkillManager

    // MARK: Body
    var body: some View {
        ZStack {
            backgroundLayer
                .ignoresSafeArea()
            
            if !showBattle {
                eventSelectionView
                    .opacity(fadeBackground ? 0 : 1)
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }

            if showVictoryOverlay {
                victoryOverlay(text: victoryMessage)
                    .zIndex(10)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .navigationTitle("Events")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showBattle) { battleScreen }
    }
}

//
// MARK: - UI
//
private extension EventView {
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

    // MARK: Event Selection
    var eventSelectionView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {

                // ⭐ EVENT SHOP BUTTON
                NavigationLink {
                    EventShopView()
                        .environmentObject(EventShopManager.shared)
                        .environmentObject(CrystalManager.shared)
                        .environmentObject(CoinManager.shared)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "cart.fill")
                        Text("Event Shop")
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(18)
                    .foregroundStyle(.linearGradient(colors: [.white, .white], startPoint: .top, endPoint: .bottom))
                }

                // ⭐ TITLE
                Text("Select an Event")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.linearGradient(colors: [.white, .white], startPoint: .top, endPoint: .bottom))
                    .padding(.top, 10)

                // ⭐ EVENT LIST
                LazyVStack(spacing: 20) {
                    ForEach(events) { event in
                        eventCard(for: event)
                    }
                }

                Spacer(minLength: 60)
            }
            .padding(.horizontal, 18)
        }
    }


    // MARK: Event Card
    func eventCard(for event: Event) -> some View {
        Button { startBattle(for: event) } label: {
            ZStack(alignment: .bottomLeading) {

                eventImage(for: event.image)
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay(gradientOverlay)
                    .overlay(borderOverlay)
                    .shadow(color: .black.opacity(0.7), radius: 10, y: 4)

                VStack(alignment: .leading, spacing: 4) {
                    Text(event.name)
                        .font(.headline.weight(.bold))
                        .foregroundColor(.white)
                        .shadow(radius: 2)

                    Text(event.description)
                        .font(.headline.weight(.bold))
                        .foregroundColor(.white)
                        .shadow(radius: 2)
                }
                .padding(12)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(selectedEvent?.id == event.id ? 0.96 : 1)
        .animation(.easeInOut(duration: 0.2), value: selectedEvent?.id)
    }

    var gradientOverlay: some View {
        LinearGradient(
            colors: [.clear, .clear, .clear],
            startPoint: .bottom,
            endPoint: .top
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    var borderOverlay: some View {
        RoundedRectangle(cornerRadius: 18)
            .stroke(Color.cyan.opacity(0.6), lineWidth: 1.4)
    }

    // MARK: Event Image Loader
    @ViewBuilder
    func eventImage(for name: String) -> some View {
        if name.lowercased().starts(with: "http") {
            AsyncImage(url: URL(string: name)) { phase in
                switch phase {
                case .empty:
                    ZStack {
                        Color.gray.opacity(0.15)
                        ProgressView().tint(.cyan)
                    }
                case .success(let img):
                    img.resizable().scaledToFill()
                default:
                    Color.gray.opacity(0.25)
                }
            }
        } else {
            Image(name).resizable().scaledToFit()
        }
    }

    // MARK: Victory Overlay
    func victoryOverlay(text: String) -> some View {
        VStack(spacing: 18) {
            Text("Victory!")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom))

            Text(text)
                .font(.headline)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            Button {
                closeBattle()
            } label: {
                Text("Back to Events")
                    .font(.headline.bold())
                    .padding(.vertical, 10)
                    .padding(.horizontal, 26)
                    .background(LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom))
                    .clipShape(Capsule())
                    .foregroundColor(.black)
            }
        }
        .padding(30)
        .background(.ultraThinMaterial)
        .cornerRadius(26)
        .shadow(color: .black.opacity(0.7), radius: 16)
        .frame(maxWidth: 320)
    }
}

//
// MARK: - BATTLE LOGIC
//
private extension EventView {

    var battleScreen: some View {
        Group {
            if let event = selectedEvent,
               let boss = bosses.first(where: { $0.id == event.bossId }) {

                BattleSceneView(controller: createController(boss: boss, event: event))
                    .environmentObjects(coinManager, crystalManager, accountManager, characterManager, skillManager)
                    .background(Color.black)
                    .ignoresSafeArea()

            } else {
                fallbackBattleView
            }
        }
    }

    func createController(boss: Boss, event: Event) -> BattleSceneController {
        let controller = BattleSceneController(
            boss: boss,
            bossHp: boss.hp,
            coinManager: coinManager,
            crystalManager: crystalManager,
            accountManager: accountManager,
            characterManager: characterManager,
            skillManager: skillManager
        )

        controller.onFight = {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {

                // 💎 Reward für Events
                let reward = Int.random(in: 10...50) // ändere wie du willst
                CrystalManager.shared.addCrystals(reward)

                // 📝 Victory Text inkl. Reward
                victoryMessage = "\(boss.name) was defeated!\n\n+💎\(reward) Event Crystals"

                // UI Update
                showVictoryOverlay = true
                showBattle = false
            }
        }


        controller.onExit = {
            closeBattle()
        }

        return controller
    }

    func startBattle(for event: Event) {
        selectedEvent = event

        withAnimation(.easeInOut(duration: 0.4)) {
            fadeBackground = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: 0.4)) {
                showBattle = true
            }
        }
    }

    func closeBattle() {
        withAnimation(.easeInOut(duration: 0.35)) {
            showVictoryOverlay = false
            selectedEvent = nil
            fadeBackground = false
        }
    }

    var fallbackBattleView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundStyle(.yellow)
            Text("No boss data found for this event.")
                .foregroundColor(.white.opacity(0.9))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
    }
}

//
// MARK: Bundle Helper
//
private extension Bundle {
    func decodeSafe<T: Decodable>(_ file: String) -> [T] {
        guard let url = url(forResource: file, withExtension: nil),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([T].self, from: data) else {
            print("⚠️ Fehler beim Laden von \(file)")
            return []
        }
        return decoded
    }
}

//
// MARK: Environment Helper
//
private extension View {
    func environmentObjects(
        _ coin: CoinManager,
        _ crystal: CrystalManager,
        _ account: AccountLevelManager,
        _ character: CharacterManager,
        _ skill: SkillManager
    ) -> some View {
        self.environmentObject(coin)
            .environmentObject(crystal)
            .environmentObject(account)
            .environmentObject(character)
            .environmentObject(skill)
    }
}

//
// MARK: - 🔍 Preview
//
#Preview {
    NavigationStack {
        EventView()
            .environmentObject(CoinManager.shared)
            .environmentObject(CrystalManager.shared)
            .environmentObject(EventShopManager.shared)
            .environmentObject(AccountLevelManager.shared)
            .environmentObject(CharacterManager.shared)
            .environmentObject(SkillManager.shared)
            .preferredColorScheme(.dark)
    }
}
