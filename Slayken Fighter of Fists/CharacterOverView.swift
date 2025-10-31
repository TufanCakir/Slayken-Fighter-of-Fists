import SwiftUI

struct CharacterOverView: View {
    @EnvironmentObject private var characterManager: CharacterManager
    @Environment(\.dismiss) private var dismiss

    // Visueller Effekt beim Wechseln
    @State private var selectedHeroID: String? = nil
    @State private var showDeleteAlert = false
    @State private var heroToDelete: GameCharacter? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                // MARK: - Hintergrund
                LinearGradient(
                    colors: [.black, .purple.opacity(0.8), .black],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 28) {

                    // MARK: - Titel
                    VStack(spacing: 6) {
                        Text("SLAYKEN")
                            .font(.system(size: 40, weight: .heavy, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, .purple.opacity(0.8)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: .purple.opacity(0.6), radius: 10)

                        Text("Choose Your Hero")
                            .font(.title3.weight(.medium))
                            .foregroundColor(.white.opacity(0.8))
                    }

                    // MARK: - Charakterauswahl
                    if characterManager.characters.isEmpty {
                        Spacer()
                        Text("No heroes found in characters.json")
                            .foregroundColor(.white.opacity(0.6))
                        Spacer()
                    } else {
                        ScrollView(showsIndicators: false) {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 20)], spacing: 20) {
                                ForEach(characterManager.characters, id: \.id) { hero in
                                    heroCard(for: hero)
                                        .onTapGesture {
                                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                                selectedHeroID = hero.id
                                                characterManager.setActiveCharacter(hero)
                                            }
                                        }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 10)
                            .padding(.bottom, 20)
                        }
                    }

                    Spacer()

                    // MARK: - Enter World Button
                    if let active = characterManager.activeCharacter {
                        NavigationLink {
                            HomeView()
                        } label: {
                            Label("Enter World as \(active.name)", systemImage: "flame.fill")
                                .font(.headline.bold())
                                .foregroundColor(.black)
                                .padding(.vertical, 16)
                                .frame(maxWidth: .infinity)
                                .background(
                                    LinearGradient(
                                        colors: [.yellow, .orange],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .cornerRadius(18)
                                .shadow(color: .yellow.opacity(0.7), radius: 12, y: 3)
                        }
                        .padding(.horizontal, 40)
                        .transition(.opacity.combined(with: .scale))
                    }

                    // MARK: - Reset Button
                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        Text("Reset Progress")
                            .font(.subheadline)
                            .foregroundColor(.red.opacity(0.8))
                    }
                    .padding(.bottom, 24)
                }
            }
            .alert("Reset all progress?", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    characterManager.resetProgress()
                    selectedHeroID = nil
                }
            } message: {
                Text("All character levels and EXP will be reset to default.")
            }
        }
        .onAppear {
            selectedHeroID = characterManager.activeCharacter?.id
        }
    }

    // MARK: - Hero Card
    private func heroCard(for hero: GameCharacter) -> some View {
        let isSelected = selectedHeroID == hero.id
        let aura = Color(hex: hero.auraColor)

        return ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: hero.gradient.top).opacity(0.9),
                            Color(hex: hero.gradient.bottom).opacity(0.95)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            isSelected ? aura : Color.clear,
                            lineWidth: isSelected ? 3 : 0
                        )
                        .shadow(color: isSelected ? aura.opacity(0.8) : .clear, radius: 12)
                )
                .shadow(color: .black.opacity(0.5), radius: 10, y: 3)

            VStack(spacing: 10) {
                Image(hero.image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 120)
                    .shadow(color: aura.opacity(0.6), radius: 8)

                VStack(spacing: 4) {
                    Text(hero.name)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Lv. \(hero.level)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.bottom, 10)
            }
            .padding(.top, 12)
        }
        .frame(height: 200)
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.45, dampingFraction: 0.7), value: isSelected)
    }
}

#Preview {
    CharacterOverView()
        .environmentObject(CharacterManager.shared)
        .preferredColorScheme(.dark)
}
