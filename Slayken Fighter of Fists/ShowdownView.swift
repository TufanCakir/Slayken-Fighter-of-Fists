//
//  ShowdownView.swift
//  Slayken Fighter of Fists
//
//  Created by Tufan Cakir on 2025-10-31.
//

import SwiftUI

@MainActor
struct ShowdownView: View {

    // MARK: - Data
    @State private var stages: [Stage] = Stage.defaultStages
    @State private var bosses: [Boss] = Bundle.main.decodeSafe("bosses.json")

    // MARK: - Managers
    @EnvironmentObject private var progressManager: StageProgressManager
    @EnvironmentObject private var coinManager: CoinManager
    @EnvironmentObject private var crystalManager: CrystalManager
    @EnvironmentObject private var accountManager: AccountLevelManager
    @EnvironmentObject private var characterManager: CharacterManager
    @EnvironmentObject private var skillManager: SkillManager

    // MARK: - UI State
    @State private var selectedStage: Stage?
    @State private var showBattle = false
    @State private var showVictory = false
    @State private var victoryText = ""
    @State private var currentWorld = 1
    @State private var justUnlockedWorld2 = false

    // MARK: - Body
    var body: some View {
        ZStack {
            backgroundLayer

            VStack(spacing: 24) {
                worldSelector
                    .padding(.top, 10)

                stageGrid(for: currentWorld)
                    .transition(.opacity)
            }

            if showVictory { victoryModal.transition(.scale.combined(with: .opacity)) }
        }
        .navigationTitle("Showdown")
        .navigationBarTitleDisplayMode(.inline)
        .animation(.easeInOut(duration: 0.35), value: showBattle)
        .onAppear(perform: checkWorldUnlock)
        .fullScreenCover(isPresented: $showBattle) { battleCover }
    }
}

//
// MARK: - 🎨 UI Layers
//
private extension ShowdownView {

