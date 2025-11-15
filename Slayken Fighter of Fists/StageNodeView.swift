import SwiftUI

struct StageNodeView: View {
    let stage: Stage
    let progress: StageProgress
    let boss: Boss?
    let onSelect: () -> Void

    @State private var isGlowing = false
    @State private var isPressed = false
    @State private var justUnlocked = false

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // MARK: - Basis-Kreis mit dynamischem Glow
                Circle()
                    .fill(Color.black.opacity(0.65))
                    .frame(width: 86, height: 86)
                    .overlay(
                        Circle()
                            .stroke(glowColor.opacity(0.25), lineWidth: 1.2)
                    )
                    .shadow(color: glowColor.opacity(isGlowing ? 0.8 : 0.0),
                            radius: isGlowing ? 10 : 0)
                    .scaleEffect(isGlowing ? 1.03 : 1.0)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                               value: isGlowing)

                // MARK: - Bossbild
                bossImage(for: boss?.image ?? "")
                    .frame(width: 74, height: 74)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(.white.opacity(0.25), lineWidth: 1))
                    .shadow(color: glowColor.opacity(progress.unlocked ? 0.4 : 0.05), radius: 6)
                    .opacity(progress.unlocked ? 1 : 0.4)
                    .saturation(progress.unlocked ? 1 : 0)
                    .scaleEffect(isPressed ? 0.92 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)

                // MARK: - Lock Overlay
                if !progress.unlocked {
                    Circle()
                        .fill(Color.black.opacity(0.55))
                        .overlay(
                            Image(systemName: "lock.fill")
                                .font(.title3.bold())
                                .foregroundColor(.white.opacity(0.9))
                        )
                        .transition(.opacity.combined(with: .scale))
                }

                // MARK: - Stage-ID Badge
                Text(String(format: "%02d", stage.id))
                    .font(.caption.bold())
                    .foregroundColor(.cyan)
                    .padding(5)
                    .background(.ultraThinMaterial)
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(.white.opacity(0.8), lineWidth: 0.8)
                    )
                    .offset(x: 30, y: -30)
                    .shadow(color: .cyan.opacity(0.6), radius: 4, y: 1)
            }
            .onTapGesture {
                guard progress.unlocked else { return }
                withAnimation(.easeInOut(duration: 0.12)) { isPressed = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        isPressed = false
                    }
                    onSelect()
                }
            }

            // MARK: - Stage-Name
            Text(stage.name)
                .font(.footnote.bold())
                .foregroundColor(.white)
                .frame(width: 90)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .opacity(progress.unlocked ? 1 : 0.5)
                .shadow(color: glowColor.opacity(0.4), radius: 4)

            // MARK: - Sterne oder Schloss
            stageStars
        }
        .frame(width: 92, height: 150)
        .padding(6)
        .background(
            LinearGradient(
                colors: backgroundColors,
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(progress.unlocked ? .white.opacity(0.35) : .gray.opacity(0.25),
                        lineWidth: 1)
        )
        .shadow(color: glowColor.opacity(progress.unlocked ? 0.6 : 0.15),
                radius: 8, y: 3)
        .overlay(unlockPulse)
        .onAppear {
            if progress.unlocked { isGlowing = true }
            if progress.unlocked && !progress.completed {
                triggerUnlockPulse()
            }
        }
        .animation(.easeInOut(duration: 0.4), value: progress.unlocked)
    }

    // MARK: - Elemente & Farblogik
    private var glowColor: Color {
        switch boss?.element.lowercased() {
        case "fire": return .orange
        case "ice": return .cyan
        case "void": return .purple
        case "nature": return .green
        default: return .blue
        }
    }

    private var backgroundColors: [Color] {
        progress.unlocked
        ? [.black, glowColor.opacity(0.6), .black]
        : [.gray.opacity(0.25), .black]
    }

    // MARK: - Unlock-Pulse Effekt
    private var unlockPulse: some View {
        Group {
            if justUnlocked {
                Circle()
                    .stroke(glowColor.gradient, lineWidth: 3)
                    .frame(width: 90, height: 90)
                    .shadow(color: glowColor.opacity(0.8), radius: 12)
                    .scaleEffect(justUnlocked ? 1.4 : 0.6)
                    .opacity(justUnlocked ? 0 : 1)
                    .animation(.easeOut(duration: 1.0), value: justUnlocked)
            }
        }
    }

    private func triggerUnlockPulse() {
        withAnimation(.easeInOut(duration: 0.8)) {
            justUnlocked = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            withAnimation { justUnlocked = false }
        }
    }

    // MARK: - Sterne
    private var stageStars: some View {
        HStack(spacing: 3) {
            if progress.unlocked {
                ForEach(0..<5, id: \.self) { i in
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundColor(i < progress.stars ? glowColor : .gray.opacity(0.4))
                        .scaleEffect(i < progress.stars ? 1.1 : 1.0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8),
                                   value: progress.stars)
                }
            } else {
                Image(systemName: "lock.fill")
                    .foregroundColor(.gray.opacity(0.6))
                    .font(.system(size: 12))
            }
        }
    }

    // MARK: - Bild-Loader
    @ViewBuilder
    private func bossImage(for name: String) -> some View {
        if name.lowercased().hasPrefix("http") {
            AsyncImage(url: URL(string: name)) { phase in
                switch phase {
                case .empty:
                    ProgressView().tint(glowColor)
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    Image(systemName: "questionmark.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.gray)
                }
            }
        } else {
            Image(name)
                .resizable()
                .scaledToFit()
        }
    }
}

