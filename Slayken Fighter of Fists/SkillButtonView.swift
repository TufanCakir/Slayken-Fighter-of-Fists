import SwiftUI

struct SkillButtonView: View {
    let skill: Skill
    @ObservedObject var controller: BattleSceneController

    var body: some View {
        ZStack {
            baseTile
            elementGlow
            if controller.isSkillOnCooldown(skill.name) {
                cooldownOverlay
            }
            content
        }
        .frame(width: 72, height: 72)
        .onTapGesture {
            guard !controller.isSkillOnCooldown(skill.name) else { return }
            controller.useSkill(skill.name)
        }
        .contentShape(Rectangle())
    }

    // MARK: - Base
    private var baseTile: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(
                LinearGradient(
                    colors: [.black.opacity(0.95), .gray.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        LinearGradient(
                            colors: [.yellow.opacity(0.85), .orange.opacity(0.65)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            )
            .shadow(color: .black.opacity(0.9), radius: 6, y: 3)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        LinearGradient(
                            colors: controller.isSkillOnCooldown(skill.name)
                            ? [.clear, .clear]
                            : [.yellow.opacity(0.8), .white.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: controller.isSkillOnCooldown(skill.name) ? 0 : 3
                    )
                    .blur(radius: 3)
                    .opacity(controller.isSkillOnCooldown(skill.name) ? 0 : 0.8)
                    .animation(.easeInOut(duration: 0.6), value: controller.isSkillOnCooldown(skill.name))
            )
    }

    // MARK: - Element Glow
    private var elementGlow: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: gradientFor(element: skill.element),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 58, height: 58)
            .shadow(color: .white.opacity(0.3), radius: 6)
            .overlay(Circle().strokeBorder(Color.white.opacity(0.25), lineWidth: 1))
    }

    // MARK: - Cooldown
    private var cooldownOverlay: some View {
        ZStack {
            Circle()
                .fill(Color.black.opacity(0.65))
                .frame(width: 58, height: 58)
            
            if let remaining = controller.cooldownRemaining[skill.name.lowercased()],
               remaining > 0 {
                Text(String(format: "%.1f", remaining))
                    .font(.system(size: 17, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.9), radius: 3)
                    .animation(nil, value: remaining)
            }

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
                        colors: [.white.opacity(0.7), .gray.opacity(0.3)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: 58, height: 58)
                .animation(.linear(duration: 0.2), value: controller.cooldownRemaining[skill.name.lowercased()])
        }
        .transition(.opacity)
    }

    // MARK: - Text & Icon
    private var content: some View {
        VStack(spacing: 3) {
            Image(systemName: iconFor(element: skill.element))
                .font(.system(size: 26, weight: .medium))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.9), radius: 3, y: 1)
            Text(skill.name)
                .font(.caption2.bold())
                .foregroundColor(.white.opacity(0.9))
                .lineLimit(1)
                .shadow(color: .black.opacity(0.8), radius: 2)
        }
    }

    // MARK: - Helpers
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
