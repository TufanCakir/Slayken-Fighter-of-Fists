//  HomeView.swift
//  Slayken Fighter of Fists
//

import SwiftUI

struct HomeView: View {

    @State private var buttons: [HomeButton] = Bundle.main.decode("homeButtons.json")

    private let columns = [
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
backgroundLayer
                    .ignoresSafeArea()
                // CONTENT
                VStack(spacing: 0) {

                    HeaderView()
                        .padding(.top, 12)
                        .padding(.bottom, 8)

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
                .zIndex(1)
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Background Layer
private extension HomeView {
    var backgroundLayer: some View {
        ZStack {

            // 🌑 DARK → BLUE → DARK Gradient
            LinearGradient(
                colors: [
                    .black,
                    Color.white.opacity(0.3),
                    .black
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

        }
    }
}
#Preview {
    HomeView()
        .environmentObject(CoinManager.shared)
        .environmentObject(CrystalManager.shared)
        .environmentObject(AccountLevelManager.shared)
        .preferredColorScheme(.dark)
}
