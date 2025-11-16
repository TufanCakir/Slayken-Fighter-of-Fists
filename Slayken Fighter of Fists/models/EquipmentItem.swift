//
//  EquipmentItem.swift
//  Slayken Fighter of Fists
//

import Foundation

struct EquipmentItem: Identifiable, Codable {
    let id: String
    let name: String
    let type: String         // weapon, armor, accessory, etc.
    let rarity: String       // common, rare, epic, legendary
    let description: String

    let stats: Stats
}

struct Stats: Codable {
    let damageMultiplier: Double?
    let defenseBoost: Int?
    let dodgeChance: Int?
}
