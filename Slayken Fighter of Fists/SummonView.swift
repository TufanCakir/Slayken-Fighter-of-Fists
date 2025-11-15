//
//  SummonView.swift
//  Slayken Fighter of Fists
//
//  Created by Tufan Cakir on 2025-11-15.
//

import SwiftUI

@MainActor
struct SummonView: View {

    @EnvironmentObject private var skillManager: SkillManager

    // Summon actions from JSON
    @State private var summonOptions: [SummonOption] = Bundle.main.decode("summonData.json")

    // Navigation
    @State private var navigateToResult = false

    // Results
    @State private var summonResult: [Skill] = []

    // Portal Animation
    @State private var showPortal = false

    // Which summon mode
    enum SummonMode { case single, multi }
    @State private var summonMode: SummonMode = .single

    // Orb animation
    @State private var orbGlow = false
    @State private var orbRotation = 0.0

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundLayer

                VStack(spacing: 32) {

                    Text("Skill Summon")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.cyan)
                        .shadow(color: .cyan.opacity(0.4), radius: 12)

                    summonOrb

                    summonButtonsDynamic

                    Spacer()
                }
                .padding(.top, 40)

                // PORTAL OVERLAY
                if showPortal {
                    SummonPortalView {
                        completeSummon()
                    }
                    .transition(.opacity)
                    .zIndex(20)
                }
            }
            .animation(.easeInOut, value: showPortal)
            .navigationDestination(isPresented: $navigateToResult) {
                SummonResultView(skills: summonResult) {
                    navigateToResult = false
                }
            }
        }
    }
}

//
// MARK: - UI
//
private extension SummonView {

    // Background
    var backgroundLayer: some View {
        LinearGradient(
            colors: [.black, .blue.opacity(0.35), .black],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(
            Image(systemName: "sparkles")
                .font(.system(size: 260))
                .foregroundStyle(.blue)
                .blur(radius: 50)
                .offset(y: -160)
        )
        .ignoresSafeArea()
    }

    // Orb
    var summonOrb: some View {
        ZStack {

            // Glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.black, .blue, .black],
                        center: .center,
                        startRadius: 15,
                        endRadius: 140
                    )
                )
                .scaleEffect(orbGlow ? 1.1 : 0.9)
                .blur(radius: 40)
                .animation(.easeInOut(duration: 1.3).repeatForever(), value: orbGlow)

            // Main Orb
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 180, height: 180)
                .shadow(color: .blue, radius: 20)

            // Rotating Energy Ring (FIXED)
            Circle()
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [.black, .blue, .black]),
                        center: .center
                    ),
                    lineWidth: 10
                )
                .frame(width: 230, height: 230)
                .blur(radius: 2)
                .rotationEffect(.degrees(orbRotation))
                .animation(.linear(duration: 6).repeatForever(autoreverses: false), value: orbRotation)

            Image(systemName: "sparkles")
                .font(.system(size: 55))
                .foregroundStyle(.cyan)
        }
        .onAppear {
            orbGlow = true
            orbRotation = 360
        }
    }

    // MARK: - Dynamic Summon Buttons (from JSON)
    var summonButtonsDynamic: some View {
        VStack(spacing: 20) {
            ForEach(summonOptions) { option in
                summonButton(option) {
                    // Set summon mode from JSON
                    if option.type.lowercased() == "single" {
                        summonMode = .single
                    } else {
                        summonMode = .multi
                    }
                    showPortal = true
                }
            }
        }
        .padding(.horizontal, 36)
    }

    func summonButton(_ data: SummonOption, action: @escaping () -> Void) -> some View {

        let c1 = Color(hex: data.colorStart)
        let c2 = Color(hex: data.colorMiddle)
        let c3 = Color(hex: data.colorEnd)

        return Button(action: action) {
            HStack {
                Image(systemName: data.icon)
                    .foregroundColor(Color(hex: data.iconColor))
                    .font(.title2)

                VStack(alignment: .leading, spacing: 4) {
                    Text(data.title)
                        .font(.headline.bold())
                        .foregroundColor(.white)

                    Text("Cost: \(data.crystal) Crystals")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }

                Spacer()
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .background(
                LinearGradient(colors: [c1, c2, c3], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .cornerRadius(18)
            .shadow(color: c2.opacity(0.6), radius: 12)
        }
    }
}

//
// MARK: - Summon Logic
//
private extension SummonView {

    func completeSummon() {
        showPortal = false

        switch summonMode {
        case .single:
            if let skill = skillManager.summonRandomSkill() {
                summonResult = [skill]
            }
        case .multi:
            summonResult = skillManager.summonTenSkills()
        }

        navigateToResult = true
    }
}

//
// MARK: - Color HEX
//


extension UIColor {
    convenience init(hex: String) {
        let clean = hex.replacingOccurrences(of: "#", with: "")
        let scanner = Scanner(string: clean)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = CGFloat((rgb >> 16) & 0xFF) / 255
        let g = CGFloat((rgb >> 8) & 0xFF) / 255
        let b = CGFloat(rgb & 0xFF) / 255
        self.init(red: r, green: g, blue: b, alpha: 1)
    }
}

//
// MARK: - Preview
//
#Preview {
    SummonView()
        .environmentObject(SkillManager.shared)
        .preferredColorScheme(.dark)
}
