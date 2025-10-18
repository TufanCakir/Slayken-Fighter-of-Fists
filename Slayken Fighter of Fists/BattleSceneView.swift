import SwiftUI
import MetalKit

struct BattleSceneView: View {
    @StateObject var controller: BattleSceneController
    
    // MARK: - Environment Managers
    @EnvironmentObject private var characterManager: CharacterLevelManager
    @EnvironmentObject private var coinManager: CoinManager
    @EnvironmentObject private var crystalManager: CrystalManager
    @EnvironmentObject private var accountManager: AccountLevelManager
    @EnvironmentObject private var summonManager: SummonManager
    @EnvironmentObject private var teamManager: TeamManager
    @EnvironmentObject private var skillManager: SkillManager
    
    // MARK: - Body
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // 1️⃣ Hintergrund
                backgroundLayer(size: geo.size)
                
                // 2️⃣ HUD + Kampfbereich
                VStack(spacing: 0) {
                    topBars
                        .padding(.top, safeTopInset() + 8)
                    Spacer(minLength: 0)
                    battleArea(size: geo.size)
                        .padding(.bottom, 140)
                }
                .zIndex(1)
                
                // 3️⃣ Fixierter Footer (unten)
                VStack {
                    Spacer()
                    teamFooter
                        .padding(.bottom, safeBottomInset() + 6)
                        .background(
                            LinearGradient(
                                colors: [.black.opacity(0.85), .black.opacity(0.4)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .blur(radius: 10)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: .black.opacity(0.4), radius: 12, y: -3)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .strokeBorder(Color.white.opacity(0.05))
                        )
                        .frame(maxWidth: .infinity)
                        .ignoresSafeArea(edges: .bottom)
                }
                .zIndex(2)
                
                // 4️⃣ Reward-Text oben
                if let reward = controller.rewardText {
                    Text(reward)
                        .font(.headline.bold())
                        .foregroundColor(.yellow)
                        .shadow(color: .orange.opacity(0.8), radius: 8)
                        .opacity(controller.rewardOpacity)
                        .transition(.opacity)
                        .padding(.top, 100)
                        .zIndex(3)
                }
                
                // 5️⃣ Tap anywhere to attack (outside of footer area)
                GeometryReader { proxy in
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .allowsHitTesting(true)
                        .gesture(
                            TapGesture()
                                .onEnded {
                                    let footerHeight: CGFloat = 180 // Footer (Team + Skills)
                                    let screenHeight = proxy.size.height

                                    // Get touch location manually via UIScreen
                                    if let window = UIApplication.shared.connectedScenes
                                        .compactMap({ ($0 as? UIWindowScene)?.windows.first })
                                        .first {
                                        let location = window.rootViewController?.view?.gestureRecognizers?.first?.location(in: window)
                                        if let y = location?.y, y < screenHeight - footerHeight {
                                            controller.performAttack()
                                        }
                                    } else {
                                        // fallback (no window info)
                                        controller.performAttack()
                                    }
                                }
                        )
                        .zIndex(9)
                }
                .ignoresSafeArea()


            }
            .ignoresSafeArea(edges: .top)
            .animation(.easeInOut(duration: 0.3), value: controller.bossHp)
        }
    }
}

//
// MARK: - Hintergrund
//
private extension BattleSceneView {
    func backgroundLayer(size: CGSize) -> some View {
        let colors = colorFor(element: controller.boss.element)
        return MetalBackgroundView(
            topColor: colors.top,
            bottomColor: colors.bottom,
            bossColor: controller.boss.filter.simd
        )
        .ignoresSafeArea()
        .overlay(
            LinearGradient(
                colors: [.black.opacity(0.05), .black.opacity(0.9)],
                startPoint: .top, endPoint: .bottom
            )
        )
    }

