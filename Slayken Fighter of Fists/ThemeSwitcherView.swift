import SwiftUI

struct ThemeSwitcherView: View {
    @EnvironmentObject var theme: ThemeManager

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Select Theme")
                    .font(.title.bold())
                    .foregroundColor(theme.tintColor)

                ForEach(theme.allThemes) { item in
                    Button {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            theme.selectTheme(item)
                        }
                    } label: {
                        HStack {
                            LinearGradient(
                                colors: item.gradient.map { Color(hex: $0) },
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .frame(width: 100, height: 40)
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8)
                                .stroke(theme.current.id == item.id ? theme.tintColor : .clear, lineWidth: 2))

                            Text(item.name)
                                .font(.headline)
                                .foregroundColor(.white)

                            Spacer()
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical, 30)
        }
        .background(LinearGradient(colors: theme.gradientColors, startPoint: .top, endPoint: .bottom).ignoresSafeArea())
    }
}
