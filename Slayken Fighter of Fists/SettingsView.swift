import SwiftUI

struct SettingsView: View {
    // MARK: - Environment Objects
    @EnvironmentObject var coinManager: CoinManager
    @EnvironmentObject var crystalManager: CrystalManager
    @EnvironmentObject var accountManager: AccountLevelManager
    @EnvironmentObject var summonManager: SummonManager
    @EnvironmentObject var teamManager: TeamManager
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var musicManager: MusicManager

    // MARK: - Local State
    @State private var showResetAlert = false
    @State private var showResetConfirmation = false
    @State private var resetAnimation = false

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                // Hintergrund
                LinearGradient(colors: [.black, .blue, .black],
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing)
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        // MARK: - Audio Section
                        settingsSection(title: "Audio") {
                            Toggle(isOn: $musicManager.isMusicOn) {
                                Label("Musik", systemImage: musicManager.isMusicOn ? "music.note" : "speaker.slash")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                            .tint(.orange)
                            .padding(.horizontal, 8)
                            .onChange(of: musicManager.isMusicOn) { _, newValue in
                                // optionales sanftes Fade beim Umschalten
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    if newValue {
                                        musicManager.toggleMusic()
                                    } else {
                                        musicManager.toggleMusic()
                                    }
                                }
                            }
                        }

                        // MARK: - Account Overview
                        settingsSection(title: "Account Overview") {
                            HStack(spacing: 22) {
                                StatBox(icon: "star.fill", title: "Level", value: "\(accountManager.level)", color: .green)
                                StatBox(icon: "diamond.fill", title: "Crystals", value: "\(crystalManager.crystals)", color: .blue)
                                StatBox(icon: "c.circle.fill", title: "Coins", value: "\(coinManager.coins)", color: .yellow)
                            }
                            .frame(maxWidth: .infinity)
                        }

                        // MARK: - Data & Storage
                        settingsSection(title: "Data & Storage") {
                            Button {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    showResetAlert = true
                                }
                            } label: {
                                Label("Reset All Progress", systemImage: "trash.fill")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.red.opacity(0.7))
                                    .cornerRadius(16)
                                    .shadow(color: .red.opacity(0.4), radius: 6)
                            }
                            .padding(.horizontal, 8)
                        }

                        // MARK: - Appearance
                        settingsSection(title: "Appearance") {
                            NavigationLink(destination: ThemeSwitcherView()) {
                                Label("Change Theme", systemImage: "paintpalette.fill")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.blue.opacity(0.6))
                                    .cornerRadius(16)
                                    .shadow(color: .blue.opacity(0.4), radius: 6)
                            }
                            .padding(.horizontal, 8)
                        }

                        Spacer(minLength: 80)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .alert("⚠️ Reset all progress?", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) { performReset() }
            } message: {
                Text("This will permanently delete your progress, characters and team setup.")
            }
            .overlay(resetConfirmationOverlay)
        }
    }

    // MARK: - Reset Overlay
    private var resetConfirmationOverlay: some View {
        Group {
            if showResetConfirmation {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.largeTitle)
                        .foregroundColor(.green)
                        .scaleEffect(resetAnimation ? 1.15 : 0.8)
                        .animation(.spring(), value: resetAnimation)
                    Text("Progress Reset")
                        .foregroundColor(.white)
                        .font(.headline)
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(16)
                .shadow(color: .green.opacity(0.4), radius: 10)
                .transition(.scale.combined(with: .opacity))
            }
        }
    }

    // MARK: - Reset Logic
    private func performReset() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        coinManager.reset()
        crystalManager.reset()
        accountManager.reset()
        summonManager.removeAll()
        teamManager.removeAll()

        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            showResetConfirmation = true
            resetAnimation = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation {
                showResetConfirmation = false
            }
        }

        print("🧩 All saved data cleared successfully.")
    }

    // MARK: - Section Wrapper
    @ViewBuilder
    private func settingsSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white.opacity(0.8))
            content()
        }
        .padding()
        .background(Color.white.opacity(0.06))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.3), radius: 5)
    }
}

// MARK: - StatBox Component
private struct StatBox: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            Text(value)
                .font(.headline.bold())
                .foregroundColor(.white)
        }
        .frame(width: 90, height: 90)
        .background(Color.white.opacity(0.08))
        .cornerRadius(16)
        .shadow(color: color.opacity(0.5), radius: 6)
    }
}

#Preview {
    SettingsView()
        .environmentObject(CoinManager.shared)
        .environmentObject(CrystalManager.shared)
        .environmentObject(AccountLevelManager.shared)
        .environmentObject(SummonManager.shared)
        .environmentObject(TeamManager.shared)
        .environmentObject(ThemeManager.shared)
        .environmentObject(MusicManager())
        .preferredColorScheme(.dark)
}
