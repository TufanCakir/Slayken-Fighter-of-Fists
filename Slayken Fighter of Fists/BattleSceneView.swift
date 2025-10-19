//
//  BattleSceneView.swift
//  Slayken Fighter of Fists
//
//  Created by Tufan Cakir on 2025-10-19.
//

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
                
                // 1️⃣ Hintergrund (Metal + Farbverlauf)
                backgroundLayer(size: geo.size)
                    .overlay(
                        controller.backgroundTint
                            .ignoresSafeArea()
                            .transition(.opacity)
                            .animation(.easeInOut(duration: 0.3), value: controller.backgroundTint)
                            .zIndex(0.1)                    )

                
                // 2️⃣ Flash bei Skillstart
                if controller.showSkillParticles {
                    Color.white
                        .opacity(0.12)
                        .blendMode(.screen)
                        .ignoresSafeArea()
                        .animation(.easeOut(duration: 0.25), value: controller.showSkillParticles)
                        .zIndex(0.5)
                }
                
                // 3️⃣ HUD + Kampfbereich
                VStack(spacing: 0) {
                    topBars
                        .padding(.top, safeTopInset() + 8)
                        .padding(.horizontal, 24)
                    
                    Spacer(minLength: geo.size.height * 0.05)
                    
                    battleArea(size: geo.size)
                        .padding(.bottom, 160)
                    
                    Spacer(minLength: geo.size.height * 0.03)
                }
                .zIndex(1)
                
                // 4️⃣ Footer (Team + Skills)
                footerBar
                    .zIndex(2)
                
                // 5️⃣ Reward Text
                if let reward = controller.rewardText {
                    Text(reward)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.yellow)
                        .shadow(color: .orange.opacity(0.9), radius: 10)
                        .opacity(controller.rewardOpacity)
                        .transition(.opacity)
                        .padding(.top, 120)
                        .zIndex(3)
                }
                
                // 6️⃣ Attack Overlay
                attackOverlayArea
                    .zIndex(9)
            }
            .ignoresSafeArea(edges: .top)
            .animation(.easeInOut(duration: 0.25), value: controller.bossHp)
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
                colors: [.black.opacity(0.05), .black.opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
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
// MARK: - Kampfbereich (Character vs Boss)
//
private extension BattleSceneView {
    func battleArea(size: CGSize) -> some View {
        HStack(spacing: 0) {
            Spacer(minLength: size.width * 0.08)
            
            characterSection
                .frame(width: size.width * 0.36, height: size.height * 0.42)
            
            Spacer()
            
            bossSection
                .frame(width: size.width * 0.36, height: size.height * 0.42)
                .scaleEffect(x: -1, y: 1)
            
            Spacer(minLength: size.width * 0.08)
        }
        .frame(maxWidth: .infinity, maxHeight: size.height * 0.6)
        .offset(y: -60) // 👈 verschiebt den ganzen Kampfbereich etwas nach oben
        .animation(.easeInOut(duration: 0.25), value: controller.showHitEffect)
        .allowsHitTesting(false)
    }


    
    // Spieler-Seite
    var characterSection: some View {
        let char = controller.activeCharacter
        return ZStack {
            // 🌀 Shadow Clone Layer
            if controller.showShadowClone {
                Image(char.image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 180)
                    .opacity(controller.shadowCloneOpacity)
                    .offset(x: controller.shadowCloneOffset)
                    .blur(radius: 3)
                    .colorMultiply(.gray)
                    .blendMode(.plusLighter)
                    .scaleEffect(1.02)
            }

            // 🧍 Original Character
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

    
    // Boss-Seite
    var bossSection: some View {
        ZStack {
            // Skill Flash pro Element
            if controller.showSkillParticles, let fx = controller.activeSkillEffect {
                Color(flashColor(for: fx.element))
                    .opacity(0.22)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .animation(.easeOut(duration: 0.25), value: controller.showSkillParticles)
            }
            
            // Metal-Particles
            if let fx = controller.activeSkillEffect {
                ZStack {
                    Color.black.opacity(0.001)
                        .blendMode(.plusLighter)
                        .allowsHitTesting(false)
                    
                    MetalSkillEffectView(
                        element: fx.element,
                        trigger: controller.showSkillParticles,
                        style: fx.style.rawValue,
                        scale: 2.5
                    )
                    .allowsHitTesting(false)
                }
                .compositingGroup()
                .blendMode(.plusLighter)
            }
            
            // Aura + Boss
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
    
    func flashColor(for element: String) -> Color {
        switch element.lowercased() {
        case "fire": return .red
        case "ice": return .cyan
        case "void": return .purple
        case "shadow": return .purple
        case "shadowclone": return .indigo
        case "thunder": return .yellow
        case "nature": return .green
        case "wind": return .mint
        case "water": return .blue
        case "tornado": return .brown
        default: return .white
        }
    }
}

//
// MARK: - Footer (Team + Skills)
//
private extension BattleSceneView {
    var footerBar: some View {
        VStack(spacing: 16) {
            Spacer()
            VStack(spacing: 14) {
                actionBar
                teamScroll
            }
            .padding(.bottom, safeBottomInset() + 10)
            .padding(.horizontal, 12)
            .background(
                LinearGradient(
                    colors: [.black.opacity(0.85), .black.opacity(0.5)],
                    startPoint: .top, endPoint: .bottom
                )
                .blur(radius: 10)
            )
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: .black.opacity(0.5), radius: 12, y: -3)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .strokeBorder(Color.white.opacity(0.05))
            )
            .frame(maxWidth: .infinity)
        }
        .ignoresSafeArea(edges: .bottom)
    }

    
    // In deiner BattleSceneView:
    var actionBar: some View {
        let skills = skillManager.getSkills(for: controller.activeCharacter.skillIDs)
        let columns = [GridItem(.adaptive(minimum: 64, maximum: 80), spacing: 12)]

        return LazyVGrid(columns: columns, spacing: 12) {
            ForEach(skills, id: \.id) { skill in
                SkillButtonView(skill: skill, controller: controller)
                    .frame(minWidth: 64, maxWidth: 80)
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
        .offset(y: 10) // 👈 ganze ActionBar leicht nach unten verschoben
    }


    
    var teamScroll: some View {
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
// MARK: - Attack Gesture Area
//
private extension BattleSceneView {
    var attackOverlayArea: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                // Oberer Kampfbereich — reagiert auf Tap
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .frame(height: proxy.size.height * 0.65) // nur obere 65% des Bildschirms
                    .onTapGesture {
                        controller.performAttack()
                    }

                // Unterer Bereich (Footer) bleibt frei
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: proxy.size.height * 0.35)
                    .allowsHitTesting(false)
            }
            .ignoresSafeArea(edges: .top)
        }
        .zIndex(1) // 👈 unterhalb des Footers
    }
}
