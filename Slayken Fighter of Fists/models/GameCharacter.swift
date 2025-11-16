//
//  GameCharacter.swift
//  Slayken Fighter of Fists
//
//  Created by Tufan Cakir on 2025-10-30.
//

import Foundation

// MARK: - Hauptmodell für Charaktere
struct GameCharacter: Identifiable, Codable, Hashable {
    // 🔹 Basisdaten
    var id: String
    var name: String
    var image: String
    var element: String
    var auraColor: String
    /// Equipment-Slots: weapon, armor, helmet, ring, etc.
     /// Beispiel: ["weapon": "berserker_blade"]
    var equipped: [String: String] = [:]



    // 🔹 Optische Daten
    var gradient: GradientColors
    var particle: ParticleEffect

    // 🔹 Kampf- & Skill-System
    var attack: Int
    var skillIDs: [String]
    var skills: [String]?

    // 🔹 Fortschritt & Levelsystem
    var level: Int
    var exp: Int
    var nextExp: Int {
        level * 100
    }

    // 🔹 Initializer mit Standardwerten
    init(
        id: String = UUID().uuidString,
        name: String,
        image: String,
        element: String,
        auraColor: String,
        gradient: GradientColors = GradientColors(top: "#000000", bottom: "#111111"),
        particle: ParticleEffect = ParticleEffect(type: "none", speed: 1.0, size: 5.0),
        attack: Int = 100,
        skillIDs: [String] = [],
        skills: [String]? = nil,
        level: Int = 1,
        exp: Int = 0,
        equipped: [String: String] = [:]
    ) {
        self.id = id
        self.name = name
        self.image = image
        self.element = element
        self.auraColor = auraColor
        self.gradient = gradient
        self.particle = particle
        self.attack = attack
        self.skillIDs = skillIDs
        self.skills = skills
        self.level = level
        self.exp = exp
        self.equipped = equipped
    }

    // 🔹 Kampfkraft basierend auf Level
    var power: Int {
        Int(Double(attack) * (1.0 + Double(level) * 0.12))
    }

    // 🔹 EXP hinzufügen + automatischer Levelaufstieg
    mutating func gainExp(_ amount: Int) {
        exp += amount
        while exp >= nextExp {
            exp -= nextExp
            level += 1
            print("🆙 \(name) hat Level \(level) erreicht!")
        }
    }
    
    // MARK: - Equatable & Hashable
    static func == (lhs: GameCharacter, rhs: GameCharacter) -> Bool {
        // Characters are considered equal if they share the same stable identifier
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        // Hash only by stable identifier to avoid requiring nested types to conform
        hasher.combine(id)
    }
}


// MARK: - Beispielcharakter (Fallback)
extension GameCharacter {
    static let example = GameCharacter(
        id: "character_1",
        name: "Sly",
        image: "character1",
        element: "fire",
        auraColor: "#FF4500",
        gradient: GradientColors(top: "#FF8000", bottom: "#400000"),
        particle: ParticleEffect(type: "burst", speed: 1.2, size: 6.0),
        attack: 100,
        skillIDs: [
            "skill_fire_001",
            "skill_fire_002",
            "skill_ice_001",
            "skill_void_001",
            "shadow_clone",
            "skill_tornado_001",
            "skill_nature_001",
            "skill_shadow_002",
            "skill_wind_001",
            "skill_water_001",
            "skill_beamstrike_001"
        ],
        skills: [
            "Inferno Punch",
            "Frost Kick",
            "Shadow Clone"
        ],
        level: 1,
        exp: 0,
        equipped: [:]
    )
}

