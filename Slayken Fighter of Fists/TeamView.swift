import SwiftUI
import Combine

struct TeamView: View {
    @EnvironmentObject var summonManager: SummonManager
    @EnvironmentObject var teamManager: TeamManager
    @State private var justSelected: String?

    // MARK: - Body
    var body: some View {
        ZStack {
            // MARK: - Hintergrund
            LinearGradient(
                colors: [.black, .blue.opacity(0.9), .black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 28) {
                titleHeader
                    .padding(.top, 20)

                // MARK: - Team Slots
                teamSlots

                Divider()
                    .background(Color.white.opacity(0.15))
                    .padding(.horizontal, 24)
                    .padding(.bottom, 8)

                // MARK: - Charakterliste
                if summonManager.ownedCharacters.isEmpty {
                    emptyStateView
                        .padding(.top, 40)
                        .transition(.opacity)
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVGrid(
                            columns: [GridItem(.adaptive(minimum: 120), spacing: 20)],
                            spacing: 20
                        ) {
                            ForEach(summonManager.ownedCharacters) { char in
                                characterCard(for: char)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 60)
                    }
                    .animation(.easeInOut(duration: 0.3), value: teamManager.selectedTeam)
                }
            }
            .padding(.bottom, 16)
        }
    }
}

// MARK: - Unteransichten
private extension TeamView {

    // MARK: - Titel
    var titleHeader: some View {
        Text("Team Setup")
            .font(.largeTitle.bold())
            .foregroundStyle(
                LinearGradient(colors: [.white, .cyan],
                               startPoint: .top,
                               endPoint: .bottom)
            )
            .shadow(color: .cyan.opacity(0.5), radius: 8, y: 3)
            .padding(.bottom, 4)
    }

    // MARK: - Leerer Zustand
    var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 56))
                .foregroundColor(.cyan.opacity(0.6))
                .symbolRenderingMode(.hierarchical)
            Text("No characters yet — summon some first!")
                .font(.headline)
                .foregroundColor(.white.opacity(0.6))
        }
        .transition(.opacity)
    }

    // MARK: - Team Slots
    var teamSlots: some View {
        HStack(spacing: 18) {
            ForEach(0..<4, id: \.self) { index in
                let char = index < teamManager.selectedTeam.count ? teamManager.selectedTeam[index] : nil

                VStack(spacing: 6) {
                    if let char {
                        loadImage(for: char.image)
                            .frame(width: 70, height: 70)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: .green.opacity(0.5), radius: 8)

                        Text(char.name)
                            .font(.caption2.bold())
                            .foregroundColor(.white)
                            .lineLimit(1)
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(.white.opacity(0.2), lineWidth: 1.5)
                            .background(Color.white.opacity(0.05))
                            .frame(width: 70, height: 70)
                            .overlay(
                                Image(systemName: "plus")
                                    .foregroundColor(.white.opacity(0.4))
                                    .font(.title3)
                            )

                        Text("Empty")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
                .frame(width: 80)
                .animation(.easeInOut, value: teamManager.selectedTeam)
            }
        }
        .padding(.horizontal, 10)
    }

    // MARK: - Charakterkarte
    func characterCard(for char: GameCharacter) -> some View {
        let isSelected = teamManager.contains(char)
        let isJustSelected = justSelected == char.id

        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                teamManager.toggleMember(char)
                justSelected = char.id
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    withAnimation(.easeOut) { justSelected = nil }
                }
            }
        } label: {
            VStack(spacing: 10) {
                loadImage(for: char.image)
                    .frame(width: 90, height: 90)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(color: .black.opacity(0.8), radius: 8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isSelected ? Color.green.opacity(0.9) : .clear, lineWidth: 2)
                    )
                    .scaleEffect(isSelected ? 1.05 : 1.0)

                Text(char.name)
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            .frame(width: 120, height: 140)
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        isSelected
                        ? LinearGradient(colors: [.green.opacity(0.4), .green.opacity(0.15)],
                                         startPoint: .top, endPoint: .bottom)
                        : LinearGradient(colors: [.white.opacity(0.08), .white.opacity(0.03)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? .green.opacity(0.6) : .white.opacity(0.1), lineWidth: 1.5)
                    .shadow(color: isJustSelected ? .green : .clear, radius: 10)
            )
        }
        .buttonStyle(.plain)
        .zIndex(0)
    }

    // MARK: - Bildlader (vereinheitlicht)
    func loadImage(for name: String) -> some View {
        Group {
            if name.lowercased().hasPrefix("http") {
                AsyncImage(url: URL(string: name)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .tint(.white)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                    case .failure(_):
                        Image("placeholder")
                            .resizable()
                            .scaledToFit()
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                Image(name)
                    .resizable()
                    .scaledToFit()
            }
        }
    }
}

#Preview {
    TeamView()
        .environmentObject(SummonManager.shared)
        .environmentObject(TeamManager.shared)
        .preferredColorScheme(.dark)
}
