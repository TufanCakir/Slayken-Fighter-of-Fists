// MARK: - InfoModalView

import SwiftUI

struct InfoModalView<Content: View>: View {
    let visible: Bool
    let onClose: () -> Void
    let content: Content

    init(visible: Bool, onClose: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.visible = visible
        self.onClose = onClose
        self.content = content()
    }

    var body: some View {
        if visible {
            ZStack {
                Color.black.opacity(0.8).ignoresSafeArea()
                LinearGradient(colors: [.black, .blue, .black],
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing)
                .ignoresSafeArea()
                .opacity(0.3)

                VStack(spacing: 18) {
                    content
                    Button("OK") { onClose() }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 34)
                        .background(Color.black)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue, lineWidth: 1.4)
                        )
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                }
                .padding(24)
                .background(Color.black.opacity(0.85))
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.blue, lineWidth: 2)
                )
                .shadow(color: .blue.opacity(0.4), radius: 20)
            }
            .transition(.opacity)
            .animation(.easeInOut, value: visible)
        }
    }
}
