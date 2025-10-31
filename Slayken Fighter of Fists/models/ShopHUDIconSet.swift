import SwiftUI

struct ShopHUDIcon: Codable {
    let symbol: String
    let color: String
}

struct ShopHUDIconSet: Codable {
    let coin: ShopHUDIcon
    let crystal: ShopHUDIcon
    let level: ShopHUDIcon
}
