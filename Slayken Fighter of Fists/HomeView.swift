//
//  HomeView.swift
//  Slayken Fighter of Fists
//

import SwiftUI

struct HomeView: View {

    // MARK: - Data
    @State private var buttons: [HomeButton] = Bundle.main.decode("homeButtons.json")

    private let columns = [
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20)
    ]

    // MARK: - Orb Animation
    @State private var orbGlow = false
    @State private var orbRotation = 0.0

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {

                // Hintergrund IMMER unten
                backgroundLayer
                    .zIndex(0)

                // Inhalt IMMER oben
                VStack(spacing: 0) {

                    // MARK: Header
                    HeaderView()
                        .padding(.top, 12)
                        .padding(.bottom, 8)

                    // MARK: Buttons Grid
                    ScrollView(showsIndicators: false) {
                        LazyVGrid(columns: columns, spacing: 24) {
                            ForEach(buttons) { button in
                                NavigationLink(
                                    destination: ScreenFactory.make(button.destination)
                                ) {
                                    HomeButtonView(button: button)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        .padding(.bottom, 60)
                    }
                }
                .zIndex(1)   // CONTENT garantiert über Ring/Orb
            }
            .navigationBarHidden(true)
        }
        .onAppear { startAnimations() }
    }
}

    // MARK: - Background Layer
    private extension HomeView {
        var backgroundLayer: some View {
            ZStack {

                // MARK: Glass Core
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 200, height: 200)
                    .shadow(color: .blue, radius: 25, y: 4)

                // MARK: Rotating Ring (isoliert!)
                Circle()
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [.black, .blue, .black]),
                            center: .center
                        ),
                        lineWidth: 10
                    )
                    .frame(width: 260, height: 260)
                    .rotationEffect(.degrees(orbRotation))
                    .allowsHitTesting(false)

                // MARK: Center Icon
                Image(systemName: "sparkles")
                    .font(.system(size: 55))
                    .foregroundStyle(.cyan)
                    .shadow(color: .blue, radius: 15)
            }
            .ignoresSafeArea()
        }
    }


    // MARK: - Animations
    private extension HomeView {
        func startAnimations() {
            orbGlow = true
            orbRotation = 360
        }
    }

#Preview {
    HomeView()
        .environmentObject(CoinManager.shared)
        .environmentObject(CrystalManager.shared)
        .environmentObject(AccountLevelManager.shared)
        .preferredColorScheme(.dark)
}
