import SwiftUI

struct ShowdownView: View {
    // MARK: - State
    @State private var stages: [Stage] = [
        .init(id: 1, name: "Inferno Rise", bossId: "boss_1", type: "boss"),
        .init(id: 2, name: "Crimson Cave", bossId: "boss_2", type: "boss")
    ]
    
    @State private var progress: [StageProgress] = [
        .init(id: 1, unlocked: true, completed: false, stars: 0),
        .init(id: 2, unlocked: false, completed: false, stars: 0)
    ]
    
    @State private var selectedStage: Stage?
    @State private var showBattle = false
    @State private var showModal = false
    @State private var modalText = ""

    // MARK: - JSON Data
    @State private var bosses: [Boss] = Bundle.main.decode("bosses.json")

    // MARK: - Managers
    @EnvironmentObject private var coinManager: CoinManager
    @EnvironmentObject private var crystalManager: CrystalManager
    @EnvironmentObject private var accountManager: AccountLevelManager
    @EnvironmentObject private var characterManager: CharacterLevelManager
    @EnvironmentObject private var summonManager: SummonManager
    @EnvironmentObject private var teamManager: TeamManager

    // MARK: - Body
    var body: some View {
        ZStack {
            backgroundLayer

            stageSelectionView
                .opacity(showBattle ? 0 : 1)
                .animation(.easeInOut(duration: 0.35), value: showBattle)
            
            if showModal {
                victoryModal
                    .zIndex(10)
                    .transition(.scale.combined(with: .opacity))
            }
        }
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
        .navigationTitle("Showdown")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Subviews
extension ShowdownView {
    
    /// Hintergrund mit sanftem Fade (ohne Bild)
    private var backgroundLayer: some View {
        LinearGradient(
            colors: [.black, .blue, .black],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    /// Stage-Auswahl (horizontales Scroll-Layout)
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
                        let p = progress.first(where: { $0.id == stage.id })
                            ?? StageProgress(id: stage.id, unlocked: false, completed: false, stars: 0)
                        let boss = bosses.first(where: { $0.id == stage.bossId })
                        
                        StageNodeView(stage: stage, progress: p, boss: boss) {
                            startBattle(for: stage, with: boss)
                        }
                        
                        if stage.id != stages.last?.id {
                            Rectangle()
                                .fill(Color.white.opacity(0.3))
                                .frame(width: 34, height: 4)
                                .cornerRadius(2)
                                .offset(y: 50)
                        }
                    }
                    Spacer(minLength: 40)
                }
                .padding(.bottom, 40)
            }
        }
        .padding(.horizontal, 20)
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
    
    /// Controller-Erstellung mit Callback-Verbindungen
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

    /// Kampf starten
    private func startBattle(for stage: Stage, with boss: Boss?) {
        guard boss != nil else { return }
        selectedStage = stage
        withAnimation(.easeInOut(duration: 0.35)) {
            showBattle = true
        }
    }

    /// Kampfende + Fortschritt aktualisieren
    private func endBattle(victoryText: String, for stage: Stage) {
        withAnimation(.easeInOut(duration: 0.3)) {
            modalText = victoryText
            showModal = true
            showBattle = false
        }

        guard let idx = progress.firstIndex(where: { $0.id == stage.id }) else { return }
        progress[idx].completed = true
        progress[idx].stars = 3
        
        // Nächste Stage freischalten
        if idx + 1 < progress.count {
            progress[idx + 1].unlocked = true
        }
    }
}

// MARK: - Helper für Environment-Übergabe
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
            .environmentObject(CoinManager.shared)
            .environmentObject(CrystalManager.shared)
            .environmentObject(AccountLevelManager.shared)
            .environmentObject(CharacterLevelManager.shared)
            .environmentObject(SummonManager.shared)
            .environmentObject(TeamManager.shared)
            .preferredColorScheme(.dark)
    }
}
