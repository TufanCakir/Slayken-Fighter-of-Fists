//
//  SettingsView.swift
//  Slayken Fighter of Fists
//
//  Created by Tufan Cakir on 2025-10-30.
//

import SwiftUI

struct SettingsView: View {

    // MARK: - Environment Objects
    @EnvironmentObject var coinManager: CoinManager
    @EnvironmentObject var crystalManager: CrystalManager
    @EnvironmentObject var accountManager: AccountLevelManager
    @EnvironmentObject var musicManager: MusicManager

    // MARK: - Local State
    @State private var showResetAlert = false
    @State private var showResetConfirmation = false
    @State private var resetAnimation = false

    // Orb Animation
    @State private var orbGlow = false
    @State private var orbRotation = 0.0

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {

                // MARK: - Hintergrund
                backgroundLayer

                // MARK: - Content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {

                        // MARK: Audio
                        settingsSection(title: "Audio") {
                            MusicToggleButton()
                                .environmentObject(musicManager)
                        }

                        // MARK: Account
                        settingsSection(title: "Account Overview") {
                            HStack(spacing: 22) {
                                StatBox(icon: "star.fill", title: "Level", value: "\(accountManager.level)", color: .green)
                                StatBox(icon: "diamond.fill", title: "Crystals", value: "\(crystalManager.crystals)", color: .blue)
                                StatBox(icon: "c.circle.fill", title: "Coins", value: "\(coinManager.coins)", color: .yellow)
                            }
                            .frame(maxWidth: .infinity)

                        }

                        // MARK: Data & Storage
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
                                    .background(.red.gradient.opacity(0.7))
                                    .cornerRadius(16)
                                    .shadow(color: .red.opacity(0.5), radius: 6)
                                
                            }
                            .padding(.horizontal, 8)
                            .shadow(color: .white, radius: 5)

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
                Text("This will permanently delete your progress, characters, skins, and shop data.")
            }
            .overlay(resetConfirmationOverlay)
            .onAppear {
                orbGlow = true
                orbRotation = 360
            }
        }
    }
}





    // MARK: - Background Layer
    extension SettingsView {
        var backgroundLayer: some View {
            ZStack {

                // MARK: Glow (soft + centered)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.black, .blue, .black],
                            center: .center,
                            startRadius: 10,
                            endRadius: 160
                        )
                    )
                    .scaleEffect(orbGlow ? 1.12 : 0.88)
                    .blur(radius: 50)
                    .drawingGroup() // bessere GPU Performance
                    .animation(.easeInOut(duration: 3).repeatForever(), value: orbGlow)

                // MARK: Main Orb (clean glass effect)
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 200, height: 200)
                    .shadow(color: .blue.opacity(0.6), radius: 25, y: 4)

                // MARK: Rotating Ring
                Circle()
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [.black, .blue, .black]),
                            center: .center
                        ),
                        lineWidth: 10
                    )
                    .frame(width: 260, height: 260)
                    .blur(radius: 2)
                    .rotationEffect(.degrees(orbRotation))
                    .animation(.linear(duration: 6).repeatForever(autoreverses: false), value: orbRotation)

                // MARK: Center Icon
                Image(systemName: "sparkles")
                    .font(.system(size: 55))
                    .foregroundStyle(.cyan)
                    .shadow(color: .cyan.opacity(0.5), radius: 12)
            }
            .ignoresSafeArea()
        }
    }

// MARK: - Reset Confirmation Overlay
extension SettingsView {
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
                .shadow(color: .white, radius: 5)
                .transition(.scale.combined(with: .opacity))
            }
        }
    }
}

// MARK: - Reset Logic
extension SettingsView {
    private func performReset() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        coinManager.reset()
        crystalManager.reset()
        accountManager.reset()
        CharacterManager.shared.resetProgress()
        StageProgressManager.shared.resetProgress()

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
}



// MARK: - Section Wrapper Component
extension SettingsView {
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

// MARK: - MusicToggleButton Component
struct MusicToggleButton: View {
    @EnvironmentObject var musicManager: MusicManager
    @State private var iconScale = 1.0

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                musicManager.isMusicOn.toggle()
                iconScale = 1.2
            }

            withAnimation(.spring(response: 0.4, dampingFraction: 0.5).delay(0.1)) {
                iconScale = 1.0
            }

        } label: {
            HStack(spacing: 12) {
                Image(systemName: musicManager.isMusicOn
                      ? "music.note"
                      : "speaker.slash.fill")
                    .font(.title3.bold())
                    .foregroundColor(.blue)
                    .scaleEffect(iconScale)

                Text(musicManager.isMusicOn ? "Music On" : "Music Off")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(.thinMaterial)
            .cornerRadius(14)
        }
    }
}


// MARK: - Erweiterung für externen Music-Call
extension MusicManager {
    @MainActor
    func handleMusicToggleExternally() async {
        await handleMusicToggle()
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
    }
}

#Preview {
    SettingsView()
        .environmentObject(CoinManager.shared)
        .environmentObject(CrystalManager.shared)
        .environmentObject(AccountLevelManager.shared)
        .environmentObject(MusicManager())
        .preferredColorScheme(.dark)
}
