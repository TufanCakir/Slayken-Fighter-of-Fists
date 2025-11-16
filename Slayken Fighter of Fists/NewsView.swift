import SwiftUI

struct NewsView: View {

    @State private var newsItems: [NewsItem] = Bundle.main.decode("news.json")

    // ORB Animation
    @State private var orbGlow = false
    @State private var orbRotation = 0.0

    var body: some View {
        ZStack {
            backgroundLayer
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 30) {

                    Text("Latest News")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.linearGradient(
                            colors: [.blue],
                            startPoint: .top, endPoint: .bottom
                        ))
                        .shadow(color: .cyan.opacity(0.4), radius: 10)
                        .padding(.top, 30)

                    ForEach(newsItems) { item in
                        NewsCard(item: item)
                    }

                    Spacer(minLength: 80)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 60)
            }
        }
    }
}

//
// MARK: - Hintergrund Layer (Energy Orb)
//
private extension NewsView {
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
    NavigationStack {
        NewsView()
            .preferredColorScheme(.dark)
    }
}
