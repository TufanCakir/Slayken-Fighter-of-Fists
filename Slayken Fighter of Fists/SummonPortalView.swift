//
//  SummonPortalView.swift
//  Slayken Fighter of Fists
//
//  Created by Tufan Cakir on 2025-11-15.
//

import SwiftUI

struct SummonPortalView: View {

    @State private var rotation: Double = 0
    @State private var ringScale: CGFloat = 0.2
    @State private var portalOpen: Bool = false
    @State private var glowPulse: Bool = false
    @State private var shockwave: Bool = false

    let onFinished: () -> Void

    var body: some View {
        ZStack {
            background

            ZStack {

                // Shockwave
                Circle()
                    .stroke(.cyan.opacity(0.8), lineWidth: 4)
                    .scaleEffect(shockwave ? 3.0 : 0.3)
                    .opacity(shockwave ? 0 : 0.5)
                    .blur(radius: 15)
                    .animation(.easeOut(duration: 1.2), value: shockwave)

                // Outer ring
                Circle()
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [.cyan, .blue, .cyan]),
                            center: .center
                        ),
                        lineWidth: 22
                    )
                    .rotationEffect(.degrees(rotation))
                    .blur(radius: 3)
                    .scaleEffect(ringScale)
                    .opacity(0.9)

                // Inner ring
                Circle()
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [.white, .cyan.opacity(0.6), .white]),
                            center: .center
                        ),
                        lineWidth: 10
                    )
                    .rotationEffect(.degrees(-rotation * 1.4))
                    .blur(radius: 1)
                    .scaleEffect(ringScale * 1.1)
                    .opacity(0.7)

                // Portal Glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.cyan.opacity(0.9), .blue.opacity(0.3), .clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: 180
                        )
                    )
                    .blur(radius: glowPulse ? 45 : 15)
                    .scaleEffect(portalOpen ? 1.4 : 0.2)
                    .animation(.easeInOut(duration: 1.2), value: portalOpen)
            }
            .frame(width: 300, height: 300)
        }
        .onAppear { startAnimation() }
    }
}

private extension SummonPortalView {

    var background: some View {
        LinearGradient(
            colors: [.black, .blue.opacity(0.4), .black],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    func startAnimation() {

        // Ring rotation
        withAnimation(.linear(duration: 5).repeatForever(autoreverses: false)) {
            rotation = 360
        }

        // Portal opens
        withAnimation(.easeOut(duration: 1.2)) {
            ringScale = 1.0
            portalOpen = true
        }

        // Glow pulse
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeInOut(duration: 1.3).repeatForever()) {
                glowPulse = true
            }
        }

        // Shockwave
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            shockwave = true
        }

        // Finish after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            onFinished()
        }
    }
}
