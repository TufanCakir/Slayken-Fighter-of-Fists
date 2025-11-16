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
            backgroundLayer

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

// MARK: - Background Layer
private extension EquipmentView {
    var backgroundLayer: some View {
        ZStack {

            // Glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.black, .blue, .black],
                        center: .center,
                        startRadius: 15,
                        endRadius: 140
                    )
                )
                .scaleEffect(orbGlow ? 1.1 : 0.9)
                .blur(radius: 40)
                .animation(.easeInOut(duration: 1.3).repeatForever(), value: orbGlow)

            // Main Orb
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 180, height: 180)
                .shadow(color: .blue, radius: 20)

            // Rotating Energy Ring (FIXED)
            Circle()
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [.black, .blue, .black]),
                        center: .center
                    ),
                    lineWidth: 10
                )
                .frame(width: 230, height: 230)
                .blur(radius: 2)
                .rotationEffect(.degrees(orbRotation))
                .animation(.linear(duration: 3).repeatForever(autoreverses: false), value: orbRotation)

            Image(systemName: "sparkles")
                .font(.system(size: 55))
                .foregroundStyle(.cyan)
        }
        .onAppear {
            orbGlow = true
            orbRotation = 360
        }
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
