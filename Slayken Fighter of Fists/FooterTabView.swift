import SwiftUI

struct FooterTabView: View {

    @State private var tabs: [FooterTab] = Bundle.main.decode("footerTabs.json")
    @State private var selectedTab: String = "HomeView"
    @State private var backgroundColor: Color = .black

    var body: some View {
        ZStack {

            // MARK: - Hintergrund animiert mit Tab-Farbe
            backgroundColor
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.35), value: backgroundColor)

            // MARK: - Haupt TabView
            TabView(selection: $selectedTab) {
                ForEach(tabs) { tab in
                    NavigationStack {
                        destinationView(for: tab.destination)
                            .navigationTitle(tab.title)
                            .navigationBarTitleDisplayMode(.inline)
                    }
                    .tag(tab.destination)
                    .tabItem {
                        Label(tab.title, systemImage: tab.icon)
                    }
                }
            }
            .tint(currentTabColor)
            .onChange(of: selectedTab) { _, _ in
                withAnimation(.easeInOut(duration: 0.35)) {
                    backgroundColor = currentTabColor
                }
            }
            .onAppear {
                backgroundColor = currentTabColor
            }
        }
    }

    // MARK: - Aktuelle Tabfarbe
    private var currentTabColor: Color {
        Color(hex: tabs.first(where: { $0.destination == selectedTab })?.color ?? "#FFFFFF")
    }

    // MARK: - Ziel-Views
    @ViewBuilder
    private func destinationView(for name: String) -> some View {
        switch name {
        case "HomeView":
            HomeView()

        case "CharacterOverView":
            CharacterOverView()

        case "CreateCharacterView":
            CreateCharacterView()

        case "ExchangeView":
            ExchangeView()

        default:
            HomeView()
        }
    }
}

#Preview {
    FooterTabView()
}
