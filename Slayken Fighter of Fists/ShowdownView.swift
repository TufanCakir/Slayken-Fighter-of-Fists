import SwiftUI

struct ShowdownView: View {
    // MARK: - Stage Setup
    @State private var stages: [Stage] = [
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
    
    // MARK: - Environment Managers
    @EnvironmentObject private var progressManager: StageProgressManager
    @EnvironmentObject private var coinManager: CoinManager
    @EnvironmentObject private var crystalManager: CrystalManager
    @EnvironmentObject private var accountManager: AccountLevelManager
    @EnvironmentObject private var characterManager: CharacterLevelManager
    @EnvironmentObject private var summonManager: SummonManager
    @EnvironmentObject private var teamManager: TeamManager
    @EnvironmentObject private var skillManager: SkillManager

    // MARK: - Local State
    @State private var selectedStage: Stage?
    @State private var showBattle = false
    @State private var showModal = false
    @State private var modalText = ""
    @State private var currentWorld = 1
    @State private var justUnlockedWorld2 = false

    // MARK: - Data
    @State private var bosses: [Boss] = Bundle.main.decode("bosses.json")

    // MARK: - Body
    var body: some View {
        ZStack {
            backgroundLayer

            VStack(spacing: 24) {
                worldSelector
                stageGrid(for: currentWorld)
            }

            if showModal {
                victoryModal
                    .zIndex(10)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .navigationTitle("Showdown")
        .navigationBarTitleDisplayMode(.inline)
        .animation(.easeInOut(duration: 0.35), value: showBattle)
        .onAppear(perform: checkWorldUnlock)
        .fullScreenCover(isPresented: $showBattle) {
            if let stage = selectedStage,
               let boss = bosses.first(where: { $0.id == stage.bossId }) {
                BattleSceneView(controller: makeController(for: boss, stage: stage))
                    .environmentObjects(
                        coinManager,
                        crystalManager,
                        accountManager,
                        characterManager,
                        summonManager,
                        teamManager,
                        skillManager
                    )
                    .background(Color.black)
                    .ignoresSafeArea()
            }
        }
    }
}

 // MARK: - UI-Abschnitte
extension ShowdownView {
    
    private var backgroundLayer: some View {
        LinearGradient(
            colors: [.black, .blue.opacity(0.8), .black],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    /// 🌍 Welt-Auswahl (Tabs + Unlock)
    private var worldSelector: some View {
        HStack(spacing: 12) {
            ForEach(1...2, id: \.self) { world in
                let allWorld1Completed = progressManager.progress
                    .filter { $0.id <= 8 }
                    .allSatisfy { $0.completed }

                let isLocked = (world == 2 && !allWorld1Completed)

                Button {
                    guard !isLocked else { return }
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        currentWorld = world
                    }
                } label: {
                    HStack(spacing: 6) {
                        if isLocked {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.gray)
                        }
                        Text("World \(world)")
                            .font(.headline.bold())
                    }
                    .foregroundColor(isLocked ? .gray.opacity(0.6) :
                        (currentWorld == world ? .white : .gray))
                    .padding(.vertical, 8)
                    .padding(.horizontal, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(currentWorld == world
                                  ? Color.blue.opacity(0.6)
                                  : Color.black.opacity(0.4))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.cyan.opacity(justUnlockedWorld2 ? 0.8 : 0),
                                    lineWidth: 2)
                            .shadow(color: .cyan.opacity(justUnlockedWorld2 ? 0.7 : 0),
                                    radius: 6)
                            .animation(.easeInOut(duration: 1.2)
                                .repeatCount(3, autoreverses: true),
                                value: justUnlockedWorld2)
                    )
                }
                .disabled(isLocked)
            }
        }
        .padding(.top, 12)
    }
    
    /// Gitter für Stages (nach Welt gefiltert)
    private func stageGrid(for world: Int) -> some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 16)]) {
                ForEach(stages.filter { $0.world == world }) { stage in
                    let progressData = progressManager.progress.first(where: { $0.id == stage.id })
                        ?? StageProgress(id: stage.id, unlocked: stage.id == 1, completed: false, stars: 0)
                    let boss = bosses.first(where: { $0.id == stage.bossId })
                    
                    StageNodeView(stage: stage, progress: progressData, boss: boss) {
                        startBattle(for: stage, with: boss)
                    }
                }
            }
            .padding()
        }
    }
    
    /// Sieg-Modal
    private var victoryModal: some View {
        InfoModalView(visible: showModal, onClose: { showModal = false }) {
            VStack(spacing: 14) {
                Text("Victory")
                    .font(.title.bold())
                    .foregroundColor(.white)
                Text(modalText)
                    .font(.headline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 10)
            }
            .padding(20)
        }
    }
}

// MARK: - Logik
extension ShowdownView {

    private func makeController(for boss: Boss, stage: Stage) -> BattleSceneController {
        let team = teamManager.selectedTeam.isEmpty
            ? [summonManager.ownedCharacters.first ?? GameCharacter.example]
            : teamManager.selectedTeam
        
        let controller = BattleSceneController(
            boss: boss,
            bossHp: boss.hp,
            team: team,
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
            withAnimation(.easeInOut(duration: 0.3)) {
                showBattle = false
            }
        }
        
        return controller
    }
    
    private func startBattle(for stage: Stage, with boss: Boss?) {
        guard boss != nil else { return }
        selectedStage = stage
        withAnimation(.easeInOut(duration: 0.35)) {
            showBattle = true
        }
    }
    
    private func endBattle(victoryText: String, for stage: Stage) {
        withAnimation(.easeInOut(duration: 0.3)) {
            modalText = victoryText
            showModal = true
            showBattle = false
        }

        // Fortschritt speichern
        progressManager.updateProgress(for: stage.id, completed: true, stars: 3)

        // 🔓 Prüfen, ob World 2 jetzt freigeschaltet wird
        checkWorldUnlock()
    }
    
    private func checkWorldUnlock() {
        let allWorld1Completed = progressManager.progress
            .filter { $0.id <= 8 }
            .allSatisfy { $0.completed }

        if allWorld1Completed && !justUnlockedWorld2 {
            withAnimation(.easeInOut(duration: 1.2)) {
                justUnlockedWorld2 = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                justUnlockedWorld2 = false
            }
        }
    }
}

// MARK: - Environment Helper
private extension View {
    func environmentObjects(
        _ coin: CoinManager,
        _ crystal: CrystalManager,
        _ account: AccountLevelManager,
        _ character: CharacterLevelManager,
        _ summon: SummonManager,
        _ team: TeamManager,
        _ skill: SkillManager
    ) -> some View {
        self.environmentObject(coin)
            .environmentObject(crystal)
            .environmentObject(account)
            .environmentObject(character)
            .environmentObject(summon)
            .environmentObject(team)
            .environmentObject(skill)
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        ShowdownView()
            .environmentObject(StageProgressManager.shared)
            .environmentObject(CoinManager.shared)
            .environmentObject(CrystalManager.shared)
            .environmentObject(AccountLevelManager.shared)
            .environmentObject(CharacterLevelManager.shared)
            .environmentObject(SummonManager.shared)
            .environmentObject(TeamManager.shared)
            .environmentObject(SkillManager()) // ✅ hinzugefügt
            .preferredColorScheme(.dark)
    }
}
