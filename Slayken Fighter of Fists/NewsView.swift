import SwiftUI

struct NewsView: View {

    @State private var newsItems: [NewsItem] = Bundle.main.decode("news.json")

    // ORB Animation
    @State private var orbGlow = false
    @State private var orbRotation = 0.0

    var body: some View {
        ZStack {
            backgroundLayer

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

            // Glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.black, .white, .black],
                        center: .center,
                        startRadius: 15,
                        endRadius: 140
                    )
                )
                .scaleEffect(orbGlow ? 1.1 : 0.9)
                .blur(radius: 40)
                .animation(.easeInOut(duration: 1.3).repeatForever(), value: orbGlow)

            // Main Orb
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 180, height: 180)
                .shadow(color: .white, radius: 20)

            // Rotating Energy Ring (FIXED)
            Circle()
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [.black, .white, .black]),
                        center: .center
                    ),
                    lineWidth: 10
                )
                .frame(width: 230, height: 230)
                .blur(radius: 2)
                .rotationEffect(.degrees(orbRotation))
                .animation(.linear(duration: 3).repeatForever(autoreverses: false), value: orbRotation)

            Image(systemName: "sparkles")
                .font(.system(size: 55))
                .foregroundStyle(.white)
        }
        .onAppear {
            orbGlow = true
            orbRotation = 360
        }
    }
}

#Preview {
    NavigationStack {
        NewsView()
            .preferredColorScheme(.dark)
    }
}
