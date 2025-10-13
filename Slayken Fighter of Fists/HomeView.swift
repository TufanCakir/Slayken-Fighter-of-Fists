import SwiftUI

struct HomeView: View {
    // MARK: - Properties
    @State private var buttons: [HomeButton] = Bundle.main.decode("homeButtons.json")
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                // Hintergrund mit leichtem Farbverlauf
                LinearGradient(
                    colors: [.black, .blue, .black],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    HeaderView()
                        .padding(.top, 10)

                    // Button-Grid
                    ScrollView(showsIndicators: false) {
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(buttons) { button in
                                NavigationLink(destination: ScreenFactory.make(button.destination)) {
                                    HomeButtonView(button: button)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 30)
                        .padding(.bottom, 40)
                    }
                }
            }

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
