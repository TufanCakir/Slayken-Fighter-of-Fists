import SwiftUI

struct NewsCard: View {
    let item: NewsItem

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // MARK: - Bild (lokal oder online)
            newsImage(for: item.image)
                .frame(height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.4), radius: 6, y: 4)

            // MARK: - Textbereich
            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(.headline.bold())
                    .foregroundColor(.white)

                Text(item.date.uppercased())
                    .font(.caption)
                    .foregroundColor(.cyan.opacity(0.8))

                Text(item.description)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(3)
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 12)
        }
        .background(
            LinearGradient(
                colors: [.black, .blue, .black],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cornerRadius(16)
        .shadow(color: .cyan.opacity(0.25), radius: 6, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Hilfsfunktion: Lokales oder Online-Bild
    @ViewBuilder
    private func newsImage(for name: String) -> some View {
        if name.lowercased().hasPrefix("http") {
            // Online fallback (nur falls du später wieder URLs nutzt)
            AsyncImage(url: URL(string: name)) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    Color.gray.opacity(0.3)
                }
            }
        } else {
            // Lokales Asset
            Image(name)
                .resizable()
                .scaledToFit() // <-- skaliert gleichmäßig, sodass alles sichtbar bleibt
                .frame(width: 350, height: 150)
                .clipShape(Circle())
        }
    }
}
