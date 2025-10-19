import SwiftUI
import Combine

@MainActor
final class BattleSceneController: ObservableObject {

    // MARK: - Published UI States
    @Published var bossHp: Int
    @Published var showHitEffect = false
    @Published var rewardText: String?
    @Published var rewardOpacity: Double = 0
    @Published var canAttack = true
    @Published var isBattleFinished = false
    @Published var activeIndex: Int = 0

    // MARK: - Visual FX
    @Published var showSkillParticles = false
    @Published var activeSkillEffect: SkillEffect?
    @Published var showShadowClone = false
    @Published var shadowCloneOpacity: Double = 0.0
    @Published var shadowCloneOffset: CGFloat = 0.0
    @Published var backgroundTint: Color = .clear

    // MARK: - Cooldowns
    @Published var cooldowns: [String: Bool] = [:]
    @Published var cooldownRemaining: [String: Double] = [:]
    @Published var cooldownDuration: [String: Double] = [:]

    // MARK: - Model Structs
    struct SkillEffect {
        let element: String
        let name: String
        let style: EffectStyle
        
        enum EffectStyle: String {
            case burst, ring, beam, spiral, wave, tornado, shadowclone
        }
    }

    // MARK: - Battle Entities
    @Published private(set) var team: [GameCharacter]
    var activeCharacter: GameCharacter { team[safe: activeIndex] ?? team.first ?? .example }
    let boss: Boss

    // MARK: - Managers
    private let coinManager: CoinManager
    private let crystalManager: CrystalManager
    private let accountManager: AccountLevelManager
    private let characterManager: CharacterLevelManager
    private let skillManager: SkillManager

    // MARK: - Logic
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

//
// MARK: - Core Gameplay
//
extension BattleSceneController {

    func performAttack() {
        guard canAttack, bossHp > 0, !isBattleFinished else { return }

        startAttackCooldown()
        triggerHitEffect()

        let damage = Int.random(in: 12...26)
        applyDamage(damage)
        displayReward("⚔️ Basic Attack – \(damage) DMG")

        checkBattleEnd()
    }
    
    private func effectStyle(for element: String) -> SkillEffect.EffectStyle {
        switch element.lowercased() {
        case "fire": return .burst
        case "ice": return .ring
        case "void": return .spiral
        case "shadow": return .wave
        case "shadowclone": return .shadowclone
        case "thunder": return .beam
        case "tornado": return .tornado
        case "nature": return .ring
        case "wind": return .beam
        default: return .burst
        }
    }


    func useSkill(_ name: String) {
        guard let skill = skillManager.skill(named: name) else { return }

        // 🎨 Hintergrund-Farbimpuls
        triggerBackgroundTint(for: skill.element)

        
        // ⚡ Aktiviere FX
        let style = effectStyle(for: skill.element)
        activeSkillEffect = SkillEffect(element: skill.element, name: skill.name, style: style)
        showSkillParticles = true

        // 🧠 Logik nach Typ
        switch skill.type.lowercased() {
        case "damage":
            castDamageSkill(name: skill.name, element: skill.element, damage: skill.damageRange ?? 20...30)
        case "heal":
            castHealSkill(name: skill.name, element: skill.element, heal: skill.healAmount ?? 20)
        case "shadowclone", "clone", "illusion":
            castShadowCloneSkill(name: skill.name, element: skill.element)
        default:
            displayReward("✨ \(skill.name) aktiviert!")
        }
    }
}



//
// MARK: - Skill Actions
//
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

    func castShadowCloneSkill(name: String, element: String) {
        guard !showShadowClone else { return }

        activateSkillEffect(element: element, name: name)
        showShadowClone = true
        shadowCloneOpacity = 0.0
        shadowCloneOffset = -60

        withAnimation(.easeOut(duration: 0.3)) {
            shadowCloneOpacity = 0.8
            shadowCloneOffset = -40
        }

        // 🌀 Clone greift verzögert an
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.performAttack()
        }

        // 💨 Clone verblasst
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 0.4)) {
                self.shadowCloneOpacity = 0.0
                self.shadowCloneOffset = -20
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                self.showShadowClone = false
                self.deactivateSkillEffect(after: 0.3)
            }
        }

        displayReward("🌀 Shadow Clone aktiviert!")
    }
}

//
// MARK: - Skill FX Handling
//
private extension BattleSceneController {

    func activateSkillEffect(element: String, name: String) {
        let style: SkillEffect.EffectStyle = switch element.lowercased() {
        case "fire": .burst
        case "ice": .ring
        case "thunder": .beam
        case "void": .spiral
        case "shadow": .wave
        case "tornado": .tornado
        case "shadowclone": .shadowclone
        default: .burst
        }
        
        activeSkillEffect = SkillEffect(element: element, name: name, style: style)
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

    func triggerBackgroundTint(for element: String) {
        let tint = colorForElement(element)
        withAnimation(.easeInOut(duration: 0.3)) { backgroundTint = tint }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            withAnimation(.easeOut(duration: 0.8)) { self.backgroundTint = .clear }
        }
    }

    func colorForElement(_ element: String) -> Color {
        switch element.lowercased() {
        case "fire": .red
        case "ice": .cyan
        case "void": .purple
        case "shadow": .purple
        case "thunder": .yellow
        case "nature": .green
        case "wind": .mint
        case "water": .blue
        case "tornado": .brown
        case "shadowclone": .indigo
        default: .clear
        }
    }
}

//
// MARK: - Damage / Heal / Feedback
//
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeInOut(duration: 0.25)) { self.showHitEffect = false }
        }
    }

    func displayReward(_ text: String) {
        rewardText = text
        withAnimation(.easeInOut(duration: 0.3)) { rewardOpacity = 1 }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 0.5)) { self.rewardOpacity = 0 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            self.rewardText = nil
        }
    }
}

//
// MARK: - Battle End
//
private extension BattleSceneController {

    func checkBattleEnd() {
        guard bossHp <= 0, !isBattleFinished else { return }
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

//
// MARK: - Cooldowns
//
extension BattleSceneController {

    func isSkillOnCooldown(_ skill: String) -> Bool {
        cooldowns[skill.lowercased()] ?? false
    }

    func startSkillCooldown(_ skill: String, duration: TimeInterval) {
        let key = skill.lowercased()
        cooldowns[key] = true
        cooldownRemaining[key] = duration
        cooldownDuration[key] = duration

        Task.detached(priority: .background) {
            let start = Date()
            while let remaining = await self.cooldownRemaining[key], remaining > 0 {
                try? await Task.sleep(nanoseconds: 200_000_000)
                let elapsed = Date().timeIntervalSince(start)
                await MainActor.run {
                    self.cooldownRemaining[key] = max(duration - elapsed, 0)
                }
            }
            await MainActor.run {
                self.cooldowns[key] = false
                self.cooldownRemaining[key] = nil
                self.cooldownDuration[key] = nil
            }
        }
    }

    func startAttackCooldown() {
        canAttack = false
        DispatchQueue.main.asyncAfter(deadline: .now() + attackCooldown) {
            self.canAttack = true
        }
    }
}

//
// MARK: - Safe Array Access
//
private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
