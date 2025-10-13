import SwiftUI

struct SummonView: View {
    @EnvironmentObject private var crystalManager: CrystalManager
    @EnvironmentObject private var summonManager: SummonManager

    @State private var summonOptions: [SummonOption] = Bundle.main.decode("summonData.json")
    @State private var featuredCharacter: GameCharacter = .example
    @State private var message: String?
    @State private var isAnimating = false
    @State private var showResult = false
    @State private var summonedCharacters: [GameCharacter] = []

    var body: some View {
        NavigationStack {
            ZStack {
                // MARK: - Hintergrund
                LinearGradient(colors: [.black, .blue.opacity(0.9), .black],
                               startPoint: .top,
                               endPoint: .bottom)
                    .ignoresSafeArea()

                VStack(spacing: 26) {

                    // MARK: - Titel
                    Text("Summon Heroes")
                        .font(.largeTitle.bold())
                        .foregroundStyle(
                            LinearGradient(colors: [.white, .cyan],
                                           startPoint: .top,
                                           endPoint: .bottom)
                        )
                        .shadow(color: .cyan.opacity(0.5), radius: 10)
                        .padding(.top, 12)

                    // MARK: - Banner des Featured Characters
                    bannerView(for: featuredCharacter)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 4)

                    // MARK: - Crystal-Anzeige
                    if let first = summonOptions.first {
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
                    }

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
                            .padding(.top, 12)
                            .transition(.opacity.combined(with: .scale))
                    }

                    Spacer()
                }
                .padding(.horizontal, 24)
            }
            .animation(.easeInOut(duration: 0.35), value: message)
            .navigationDestination(isPresented: $showResult) {
                SummonResultView(characters: summonedCharacters)
            }
            .onAppear {
                // Optional: zufälligen Charakter als Banner wählen
                if let random = summonManager.ownedCharacters.randomElement() {
                    featuredCharacter = random
                }
            }
        }
    }

    // MARK: - Banner
    private func bannerView(for char: GameCharacter) -> some View {
        ZStack(alignment: .bottomLeading) {
            Image(char.image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .cyan.opacity(0.4), radius: 10)
                .overlay(
                    LinearGradient(
                        colors: [.black.opacity(0.6), .clear, .black.opacity(0.6)],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                )
   

            VStack(alignment: .leading, spacing: 4) {
                Text(char.name)
                    .font(.title2.bold())
                    .foregroundColor(.white)
                    .font(.subheadline)
                    .foregroundColor(.cyan.opacity(0.8))
            }
            .padding(16)
        }
        .frame(height: 220)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.25))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.cyan.opacity(0.3), lineWidth: 1.2)
        )
        .shadow(color: .cyan.opacity(0.3), radius: 8, y: 4)
    }

    // MARK: - Button
    private func summonButton(for option: SummonOption) -> some View {
        Button {
            summon(option)
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(option.title)
                        .font(.headline.bold())
                        .foregroundColor(.white)
                    HStack(spacing: 12) {
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

    // MARK: - Logic
    private func summon(_ option: SummonOption) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            isAnimating = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isAnimating = false
            }
        }

        if crystalManager.spendCrystals(option.crystal) {
            message = "You summoned a new hero!"

            let newChars = summonManager.summon(
                from: [GameCharacter.example],
                count: option.type == "multi" ? 10 : 1
            )

            summonedCharacters = newChars

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                showResult = true
            }
        } else {
            message = "Not enough crystals."
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation(.easeOut(duration: 0.3)) {
                message = nil
            }
        }
    }
}
