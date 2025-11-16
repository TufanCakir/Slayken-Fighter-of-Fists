//
//  EquipmentSelectModal.swift
//

import SwiftUI

struct EquipmentSelectModal: View {

    let slot: String
    let items: [EventShopItem]
    let onSelect: (EventShopItem) -> Void

    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {

                if items.isEmpty {
                    Text("Keine Ausrüstung für diesen Slot.")
                        .foregroundColor(.gray)
                        .padding()
                }

                ForEach(items) { item in
                    HStack {
                        Image(item.id)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                            .padding(6)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.name)
                                .font(.headline)

                            Text(item.description)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }

                        Spacer()

                        Button("Ausrüsten") {
                            onSelect(item)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .navigationTitle("\(slot.capitalized) auswählen")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Schließen") { dismiss() }
                }
            }
        }
    }
}
