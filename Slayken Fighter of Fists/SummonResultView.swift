//
//  SummonResultView.swift
//  Slayken Fighter of Fists
//
//  Created by Tufan Cakir on 2025-11-15.
//

import SwiftUI

@MainActor
struct SummonResultView: View {

    let skills: [Skill]
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 20) {

            Text("Summon Results")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(.cyan)
                .shadow(color: .cyan.opacity(0.6), radius: 10)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(skills, id: \.id) { skill in
                        resultCard(for: skill)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
                .padding(.horizontal)
            }

            Button(action: onClose) {
                Text("OK")
                    .font(.title3.bold())
                    .padding(.horizontal, 40)
                    .padding(.vertical, 14)
                    .background(.cyan)
                    .foregroundColor(.black)
                    .cornerRadius(16)
                    .shadow(color: .cyan.opacity(0.6), radius: 10)
            }
            .padding(.top, 10)

            Spacer(minLength: 10)
        }
        .padding(.top, 30)
        .padding(.bottom, 40)
        .background(
            LinearGradient(
                colors: [.black.opacity(0.95), .blue.opacity(0.4), .black.opacity(0.95)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }
}

private extension SummonResultView {

    func resultCard(for skill: Skill) -> some View {
        HStack(spacing: 12) {

            Circle()
                .fill(color(for: skill.element))
                .frame(width: 22, height: 22)

            VStack(alignment: .leading, spacing: 4) {
                Text(skill.name)
                    .font(.headline)
                    .foregroundColor(.white)

                Text(skill.element.capitalized)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer()

            Text("CD: \(Int(skill.cooldown))s")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding()
        .background(Color.white.opacity(0.06))
        .cornerRadius(14)
        .shadow(color: color(for: skill.element).opacity(0.5), radius: 7)
    }

    func color(for element: String) -> Color {
        switch element.lowercased() {
        case "fire": return .orange
        case "ice": return .cyan
        case "void": return .purple
        case "thunder": return .yellow
        case "nature": return .green
        case "wind": return .mint
        case "water": return .blue
        case "shadow": return .black
        case "shadowclone": return .black.opacity(0.8)
        case "tornado": return .gray
        case "beamstrike": return .white
        default: return .gray
        }
    }
}
