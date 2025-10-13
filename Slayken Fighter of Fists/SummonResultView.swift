import SwiftUI

struct SummonResultView: View {
    let characters: [GameCharacter]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.black, .blue.opacity(0.9), .black],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Text("Summon Result")
                    .font(.largeTitle.bold())
                    .foregroundStyle(
                        LinearGradient(colors: [.white, .cyan],
                                       startPoint: .top,
                                       endPoint: .bottom)
                    )
                    .shadow(color: .cyan.opacity(0.5), radius: 10)

                ScrollView(showsIndicators: false) {
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 120), spacing: 20)],
                        spacing: 20
                    ) {
                        ForEach(characters) { char in
                            VStack(spacing: 10) {
                                Image(char.image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 90, height: 90)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .shadow(color: .cyan.opacity(0.6), radius: 10)

                                Text(char.name)
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding()
                }

                Button("Back") {
                    dismiss()
                }
                .font(.headline.bold())
                .padding(.horizontal, 40)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                .shadow(color: .cyan.opacity(0.5), radius: 8)
            }
            .padding(.top, 30)
        }
    }
}
