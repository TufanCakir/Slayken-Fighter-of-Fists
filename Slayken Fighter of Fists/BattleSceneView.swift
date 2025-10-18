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

    // MARK: - Body
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Hintergrund
                backgroundLayer(size: geo.size)

                // Kampf + HUD
                VStack(spacing: 0) {
                               topBars
                                   .padding(.top, safeTopInset() + 8)

                               Spacer()

                               battleArea(size: geo.size)
                                   .frame(maxWidth: .infinity, maxHeight: .infinity)


                
                        .padding(.bottom, 180) // Platz für fixierten Footer
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .zIndex(1)

                // Fixierter Footer (Team + Skills)
                teamFooter
                    .frame(maxWidth: .infinity)
                    .frame(height: 180)
                    .background(
                        LinearGradient(
                            colors: [.black.opacity(0.85), .black.opacity(0.4)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .blur(radius: 8)
                    )
                    .position(
                        x: geo.size.width / 2,
                        y: geo.size.height - 90
                    )
                    .zIndex(2)

                // Reward Text
                if let reward = controller.rewardText {
                    Text(reward)
                        .font(.headline.bold())
                        .foregroundColor(.yellow)
                        .shadow(color: .orange, radius: 8)
                        .opacity(controller.rewardOpacity)
                        .animation(.easeInOut(duration: 0.4), value: controller.rewardOpacity)
                        .zIndex(3)
                        .transition(.opacity)
                        .padding(.top, 100)
                }
            }
            .ignoresSafeArea(edges: .top)
            .animation(.easeInOut(duration: 0.25), value: controller.bossHp)
        }
    }
}

//
// MARK: - Hintergrund
//
extension BattleSceneView {
    private func backgroundLayer(size: CGSize) -> some View {
        let colors = colorFor(element: controller.boss.element)

        return MetalBackgroundView(
            topColor: colors.top,
            bottomColor: colors.bottom,
            bossColor: controller.boss.filter.simd
        )
        .ignoresSafeArea()
        .overlay(
            LinearGradient(
                colors: [.black.opacity(0.1), .black.opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private func colorFor(element: String) -> (top: SIMD4<Float>, bottom: SIMD4<Float>) {
        switch element.lowercased() {
        case "fire": return (SIMD4(1, 0.4, 0.1, 1), SIMD4(0.3, 0, 0, 1))
        case "ice": return (SIMD4(0.6, 0.9, 1, 1), SIMD4(0, 0.2, 0.4, 1))
        case "void": return (SIMD4(0.3, 0, 0.5, 1), SIMD4(0.05, 0, 0.15, 1))
        case "nature": return (SIMD4(0.3, 0.8, 0.4, 1), SIMD4(0, 0.2, 0.05, 1))
        default: return (SIMD4(0.4, 0.4, 0.4, 1), SIMD4(0, 0, 0, 1))
        }
    }
}

//
// MARK: - HUD
//
extension BattleSceneView {
    private var topBars: some View {
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

    private func safeTopInset() -> CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.windows.first?.safeAreaInsets.top }
            .first ?? 0
    }
}

//
// MARK: - Kampfbereich
//
extension BattleSceneView {
    private func battleArea(size: CGSize) -> some View {
        ZStack {
            characterSection
                .offset(x: -size.width * 0.25, y: 40)

            bossSection
                .offset(x: size.width * 0.25, y: -10)
        }
        .allowsHitTesting(false)
    }

    private var characterSection: some View {
        let char = controller.activeCharacter

        return ZStack {
            MetalAuraView()
                .frame(width: 240, height: 240)
                .opacity(0.9)
                .blur(radius: 30)
                .blendMode(.screen)

            Image(char.image)
                .resizable()
                .scaledToFit()
                .frame(width: 160)
                .shadow(color: .cyan.opacity(0.6), radius: 10)

            Ellipse()
                .fill(Color.black.opacity(0.5))
                .frame(width: 90, height: 25)
                .blur(radius: 15)
                .offset(y: 70)
        }
    }

    private var bossSection: some View {
        ZStack {
            // 🔥 Effekt fix im Layout (kein Springen)
            MetalSkillEffectView(
                element: controller.activeSkillEffect?.element ?? "fire",
                trigger: controller.showSkillParticles
            )
            .frame(width: 240, height: 240)
            .blendMode(.screen)
            .opacity(controller.showSkillParticles ? 1 : 0)
            .offset(x: 0, y: -20)
            .animation(.easeInOut(duration: 0.4), value: controller.showSkillParticles)
            .zIndex(1)

            MetalAuraView()
                .frame(width: 260, height: 260)
                .opacity(0.85)
                .blur(radius: 35)
                .blendMode(.screen)
                .colorMultiply(controller.boss.filter.color)
                .scaleEffect(controller.showHitEffect ? 1.1 : 1)
                .animation(.easeInOut(duration: 0.25), value: controller.showHitEffect)

            Image(controller.boss.image)
                .resizable()
                .scaledToFit()
                .frame(width: 180)
                .colorMultiply(controller.boss.filter.color)
                .opacity(controller.showHitEffect ? 0.7 : 1)
                .scaleEffect(controller.showHitEffect ? 1.05 : 1)
                .shadow(color: controller.boss.filter.color.opacity(0.6), radius: 12)

            Ellipse()
                .fill(Color.black.opacity(0.55))
                .frame(width: 120, height: 35)
                .blur(radius: 20)
                .offset(y: 90)
        }
    }
}

//
// MARK: - Bars
//
extension BattleSceneView {
    private var bossHpBar: some View {
        GeometryReader { geo in
            let hpRatio = max(CGFloat(controller.bossHp) / 100, 0)
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.15))
                Capsule()
                    .fill(LinearGradient(colors: [.red, .orange], startPoint: .leading, endPoint: .trailing))
                    .frame(width: geo.size.width * hpRatio)
                    .shadow(color: .red.opacity(0.5), radius: 3)
            }
        }
        .frame(width: 180, height: 8)
        .animation(.easeInOut(duration: 0.3), value: controller.bossHp)
    }