    func colorFor(element: String) -> (top: SIMD4<Float>, bottom: SIMD4<Float>) {
        switch element.lowercased() {
        case "fire":   return (SIMD4(1, 0.4, 0.1, 1), SIMD4(0.3, 0, 0, 1))
        case "ice":    return (SIMD4(0.6, 0.9, 1, 1), SIMD4(0, 0.2, 0.4, 1))
        case "void":   return (SIMD4(0.3, 0, 0.5, 1), SIMD4(0.05, 0, 0.15, 1))
        case "nature": return (SIMD4(0.3, 0.8, 0.4, 1), SIMD4(0, 0.2, 0.05, 1))
        default:       return (SIMD4(0.5, 0.5, 0.5, 1), SIMD4(0, 0, 0, 1))
        }
    }
}

//
// MARK: - HUD (oben)
//
private extension BattleSceneView {
    var topBars: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("Lv. \(characterManager.getLevel(for: controller.activeCharacter.id))")
                    .font(.caption.bold())
                    .foregroundColor(.white)
                expBar(for: controller.activeCharacter.id)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text(controller.boss.name)
                    .font(.caption.bold())
                    .foregroundColor(.white)
                bossHpBar
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
        .background(
            LinearGradient(colors: [.black.opacity(0.7), .black.opacity(0.3)],
                           startPoint: .top, endPoint: .bottom)
            .blur(radius: 10)
        )
    }

    func safeTopInset() -> CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.windows.first?.safeAreaInsets.top }
            .first ?? 0
    }

    func safeBottomInset() -> CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.windows.first?.safeAreaInsets.bottom }
            .first ?? 0
    }
}

//
// MARK: - Kampfbereich
//
private extension BattleSceneView {
    func battleArea(size: CGSize) -> some View {
        HStack {
            Spacer(minLength: size.width * 0.05)

            // 🟦 Spieler links (schaut nach rechts)
            characterSection
                .frame(width: size.width * 0.4, height: size.height * 0.4)
                .scaleEffect(x: 1, y: 1)

            Spacer()

            // 🟥 Boss rechts (spiegeln, schaut nach links)
            bossSection
                .frame(width: size.width * 0.4, height: size.height * 0.4)
                .scaleEffect(x: -1, y: 1)

            Spacer(minLength: size.width * 0.05)
        }
        .frame(maxWidth: .infinity, maxHeight: size.height * 0.6)
        .contentShape(Rectangle())
        .animation(.easeInOut(duration: 0.25), value: controller.showHitEffect)
        .allowsHitTesting(false)
    }

    var characterSection: some View {
        let char = controller.activeCharacter
        return ZStack {
            MetalAuraView()
                .frame(width: 260, height: 260)
                .opacity(0.8)
                .blur(radius: 40)
                .blendMode(.screen)
                .scaleEffect(controller.showHitEffect ? 1.1 : 1)

            Image(char.image)
                .resizable()
                .scaledToFit()
                .frame(width: 180)
                .shadow(color: .cyan.opacity(0.6), radius: 10)
                .scaleEffect(controller.showHitEffect ? 1.05 : 1)

            Ellipse()
                .fill(Color.black.opacity(0.4))
                .frame(width: 100, height: 25)
                .blur(radius: 15)
                .offset(y: 80)
        }
    }

    var bossSection: some View {
        ZStack {
            MetalSkillEffectView(
                element: controller.activeSkillEffect?.element ?? controller.boss.element,
                trigger: controller.showSkillParticles
            )
            .frame(width: 280, height: 280)
            .blendMode(.screen)
            .opacity(controller.showSkillParticles ? 1 : 0)
            .offset(y: -10)

            MetalAuraView()
                .frame(width: 280, height: 280)
                .opacity(0.85)
                .blur(radius: 40)
                .blendMode(.screen)
                .colorMultiply(controller.boss.filter.color)
                .scaleEffect(controller.showHitEffect ? 1.1 : 1)

            Image(controller.boss.image)
                .resizable()
                .scaledToFit()
                .frame(width: 200)
                .colorMultiply(controller.boss.filter.color)
                .opacity(controller.showHitEffect ? 0.7 : 1)
                .shadow(color: controller.boss.filter.color.opacity(0.6), radius: 12)
                .scaleEffect(controller.showHitEffect ? 1.05 : 1)

            Ellipse()
                .fill(Color.black.opacity(0.55))
                .frame(width: 120, height: 35)
                .blur(radius: 20)
                .offset(y: 80)
        }
    }
}

