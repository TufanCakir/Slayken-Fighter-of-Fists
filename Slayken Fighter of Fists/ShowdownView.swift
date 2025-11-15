import SwiftUI

@MainActor
struct ShowdownView: View {

    // MARK: - Data
    @State private var stages: [Stage] = Bundle.main.decodeSafe("stages.json")
    @State private var bosses: [Boss] = Bundle.main.decodeSafe("bosses.json")

    // MARK: - Managers
    @EnvironmentObject private var progressManager: StageProgressManager
    @EnvironmentObject private var coinManager: CoinManager
    @EnvironmentObject private var crystalManager: CrystalManager
    @EnvironmentObject private var accountManager: AccountLevelManager
    @EnvironmentObject private var characterManager: CharacterManager
    @EnvironmentObject private var skillManager: SkillManager

    // MARK: - UI
    @State private var selectedStage: Stage?
    @State private var showBattle = false
    @State private var showVictory = false
    @State private var victoryText = ""
    @State private var currentWorld = 1
    // ORB Animation
     @State private var orbGlow = false
     @State private var orbRotation = 0.0
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

            if showVictory {
                victoryModal.transition(.scale.combined(with: .opacity))
            }
        }
        .navigationTitle("Showdown")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showBattle) { battleCover }
        .animation(.easeInOut(duration: 0.35), value: showBattle)
    }
}

//
// MARK: - BACKGROUND
//
private extension ShowdownView {
    
    var backgroundLayer: some View {
        ZStack {

            // Glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.black, .blue, .black],
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
                .shadow(color: .blue, radius: 20)

            // Rotating Energy Ring (FIXED)
            Circle()
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [.black, .blue, .black]),
                        center: .center
                    ),
                    lineWidth: 10
                )
                .frame(width: 230, height: 230)
                .blur(radius: 2)
                .rotationEffect(.degrees(orbRotation))
                .animation(.linear(duration: 6).repeatForever(autoreverses: false), value: orbRotation)

            Image(systemName: "sparkles")
                .font(.system(size: 55))
                .foregroundStyle(.cyan)
        }
        .onAppear {
            orbGlow = true
            orbRotation = 360
        }
    }
}

//
// MARK: - WORLD SELECTOR
//
private extension ShowdownView {

    var worldSelector: some View {
        let worlds = Set(stages.map { $0.world }).sorted()

        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(worlds, id: \.self) { world in

                    let isLocked = isWorldLocked(world)

                    Button {
                        guard !isLocked else { return }
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                            currentWorld = world
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: isLocked ? "lock.fill" : "globe.europe.africa.fill")
                                .foregroundColor(isLocked ? .gray : .cyan)
                            Text("World \(world)")
                                .font(.headline.bold())
                        }
                        .foregroundColor(currentWorld == world && !isLocked ? .white : .gray.opacity(isLocked ? 0.6 : 1))
                        .padding(.vertical, 10)
                        .padding(.horizontal, 24)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(currentWorld == world && !isLocked
                                      ? Color.blue.opacity(0.7)
                                      : Color.black.opacity(0.4))
                        )
                        .shadow(color: currentWorld == world && !isLocked ? .cyan.opacity(0.5) : .clear,
                                radius: 8)
                    }
                    .disabled(isLocked)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    func isWorldLocked(_ world: Int) -> Bool {
        if world == 1 { return false }

        let previousWorld = world - 1
        let previousWorldStages = stages.filter { $0.world == previousWorld }
        let maxStage = previousWorldStages.map(\.id).max() ?? 0

        let completed = progressManager.progress
            .filter { $0.id <= maxStage }
            .allSatisfy { $0.completed }

        return !completed
    }
}

//
// MARK: - STAGE GRID
//
private extension ShowdownView {

    func stageGrid(for world: Int) -> some View {
        let filteredStages = stages.filter { $0.world == world }

        return ScrollView(showsIndicators: false) {
            LazyVGrid(columns: gridColumns, spacing: 16) {
                ForEach(filteredStages) { stage in
                    stageItem(stage)
                }
            }
            .padding(.horizontal, 0)
            .padding(.vertical, 0)
        }
    }

    var gridColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 14),
            GridItem(.flexible(), spacing: 14),
            GridItem(.flexible(), spacing: 14)
        ]
    }

    @ViewBuilder
    func stageItem(_ stage: Stage) -> some View {

        let progressData =
            progressManager.progress.first(where: { $0.id == stage.id })
            ?? StageProgress(id: stage.id,
                             unlocked: stage.id == 1,
                             completed: false,
                             stars: stage.stars ?? 0)

        let boss = bosses.first(where: { $0.id == stage.bossId })

        StageNodeView(stage: stage, progress: progressData, boss: boss) {
            startBattle(for: stage, with: boss)
        }
        .frame(height: 200)
        .contentShape(Rectangle())
        .scaleEffect(selectedStage?.id == stage.id ? 0.96 : 1.0)
        .animation(.easeInOut(duration: 0.25), value: selectedStage?.id)
    }
}




//
// MARK: - BATTLE + VICTORY LOGIC
//
private extension ShowdownView {

    func startBattle(for stage: Stage, with boss: Boss?) {
        guard boss != nil else { return }
        selectedStage = stage
        showBattle = true
    }

    var battleCover: some View {
        if let stage = selectedStage,
           let boss = bosses.first(where: { $0.id == stage.bossId }) {

            return AnyView(
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
            )
        }

        return AnyView(fallbackBattleView)
    }

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
            withAnimation { showBattle = false }
            selectedStage = nil
        }

        return controller
    }

    func endBattle(victoryText: String, for stage: Stage) {
        self.victoryText = victoryText
        showVictory = true
        showBattle = false

        progressManager.updateProgress(for: stage.id, completed: true, stars: 10)
    }

    var victoryModal: some View {
        InfoModalView(visible: showVictory, onClose: { showVictory = false }) {
            VStack(spacing: 16) {
                Text("Victory!")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(LinearGradient(colors: [.yellow, .orange],
                                                    startPoint: .top,
                                                    endPoint: .bottom))

                Text(victoryText)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(24)
        }
    }

    var fallbackBattleView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundStyle(.yellow)
            Text("No boss data found.")
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
    }
}

//
// MARK: - HELPERS
//
private extension Bundle {
    func decodeSafe<T: Decodable>(_ file: String) -> [T] {
        guard let url = url(forResource: file, withExtension: nil),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([T].self, from: data)
        else {
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
