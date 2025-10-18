import SwiftUI

struct WelcomeView: View {
    @State private var glow = false
    @State private var showTitle = false
    @State private var showSubtitle = false
    @State private var showButton = false
    @State private var navigateToHome = false

    var body: some View {
        NavigationStack {
            ZStack {
                // MARK: - Hintergrund
                LinearGradient(
                    colors: [.black, .blue, .black],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                .opacity(showTitle ? 1 : 0)
                .animation(.easeInOut(duration: 1.2), value: showTitle)

                VStack(spacing: 28) {

                    // MARK: - Titel
                    VStack(spacing: 6) {
                        Text("Willkommen zu")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(.red)
                            .opacity(showSubtitle ? 1 : 0)
                            .offset(y: showSubtitle ? 0 : 20)
                            .animation(.easeOut(duration: 1.0).delay(0.6), value: showSubtitle)
                            .shadow(color: .black.opacity(0.5), radius: 10, y: 5)

                        Text("Slayken Fighter of Fists")
                            .font(.system(size: 50, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(colors: [.orange, .red, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .shadow(color: .black.opacity(0.5), radius: 10, y: 5)
                            .opacity(showSubtitle ? 1 : 0)
                            .offset(y: showSubtitle ? 0 : 30)
                            .animation(.easeOut(duration: 1.2).delay(0.8), value: showSubtitle)

             
                    }

                    // MARK: - Start Button
                    if showButton {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.6)) {
                                navigateToHome = true
                            }
                        }) {
                            Text("Spiel starten")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 50)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(
                                            LinearGradient(colors: [.orange, .red, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
                                        )
                                        .shadow(color: .black.opacity(0.5), radius: 10)
                                )
                                .scaleEffect(glow ? 1.05 : 1.0)
                        }
                        .transition(.opacity.combined(with: .scale))
                        .animation(.easeInOut(duration: 1.2).delay(1.5), value: showButton)
                    }
                }
                .multilineTextAlignment(.center)
                .padding()
            }
            .onAppear {
                glow = true
                // Schrittweise Animationen
                withAnimation {
                    showTitle = true
                }
                withAnimation(.easeOut(duration: 1.2).delay(0.4)) {
                    showSubtitle = true
                }
                withAnimation(.easeOut(duration: 1.2).delay(1.2)) {
                    showButton = true
                }
            }
            // MARK: - Navigation
            .fullScreenCover(isPresented: $navigateToHome) {
                FooterTabView()
            }
        }
    }
}



#Preview {
    WelcomeView()
}
