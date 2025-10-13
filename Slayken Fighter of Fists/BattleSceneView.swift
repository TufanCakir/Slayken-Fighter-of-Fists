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

                    ZStack {
                        characterSection
                            .offset(x: -geo.size.width * 0.22, y: 40)

                        bossSection
                            .offset(x: geo.size.width * 0.22, y: -10)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .zIndex(1)

                    teamFooter
                        .padding(.bottom, 20)
                }

                // Tap-to-Attack Overlay
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { controller.performAttack() }
            }
            .animation(.easeInOut(duration: 0.3), value: controller.bossHp)
            .ignoresSafeArea(edges: .top)
        }
    }
}

// MARK: - Unteransichten & Komponenten
extension BattleSceneView {

    // MARK: - Hintergrund mit dynamischem Metal
    private func backgroundLayer(size: CGSize) -> some View {
        MetalBackgroundView(
            topColor: colorFor(element: controller.boss.element ?? "default").top,
            bottomColor: colorFor(element: controller.boss.element ?? "default").bottom
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

    // MARK: - Element-Farbdefinition
    private func colorFor(element: String) -> (top: SIMD4<Float>, bottom: SIMD4<Float>) {
        switch element.lowercased() {
        case "fire":
            return (
                SIMD4<Float>(1.0, 0.4, 0.1, 1.0), // oben: orange
                SIMD4<Float>(0.3, 0.0, 0.0, 1.0)  // unten: rot
            )
        case "ice":
            return (
                SIMD4<Float>(0.6, 0.9, 1.0, 1.0), // oben: hellblau
                SIMD4<Float>(0.0, 0.2, 0.4, 1.0)  // unten: dunkelblau
            )
        case "void":
            return (
                SIMD4<Float>(0.3, 0.0, 0.5, 1.0), // oben: violett
                SIMD4<Float>(0.05, 0.0, 0.15, 1.0) // unten: schwarzlila
            )
        case "nature":
            return (
                SIMD4<Float>(0.3, 0.8, 0.4, 1.0), // oben: grün
                SIMD4<Float>(0.0, 0.2, 0.05, 1.0)  // unten: dunkelgrün
            )
        default:
            return (
                SIMD4<Float>(0.4, 0.4, 0.4, 1.0), // neutraler Himmel
                SIMD4<Float>(0.0, 0.0, 0.0, 1.0)  // Boden dunkel
            )
        }
    }

    // MARK: - HUD (EXP & HP)
    private var topBars: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Lv. \(characterManager.getLevel(for: controller.activeCharacter.id))")
                    .font(.caption.bold())
                    .foregroundColor(.white)
                expBar(for: controller.activeCharacter.id)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(controller.boss.name)
                    .font(.caption.bold())
                    .foregroundColor(.white)
                bossHpBar
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
        .background(
            LinearGradient(colors: [.black.opacity(0.6), .black.opacity(0.1)],
                           startPoint: .top, endPoint: .bottom)
                .blur(radius: 10)
                .ignoresSafeArea(edges: .top)
        )
    }

    private func safeTopInset() -> CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.windows.first?.safeAreaInsets.top }
            .first ?? 0
    }

    // MARK: - Boss HP-Bar
    private var bossHpBar: some View {
        GeometryReader { geo in
            let width = max(CGFloat(controller.bossHp) / 100, 0)
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.15))
                Capsule()
                    .fill(LinearGradient(colors: [.red, .orange],
                                         startPoint: .leading, endPoint: .trailing))
                    .frame(width: geo.size.width * width)
                    .shadow(color: .red.opacity(0.5), radius: 3)
            }
        }
        .frame(width: 180, height: 8)
        .animation(.easeInOut(duration: 0.3), value: controller.bossHp)
    }

    // MARK: - Charakter & Boss Sektionen
    private var characterSection: some View {
        let char = controller.activeCharacter

        return ZStack {
            MetalAuraView()
                .frame(width: 240, height: 240)
                .opacity(0.85)
                .blur(radius: 28)
                .blendMode(.screen)
                .scaleEffect(controller.showHitEffect ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.25), value: controller.showHitEffect)

            Image(char.image)
                .resizable()
                .scaledToFit()
                .frame(width: 160)
                .shadow(color: .cyan.opacity(0.7), radius: 12)

            Ellipse()
                .fill(Color.black.opacity(0.45))
                .frame(width: 90, height: 25)
                .blur(radius: 15)
                .offset(y: 70)
        }
    }

    private var bossSection: some View {
        ZStack {
            MetalAuraView()
                .frame(width: 260, height: 260)
                .opacity(0.9)
                .blur(radius: 35)
                .blendMode(.screen)
                .colorMultiply(.red)
                .scaleEffect(controller.showHitEffect ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.25), value: controller.showHitEffect)

            Image(controller.boss.image)
                .resizable()
                .scaledToFit()
                .frame(width: 180)
                .shadow(color: .red.opacity(0.8), radius: 20)
                .opacity(controller.showHitEffect ? 0.6 : 1)
                .scaleEffect(controller.showHitEffect ? 1.05 : 1)

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

    // MARK: - EXP-Bar
    private func expBar(for characterId: String) -> some View {
        let progress = progressFor(characterId: characterId)
        return ZStack(alignment: .leading) {
            Capsule().fill(Color.white.opacity(0.15))
            Capsule()
                .fill(LinearGradient(colors: [.blue, .cyan],
                                     startPoint: .leading, endPoint: .trailing))
                .frame(width: 180 * progress)
                .shadow(color: .cyan.opacity(0.4), radius: 4)
        }
        .frame(width: 180, height: 8)
    }

    private func progressFor(characterId: String) -> Double {
        guard let char = characterManager.characters.first(where: { $0.id == characterId }) else { return 0 }
        let expToNext = Double(char.level * 100)
        return min(Double(char.exp) / expToNext, 1.0)
    }

    // MARK: - Team Footer
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
                                                     startPoint: .top,
                                                     endPoint: .bottom)
                                    : LinearGradient(colors: [.white.opacity(0.25)],
                                                     startPoint: .top,
                                                     endPoint: .bottom),
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
