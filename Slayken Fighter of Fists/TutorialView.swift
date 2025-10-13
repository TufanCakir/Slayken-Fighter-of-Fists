import SwiftUI

struct TutorialView: View {
    @State private var steps: [TutorialStep] = Bundle.main.decode("tutorial.json")
    @State private var currentIndex = 0
    @State private var showText = false
    @State private var showTitle = false
    @State private var showHint = false
    @State private var showWelcome = false // 👈 Neu
    
    // MARK: - Helpers
    private func dotFill(for isActive: Bool) -> AnyShapeStyle {
        if isActive {
            return AnyShapeStyle(
                LinearGradient(colors: [.black, .blue, .black],
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing)
            )
        } else {
            return AnyShapeStyle(Color.white.opacity(0.25))
        }
    }
    
    var body: some View {
        ZStack {
            // MARK: - Hintergrund
            LinearGradient(colors: [.black, .blue, .black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .overlay(
                RadialGradient(colors: [.orange.opacity(0.15), .clear],
                               center: .center,
                               startRadius: 50,
                               endRadius: 450)
                    .blur(radius: 120)
            )
            
            VStack(spacing: 40) {
                Spacer(minLength: 60)
                
                // MARK: - Inhalt
                if currentIndex < steps.count {
                    let step = steps[currentIndex]
                    
                    VStack(spacing: 24) {
                        if showTitle {
                            Text(step.title)
                                .font(.largeTitle.bold())
                                .foregroundStyle(LinearGradient(colors: [.orange, .red, .orange],
                                                                startPoint: .top,
                                                                endPoint: .bottom))
                                .multilineTextAlignment(.center)
                                .shadow(color: .orange.opacity(0.6), radius: 8, y: 4)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                        
                        if showText {
                            Text(step.text)
                                .font(.system(size: 20, weight: .bold, design: .rounded))                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                                .transition(.opacity.combined(with: .scale))
                        }
                        
                        if showHint {
                            Text("Tap to continue")
                                .font(.system(size: 20, weight: .bold, design: .rounded))                                                        .foregroundColor(.white.opacity(0.8))
                                .opacity(showHint ? 1 : 0.3)
                                .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true),
                                           value: showHint)
                                .padding(.top, 10)
                        }
                    }
                    .onAppear {
                        withAnimation(.easeOut(duration: 0.8)) { showTitle = true }
                        withAnimation(.easeOut(duration: 1.0).delay(0.3)) { showText = true }
                        withAnimation(.easeIn(duration: 1.5).delay(1.0)) { showHint = true }
                    }
                    .onTapGesture { nextStep() }
                } else {
                    // MARK: - Ende des Tutorials
                    VStack(spacing: 12) {
                        Text("You're ready!")
                            .font(.system(size: 50, weight: .bold, design: .rounded))
                            .foregroundStyle(LinearGradient(colors: [.orange, .red, .orange],
                                                            startPoint: .top,
                                                            endPoint: .bottom))
                            .shadow(color: .orange, radius: 10)
                        Text("Tap to begin your journey.")
                            .font(.system(size: 30, weight: .bold, design: .rounded))  
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            showWelcome = true // 👈 öffnet WelcomeView
                        }
                    }
                }
                
                Spacer()
                
                // MARK: - Fortschritts-Indikator
                progressIndicator
                
                Spacer(minLength: 40)
            }
        }
        .animation(.easeInOut, value: currentIndex)
        // 👇 Zeigt WelcomeView nach Abschluss des Tutorials
        .fullScreenCover(isPresented: $showWelcome) {
            WelcomeView()
                .transition(.opacity.combined(with: .scale))
        }
    }
    
    // MARK: - Fortschritts-Indikator (Dots)
    private var progressIndicator: some View {
        HStack(spacing: 10) {
            ForEach(0..<steps.count, id: \.self) { index in
                let isActive = index == currentIndex
                Circle()
                    .fill(dotFill(for: isActive))
                    .frame(width: isActive ? 14 : 8,
                           height: isActive ? 14 : 8)
                    .shadow(color: isActive ? Color.orange.opacity(0.6) : .clear, radius: 6)
                    .scaleEffect(isActive ? 1.2 : 1.0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8),
                               value: currentIndex)
            }
        }
    }
    
    // MARK: - Nächster Schritt
    private func nextStep() {
        showTitle = false
        showText = false
        showHint = false
        
        withAnimation(.easeInOut(duration: 0.3)) {
            currentIndex += 1
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            showTitle = true
            showText = true
            showHint = true
        }
    }
}

#Preview {
    TutorialView()
}
