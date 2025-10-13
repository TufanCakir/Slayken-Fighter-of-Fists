import SwiftUI

struct StageNodeView: View {
    let stage: Stage
    let progress: StageProgress
    let boss: Boss?
    let onSelect: () -> Void

    @State private var glow = false

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                // MARK: - Hintergrundkreis (Glow-Effekt bei Unlock)
                Circle()
                    .fill(Color.black.opacity(0.6))
                    .frame(width: 82, height: 82)
                    .shadow(color: glow ? .blue.opacity(0.8) : .clear, radius: 10)
                    .scaleEffect(glow ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: glow)

                // MARK: - Bossbild (lokal oder online)
                bossImage(for: boss?.image ?? "")
                    .frame(width: 74, height: 74)
                    .clipShape(Circle())
                    .overlay(
                        Circle().stroke(.white.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: .blue.opacity(progress.unlocked ? 0.5 : 0.1), radius: 5)
                    .opacity(progress.unlocked ? 1 : 0.35)
                    .saturation(progress.unlocked ? 1 : 0)

                // MARK: - Lock Overlay (wenn gesperrt)
                if !progress.unlocked {
                    Circle()
                        .fill(Color.black.opacity(0.55))
                        .overlay(
                            Image(systemName: "lock.fill")
                                .font(.title2.bold())
                                .foregroundColor(.white.opacity(0.9))
                        )
                }

                // MARK: - Stage-Badge
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

            // MARK: - Stage-Name
            Text(stage.name)
                .font(.footnote.bold())
                .foregroundColor(.white)
                .frame(width: 90)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .opacity(progress.unlocked ? 1 : 0.6)

            // MARK: - Sterne oder Schloss
            HStack(spacing: 2) {
                if progress.unlocked {
                    ForEach(0..<3, id: \.self) { i in
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                            .foregroundColor(i < progress.stars ? .yellow : .gray.opacity(0.5))
                    }
                } else {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.gray)
                        .font(.system(size: 12))
                }
            }
        }
        .frame(width: 92, height: 150)
        .padding(6)
        .background(
            LinearGradient(
                colors: progress.unlocked
                    ? [.black, .blue.opacity(0.8), .black]
                    : [.gray.opacity(0.3), .black],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(progress.unlocked ? .white.opacity(0.3) : .gray.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.5), radius: 6, y: 3)
        .onTapGesture {
            if progress.unlocked {
                onSelect()
            }
        }
        .onAppear {
            if progress.unlocked {
                glow = true
            }
        }
        .animation(.easeInOut(duration: 0.4), value: progress.unlocked)
    }

    // MARK: - Lokale oder Online-Bilder automatisch erkennen
    @ViewBuilder
    private func bossImage(for name: String) -> some View {
        if name.lowercased().hasPrefix("http") {
            // Falls du doch mal ein Online-Bild nutzt
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
            // Lokales Bild
            Image(name)
                .resizable()
                .scaledToFit() // <-- skaliert gleichmäßig, sodass alles sichtbar bleibt
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
                image: "character1", // 🔹 Lokaler Asset-Name statt URL
                background: "",
                hp: 100,
                defense: 10
            ),
            onSelect: { print("Stage tapped!") }
        )
        .padding()
    }
}
