import SwiftUI

struct NewsView: View {
    @State private var newsItems: [NewsItem] = Bundle.main.decode("news.json")

    var body: some View {
        ZStack {
            LinearGradient(colors: [.black, .blue, .black], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 30) {
                    Text("Latest News")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.linearGradient(colors: [.white, .cyan], startPoint: .top, endPoint: .bottom))
                        .shadow(color: .cyan.opacity(0.4), radius: 10)
                        .padding(.top, 20)

                    ForEach(newsItems) { item in
                        NewsCard(item: item)
                    }

                    Spacer(minLength: 60)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
    }
}

#Preview {
    NavigationStack {
        NewsView()
            .preferredColorScheme(.dark)
    }
}
