//
//  InventoryManager.swift
//  Slayken Fighter of Fists
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class InventoryManager: ObservableObject {

    // MARK: - Singleton
    static let shared = InventoryManager()

    // MARK: - Published Saved Data
    @Published private(set) var ownedItems: Set<String> = []          // Gespeicherte IDs
    @Published private(set) var materials: [String: Int] = [:]        // z.B. event_core, void_fragment

    // MARK: - Voll aufgelöste Item-Daten (geladen von EventShopManager)
    private var allEquipmentItems: [String: EventShopItem] = [:]

    private init() {
        load()
    }

    // MARK: - Vom Shop-Manager aufgerufen
    func registerEquipmentItems(_ items: [EventShopItem]) {
        allEquipmentItems = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })
        print("📦 Inventory hat \(allEquipmentItems.count) Equipment-Items registriert")
        objectWillChange.send()
    }

    // MARK: - Item ins Inventar legen
    func addItem(_ id: String) {

        guard !ownedItems.contains(id) else {
            print("⚠️ Item \(id) gehört dir bereits")
            return
        }

        guard allEquipmentItems[id] != nil else {
            print("❌ FEHLER: addItem(\(id)) → ID NICHT in allEquipmentItems!")
            return
        }

        ownedItems.insert(id)
        save()
        objectWillChange.send()

        print("🟢 Item hinzugefügt: \(id)")
    }

    func owns(_ id: String) -> Bool {
        ownedItems.contains(id)
    }

    func reset() {
        ownedItems.removeAll()
        materials.removeAll()

        UserDefaults.standard.removeObject(forKey: "owned_items")
        UserDefaults.standard.removeObject(forKey: "materials")

        print("🔄 InventoryManager reset! Alle Items & Materialien gelöscht.")
        objectWillChange.send()
    }

    // MARK: - Rückgabe fertiger EquipmentObjekte
    var ownedEquipment: [EventShopItem] {
        let items = ownedItems.compactMap { allEquipmentItems[$0] }
        print("📦 ownedEquipment = \(items.count) Items")
        return items
    }

    // MARK: - Materialien
    func addMaterial(_ id: String, amount: Int = 1) {
        materials[id, default: 0] += amount
        save()
        objectWillChange.send()

        print("🧱 Material \(id) +\(amount) → total: \(materials[id] ?? 0)")
    }
    
    var allEquipment: [String : EventShopItem] {
        allEquipmentItems
    }

    func materialCount(_ id: String) -> Int {
        materials[id, default: 0]
    }

    // MARK: - SAVE & LOAD
    private func save() {
        UserDefaults.standard.set(Array(ownedItems), forKey: "owned_items")
        UserDefaults.standard.set(materials, forKey: "materials")
    }

    private func load() {
        if let saved = UserDefaults.standard.array(forKey: "owned_items") as? [String] {
            ownedItems = Set(saved)
        }
        if let saved = UserDefaults.standard.dictionary(forKey: "materials") as? [String: Int] {
            materials = saved
        }

        print("📥 Inventory geladen → \(ownedItems.count) items, \(materials.count) materials")
    }
    
    func debugInventory() {
        print("------ DEBUG INVENTORY ------")
        print("Owned IDs:", ownedItems)

        print("Equipment IDs:", allEquipmentItems.keys)
        
        let found = ownedItems.compactMap { allEquipmentItems[$0] }
        print("Found Items:", found.count)
    }

}

