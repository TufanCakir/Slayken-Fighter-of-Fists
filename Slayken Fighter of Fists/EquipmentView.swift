//
//  EquipmentView.swift
//

import SwiftUI

struct EquipmentView: View {

    @EnvironmentObject var characterManager: CharacterManager
    @EnvironmentObject var inventoryManager: InventoryManager

    @State private var selectedSlot: String?
    @State private var showModal = false

    // ORB Animation
    @State private var orbGlow = false
    @State private var orbRotation = 0.0

    private let leftSlots = ["head", "shoulder", "chest", "hands", "legs"]
    private let rightSlots = ["weapon", "ring", "neck", "feet"]

    var body: some View {
        ZStack {
            
            // Hintergrund ORB + RING + ICON
            RotatingOrbView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()

            if let character = characterManager.activeCharacter {
                VStack(spacing: 22) {

                    // MARK: Charakter Name
                    Text(character.name)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))

                    // MARK: Ausrüstung Layout
                    HStack(alignment: .center, spacing: 20) {

                        // LEFT SIDE
                        VStack(spacing: 20) {
                            ForEach(leftSlots, id: \.self) { slot in
                                EquipmentSlotView(
                                    slot: slot,
                                    equippedItem: characterManager.equippedItem(for: slot),
                                    tapAction: { openSlot(slot) }
                                )
                            }
                        }

                        Spacer()

                        // CHARACTER IMAGE
                        Image(character.image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 130)
                            .shadow(color: .white.opacity(0.3), radius: 10)

                        Spacer()

                        // RIGHT SIDE
                        VStack(spacing: 20) {
                            ForEach(rightSlots, id: \.self) { slot in
                                EquipmentSlotView(
                                    slot: slot,
                                    equippedItem: characterManager.equippedItem(for: slot),
                                    tapAction: { openSlot(slot) }
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 24)

                    // Tipp
                    Text("Tippe auf einen Slot um Items auszurüsten.")
                        .foregroundColor(.white.opacity(0.6))
                        .font(.caption)
                        .padding(.top, 10)
                }
            }
        }
        .sheet(isPresented: $showModal) {
            EquipmentSelectModal(
                slot: selectedSlot ?? "",
                items: itemsForSlot(selectedSlot),
                onSelect: { item in
                    characterManager.equip(item)
                    showModal = false
                }
            )
        }
    }
}

// MARK: - Slot Handling
private extension EquipmentView {

    func openSlot(_ slot: String) {
        selectedSlot = slot
        showModal = true
    }

    func itemsForSlot(_ slot: String?) -> [EventShopItem] {
        guard let slot else { return [] }
        return inventoryManager.ownedEquipment.filter { $0.slot == slot }
    }
}

#Preview {
    let cm = CharacterManager.shared
    cm.activeCharacter = GameCharacter.example

    let im = InventoryManager.shared

    return EquipmentView()
        .environmentObject(cm)
        .environmentObject(im)
        .preferredColorScheme(.dark)
}
