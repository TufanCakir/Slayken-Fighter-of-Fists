import SwiftUI

struct StageNodeView: View {
    let stage: Stage
    let progress: StageProgress
    let boss: Boss?
    let onSelect: () -> Void

    @State private var glow = false
    @State private var scale: CGFloat = 1.0
    @State private var justUnlocked = false

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // MARK: - Hintergrundkreis (mit Glow)
                Circle()
                    .fill(.black.opacity(0.6))
                    .frame(width: 86, height: 86)
                    .shadow(color: glowColor.opacity(glow ? 0.8 : 0), radius: 10)
                    .scaleEffect(glow ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 1.3).repeatForever(autoreverses: true), value: glow)

                // MARK: - Bossbild
                bossImage(for: boss?.image ?? "")
                    .frame(width: 74, height: 74)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(.white.opacity(0.3), lineWidth: 1))
                    .shadow(color: glowColor.opacity(progress.unlocked ? 0.4 : 0.05), radius: 6)
                    .opacity(progress.unlocked ? 1 : 0.35)
                    .saturation(progress.unlocked ? 1 : 0)

                // MARK: - Lock Overlay
                if !progress.unlocked {
                    Circle()
                        .fill(Color.black.opacity(0.55))
                        .overlay(
                            Image(systemName: "lock.fill")
                                .font(.title2.bold())
                                .foregroundColor(.white.opacity(0.9))
                        )
                        .transition(.opacity.combined(with: .scale))
                }

                // MARK: - Badge
                Text(String(format: "%02d", stage.id))
                    .font(.caption.bold())
                    .foregroundColor(.cyan)
                    .padding(5)
                    .background(.ultraThinMaterial)
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(.white.opacity(0.8), lineWidth: 1)
                    )
                    .offset(x: 30, y: -30)
                    .shadow(radius: 2)
            }
            .scaleEffect(scale)
            .onTapGesture {
                guard progress.unlocked else { return }
                withAnimation(.easeInOut(duration: 0.15)) {
                    scale = 0.92
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                        scale = 1.0
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
            HStack(spacing: 2) {
                if progress.unlocked {
                    ForEach(0..<3, id: \.self) { i in
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                            .foregroundColor(i < progress.stars ? .yellow : .gray.opacity(0.4))
                            .scaleEffect(i < progress.stars ? 1.05 : 1.0)
                            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: progress.stars)
                    }
                } else {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.gray.opacity(0.6))
                        .font(.system(size: 12))
                }
            }
        }
        .frame(width: 92, height: 150)
        .padding(6)
        .background(
            LinearGradient(
                colors: progress.unlocked
                    ? [Color.black, glowColor.opacity(0.8), .black]
                    : [.gray.opacity(0.25), .black],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(progress.unlocked ? .white.opacity(0.35) : .gray.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: glowColor.opacity(progress.unlocked ? 0.6 : 0.2), radius: 8, y: 3)
        .onAppear {
            if progress.unlocked { glow = true }
            if progress.unlocked && !progress.completed {
                // 🎇 Effekt bei neu freigeschalteter Stage
                withAnimation(.easeInOut(duration: 0.8)) {
                    justUnlocked = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    justUnlocked = false
                }
            }
        }
        .overlay(
            // Glänzender Unlock-Effekt
            Group {
                if justUnlocked {
                    Circle()
                        .stroke(glowColor.gradient, lineWidth: 3)
                        .frame(width: 90, height: 90)
                        .shadow(color: glowColor.opacity(0.7), radius: 12)
                        .scaleEffect(justUnlocked ? 1.2 : 0.6)
                        .opacity(justUnlocked ? 0 : 1)
                        .animation(.easeOut(duration: 1.0), value: justUnlocked)
                }
            }
        )
        .animation(.easeInOut(duration: 0.4), value: progress.unlocked)
    }

    // MARK: - Glow Farbe
    private var glowColor: Color {
        switch boss?.element?.lowercased() {
        case "fire": return .red
        case "ice": return .cyan
        case "void": return .purple
        case "nature": return .green
        default: return .blue
        }
    }

    // MARK: - Lokale oder Online-Bilder automatisch erkennen
    @ViewBuilder
    private func bossImage(for name: String) -> some View {
        if name.lowercased().hasPrefix("http") {
            AsyncImage(url: URL(string: name)) { phase in
                switch phase {
                case .empty:
                    ProgressView().tint(.cyan)
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    Image(systemName: "xmark.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.gray)
                }
            }
        } else {
            Image(name)
                .resizable()
                .scaledToFit()
                .frame(width: 74, height: 74)
                .clipShape(Circle())
        }
    }
}

#Preview {
    ZStack {
        LinearGradient(colors: [.black, .blue, .black],
                       startPoint: .topLeading,
                       endPoint: .bottomTrailing)
            .ignoresSafeArea()

        StageNodeView(
            stage: Stage(id: 1, name: "Sly", bossId: "boss_1", type: "boss"),
            progress: StageProgress(id: 1, unlocked: true, completed: true, stars: 3),
            boss: Boss(
                id: "boss_1",
                name: "Sly",
                image: "character1",
                background: "",
                element: "fire",
                hp: 100
            ),
            onSelect: { print("Stage tapped!") }
        )
        .padding()
    }
}
