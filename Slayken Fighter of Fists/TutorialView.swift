import SwiftUI

struct TutorialView: View {

    @State private var steps: [TutorialStep] = Bundle.main.decode("tutorial.json")
    @State private var currentIndex = 0

    @State private var showTitle = false
    @State private var showText = false
    @State private var showHint = false

    @State private var showWelcome = false

    // ORB Animation
    @State private var orbGlow = false
    @State private var orbRotation = 0.0

    var body: some View {
        ZStack {
            backgroundLayer

            VStack {
                Spacer()

                // MARK: - STEP CONTENT
                if currentIndex < steps.count {
                    stepContent
                } else {
                    finishedContent
                }

                Spacer()

                // MARK: - Progress Dots
                progressIndicator
                    .padding(.bottom, 40)
            }
            .padding(.horizontal, 20)
        }
        .fullScreenCover(isPresented: $showWelcome) {
            HomeView()
                .transition(.opacity.combined(with: .scale))
        }
        .onAppear {
            startStepAnimations()
            orbGlow = true
            orbRotation = 360
        }
    }
}

//
// MARK: - Step Content
//

private extension TutorialView {

    var stepContent: some View {
        let step = steps[currentIndex]

        return VStack(spacing: 24) {

            if showTitle {
                Text(step.title)
                    .font(.largeTitle.bold())
                    .foregroundStyle(
                        LinearGradient(colors: [.white, .white, .white],
                                       startPoint: .top,
                                       endPoint: .bottom)
                    )
                    .multilineTextAlignment(.center)
                    .shadow(color: .white, radius: 10, y: 4)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            if showText {
                Text(step.text)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 36)
                    .transition(.opacity.combined(with: .scale))
            }

            if showHint {
                Text("Tap to continue")
                    .font(.headline.bold())
                    .foregroundColor(.white)
                    .opacity(showHint ? 1 : 0.3)
                    .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true),
                               value: showHint)
            }
        }
        .onTapGesture { nextStep() }
    }

    var finishedContent: some View {
        VStack(spacing: 20) {
            Text("You're ready!")
                .font(.system(size: 48, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(colors: [.white, .white, .white],
                                   startPoint: .top,
                                   endPoint: .bottom)
                )
                .shadow(color: .orange.opacity(0.7), radius: 15)

            Text("Tap to begin your journey.")
                .font(.title.weight(.bold))
                .foregroundColor(.white.opacity(0.85))
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.5)) {
                showWelcome = true
            }
        }
    }
}

//
// MARK: - Background Layer PRO
//

private extension TutorialView {
    var backgroundLayer: some View {
        ZStack {

            // Glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.black, .blue, .black],
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
                .shadow(color: .blue, radius: 20)

            // Rotating Energy Ring (FIXED)
            Circle()
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [.black, .blue, .black]),
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
                .foregroundStyle(.cyan)
        }
        .onAppear {
            orbGlow = true
            orbRotation = 360
        }
    }
}

//
// MARK: - Progress Indicator
//

private extension TutorialView {
    var progressIndicator: some View {
        HStack(spacing: 10) {
            ForEach(0..<steps.count, id: \.self) { index in
                let isActive = index == currentIndex

                Circle()
                    .fill(isActive ?
                          AnyShapeStyle(LinearGradient(colors: [.black, .blue, .black],
                                                       startPoint: .topLeading,
                                                       endPoint: .bottomTrailing))
                          :
                          AnyShapeStyle(Color.white.opacity(0.25))
                    )
                    .frame(width: isActive ? 14 : 8,
                           height: isActive ? 14 : 8)
                    .shadow(color: isActive ? .cyan.opacity(0.6) : .clear, radius: 6)
                    .scaleEffect(isActive ? 1.3 : 1.0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8),
                               value: currentIndex)
            }
        }
    }
}

//
// MARK: - Step Transition
//

private extension TutorialView {

    func startStepAnimations() {
        withAnimation(.easeOut(duration: 0.8)) { showTitle = true }
        withAnimation(.easeOut(duration: 1.0).delay(0.3)) { showText = true }
        withAnimation(.easeIn(duration: 1.5).delay(1.0)) { showHint = true }
    }

    func nextStep() {
        showTitle = false
        showText = false
        showHint = false

        withAnimation(.easeInOut(duration: 0.3)) {
            currentIndex += 1
        }

        guard currentIndex < steps.count else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            startStepAnimations()
        }
    }
}

#Preview {
    TutorialView()
        .preferredColorScheme(.dark)
}
