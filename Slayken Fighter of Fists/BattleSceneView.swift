import SwiftUI

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
                // MARK: - Hintergrund mit Parallax
                backgroundLayer(size: geo.size)

                VStack(spacing: 0) {
                    // MARK: - HUD oben
                    topBars
                        .padding(.top, safeTopInset() + 8)

                    Spacer()

                    // MARK: - Kampfbereich
                    ZStack {
                        // 🔹 Charakter links (weiter vorne)
                        characterSection
                            .offset(x: -geo.size.width * 0.22, y: 40)

                        // 🔸 Boss rechts (weiter hinten)
                        bossSection
                            .offset(x: geo.size.width * 0.22, y: -10)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .zIndex(1)

                    // MARK: - Team-Footer
                    teamFooter
                        .padding(.bottom, 20)
                }

                // MARK: - Tap-to-Attack Overlay
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

    // MARK: - Hintergrund mit Parallax-Overlay
    private func backgroundLayer(size: CGSize) -> some View {
        GeometryReader { geo in
            AsyncImage(url: URL(string: controller.boss.background)) { phase in
                switch phase {
                case .success(let image):
                    image.resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: size.width * 1.1, height: size.height * 1.1)
                        .clipped()
                        .offset(x: (geo.frame(in: .global).minX / 30)) // Parallax
                        .overlay(
                            LinearGradient(
                                colors: [.black.opacity(0.15), .black.opacity(0.6)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                default:
                    LinearGradient(colors: [.black, .red.opacity(0.4)],
                                   startPoint: .top, endPoint: .bottom)
                }
            }
        }
        .ignoresSafeArea()
    }

    
    // MARK: - Kampfbereich
    private func battleArea(in size: CGSize) -> some View {
        ZStack {
            characterSection
                .offset(x: -size.width * 0.25, y: 40)
            
            bossSection
                .offset(x: size.width * 0.25, y: -10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .zIndex(1)
    }
    
    // MARK: - HUD (EXP & HP)
    private var topBars: some View {
        HStack {
            // Charakterseite
            VStack(alignment: .leading, spacing: 4) {
                Text("Lv. \(characterManager.getLevel(for: controller.activeCharacter.id))")
                    .font(.caption.bold())
                    .foregroundColor(.white)
                expBar(for: controller.activeCharacter.id)
            }

            Spacer()

            // Bossseite
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
    
    // MARK: - Charakter (links)
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
            
            loadImage(char.image, width: 160)
                .scaledToFit()
                .frame(width: 160)
                .shadow(color: .cyan.opacity(0.7), radius: 12)
                .transition(.opacity)
            
            Ellipse()
                .fill(Color.black.opacity(0.45))
                .frame(width: 90, height: 25)
                .blur(radius: 15)
                .offset(y: 70)
        }
    }
    
    // MARK: - Boss (rechts)
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
            
            loadImage(controller.boss.image)
                .scaledToFit()
                .frame(width: 180)
                .shadow(color: .red.opacity(0.8), radius: 20)
                .opacity(controller.showHitEffect ? 0.6 : 1)
                .scaleEffect(controller.showHitEffect ? 1.05 : 1)
                .animation(.easeOut(duration: 0.25), value: controller.showHitEffect)
            
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
                    .animation(.easeInOut(duration: 0.6), value: controller.rewardOpacity)
            }
        }
    }
    
    // MARK: - Team Footer
    private var teamFooter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(Array(controller.team.enumerated()), id: \.offset) { index, member in
                    VStack(spacing: 4) {
                        loadImage(member.image)
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
        .animation(.easeInOut(duration: 0.3), value: progress)
    }
    
    private func progressFor(characterId: String) -> Double {
        guard let char = characterManager.characters.first(where: { $0.id == characterId }) else { return 0 }
        let expToNext = Double(char.level * 100)
        return min(Double(char.exp) / expToNext, 1.0)
    }
    
    // MARK: - Bildlader
    @ViewBuilder
    private func loadImage(_ name: String, width: CGFloat? = nil) -> some View {
        if name.lowercased().hasPrefix("http"),
           let url = URL(string: name) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .tint(.white)
                        .frame(width: width ?? 60, height: width ?? 60)
                    
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(width: width)
                        .transition(.opacity)
                    
                case .failure:
                    Color.gray.opacity(0.3)
                        .overlay(
                            Image(systemName: "photo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: width ?? 30, height: width ?? 30)
                                .foregroundColor(.white.opacity(0.7))
                        )
                    
                @unknown default:
                    EmptyView()
                }
            }
            
        } else {
            Image(name)
                .resizable()
                .scaledToFit()
                .frame(width: width)
        }
    }
}
