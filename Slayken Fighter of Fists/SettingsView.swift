import SwiftUI

struct SettingsView: View {
    // MARK: - Environment Objects
    @EnvironmentObject var coinManager: CoinManager
    @EnvironmentObject var crystalManager: CrystalManager
    @EnvironmentObject var accountManager: AccountLevelManager
    @EnvironmentObject var summonManager: SummonManager
    @EnvironmentObject var teamManager: TeamManager
    @EnvironmentObject var themeManager: ThemeManager

    // MARK: - Local State
    @State private var showResetAlert = false
    @State private var showResetConfirmation = false
    @State private var resetAnimation = false

    var body: some View {
        NavigationStack {
            ZStack {
                // MARK: Hintergrund (Theme-Gradient)
                LinearGradient(
                    colors: [.black, .blue, .black],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {

       

                        // MARK: - Account Overview
                        settingsSection(title: "Account Overview") {
                            HStack(spacing: 22) {
                                StatBox(icon: "star", title: "Level", value: "\(accountManager.level)", color: .green)
                                StatBox(icon: "diamond.fill", title: "Crystals", value: "\(crystalManager.crystals)", color: .blue)
                                StatBox(icon: "c.circle", title: "Coins", value: "\(coinManager.coins)", color: .yellow)
                            }
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
                            .padding(.horizontal, 20)
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
                            .padding(.horizontal, 20)
                        }

                        Spacer(minLength: 60)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .alert("⚠️ Reset all progress?", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    performReset()
                }
            } message: {
                Text("This will permanently delete your progress, characters and team setup.")
            }
            .overlay(
                // Optional: kleine visuelle Bestätigung nach Reset
                Group {
                    if showResetConfirmation {
                        VStack(spacing: 8) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.largeTitle)
                                .foregroundColor(.green)
                                .scaleEffect(resetAnimation ? 1.2 : 0.8)
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
            )
        }
    }

    // MARK: - Helper Functions
    private func performReset() {
        // Haptics
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

        // Animation ausblenden
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation {
                showResetConfirmation = false
            }
        }

        print("🧩 All saved data cleared successfully.")
    }

    // MARK: - Helper UI Sections
    @ViewBuilder
    private func settingsSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white.opacity(0.8))
            content()
        }
        .padding()
        .background(Color.white.opacity(0.05))
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
        .shadow(color: color.opacity(0.4), radius: 6)
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
        .preferredColorScheme(.dark)
}