    private func expBar(for id: String) -> some View {
        let progress = progressFor(characterId: id)
        return GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.15))
                Capsule()
                    .fill(LinearGradient(colors: [.blue, .cyan], startPoint: .leading, endPoint: .trailing))
                    .frame(width: geo.size.width * progress)
                    .shadow(color: .cyan.opacity(0.4), radius: 4)
            }
        }
        .frame(width: 180, height: 8)
    }

    private func progressFor(characterId: String) -> Double {
        guard let char = characterManager.characters.first(where: { $0.id == characterId }) else { return 0 }
        let expToNext = Double(char.level * 100)
        return min(Double(char.exp) / expToNext, 1.0)
    }
}

//
// MARK: - Team Footer
//
extension BattleSceneView {
    private var teamFooter: some View {
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
                                        ? LinearGradient(colors: [.cyan, .blue], startPoint: .top, endPoint: .bottom)
                                        : LinearGradient(colors: [.white.opacity(0.25)], startPoint: .top, endPoint: .bottom),
                                        lineWidth: index == controller.activeIndex ? 3 : 1
                                    )
                                )
                                .shadow(color: index == controller.activeIndex ? .blue.opacity(0.6) : .clear, radius: 8)
                                .scaleEffect(index == controller.activeIndex ? 1.1 : 1)
                                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: controller.activeIndex)
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

    private var actionBar: some View {
        let skills = controller.activeCharacter.skills
        return HStack(spacing: 20) {
            ForEach(skills, id: \.self) { skill in
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: gradientFor(skill: skill),
                                             startPoint: .topLeading,
                                             endPoint: .bottomTrailing))
                        .frame(width: 64, height: 64)
                        .shadow(color: .white.opacity(0.2), radius: 4)
                        .overlay(Circle().strokeBorder(Color.white.opacity(0.3), lineWidth: 1.5))

                    VStack(spacing: 3) {
                        Image(systemName: iconFor(skill: skill))
                            .font(.system(size: 22))
                            .foregroundColor(.white)
                        Text(skill.capitalized)
                            .font(.caption2.bold())
                            .foregroundColor(.white.opacity(0.85))
                    }

                    if controller.isSkillOnCooldown(skill) {
                        Circle()
                            .fill(Color.black.opacity(0.55))
                            .overlay(
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(.white)
                            )
                    }
                }
                .onTapGesture {
                    guard !controller.isSkillOnCooldown(skill) else { return }
                    controller.useSkill(skill)
                }
                .scaleEffect(controller.isSkillOnCooldown(skill) ? 0.9 : 1)
                .opacity(controller.isSkillOnCooldown(skill) ? 0.5 : 1)
                .animation(.easeInOut(duration: 0.2), value: controller.isSkillOnCooldown(skill))
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
        .background(
            LinearGradient(colors: [.black.opacity(0.8), .black.opacity(0.4)],
                           startPoint: .top,
                           endPoint: .bottom)
            .blur(radius: 6)
        )
        .clipShape(Capsule())
        .shadow(color: .blue.opacity(0.3), radius: 6)
    }

    private func gradientFor(skill: String) -> [Color] {
        switch skill.lowercased() {
        case "inferno punch", "blazing kick": return [.red, .orange]
        case "frost smash", "glacial wall": return [.cyan, .blue]
        case "void strike", "dark collapse": return [.purple, .black]
        case "thunder break", "lightning flash": return [.yellow, .orange]
        case "healing bloom", "nature vines": return [.green, .mint]
        default: return [.gray, .white.opacity(0.5)]
        }
    }

    private func iconFor(skill: String) -> String {
        switch skill.lowercased() {
        case "inferno punch", "blazing kick": return "flame.fill"
        case "frost smash", "glacial wall": return "snowflake"
        case "void strike", "dark collapse": return "circle.dashed"
        case "thunder break", "lightning flash": return "bolt.fill"
        case "healing bloom", "nature vines": return "leaf.fill"
        default: return "sparkles"
        }
    }
}
