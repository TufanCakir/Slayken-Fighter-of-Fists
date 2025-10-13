import SwiftUI

struct HomeButtonView: View {
    let button: HomeButton
    @State private var isPressed = false
    @State private var glowPulse = false

    var body: some View {
        VStack(spacing: 10) {
            // MARK: - Icon
            ZStack {
                Circle()
                    .fill(Color(hex: button.color))
       
                
                    .shadow(color: Color(hex: button.color).opacity(0.6), radius: 14)
                    .shadow(color: .white.opacity(0.15), radius: 4)
                    .scaleEffect(glowPulse ? 1.05 : 1.0)
                    .animation(
                        .easeInOut(duration: 1.4)
                            .repeatForever(autoreverses: true),
                        value: glowPulse
                    )

                Image(systemName: button.icon)
                    .font(.system(size: 38, weight: .semibold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
            }
            .frame(width: 80, height: 80)
            .scaleEffect(isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isPressed)
            .onAppear { glowPulse = true }

            // MARK: - Titel
            Text(button.title)
                .font(.headline)
                .foregroundColor(.white.opacity(0.9))
                .shadow(color: .black.opacity(0.6), radius: 2)
        }
        .frame(maxWidth: .infinity, minHeight: 130)
        .padding()


        .scaleEffect(isPressed ? 0.96 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.15)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}
    