    var backgroundLayer: some View {
        LinearGradient(colors: [.black, .indigo.opacity(0.85), .black],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
            .overlay(
                ZStack {
                    Circle()
                        .fill(.purple.opacity(0.1))
                        .blur(radius: 120)
                        .offset(x: -150, y: -250)
                    Circle()
                        .fill(.blue.opacity(0.1))
                        .blur(radius: 120)
                        .offset(x: 160, y: 240)
                }
            )
            .ignoresSafeArea()
    }

    // 🌍 Welt-Auswahl
    var worldSelector: some View {
        let allWorld1Completed = progressManager.progress
            .filter { $0.id <= 8 }
            .allSatisfy { $0.completed }

        return HStack(spacing: 14) {
            ForEach(1...2, id: \.self) { world in
                let isLocked = (world == 2 && !allWorld1Completed)

                Button {
                    guard !isLocked else { return }
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        currentWorld = world
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: isLocked ? "lock.fill" : "globe.europe.africa.fill")
                            .foregroundColor(isLocked ? .gray : .cyan)
                        Text("World \(world)")
                            .font(.headline.bold())
                    }
                    .foregroundColor(isLocked ? .gray.opacity(0.6) :
                                    (currentWorld == world ? .white : .gray))
                    .padding(.vertical, 8)
                    .padding(.horizontal, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(currentWorld == world
                                  ? Color.blue.opacity(0.6)
                                  : Color.black.opacity(0.4))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                Color.cyan.opacity(justUnlockedWorld2 ? 0.8 : 0),
                                lineWidth: 2
                            )
                            .shadow(color: .cyan.opacity(justUnlockedWorld2 ? 0.7 : 0),
                                    radius: 6)
                            .animation(
                                .easeInOut(duration: 1.2)
                                    .repeatCount(3, autoreverses: true),
                                value: justUnlockedWorld2
                            )
                    )
                }
                .disabled(isLocked)
            }
        }
    }

    // 🗺️ Stage Grid
    func stageGrid(for world: Int) -> some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), spacing: 18)]) {
                ForEach(stages.filter { $0.world == world }) { stage in
                    let progressData = progressManager.progress.first(where: { $0.id == stage.id })
                        ?? StageProgress(id: stage.id, unlocked: stage.id == 1, completed: false, stars: 0)
                    let boss = bosses.first(where: { $0.id == stage.bossId })

                    StageNodeView(stage: stage, progress: progressData, boss: boss) {
                        startBattle(for: stage, with: boss)
                    }
                    .scaleEffect(selectedStage?.id == stage.id ? 0.96 : 1.0)
                    .animation(.easeInOut(duration: 0.25), value: selectedStage?.id)
                }
            }
            .padding()
        }
    }

    // 🏆 Victory Modal
    var victoryModal: some View {
        InfoModalView(visible: showVictory, onClose: { showVictory = false }) {
            VStack(spacing: 16) {
                Text("Victory!")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(LinearGradient(colors: [.yellow, .orange],
                                                    startPoint: .top,
                                                    endPoint: .bottom))
                    .shadow(color: .orange.opacity(0.7), radius: 10)

                Text(victoryText)
                    .font(.headline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 10)
            }
            .padding(24)
        }
        .transition(.opacity.combined(with: .scale))
    }

    // 🕹 Battle Screen
    var battleCover: some View {
        Group {
            if let stage = selectedStage,
               let boss = bosses.first(where: { $0.id == stage.bossId }) {
                BattleSceneView(controller: makeController(for: boss, stage: stage))
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
}

//
// MARK: - ⚔️ Logic
//
private extension ShowdownView {

    func makeController(for boss: Boss, stage: Stage) -> BattleSceneController {
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
            endBattle(victoryText: "\(boss.name) was defeated!", for: stage)
        }

        controller.onExit = {
            withAnimation(.easeInOut(duration: 0.4)) {
                showBattle = false
                selectedStage = nil
            }
        }

        return controller
    }

    func startBattle(for stage: Stage, with boss: Boss?) {
        guard let boss else { return }
        selectedStage = stage
        withAnimation(.easeInOut(duration: 0.35)) { showBattle = true }
        print("⚔️ Starting battle against \(boss.name)")
    }

    func endBattle(victoryText: String, for stage: Stage) {
        withAnimation(.easeInOut(duration: 0.35)) {
            self.victoryText = victoryText
            self.showVictory = true
            self.showBattle = false
        }

        progressManager.updateProgress(for: stage.id, completed: true, stars: 3)
        checkWorldUnlock()
    }

    func checkWorldUnlock() {
        let allWorld1Completed = progressManager.progress
            .filter { $0.id <= 8 }
            .allSatisfy { $0.completed }

        guard allWorld1Completed, !justUnlockedWorld2 else { return }

        withAnimation(.easeInOut(duration: 1.2)) { justUnlockedWorld2 = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { justUnlockedWorld2 = false }
    }
}

//
// MARK: - 🧩 Fallback
//
private extension ShowdownView {
    var fallbackBattleView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundStyle(.yellow)
            Text("No boss data found for this stage.")
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
// MARK: - 📜 Stage Presets
//
extension Stage {
    static let defaultStages: [Stage] = [
        // 🌍 World 1
        .init(id: 1, name: "Slayken Fighter of Fists", bossId: "boss_1", type: "boss", world: 1),
        .init(id: 2, name: "Ice Rise", bossId: "boss_2", type: "boss", world: 1),
        .init(id: 3, name: "Void Cave", bossId: "boss_3", type: "boss", world: 1),
        .init(id: 4, name: "Crimson Cave", bossId: "boss_4", type: "boss", world: 1),
        .init(id: 5, name: "Snow Arena", bossId: "boss_5", type: "boss", world: 1),
        .init(id: 6, name: "Void Land", bossId: "boss_6", type: "boss", world: 1),
        .init(id: 7, name: "Inferno Rise", bossId: "boss_7", type: "boss", world: 1),
        .init(id: 8, name: "Snow Land", bossId: "boss_8", type: "boss", world: 1),

        // 🌍 World 2 — Elite
        .init(id: 9, name: "Dark Sly", bossId: "boss_9", type: "boss", world: 2),
        .init(id: 10, name: "Frozen Keyo", bossId: "boss_10", type: "boss", world: 2),
        .init(id: 11, name: "Shadow Kenix", bossId: "boss_11", type: "boss", world: 2),
        .init(id: 12, name: "Toxic Senix", bossId: "boss_12", type: "boss", world: 2),
        .init(id: 13, name: "Crimson Ley", bossId: "boss_13", type: "boss", world: 2),
        .init(id: 14, name: "Glacier Len", bossId: "boss_14", type: "boss", world: 2),
        .init(id: 15, name: "Abyss Gen", bossId: "boss_15", type: "boss", world: 2),
        .init(id: 16, name: "Verdant Ganix", bossId: "boss_16", type: "boss", world: 2)
    ]
}

//
// MARK: - Preview
//
#Preview {
    NavigationStack {
        ShowdownView()
            .environmentObject(StageProgressManager.shared)
            .environmentObject(CoinManager.shared)
            .environmentObject(CrystalManager.shared)
            .environmentObject(AccountLevelManager.shared)
            .environmentObject(CharacterManager.shared)
            .environmentObject(SkillManager.shared)
            .preferredColorScheme(.dark)
    }
}
