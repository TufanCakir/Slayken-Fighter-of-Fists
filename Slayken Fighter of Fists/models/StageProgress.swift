import Foundation

struct StageProgress: Identifiable, Codable {
    let id: Int
    var unlocked: Bool
    var completed: Bool
    var stars: Int
}
