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
    @Published private var cooldowns: [String: Bool] = [:]

    // MARK: - Skill / Particle FX
    @Published var showSkillParticles = false
    @Published var activeSkillEffect: SkillEffect? = nil

    struct SkillEffect {
        let element: String
        let name: String
    }

    // MARK: - Team & Boss
    @Published private(set) var team: [GameCharacter]
    var activeCharacter: GameCharacter { team[activeIndex] }
    let boss: Boss

    // MARK: - Managers
    let coinManager: CoinManager
    let crystalManager: CrystalManager
    let accountManager: AccountLevelManager
    let characterManager: CharacterLevelManager

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

// MARK: - Gameplay Logic (Attack + Cooldowns)
extension BattleSceneController {

    // MARK: - Basic Attack
    func performAttack() {
        guard canAttack, bossHp > 0 else { return }

        startCooldown()
        triggerHitEffect(intensity: 1.0)

        let damage = Int.random(in: 12...26)
        applyDamage(damage)
        displayReward("⚔️ Basic Attack")

        if bossHp <= 0 { battleFinished() }
    }

    // MARK: - Cooldown System
    func isSkillOnCooldown(_ skill: String) -> Bool {
        cooldowns[skill.lowercased()] ?? false
    }

    private func startSkillCooldown(_ skill: String, duration: Double) {
        let key = skill.lowercased()
        cooldowns[key] = true

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            self.cooldowns[key] = false
        }
    }

    private func startCooldown() {
        canAttack = false
        DispatchQueue.main.asyncAfter(deadline: .now() + attackCooldown) {
            self.canAttack = true
        }
    }
}

// MARK: - Skill System
extension BattleSceneController {

    func useSkill(_ skill: String) {
        guard !isSkillOnCooldown(skill), bossHp > 0 else { return }

        let key = skill.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        startSkillCooldown(skill, duration: 3.0)

        print("🎯 Using skill: \(key)")
        triggerHitEffect(intensity: 1.4)

        // Leite an passende Kategorie weiter
        switch key {
        case "inferno punch":
            castDamageSkill(name: "Inferno Punch", element: "fire", damage: 60...75)
        case "blazing kick":
            castDamageSkill(name: "Blazing Kick", element: "fire", damage: 70...90)

        case "frost smash":
            castDamageSkill(name: "Frost Smash", element: "ice", damage: 45...65)
        case "glacial wall":
            castHealSkill(name: "Glacial Wall", element: "ice", heal: 30)

        case "thunder break":
            castDamageSkill(name: "Thunder Break", element: "thunder", damage: 50...70)
        case "lightning flash":
            castDamageSkill(name: "Lightning Flash", element: "thunder", damage: 60...85)

        case "healing bloom":
            castHealSkill(name: "Healing Bloom", element: "nature", heal: 25)
        case "nature vines":
            castDamageSkill(name: "Nature Vines", element: "nature", damage: 30...45)

        case "void strike":
            castDamageSkill(name: "Void Strike", element: "void", damage: 55...75)
        case "dark collapse":
            castDamageSkill(name: "Dark Collapse", element: "void", damage: 70...95)

        default:
            performAttack()
        }
    }

    // MARK: - Attack Skill
    private func castDamageSkill(name: String, element: String, damage: ClosedRange<Int>) {
        // 1️⃣ Effekt aktivieren
        activateSkillEffect(element: element, name: name)

        // 2️⃣ Schaden berechnen
        let dmg = Int.random(in: damage)
        applyDamage(dmg)
        displayReward("🔥 \(name)!")

        // 3️⃣ Treffer-Feedback
        triggerHitEffect(intensity: 1.3)

        // 4️⃣ Effekt deaktivieren
        deactivateSkillEffect(after: 1.2)

        // 5️⃣ Boss besiegt?
        if bossHp <= 0 { battleFinished() }
    }

    // MARK: - Heal Skill
    private func castHealSkill(name: String, element: String, heal: Int) {
        activateSkillEffect(element: element, name: name)
        healCharacter(amount: heal, reward: "💚 \(name)!")
        deactivateSkillEffect(after: 1.2)
    }

    // MARK: - Skill FX Control
    private func activateSkillEffect(element: String, name: String) {
        activeSkillEffect = SkillEffect(element: element, name: name)
        withAnimation(.easeOut(duration: 0.1)) {
            showSkillParticles = true
        }
    }

    private func deactivateSkillEffect(after delay: TimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(.easeInOut(duration: 0.4)) {
                self.showSkillParticles = false
                self.activeSkillEffect = nil
            }
        }
    }
}

// MARK: - Damage / Heal / Rewards
extension BattleSceneController {

    private func applyDamage(_ amount: Int) {
        bossHp = max(bossHp - amount, 0)
    }

    private func healCharacter(amount: Int, reward: String) {
        triggerHitEffect(intensity: 0.8)
        displayReward(reward)
    }

    private func triggerHitEffect(intensity: Double = 1.0) {
        withAnimation(.easeOut(duration: 0.1)) {
            showHitEffect.toggle()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeInOut(duration: 0.25)) {
                self.showHitEffect = false
            }
        }
    }

    private func displayReward(_ text: String) {
        rewardText = text
        withAnimation(.easeInOut(duration: 0.3)) { rewardOpacity = 1 }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 0.5)) { self.rewardOpacity = 0 }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            self.rewardText = nil
        }
    }

    private func battleFinished() {
        isBattleFinished = true
        triggerRewards()
        onBossDefeated?()
        onFight?()
    }

    private func triggerRewards() {
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
