import Foundation

struct Skill: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let type: String        // z. B. "damage", "heal", "buff"
    let element: String     // z. B. "fire", "ice", "void"
    let description: String
    let cooldown: TimeInterval

    // Optional, je nach Skilltyp
    let minDamage: Int?
    let maxDamage: Int?
    let healAmount: Int?

    // MARK: - Berechnete Properties
    var damageRange: ClosedRange<Int>? {
        guard let min = minDamage, let max = maxDamage else { return nil }
        return min...max
    }
}
