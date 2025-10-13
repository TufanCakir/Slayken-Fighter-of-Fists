import Foundation

struct Event: Identifiable, Codable {
    let id: Int
    let name: String
    let description: String
    let bossId: String
    let image: String
}
