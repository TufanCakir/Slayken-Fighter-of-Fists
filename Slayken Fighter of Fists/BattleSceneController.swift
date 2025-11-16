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
    @Published private(set) var skillCooldowns: [String: Bool] = [:]

    // MARK: - Visual FX
    @Published var showSkillParticles = false
    @Published var activeSkillEffect: SkillEffect?
    @Published var showShadowClone = false
    @Published var shadowCloneOpacity: Double = 0.0
    @Published var shadowCloneOffset: CGFloat = 0.0
    @Published var backgroundTint: Color = .clear

    // MARK: - Cooldowns
    @Published private(set) var cooldowns: [String: Bool] = [:]
    @Published private(set) var cooldownRemaining: [String: Double] = [:]
    @Published private(set) var cooldownDuration: [String: Double] = [:]

    // MARK: - Models
    struct SkillEffect {
        let element: String
        let name: String
        let style: EffectStyle
        enum EffectStyle: String {
            case burst, ring, beam, spiral, wave, tornado, shadowclone, beamstrike, tide_crash
        }
    }

    // MARK: - Entities
    @Published private(set) var activeCharacter: GameCharacter
    let boss: Boss

    // MARK: - Managers
    private let coinManager: CoinManager
    private let crystalManager: CrystalManager
    private let accountManager: AccountLevelManager
    private let characterManager: CharacterManager
    private let skillManager: SkillManager

    // MARK: - Logic
    private var cancellables = Set<AnyCancellable>()
    private let attackCooldown: TimeInterval = 0.5

    // MARK: - Callbacks
    var onFight: (() -> Void)?
    var onExit: (() -> Void)?
    var onBossDefeated: (() -> Void)?

    // MARK: - Init
    init(
        boss: Boss,
        bossHp: Int,
        coinManager: CoinManager,
        crystalManager: CrystalManager,
        accountManager: AccountLevelManager,
        characterManager: CharacterManager,
        skillManager: SkillManager
    ) {
        self.boss = boss
        self.bossHp = bossHp
        self.coinManager = coinManager
        self.crystalManager = crystalManager
        self.accountManager = accountManager
        self.characterManager = characterManager
        self.skillManager = skillManager

        // 🔹 Lade aktiven Spielercharakter
        if let hero = characterManager.activeCharacter {
            self.activeCharacter = hero
            print("✅ Loaded active player: \(hero.name) with \(hero.skillIDs.count) skills.")
        } else {
            // Fallback: Erster Charakter aus JSON
            let jsonChars: [GameCharacter] = Bundle.main.decode("characters.json")
            self.activeCharacter = jsonChars.first ?? .example
            print("⚠️ No activeCharacter found — fallback to \(self.activeCharacter.name)")
        }

        observeCharacterUpdates()
    }

    // MARK: - Character Sync
    private func observeCharacterUpdates() {
        characterManager.$activeCharacter
            .compactMap { $0 }
            .sink { [weak self] updated in
                self?.activeCharacter = updated
                print("🧙‍♂️ Active character updated to \(updated.name)")
            }
            .store(in: &cancellables)
    }
}

//
// MARK: - ⚔️ Core Gameplay
//
extension BattleSceneController {

    func performAttack() {
        guard canAttack, bossHp > 0, !isBattleFinished else { return }

        startAttackCooldown()
        triggerHitEffect()

        let baseDamage = Int.random(in: 12...26)
        let scaled = Int(Double(baseDamage) * (Double(activeCharacter.level) * 0.15 + 1.0))
        applyDamage(scaled)
        displayReward("⚔️ \(activeCharacter.name) – \(scaled) DMG")

        checkBattleEnd()
    }
}

//
// MARK: - 🧙 Skills
//
extension BattleSceneController {

    func useSkill(_ id: String) {
        guard let skill = skillManager.skill(named: id) else { return }

        triggerBackgroundTint(for: skill.element)
        let style = effectStyle(for: skill.element)
        activeSkillEffect = SkillEffect(element: skill.element, name: skill.name, style: style)
        showSkillParticles = true

        switch skill.type.lowercased() {
        case "damage":
            castDamageSkill(name: skill.name, element: skill.element, damage: skill.damageRange ?? 20...30)
        case "heal":
            castHealSkill(name: skill.name, element: skill.element, heal: skill.healAmount ?? 20)
        case "shadowclone":
            castShadowCloneSkill(name: skill.name, element: skill.element)
        default:
            displayReward("✨ \(skill.name) aktiviert!")
        }
    }

    private func effectStyle(for element: String) -> SkillEffect.EffectStyle {
        switch element.lowercased() {
        case "fire": .burst
        case "ice": .ring
        case "void": .spiral
        case "shadow": .wave
        case "shadowclone": .shadowclone
        case "thunder": .beam
        case "tornado": .tornado
        case "nature": .ring
        case "wind": .beam
        case "beamstrike": .beamstrike
        case "tide_crash": .tide_crash
        default: .burst
        }
    }
}

//
// MARK: - 💥 Skill Actions
//
// MARK: - ⏳ Cooldowns
extension BattleSceneController {

    /// 🔹 Prüft, ob ein Skill aktuell auf Cooldown ist.
    func isSkillOnCooldown(_ skill: String) -> Bool {
        cooldowns[skill.lowercased()] ?? false
    }

    /// 🔹 Startet den Cooldown für einen Skill.
    func startSkillCooldown(_ skill: String, duration: TimeInterval) {
        let key = skill.lowercased()
        cooldowns[key] = true
        cooldownRemaining[key] = duration
        cooldownDuration[key] = duration

        Task.detached(priority: .background) { [weak self] in
            guard let self else { return }
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
        displayReward("💚 \(name)! +\(heal) HP")
        deactivateSkillEffect(after: 1.2)
    }

    func castShadowCloneSkill(name: String, element: String) {
        guard !showShadowClone else { return }
        activateSkillEffect(element: element, name: name)
        showShadowClone = true
        shadowCloneOpacity = 0
        shadowCloneOffset = -60

        withAnimation(.easeOut(duration: 0.3)) {
            shadowCloneOpacity = 0.8
            shadowCloneOffset = -40
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.performAttack()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 0.4)) {
                self.shadowCloneOpacity = 0
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
// MARK: - 🎨 FX + Damage + Rewards (gleich geblieben)
//
private extension BattleSceneController {

    func activateSkillEffect(element: String, name: String) {
        activeSkillEffect = SkillEffect(element: element, name: name, style: effectStyle(for: element))
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
        case "beamstrike": .green
        case "tide_crash": .blue
        default: .clear
        }
    }

    func applyDamage(_ amount: Int) {
        bossHp = max(bossHp - amount, 0)
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            withAnimation(.easeInOut(duration: 0.5)) { self.rewardOpacity = 0 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            self.rewardText = nil
        }
    }

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
        accountManager.addExp(exp / 2)

        characterManager.levelUp(id: activeCharacter.id, expGained: exp)
        displayReward("+\(coins) 💰 +\(crystals) 💎 +\(exp) EXP")
    }
}

//
// MARK: - Cooldowns
//
extension BattleSceneController {
    func startAttackCooldown() {
        canAttack = false
        DispatchQueue.main.asyncAfter(deadline: .now() + attackCooldown) {
            self.canAttack = true
        }
    }
}
