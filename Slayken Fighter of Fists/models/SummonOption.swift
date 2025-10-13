import SwiftUI

struct SummonOption: Identifiable, Codable {
    let id: String
    let title: String
    let crystal: Int
    let type: String
    let icon: String
    let iconColor: String
    let colorStart: String
    let colorMiddle: String
    let colorEnd: String

    var gradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(hex: colorStart),
                Color(hex: colorMiddle),
                Color(hex: colorEnd)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var iconColorValue: Color {
        Color(hex: iconColor)
    }
}
