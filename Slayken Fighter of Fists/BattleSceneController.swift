import SwiftUI
import Combine

@MainActor
final class BattleSceneController: ObservableObject {

    // MARK: - Published States (UI Binding)
    @Published var bossHp: Int
    @Published var showHitEffect = false
    @Published var rewardText: String?
    @Published var rewardOpacity: Double = 0
    @Published var canAttack = true
    @Published var isBattleFinished = false
    @Published var activeIndex: Int = 0

    // MARK: - Skill / Particle FX
    @Published var showSkillParticles = false
    @Published var activeSkillEffect: SkillEffect?

   
    // MARK: - Cooldowns
    @Published var cooldowns: [String: Bool] = [:]
    @Published var cooldownRemaining: [String: Double] = [:]
    @Published var cooldownDuration: [String: Double] = [:]

    struct SkillEffect {
        let element: String
        let name: String
    }

    // MARK: - Team & Boss
    @Published private(set) var team: [GameCharacter]
    var activeCharacter: GameCharacter { team[safe: activeIndex] ?? team.first ?? .example }
    let boss: Boss

    // MARK: - Managers
    private let coinManager: CoinManager
    private let crystalManager: CrystalManager
    private let accountManager: AccountLevelManager
    private let characterManager: CharacterLevelManager
    private let skillManager: SkillManager

    // MARK: - Internal Logic
    private var cancellables = Set<AnyCancellable>()
    private let attackCooldown: TimeInterval = 0.5
    private var lastAttackTime: Date = .distantPast

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
        characterManager: CharacterLevelManager,
        skillManager: SkillManager
    ) {
        self.boss = boss
        self.bossHp = bossHp
        self.team = team.isEmpty ? [GameCharacter.example] : team
        self.coinManager = coinManager
        self.crystalManager = crystalManager
        self.accountManager = accountManager
        self.characterManager = characterManager
        self.skillManager = skillManager
    }
}

// MARK: - Gameplay Logic
extension BattleSceneController {

    /// Führt einen normalen Basisangriff aus.
    func performAttack() {
        guard canAttack, bossHp > 0, !isBattleFinished else { return }

        startAttackCooldown()
        triggerHitEffect(intensity: 1.0)

        let damage = Int.random(in: 12...26)
        applyDamage(damage)
        displayReward("⚔️ Basic Attack – \(damage) DMG")

        checkBattleEnd()
    }

    // MARK: - Skill Interface
    func useSkill(_ skillName: String) {
        guard let skill = skillManager.skill(named: skillName),
              !isSkillOnCooldown(skillName),
              bossHp > 0 else { return }

        startSkillCooldown(skillName, duration: skill.cooldown)

        switch skill.type.lowercased() {
        case "damage":
            castDamageSkill(
                name: skill.name,
                element: skill.element,
                damage: skill.damageRange ?? 20...30
            )

        case "heal":
            castHealSkill(
                name: skill.name,
                element: skill.element,
                heal: skill.healAmount ?? 20
            )

        default:
            displayReward("✨ \(skill.name) aktiviert!")
        }
    }

    // MARK: - Cooldowns
    func isSkillOnCooldown(_ skill: String) -> Bool {
        cooldowns[skill.lowercased()] ?? false
    }

    private func startSkillCooldown(_ skill: String, duration: TimeInterval) {
        let key = skill.lowercased()
        cooldowns[key] = true
        cooldownRemaining[key] = duration
        cooldownDuration[key] = duration

        Task {
            let start = Date()
            while let remaining = cooldownRemaining[key], remaining > 0 {
                try? await Task.sleep(nanoseconds: 200_000_000) // alle 0.2 Sek aktualisieren
                let elapsed = Date().timeIntervalSince(start)
                cooldownRemaining[key] = max(duration - elapsed, 0)
            }
            cooldowns[key] = false
            cooldownRemaining[key] = nil
            cooldownDuration[key] = nil
        }
    }


    private func startAttackCooldown() {
        canAttack = false
        Task {
            try? await Task.sleep(nanoseconds: UInt64(attackCooldown * 1_000_000_000))
            canAttack = true
        }
    }
}

// MARK: - Skill Actions
private extension BattleSceneController {

    func castDamageSkill(name: String, element: String, damage: ClosedRange<Int>) {
        activateSkillEffect(element: element, name: name)

        let dmg = Int.random(in: damage)
        applyDamage(dmg)
        displayReward("🔥 \(name)! – \(dmg) DMG")

        triggerHitEffect(intensity: 1.3)
        deactivateSkillEffect(after: 1.2)

        checkBattleEnd()
    }

    func castHealSkill(name: String, element: String, heal: Int) {
        activateSkillEffect(element: element, name: name)
        healCharacter(amount: heal, reward: "💚 \(name)! +\(heal) HP")
        deactivateSkillEffect(after: 1.2)
    }

    func activateSkillEffect(element: String, name: String) {
        activeSkillEffect = SkillEffect(element: element, name: name)
        withAnimation(.easeOut(duration: 0.15)) { showSkillParticles = true }
    }

    func deactivateSkillEffect(after delay: TimeInterval) {
        Task {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            withAnimation(.easeInOut(duration: 0.4)) {
                showSkillParticles = false
                activeSkillEffect = nil
            }
        }
    }
}

// MARK: - Damage / Heal / Rewards
private extension BattleSceneController {

    func applyDamage(_ amount: Int) {
        bossHp = max(bossHp - amount, 0)
    }

    func healCharacter(amount: Int, reward: String) {
        triggerHitEffect(intensity: 0.8)
        displayReward(reward)
    }

    func triggerHitEffect(intensity: Double = 1.0) {
        withAnimation(.easeOut(duration: 0.1)) { showHitEffect = true }

        Task {
            try? await Task.sleep(nanoseconds: 400_000_000)
            withAnimation(.easeInOut(duration: 0.25)) { showHitEffect = false }
        }
    }

    func displayReward(_ text: String) {
        rewardText = text
        withAnimation(.easeInOut(duration: 0.3)) { rewardOpacity = 1 }

        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            withAnimation(.easeInOut(duration: 0.5)) { rewardOpacity = 0 }

            try? await Task.sleep(nanoseconds: 600_000_000)
            rewardText = nil
        }
    }
}

// MARK: - Battle End / Rewards
private extension BattleSceneController {

    func checkBattleEnd() {
        guard bossHp <= 0, !isBattleFinished else { return }
        battleFinished()
    }

    func battleFinished() {
        isBattleFinished = true
        triggerRewards()
        onBossDefeated?()
        onFight?()
    }

    func triggerRewards() {
        let coins = Int.random(in: 10...20)
        let crystals = Int.random(in: 10...20)
        let exp = Int.random(in: 18...28)

        coinManager.addCoins(coins)
        crystalManager.addCrystals(crystals)
        characterManager.levelUp(id: activeCharacter.id, expGained: exp)
        accountManager.addExp(exp / 2)

        displayReward("+\(coins) 💰 +\(crystals) 💎 +\(exp) EXP")
    }
}

// MARK: - Array Safe Index
private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
