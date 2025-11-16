import SwiftUI

struct CharacterOverView: View {

    @EnvironmentObject private var characterManager: CharacterManager
    @Environment(\.dismiss) private var dismiss

    // MARK: - States
    @State private var selectedHeroID: String? = nil
    @State private var showDeleteAlert = false
    @State private var selectedSlot: String? = nil
    @State private var showEquipmentSheet = false

    // ORB Animation
    @State private var orbGlow = false
    @State private var orbRotation = 0.0


    var body: some View {
        NavigationStack {
            ZStack {
                backgroundLayer

                VStack(spacing: 28) {
                    headerSection
                    heroGridSection
                    Spacer()
                    enterWorldButtonSection
                    resetButtonSection
                }
                .padding(.top, 12)
            }
        }
        .onAppear {
            selectedHeroID = characterManager.activeCharacter?.id
        }
        .sheet(isPresented: $showEquipmentSheet) {
            EquipmentView()
                .environmentObject(InventoryManager.shared)
                .environmentObject(characterManager)
                .presentationDetents([.medium, .large])
        }
        .alert("Delete this character?", isPresented: $showDeleteAlert) {

            Button("Cancel", role: .cancel) {}

            Button("Delete", role: .destructive) {
                if let id = selectedHeroID {
                    characterManager.deleteCharacter(id: id)
                }
            }

        } message: {
            Text("This hero will be permanently removed.")
        }
    }
}

//
// MARK: - UI
//
private extension CharacterOverView {

    // MARK: Background Layer
    var backgroundLayer: some View {
        ZStack {
            LinearGradient(
                colors: [.black, .blue.opacity(0.35), .black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(
                    RadialGradient(
                        colors: [.black, .blue, .black],
                        center: .center,
                        startRadius: 20,
                        endRadius: 260
                    )
                )
                .scaleEffect(orbGlow ? 1.1 : 0.9)
                .blur(radius: 40)
                .animation(.easeInOut(duration: 1.4).repeatForever(), value: orbGlow)

            Circle()
                .stroke(
                    AngularGradient(
                        colors: [.black, .blue, .black],
                        center: .center
                    ),
                    lineWidth: 12
                )
                .frame(width: 330, height: 330)
                .rotationEffect(.degrees(orbRotation))
                .blur(radius: 2)
                .animation(.linear(duration: 6).repeatForever(), value: orbRotation)
        }
        .onAppear {
            orbGlow = true
            orbRotation = 360
        }
    }

    // MARK: Header
    var headerSection: some View {
        Text("Choose Your Hero")
            .font(.title3)
            .foregroundColor(.white)
    }




    // MARK: Hero Grid
    var heroGridSection: some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 20)], spacing: 20) {
                ForEach(characterManager.characters, id: \.id) { hero in
                    heroCard(hero)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                selectedHeroID = hero.id
                                characterManager.setActiveCharacter(hero)
                            }
                        }
                        .onLongPressGesture(minimumDuration: 0.45) {
                            selectedHeroID = hero.id
                            showEquipmentSheet = true
                        }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }

    func heroCard(_ hero: GameCharacter) -> some View {

        let isSelected = selectedHeroID == hero.id
        let auraColor = Color(hex: hero.auraColor)

        return ZStack(alignment: .topTrailing) {

            // MARK: - Background + Image + Text wie bisher
            ZStack(alignment: .bottom) {

                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: hero.gradient.top),
                                Color(hex: hero.gradient.bottom)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(isSelected ? auraColor : .clear, lineWidth: 3)
                    )
                    .shadow(color: auraColor.opacity(0.7), radius: isSelected ? 12 : 5)

                VStack(spacing: 10) {
                    Image(hero.image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 120)

                    VStack(spacing: 4) {
                        Text(hero.name)
                            .foregroundColor(.white)
                            .font(.headline)

                        Text("Lv. \(hero.level)")
                            .foregroundColor(.white.opacity(0.8))
                            .font(.caption)
                    }
                    .padding(.bottom, 8)
                }
            }

            // MARK: - Delete Button
            Button {
                selectedHeroID = hero.id
                showDeleteAlert = true
            } label: {
                Image(systemName: "trash.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.red.opacity(0.85))
                    .clipShape(Circle())
                    .shadow(color: .red.opacity(0.6), radius: 6)
            }
            .padding(10)

        }
        .frame(height: 200)
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.5, dampingFraction: 0.75), value: isSelected)
    }

    // MARK: Enter World
    @ViewBuilder
    var enterWorldButtonSection: some View {
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
                    .shadow(color: .yellow.opacity(0.7), radius: 12)
            }
            .padding(.horizontal, 40)
        }
    }


    // MARK: Reset
    var resetButtonSection: some View {
        Button(role: .destructive) {
            showDeleteAlert = true
        } label: {
            Text("Reset Progress")
                .foregroundColor(.red.opacity(0.8))
        }
        .padding(.bottom, 24)
    }
}


#Preview {
    CharacterOverView()
        .environmentObject(CharacterManager.shared)
        .preferredColorScheme(.dark)
}
