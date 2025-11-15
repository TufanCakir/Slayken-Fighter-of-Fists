import Foundation


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
}
