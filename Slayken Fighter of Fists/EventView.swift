//
//  EventView.swift
//  Slayken Fighter of Fists
//
//  Created by Tufan Cakir on 2025-10-30.
//

import SwiftUI

@MainActor
struct EventView: View {
    // MARK: - JSON Data
    @State private var events: [Event] = Bundle.main.decodeSafe("events.json")
    @State private var bosses: [Boss] = Bundle.main.decodeSafe("eventBosses.json")

    // MARK: - States
    @State private var selectedEvent: Event?
    @State private var showBattle = false
    @State private var victoryText: String?
    @State private var fadeBackground = false

    // MARK: - Environment Managers
    @EnvironmentObject private var coinManager: CoinManager
    @EnvironmentObject private var crystalManager: CrystalManager
    @EnvironmentObject private var accountManager: AccountLevelManager
    @EnvironmentObject private var characterManager: CharacterManager
    @EnvironmentObject private var skillManager: SkillManager

    // MARK: - Body
    var body: some View {
        ZStack {
            backgroundLayer

            // Event-Auswahl
            if !showBattle {
                eventSelectionView
                    .opacity(fadeBackground ? 0 : 1)
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }

            // Siegesoverlay
            if let text = victoryText {
                victoryOverlay(text: text)
                    .zIndex(10)
                    .transition(.scale.combined(with: .opacity))
            }

            // Sanftes Schwarz beim Übergang in Battle
            if showBattle {
                Color.black.opacity(0.8)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .zIndex(5)
            }
        }
        .navigationTitle("Events")
        .navigationBarTitleDisplayMode(.inline)
        .animation(.easeInOut(duration: 0.35), value: showBattle)
        .fullScreenCover(isPresented: $showBattle) { battleScreen }
    }
}

//
// MARK: - UI Layer
//
private extension EventView {

    // MARK: Background
    var backgroundLayer: some View {
        LinearGradient(
            colors: [.black, .indigo.opacity(0.9), .black],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(
            Image(systemName: "sparkles")
                .font(.system(size: 300))
                .foregroundStyle(.linearGradient(colors: [.indigo.opacity(0.25), .clear], startPoint: .top, endPoint: .bottom))
                .blur(radius: 80)
                .offset(y: -100)
        )
        .ignoresSafeArea()
    }

    // MARK: Event Auswahl
    var eventSelectionView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 32) {
                Text("Select an Event")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(LinearGradient(colors: [.white, .cyan], startPoint: .top, endPoint: .bottom))
                    .shadow(color: .cyan.opacity(0.4), radius: 10)
                    .padding(.top, 28)

                LazyVStack(spacing: 20) {
                    ForEach(events) { event in
                        eventCard(for: event)
                            .transition(.opacity.combined(with: .scale))
                    }
                }

                Spacer(minLength: 80)
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: Event Card
    func eventCard(for event: Event) -> some View {
        Button { startBattle(for: event) } label: {
            ZStack(alignment: .bottomLeading) {
                eventImage(for: event.image)
                    .frame(height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay(
                        LinearGradient(colors: [.black.opacity(0.6), .clear],
                                       startPoint: .bottom, endPoint: .top)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.cyan.opacity(0.6), lineWidth: 1.5)
                    )
                    .shadow(color: .black.opacity(0.7), radius: 10, y: 4)

                VStack(alignment: .leading, spacing: 6) {
                    Text(event.name)
                        .font(.headline.bold())
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.9), radius: 2)

                    Text(event.description)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(2)
                }
                .padding(12)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(selectedEvent?.id == event.id ? 0.96 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: selectedEvent?.id)
    }

    // MARK: Victory Overlay
    func victoryOverlay(text: String) -> some View {
        VStack(spacing: 16) {
            Text("Victory!")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom))
                .shadow(color: .orange.opacity(0.9), radius: 10)

            Text(text)
                .font(.headline)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            Button("Back to Events") {
                withAnimation(.easeInOut(duration: 0.4)) {
                    victoryText = nil
                    showBattle = false
                    selectedEvent = nil
                }
            }
            .font(.headline.bold())
            .padding(.vertical, 10)
            .padding(.horizontal, 26)
            .background(LinearGradient(colors: [.yellow, .orange],
                                       startPoint: .topLeading,
                                       endPoint: .bottomTrailing))
            .clipShape(Capsule())
            .foregroundColor(.black)
            .shadow(color: .yellow.opacity(0.6), radius: 8)
        }
        .padding(30)
        .background(.ultraThinMaterial)
        .cornerRadius(26)
        .shadow(color: .black.opacity(0.8), radius: 16)
        .frame(maxWidth: 320)
        .transition(.scale)
    }

    // MARK: Event Image Loader
    @ViewBuilder
    func eventImage(for name: String) -> some View {
        if name.lowercased().hasPrefix("http") {
            AsyncImage(url: URL(string: name)) { phase in
                switch phase {
                case .empty:
                    ZStack {
                        Color.gray.opacity(0.15)
                        ProgressView().tint(.cyan)
                    }
                case .success(let image):
                    image.resizable().scaledToFill()
                case .failure:
                    Color.gray.opacity(0.25)
                @unknown default:
                    Color.gray.opacity(0.25)
                }
            }
        } else {
            Image(name)
                .resizable()
                .scaledToFill()
        }
    }
}

//
// MARK: - ⚔️ Battle Logic
//
private extension EventView {

    var battleScreen: some View {
        Group {
            if let event = selectedEvent,
               let boss = bosses.first(where: { $0.id == event.bossId }) {
                BattleSceneView(controller: makeController(for: boss, event: event))
                    .environmentObjects(
                        coinManager,
                        crystalManager,
                        accountManager,
                        characterManager,
                        skillManager
                    )
                    .background(Color.black)
                    .ignoresSafeArea()
            } else {
                fallbackBattleView
            }
        }
    }

    func makeController(for boss: Boss, event: Event) -> BattleSceneController {
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.easeInOut(duration: 0.4)) {
                    showBattle = false
                    fadeBackground = false
                    victoryText = "\(boss.name) was defeated!"
                }
            }
        }

        controller.onExit = {
            withAnimation(.easeInOut(duration: 0.4)) {
                showBattle = false
                selectedEvent = nil
            }
        }

        return controller
    }

    func startBattle(for event: Event) {
        selectedEvent = event
        withAnimation(.easeInOut(duration: 0.5)) {
            fadeBackground = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            withAnimation(.easeInOut(duration: 0.4)) {
                showBattle = true
            }
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
// MARK: - 📦 Helpers
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
            .environmentObject(AccountLevelManager.shared)
            .environmentObject(CharacterManager.shared)
            .environmentObject(SkillManager.shared)
            .preferredColorScheme(.dark)
    }
}
