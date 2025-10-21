import SwiftUI

struct SkillButtonView: View {
    let skill: Skill
    @ObservedObject var controller: BattleSceneController

    // 🔧 Dynamische Button-Größe (Skaliert automatisch bei wenig Platz)
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var buttonSize: CGFloat { sizeClass == .compact ? 60 : 72 }

    var body: some View {
        ZStack {
            baseTile
            elementGlow
            if controller.isSkillOnCooldown(skill.name) {
                cooldownOverlay
            }
            content
        }
        .frame(width: buttonSize, height: buttonSize)
        .contentShape(Rectangle())
        .onTapGesture {
            guard !controller.isSkillOnCooldown(skill.name) else { return }
            controller.useSkill(skill.name)
        }
        .animation(.easeInOut(duration: 0.25), value: controller.cooldownRemaining[skill.name.lowercased()])
        .accessibilityLabel(Text(skill.name))
        .accessibilityHint(Text("Aktiviere Fähigkeit"))
    }
}

//
// MARK: - Tile & Hintergrund
//
private extension SkillButtonView {
    var baseTile: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(
                LinearGradient(
                    colors: [.black.opacity(0.9), .gray.opacity(0.35)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(
                        LinearGradient(
                            colors: controller.isSkillOnCooldown(skill.name)
                            ? [.gray.opacity(0.2), .gray.opacity(0.1)]
                            : [.yellow.opacity(0.9), .orange.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: controller.isSkillOnCooldown(skill.name) ? 1 : 2
                    )
                    .shadow(color: .black.opacity(0.8), radius: 3)
            )
            .shadow(color: .black.opacity(0.6), radius: 6, y: 3)
            .overlay(
                // Glüheffekt bei aktivem Skill
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        LinearGradient(colors: [.white.opacity(0.8), .yellow.opacity(0.8)],
                                       startPoint: .topLeading,
                                       endPoint: .bottomTrailing),
                        lineWidth: 3
                    )
                    .blur(radius: 4)
                    .opacity(controller.showSkillParticles ? 0.9 : 0)
                    .animation(.easeInOut(duration: 0.4), value: controller.showSkillParticles)
            )
    }
}

//
// MARK: - Element Glow
//
private extension SkillButtonView {
    var elementGlow: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: gradientFor(element: skill.element),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: buttonSize * 0.8, height: buttonSize * 0.8)
            .shadow(color: gradientFor(element: skill.element).first!.opacity(0.5), radius: 10)
            .overlay(Circle().strokeBorder(Color.white.opacity(0.25), lineWidth: 1))
            .opacity(controller.isSkillOnCooldown(skill.name) ? 0.3 : 1)
    }
}

//
// MARK: - Cooldown Overlay
//
private extension SkillButtonView {
    var cooldownOverlay: some View {
        ZStack {
            Circle()
                .fill(Color.black.opacity(0.65))
                .frame(width: buttonSize * 0.8, height: buttonSize * 0.8)
            
            if let remaining = controller.cooldownRemaining[skill.name.lowercased()],
               remaining > 0 {
                Text(String(format: "%.1f", remaining))
                    .font(.system(size: buttonSize * 0.25, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.9), radius: 3)
                    .transition(.opacity)
            }

            // Fortschrittsring
            Circle()
                .trim(
                    from: 0,
                    to: CGFloat(
                        1 - ((controller.cooldownRemaining[skill.name.lowercased()] ?? 0)
                             / (controller.cooldownDuration[skill.name.lowercased()] ?? 1))
                    )
                )
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.8), .gray.opacity(0.3)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: buttonSize * 0.8, height: buttonSize * 0.8)
                .animation(.linear(duration: 0.2), value: controller.cooldownRemaining[skill.name.lowercased()])
        }
    }
}

//
// MARK: - Text & Icon
//
private extension SkillButtonView {
    var content: some View {
        VStack(spacing: 3) {
            Image(systemName: iconFor(element: skill.element))
                .font(.system(size: buttonSize * 0.36, weight: .medium))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.9), radius: 3, y: 1)
                .opacity(controller.isSkillOnCooldown(skill.name) ? 0.6 : 1)
            
            Text(skill.name)
                .font(.caption2.bold())
                .foregroundColor(.white.opacity(0.9))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .shadow(color: .black.opacity(0.8), radius: 2)
        }
        .padding(.top, 2)
    }
}

//
// MARK: - Helper Functions
//
private extension SkillButtonView {
    func gradientFor(element: String) -> [Color] {
        switch element.lowercased() {
        case "fire": return [.red, .orange]
        case "ice": return [.cyan, .blue]
        case "void": return [.purple, .black]
        case "thunder": return [.yellow, .orange]
        case "nature": return [.green, .mint]
        case "shadow": return [.purple, .black]
        case "shadowclone": return [.indigo, .indigo]
        case "wind": return [.mint, .mint]
        case "beamstrike": return [.green, .green]
        case "water": return [.blue, .blue]
        case "tornado": return [.brown, .brown]
        default: return [.gray, .white.opacity(0.5)]
        }
    }

    func iconFor(element: String) -> String {
        switch element.lowercased() {
        case "fire": return "flame.fill"
        case "ice": return "snowflake"
        case "void": return "circle.dashed"
        case "thunder": return "bolt.fill"
        case "nature": return "leaf.fill"
        case "shadow": return "moon.fill"
        case "shadowclone": return "person.2.fill"
        case "wind": return "wind.circle"
        case "water": return "drop.fill"
        case "tornado": return "tornado.circle"
        case "beamstrike": return "headlight.high.beam.fill"
        default: return "sparkles"
        }
    }
}

