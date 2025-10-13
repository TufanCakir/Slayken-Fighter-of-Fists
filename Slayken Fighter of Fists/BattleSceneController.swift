import SwiftUI
import Combine

@MainActor
final class BattleSceneController: ObservableObject {
    // MARK: - Published (UI-Binding)
    @Published var bossHp: Int
    @Published var showHitEffect = false
    @Published var rewardText: String? = nil
    @Published var rewardOpacity: Double = 0
    @Published var canAttack = true
    @Published var isBattleFinished = false
    @Published var activeIndex: Int = 0

    // Team-Unterstützung
    @Published private(set) var team: [GameCharacter]
    var activeCharacter: GameCharacter { team[activeIndex] }

    // MARK: - Core Models
    let boss: Boss

    // MARK: - Managers (sichtbar für View)
    let coinManager: CoinManager
    let crystalManager: CrystalManager
    let accountManager: AccountLevelManager
    let characterManager: CharacterLevelManager


    // MARK: - Internal
    private var cancellables = Set<AnyCancellable>()
    private var lastAttackTime: Date = .distantPast
    private let attackCooldown: TimeInterval = 0.5

    // MARK: - Callbacks
    var onFight: (() -> Void)?
    var onExit: (() -> Void)?
    var onBossDefeated: (() -> Void)?

    // MARK: - Init
    init(
        boss: Boss,
        bossHp: Int,
        team: [GameCharacter],
        coinManager: CoinManager,
        crystalManager: CrystalManager,
        accountManager: AccountLevelManager,
        characterManager: CharacterLevelManager
    ) {
        self.boss = boss
        self.bossHp = bossHp
        self.team = team.isEmpty ? [GameCharacter.example] : team
        self.coinManager = coinManager
        self.crystalManager = crystalManager
        self.accountManager = accountManager
        self.characterManager = characterManager
    }
}

// MARK: - Gameplay Logic
extension BattleSceneController {

    /// Führt einen normalen Angriff aus
    func performAttack() {
        guard canAttack, bossHp > 0 else { return }

        startCooldown()
        triggerHitAnimation()

        // Basis-Schaden (künftig skalierbar über Charakterwerte)
        let baseDamage = Int.random(in: 12...26)
        bossHp = max(bossHp - baseDamage, 0)

        #if DEBUG
        print("⚔️ \(activeCharacter.name) greift an → \(baseDamage) Schaden | Boss HP: \(bossHp)")
        #endif

        if bossHp == 0 {
            battleFinished()
        }
    }

    /// Aktiviert Treffer-Animation und beendet sie nach kurzer Zeit
    private func triggerHitAnimation() {
        withAnimation(.easeOut(duration: 0.15)) {
            showHitEffect = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.easeInOut(duration: 0.2)) {
                self.showHitEffect = false
            }
        }
    }

    /// Aktiviert Angriffscooldown
    private func startCooldown() {
        canAttack = false
        lastAttackTime = Date()

        DispatchQueue.main.asyncAfter(deadline: .now() + attackCooldown) {
            self.canAttack = true
        }
    }

    /// Wechselt zum nächsten Charakter im Team
    func switchToNextCharacter() {
        guard !team.isEmpty else { return }
        activeIndex = (activeIndex + 1) % team.count

        #if DEBUG
        print("🔄 Aktiver Charakter gewechselt zu: \(activeCharacter.name)")
        #endif
    }

    /// Wird aufgerufen, wenn der Boss besiegt wurde
    private func battleFinished() {
        isBattleFinished = true
        triggerRewards()
        onBossDefeated?()
        onFight?()

        #if DEBUG
        print("🏆 Boss \(boss.name) besiegt! Kampf abgeschlossen.")
        #endif
    }
}

// MARK: - Reward System
extension BattleSceneController {

    /// Berechnet & vergibt Belohnungen
    private func triggerRewards() {
        let coins = Int.random(in: 10...20)
        let crystals = Int.random(in: 10...20)
        let exp = Int.random(in: 18...28)

        coinManager.addCoins(coins)
        if crystals > 0 {
            crystalManager.addCrystals(crystals)
            displayReward("+\(crystals) 💎")
        } else {
            displayReward("+\(coins) 💰")
        }

        // EXP-Verteilung auf aktiven Charakter
        characterManager.levelUp(id: activeCharacter.id, expGained: exp)
        accountManager.addExp(exp / 2)

        #if DEBUG
        print("✨ Belohnung: \(coins) Coins, \(crystals) Crystals, \(exp) EXP → \(activeCharacter.name)")
        #endif
    }

    /// Zeigt kurzzeitig einen Belohnungstext an
    private func displayReward(_ text: String) {
        rewardText = text
        withAnimation(.easeInOut(duration: 0.4)) { rewardOpacity = 1 }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 0.5)) {
                self.rewardOpacity = 0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            self.rewardText = nil
        }
    }
}
