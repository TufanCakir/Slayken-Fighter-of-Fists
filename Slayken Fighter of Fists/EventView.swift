import SwiftUI

struct EventView: View {
    // MARK: - JSON Data
    @State private var events: [Event] = Bundle.main.decode("events.json")
    @State private var bosses: [Boss] = Bundle.main.decode("eventBosses.json")

    // MARK: - States
    @State private var selectedEvent: Event?
    @State private var showBattle = false
    @State private var victoryText: String?

    // MARK: - Managers
    @EnvironmentObject private var coinManager: CoinManager
    @EnvironmentObject private var crystalManager: CrystalManager
    @EnvironmentObject private var accountManager: AccountLevelManager
    @EnvironmentObject private var characterManager: CharacterLevelManager
    @EnvironmentObject private var summonManager: SummonManager
    @EnvironmentObject private var teamManager: TeamManager

    var body: some View {
        ZStack {
            backgroundLayer

            if !showBattle {
                eventSelectionView
                    .transition(.opacity.combined(with: .scale))
            }

            if let text = victoryText {
                victoryOverlay(text: text)
                    .zIndex(10)
                    .transition(.scale.combined(with: .opacity))
            }

            if showBattle {
                Color.black.opacity(0.7)
                    .ignoresSafeArea()
                    .transition(.opacity)
            }
        }
        .fullScreenCover(isPresented: $showBattle) {
            if let event = selectedEvent,
               let boss = bosses.first(where: { $0.id == event.bossId }) {
                BattleSceneView(controller: makeController(for: boss, event: event))
                    .environmentObjects(
                        coinManager,
                        crystalManager,
                        accountManager,
                        characterManager,
                        summonManager,
                        teamManager
                    )
                    .background(Color.black)
                    .ignoresSafeArea()
            }
        }
        .navigationTitle("Events")
        .navigationBarTitleDisplayMode(.inline)
        .animation(.easeInOut(duration: 0.3), value: showBattle)
    }
}

// MARK: - Subviews
extension EventView {

    /// Hintergrund (Soft Gradient)
    private var backgroundLayer: some View {
        LinearGradient(
            colors: [.black, .blue, .black],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    /// Eventauswahl
    private var eventSelectionView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 30) {
                Text("Select an Event")
                    .font(.title2.bold())
                    .foregroundColor(.white.opacity(0.95))
                    .padding(.top, 24)

                ForEach(events) { event in
                    eventCard(for: event)
                        .transition(.scale.combined(with: .opacity))
                }

                Spacer(minLength: 60)
            }
            .padding(.horizontal, 20)
        }
    }

    /// Einzelne Eventkarte
    private func eventCard(for event: Event) -> some View {
        Button { startBattle(for: event) } label: {
            ZStack(alignment: .bottomLeading) {
                eventImage(for: event.image)
                    .frame(height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        LinearGradient(
                            colors: [.black.opacity(0.6), .clear],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.cyan.opacity(0.5), lineWidth: 1.5)
                    )
                    .shadow(color: .black.opacity(0.6), radius: 8)

                VStack(alignment: .leading, spacing: 6) {
                    Text(event.name)
                        .font(.headline.bold())
                        .foregroundColor(.white)
                        .shadow(color: .black, radius: 3)
                    Text(event.description)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.85))
                        .lineLimit(2)
                }
                .padding(12)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(selectedEvent?.id == event.id ? 0.97 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: selectedEvent?.id)
    }

    /// Sieg Overlay
    private func victoryOverlay(text: String) -> some View {
        VStack(spacing: 12) {
            Text("Victory!")
                .font(.title.bold())
                .foregroundColor(.yellow)
                .shadow(color: .orange, radius: 6)
            Text(text)
                .font(.headline)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            Button("Back to Events") {
                withAnimation {
                    victoryText = nil
                    showBattle = false
                    selectedEvent = nil
                }
            }
            .font(.headline)
            .padding(.vertical, 8)
            .padding(.horizontal, 20)
            .background(Color.yellow)
            .cornerRadius(10)
            .foregroundColor(.black)
            .shadow(color: .yellow.opacity(0.6), radius: 6)
        }
        .padding(24)
        .background(Color.black.opacity(0.85))
        .cornerRadius(20)
        .shadow(color: .black, radius: 12)
        .frame(maxWidth: 300)
    }

    /// Bild (lokal oder online automatisch)
    @ViewBuilder
    private func eventImage(for name: String) -> some View {
        if name.lowercased().hasPrefix("http") {
            AsyncImage(url: URL(string: name)) { phase in
                switch phase {
                case .empty:
                    Color.gray.opacity(0.2).overlay(ProgressView())
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    Color.gray.opacity(0.3)
                }
            }
        } else {
            Image(name)
                .resizable()
                .scaledToFit() // <-- skaliert gleichmäßig, sodass alles sichtbar bleibt
                .frame(width: 350, height: 150)
                .clipShape(Circle())
        }
    }
}

// MARK: - Logic
extension EventView {
    private func makeController(for boss: Boss, event: Event) -> BattleSceneController {
        let team = teamManager.selectedTeam.isEmpty
            ? [summonManager.ownedCharacters.first ?? GameCharacter.example]
            : teamManager.selectedTeam

        let controller = BattleSceneController(
            boss: boss,
            bossHp: boss.hp,
            team: team,
            coinManager: coinManager,
            crystalManager: crystalManager,
            accountManager: accountManager,
            characterManager: characterManager
        )

        controller.onFight = {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation {
                    showBattle = false
                    victoryText = "\(boss.name) was defeated!"
                }
            }
        }

        controller.onExit = {
            withAnimation {
                showBattle = false
                selectedEvent = nil
            }
        }

        return controller
    }

    private func startBattle(for event: Event) {
        selectedEvent = event
        withAnimation(.easeInOut(duration: 0.3)) {
            showBattle = true
        }
    }
}

// MARK: - Helper für EnvironmentObjects
private extension View {
    func environmentObjects(
        _ coin: CoinManager,
        _ crystal: CrystalManager,
        _ account: AccountLevelManager,
        _ character: CharacterLevelManager,
        _ summon: SummonManager,
        _ team: TeamManager
    ) -> some View {
        self.environmentObject(coin)
            .environmentObject(crystal)
            .environmentObject(account)
            .environmentObject(character)
            .environmentObject(summon)
            .environmentObject(team)
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        EventView()
            .environmentObject(CoinManager.shared)
            .environmentObject(CrystalManager.shared)
            .environmentObject(AccountLevelManager.shared)
            .environmentObject(CharacterLevelManager.shared)
            .environmentObject(SummonManager.shared)
            .environmentObject(TeamManager.shared)
            .preferredColorScheme(.dark)
    }
}
