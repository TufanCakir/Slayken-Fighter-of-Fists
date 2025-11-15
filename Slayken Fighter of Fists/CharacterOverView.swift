import SwiftUI

struct CharacterOverView: View {
    @EnvironmentObject private var characterManager: CharacterManager
    @Environment(\.dismiss) private var dismiss

    // MARK: - States
    @State private var selectedHeroID: String? = nil
    @State private var showDeleteAlert = false
    @State private var heroToDelete: GameCharacter? = nil

    // ORB Animation
    @State private var orbGlow = false
    @State private var orbRotation = 0.0

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundLayer    // ⭐ Neue Perfect Background Animation

                // MARK: Hauptinhalt
                VStack(spacing: 28) {

                    headerSection

                    heroGridSection

                    Spacer()

                    enterWorldButtonSection

                    resetButtonSection
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
}

//
// MARK: - UI Komponenten
//
private extension CharacterOverView {

    // MARK: Background Layer
    var backgroundLayer: some View {
        ZStack {

            // Base Gradient (gleich wie Summon)
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

            // ⭐ Glow (1:1 wie Summon)
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.black, .blue, .black],
                        center: .center,
                        startRadius: 15,
                        endRadius: 260
                    )
                )
                .scaleEffect(orbGlow ? 1.1 : 0.9)
                .blur(radius: 40)
                .animation(.easeInOut(duration: 1.3).repeatForever(), value: orbGlow)

            // ⭐ Rotating Ring (identisch wie Summon)
            Circle()
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            .black,
                            .blue,
                            .black
                        ]),
                        center: .center
                    ),
                    lineWidth: 12
                )
                .frame(width: 330, height: 330)
                .blur(radius: 2)
                .rotationEffect(.degrees(orbRotation))
                .animation(.linear(duration: 6).repeatForever(autoreverses: false), value: orbRotation)
                .opacity(0.8)

            // ⭐ Sparkles Icon
            Image(systemName: "sparkles")
                .font(.system(size: 55))
                .foregroundStyle(.cyan.opacity(0.9))
                .shadow(color: .cyan.opacity(0.5), radius: 15)
        }
        .onAppear {
            orbGlow = true
            orbRotation = 360
        }
    }

    // MARK: Header
    var headerSection: some View {
        VStack(spacing: 6) {
            Text("Choose Your Hero")
                .font(.title3)
                .foregroundColor(.white)
        }
    }

    // MARK: Hero Grid
    var heroGridSection: some View {
        Group {
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
        }
    }

    // MARK: Enter World Button
    var enterWorldButtonSection: some View {
        Group {
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
        }
    }

    // MARK: Reset Button
    var resetButtonSection: some View {
        Button(role: .destructive) {
            showDeleteAlert = true
        } label: {
            Text("Reset Progress")
                .font(.subheadline)
                .foregroundColor(.red.opacity(0.8))
        }
        .padding(.bottom, 24)
    }

    // MARK: Hero Card
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
                        .stroke(isSelected ? aura : Color.clear, lineWidth: isSelected ? 3 : 0)
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