//
// MARK: - Status Bars
//
private extension BattleSceneView {
    var bossHpBar: some View {
        GeometryReader { geo in
            let hpRatio = max(CGFloat(controller.bossHp) / 100, 0)
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.15))
                Capsule()
                    .fill(LinearGradient(colors: [.red, .orange],
                                         startPoint: .leading,
                                         endPoint: .trailing))
                    .frame(width: geo.size.width * hpRatio)
                    .shadow(color: .red.opacity(0.5), radius: 3)
            }
        }
        .frame(width: 180, height: 8)
    }

    func expBar(for id: String) -> some View {
        let progress = progressFor(characterId: id)
        return GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.15))
                Capsule()
                    .fill(LinearGradient(colors: [.blue, .cyan],
                                         startPoint: .leading,
                                         endPoint: .trailing))
                    .frame(width: geo.size.width * progress)
                    .shadow(color: .cyan.opacity(0.4), radius: 4)
            }
        }
        .frame(width: 180, height: 8)
    }

    func progressFor(characterId: String) -> Double {
        guard let char = characterManager.characters.first(where: { $0.id == characterId }) else { return 0 }
        let expToNext = Double(char.level * 100)
        return min(Double(char.exp) / expToNext, 1.0)
    }
}

//
// MARK: - Footer (Skills + Team)
//
private extension BattleSceneView {
    var teamFooter: some View {
        VStack(spacing: 12) {
            actionBar
                .padding(.bottom, 8)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(Array(controller.team.enumerated()), id: \.offset) { index, member in
                        VStack(spacing: 4) {
                            Image(member.image)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                                .clipShape(Circle())
                                .overlay(
                                    Circle().strokeBorder(
                                        index == controller.activeIndex
                                        ? LinearGradient(colors: [.cyan, .blue],
                                                         startPoint: .top, endPoint: .bottom)
                                        : LinearGradient(colors: [.white.opacity(0.25)],
                                                         startPoint: .top, endPoint: .bottom),
                                        lineWidth: index == controller.activeIndex ? 3 : 1
                                    )
                                )
                                .shadow(color: index == controller.activeIndex ? .blue.opacity(0.6) : .clear, radius: 8)
                                .scaleEffect(index == controller.activeIndex ? 1.1 : 1)
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        controller.activeIndex = index
                                    }
                                }
                            
                            Text(member.name)
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    var actionBar: some View {
        let skills = skillManager.getSkills(for: controller.activeCharacter.skillIDs)

        return HStack(spacing: 16) {
            ForEach(skills, id: \.id) { skill in
                SkillButtonView(skill: skill, controller: controller)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.black.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.7), radius: 10, y: -2)
        )
        .padding(.horizontal, 20)
    }

    
    //
    // MARK: - Skill Helper
    //
    private func gradientFor(element: String) -> [Color] {
        switch element.lowercased() {
        case "fire": return [.red, .orange]
        case "ice": return [.cyan, .blue]
        case "void": return [.purple, .black]
        case "thunder": return [.yellow, .orange]
        case "nature": return [.green, .mint]
        default: return [.gray, .white.opacity(0.5)]
        }
    }
    
    private func iconFor(element: String) -> String {
        switch element.lowercased() {
        case "fire": return "flame.fill"
        case "ice": return "snowflake"
        case "void": return "circle.dashed"
        case "thunder": return "bolt.fill"
        case "nature": return "leaf.fill"
        default: return "sparkles"
        }
    }
}
