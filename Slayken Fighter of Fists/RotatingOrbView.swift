import SwiftUI

struct RotatingOrbView: View {
    
    @State private var orbRotation = 0.0
    
    var body: some View {
        ZStack {

            // Glow Layer
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.black, .white, .black],
                        center: .center,
                        startRadius: 20,
                        endRadius: 180
                    )
                )
                .blur(radius: 40)
                .frame(width: 350, height: 350)

            // Main Orb
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 180, height: 180)
                .shadow(color: .white.opacity(0.5), radius: 20)

            // Rotating Ring
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
                .animation(.linear(duration: 6).repeatForever(autoreverses: false),
                           value: orbRotation)

            // Sparkle Icon
            Image(systemName: "sparkles")
                .font(.system(size: 55))
                .foregroundStyle(.white.opacity(0.9))
        }
        .onAppear {
            orbRotation = 360
        }
    }
}
