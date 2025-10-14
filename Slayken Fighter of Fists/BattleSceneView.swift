import SwiftUI
import MetalKit

struct BattleSceneView: View {
    @ObservedObject var controller: BattleSceneController

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
                // MARK: - Dynamischer Metal-Hintergrund
                backgroundLayer(size: geo.size)

                VStack(spacing: 0) {
                    topBars
                        .padding(.top, safeTopInset() + 8)

                    Spacer()

                    battleArea(size: geo.size)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    teamFooter
                        .padding(.bottom, 20)
                }

                // Tap-to-Attack Overlay
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { controller.performAttack() }
            }
            .ignoresSafeArea(edges: .top)
            .animation(.easeInOut(duration: 0.25), value: controller.bossHp)
        }
    }
}

// MARK: - Background
extension BattleSceneView {
    private func backgroundLayer(size: CGSize) -> some View {
        let elementColors = colorFor(element: controller.boss.element)
        return MetalBackgroundView(
            topColor: elementColors.top,
            bottomColor: elementColors.bottom,
            bossColor: controller.boss.filter.simd
        )
        .ignoresSafeArea()
        .overlay(
            LinearGradient(
                colors: [.black.opacity(0.1), .black.opacity(0.7)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private func colorFor(element: String) -> (top: SIMD4<Float>, bottom: SIMD4<Float>) {
        switch element.lowercased() {
        case "fire": return (SIMD4(1.0, 0.4, 0.1, 1.0), SIMD4(0.3, 0.0, 0.0, 1.0))
        case "ice": return (SIMD4(0.6, 0.9, 1.0, 1.0), SIMD4(0.0, 0.2, 0.4, 1.0))
        case "void": return (SIMD4(0.3, 0.0, 0.5, 1.0), SIMD4(0.05, 0.0, 0.15, 1.0))
        case "nature": return (SIMD4(0.3, 0.8, 0.4, 1.0), SIMD4(0.0, 0.2, 0.05, 1.0))
        default: return (SIMD4(0.4, 0.4, 0.4, 1.0), SIMD4(0.0, 0.0, 0.0, 1.0))
        }
    }
}

// MARK: - Top Bars (HUD)
extension BattleSceneView {
    private var topBars: some View {
        HStack {
            // Player Side
            VStack(alignment: .leading, spacing: 6) {
                Text("Lv. \(characterManager.getLevel(for: controller.activeCharacter.id))")
                    .font(.caption.bold())
                    .foregroundColor(.white)
                expBar(for: controller.activeCharacter.id)
            }

            Spacer()

            // Boss Side
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

// MARK: - Battle Area
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

    // MARK: - Character
    private var characterSection: some View {
        let char = controller.activeCharacter
        return ZStack {
            MetalAuraView()
                .frame(width: 240, height: 240)
                .opacity(0.9)
                .blur(radius: 30)
                .blendMode(.screen)
                .scaleEffect(controller.showHitEffect ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.25), value: controller.showHitEffect)

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

    // MARK: - Boss
    private var bossSection: some View {
        ZStack {
            MetalAuraView()
                .frame(width: 260, height: 260)
                .opacity(0.85)
                .blur(radius: 35)
                .blendMode(.screen)
                .colorMultiply(controller.boss.filter.color)
                .scaleEffect(controller.showHitEffect ? 1.1 : 1.0)
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

            if let reward = controller.rewardText {
                Text(reward)
                    .font(.headline.bold())
                    .foregroundColor(.yellow)
                    .shadow(color: .orange, radius: 8)
                    .opacity(controller.rewardOpacity)
            }
        }
    }
}

// MARK: - UI Bars
extension BattleSceneView {
    private var bossHpBar: some View {
        GeometryReader { geo in
            let hpRatio = max(CGFloat(controller.bossHp) / 100, 0)
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.15))
                Capsule()
                    .fill(LinearGradient(colors: [.red, .orange],
                                         startPoint: .leading, endPoint: .trailing))
                    .frame(width: geo.size.width * hpRatio)
                    .shadow(color: .red.opacity(0.5), radius: 3)
            }
        }
        .frame(width: 180, height: 8)
        .animation(.easeInOut(duration: 0.3), value: controller.bossHp)
    }

    private func expBar(for characterId: String) -> some View {
        let progress = progressFor(characterId: characterId)
        return GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.15))
                Capsule()
                    .fill(LinearGradient(colors: [.blue, .cyan],
                                         startPoint: .leading, endPoint: .trailing))
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

// MARK: - Team Footer
extension BattleSceneView {
    private var teamFooter: some View {
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
                            .shadow(
                                color: index == controller.activeIndex ? .blue.opacity(0.6) : .clear,
                                radius: 8
                            )
                            .scaleEffect(index == controller.activeIndex ? 1.1 : 1.0)
                            .animation(.spring(response: 0.4, dampingFraction: 0.8),
                                       value: controller.activeIndex)
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    controller.activeIndex = index
                                }
                            }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
}
