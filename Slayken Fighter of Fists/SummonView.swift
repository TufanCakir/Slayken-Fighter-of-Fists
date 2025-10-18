import SwiftUI

struct SummonView: View {
    // MARK: - Environment
    @EnvironmentObject private var crystalManager: CrystalManager
    @EnvironmentObject private var summonManager: SummonManager

    // MARK: - States
    @State private var summonOptions: [SummonOption] = Bundle.main.decode("summonData.json")
    @State private var featuredCharacter: GameCharacter = .example
    @State private var allCharacters: [GameCharacter] = CharacterLoader.loadCharacters()
    @State private var summonedCharacters: [GameCharacter] = []

    @State private var message: String?
    @State private var isAnimating = false
    @State private var showResult = false

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                // 🔹 Hintergrund mit sanftem Farbverlauf
                LinearGradient(colors: [.black, .blue.opacity(0.85), .black],
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing)
                    .ignoresSafeArea()

                VStack(spacing: 26) {
                    // MARK: - Titel
                    Text("Summon Heroes")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(colors: [.white, .cyan],
                                           startPoint: .top,
                                           endPoint: .bottom)
                        )
                        .shadow(color: .cyan.opacity(0.5), radius: 10)
                        .padding(.top, 12)

                    // MARK: - Featured Banner
                    bannerView(for: featuredCharacter)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 4)

                    // MARK: - Crystal-Anzeige
                    crystalDisplay

                    // MARK: - Buttons
                    VStack(spacing: 18) {
                        ForEach(summonOptions) { option in
                            summonButton(for: option)
                        }
                    }

                    // MARK: - Nachricht
                    if let message = message {
                        Text(message)
                            .font(.headline.bold())
                            .foregroundColor(.yellow)
                            .transition(.opacity.combined(with: .scale))
                            .padding(.top, 12)
                    }

                    Spacer()
                }
                .padding(.horizontal, 24)
            }
            .navigationDestination(isPresented: $showResult) {
                SummonResultView(characters: summonedCharacters)
            }
            .onAppear {
                // Zufälligen Featured Character auswählen
                featuredCharacter = allCharacters.randomElement() ?? .example
            }
            .animation(.easeInOut(duration: 0.35), value: message)
        }
    }
}

// MARK: - Banner View
extension SummonView {
    private func bannerView(for char: GameCharacter) -> some View {
        ZStack(alignment: .bottomLeading) {
            Image(char.image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: .cyan.opacity(0.3), radius: 10)
                .overlay(
                    LinearGradient(
                        colors: [.black.opacity(0.6), .clear, .black.opacity(0.7)],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                )

            VStack(alignment: .leading, spacing: 6) {
                Text(char.name)
                    .font(.title.bold())
                    .foregroundColor(.white)

                Text(char.element.capitalized)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.cyan.opacity(0.8))
            }
            .padding(16)
        }
        .frame(height: 220)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.25))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.cyan.opacity(0.4), lineWidth: 1.5)
        )
        .shadow(color: .cyan.opacity(0.3), radius: 8, y: 4)
    }
}

// MARK: - Crystal Display
extension SummonView {
    private var crystalDisplay: some View {
        if let first = summonOptions.first {
            return AnyView(
                HStack(spacing: 6) {
                    Image(systemName: first.icon)
                        .font(.title3)
                        .foregroundColor(first.iconColorValue)
                        .shadow(color: first.iconColorValue.opacity(0.6), radius: 6)
                    Text("\(crystalManager.crystals)")
                        .font(.headline.bold())
                        .foregroundColor(.white)
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 14)
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                .shadow(color: first.iconColorValue.opacity(0.4), radius: 6)
            )
        } else {
            return AnyView(EmptyView())
        }
    }
}

// MARK: - Summon Buttons
extension SummonView {
    private func summonButton(for option: SummonOption) -> some View {
        Button {
            performSummon(option)
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(option.title)
                        .font(.headline.bold())
                        .foregroundColor(.white)
                    HStack(spacing: 10) {
                        Image(systemName: option.icon)
                            .font(.subheadline)
                            .foregroundColor(option.iconColorValue)
                        Text("\(option.crystal)")
                            .font(.subheadline)
                            .foregroundColor(.white)
                    }
                }
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(option.gradient)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(option.iconColorValue.opacity(0.6), lineWidth: 1.5)
            )
            .cornerRadius(14)
            .shadow(color: option.iconColorValue.opacity(0.6), radius: 8)
            .scaleEffect(isAnimating ? 1.03 : 1)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Summon Logic
extension SummonView {
    private func performSummon(_ option: SummonOption) {
        // Kurze Button-Animation
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            isAnimating = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isAnimating = false
            }
        }

        // Prüfen, ob genug Kristalle da sind
        guard crystalManager.spendCrystals(option.crystal) else {
            withAnimation {
                message = "Not enough crystals 💎"
            }
            clearMessage(after: 1.5)
            return
        }

        // Summon durchführen
        withAnimation {
            message = "Summoning..."
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            let count = option.type == "multi" ? 10 : 1
            summonedCharacters = summonManager.summon(from: allCharacters, count: count)

            withAnimation(.spring()) {
                message = "You summoned a new hero!"
            }

            // Ergebnis anzeigen
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                showResult = true
            }

            clearMessage(after: 2.0)
        }
    }

    private func clearMessage(after delay: Double) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(.easeOut(duration: 0.3)) {
                message = nil
            }
        }
    }
}
