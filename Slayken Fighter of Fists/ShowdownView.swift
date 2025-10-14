import SwiftUI

struct ShowdownView: View {
    // MARK: - Stage Setup
    @State private var stages: [Stage] = [
        .init(id: 1, name: "Slayken Fighter of Fists", bossId: "boss_1", type: "boss"),
        .init(id: 2, name: "Ice Rise", bossId: "boss_2", type: "boss"),
        .init(id: 3, name: "Void Cave", bossId: "boss_3", type: "boss"),
        .init(id: 4, name: "Crimson Cave", bossId: "boss_4", type: "boss"),
        .init(id: 5, name: "Snow Arena", bossId: "boss_5", type: "boss"),
        .init(id: 6, name: "Void Land", bossId: "boss_6", type: "boss"),
        .init(id: 7, name: "Inferno Rise", bossId: "boss_7", type: "boss"),
        .init(id: 8, name: "Snow Land", bossId: "boss_8", type: "boss")
    ]
    
    // MARK: - Managers
    @EnvironmentObject private var progressManager: StageProgressManager
    @EnvironmentObject private var coinManager: CoinManager
    @EnvironmentObject private var crystalManager: CrystalManager
    @EnvironmentObject private var accountManager: AccountLevelManager
    @EnvironmentObject private var characterManager: CharacterLevelManager
    @EnvironmentObject private var summonManager: SummonManager
    @EnvironmentObject private var teamManager: TeamManager

    // MARK: - Local UI State
    @State private var selectedStage: Stage?
    @State private var showBattle = false
    @State private var showModal = false
    @State private var modalText = ""

    // MARK: - Data
    @State private var bosses: [Boss] = Bundle.main.decode("bosses.json")

    // MARK: - Body
    var body: some View {
        ZStack {
            backgroundLayer

            if !showBattle {
                stageSelectionView
                    .transition(.opacity.combined(with: .scale))
            }

            if showModal {
                victoryModal
                    .zIndex(10)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.35), value: showBattle)
        .navigationTitle("Showdown")
        .navigationBarTitleDisplayMode(.inline)
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
                        teamManager
                    )
                    .background(Color.black)
                    .ignoresSafeArea()
            }
        }
    }
}

 // MARK: - Subviews
extension ShowdownView {
    
    /// Hintergrund mit weichem Farbverlauf
    private var backgroundLayer: some View {
        LinearGradient(colors: [.black, .blue, .black],
                       startPoint: .top,
                       endPoint: .bottom)
            .ignoresSafeArea()
    }

    /// Stage-Auswahl
    private var stageSelectionView: some View {
        VStack(spacing: 36) {
            Text("Choose a Stage")
                .font(.title2.bold())
                .foregroundColor(.white)
                .padding(.top, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 30) {
                    Spacer(minLength: 40)

                    ForEach(stages, id: \.id) { stage in
                        let progressData = progressManager.progress.first(where: { $0.id == stage.id })
                            ?? StageProgress(id: stage.id, unlocked: stage.id == 1, completed: false, stars: 0)
                        let boss = bosses.first(where: { $0.id == stage.bossId })
                        
                        StageNodeView(stage: stage, progress: progressData, boss: boss) {
                            startBattle(for: stage, with: boss)
                        }

                        if stage.id != stages.last?.id {
                            connectorLine
                        }
                    }

                    Spacer(minLength: 40)
                }
                .padding(.bottom, 40)
            }
        }
        .padding(.horizontal, 20)
    }

    /// Linie zwischen Stages
    private var connectorLine: some View {
        Rectangle()
            .fill(Color.white.opacity(0.3))
            .frame(width: 34, height: 4)
            .cornerRadius(2)
            .offset(y: 50)
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

// MARK: - Logic
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
            characterManager: characterManager
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

        // Fortschritt zentral im Manager speichern
        progressManager.updateProgress(for: stage.id, completed: true, stars: 3)
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
        _ team: TeamManager
    ) -> some View {
        self.environmentObject(coin)
            .environmentObject(crystal)
            .environmentObject(account)
            .environmentObject(character)
            .environmentObject(summon)
            .environmentObject(team)
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
            .preferredColorScheme(.dark)
    }
}
