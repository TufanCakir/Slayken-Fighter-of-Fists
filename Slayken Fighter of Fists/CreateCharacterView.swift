//
//  CreateCharacterView.swift
//  Slayken Fighter of Fists
//
//  Created by Tufan Cakir on 2025-10-31.
//

import SwiftUI

@MainActor
struct CreateCharacterView: View {
    // MARK: - Environment
    @EnvironmentObject private var characterManager: CharacterManager
    @Environment(\.dismiss) private var dismiss

    // MARK: - States
    @State private var selectedElement: String = "fire"
    @State private var selectedExtras: Set<String> = []
    @State private var selectedName: String = ""
    @State private var createdCharacter: GameCharacter?
    @State private var showResult = false
    @State private var imageScale: CGFloat = 0.9
    @FocusState private var nameFocused: Bool
    @State private var loadedSkills: [Skill] = []
    // MARK: - Orb
       @State private var orbGlow = false
       @State private var orbRotation = 0.0
    // MARK: - Elements
    private let elements: [String] = [
        "fire", "ice", "void", "thunder", "nature", "wind", "water", "shadow",
        "shadowclone", "tornado", "beamstrike"
    ]

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundLayer


                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        titleSection
                        nameInputSection
                        mainElementPicker
                        previewBox(for: selectedElement)
                        skillPreview
                        createButton
                    }
                    .padding(.bottom, 80)
                    .animation(.spring(response: 0.45, dampingFraction: 0.8), value: selectedElement)
                }
            }
            .navigationDestination(isPresented: $showResult) {
                CharacterOverView()
                    .environmentObject(characterManager)
            }
            .onAppear(perform: updateSkillPreview)
            .onChange(of: selectedElement) {
                updateSkillPreview()
            }
            .onChange(of: selectedExtras) {
                updateSkillPreview()
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Background Orb Layer
private extension CreateCharacterView {
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
                .animation(.linear(duration: 6).repeatForever(autoreverses: false), value: orbRotation)

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

//
// MARK: - Logik
//
private extension CreateCharacterView {
    func updateSkillPreview() {
        guard SkillManager.shared.isLoaded else { return }

        let combined = [selectedElement] + selectedExtras
        let allSkills = combined.flatMap { SkillManager.shared.getSkills(forElement: $0).prefix(3) }

        loadedSkills = Array(allSkills.prefix(12))
        print("🧩 Elemente: \(combined.joined(separator: ", ")) → \(loadedSkills.count) Skills geladen")
    }

    func createCharacter() {
        guard !selectedName.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        let skillIDs = loadedSkills.map(\.id)
        let newChar = GameCharacter(
            name: selectedName,
            image: previewImageName(for: selectedElement),
            element: selectedElement,
            auraColor: accentColor(for: selectedElement).toHexString(),
            gradient: gradient(for: selectedElement),
            particle: particle(for: selectedElement),
            skillIDs: skillIDs
        )

        characterManager.addCharacter(newChar)
        createdCharacter = newChar

        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            showResult = true
        }

        print("🎉 Neuer Charakter \(newChar.name) erstellt mit \(skillIDs.count) Skills.")
    }

    func toggleExtraElement(_ element: String) {
        if selectedExtras.contains(element) {
            selectedExtras.remove(element)
        } else if selectedExtras.count < 3 {
            selectedExtras.insert(element)
        }
        updateSkillPreview()
    }
}

//
// MARK: - UI-Sektionen
//
private extension CreateCharacterView {

    var titleSection: some View {
        VStack(spacing: 6) {
            Text("Create Your Hero")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(LinearGradient(colors: [.white, accentColor(for: selectedElement)],
                                                startPoint: .top, endPoint: .bottom))
                .shadow(color: accentColor(for: selectedElement).opacity(0.7), radius: 12)
            Text("Choose elements and skills to forge your legend.")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.top, 20)
    }

    var nameInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Hero Name")
                .font(.headline)
                .foregroundColor(.white.opacity(0.85))
            HStack {
                TextField("Enter name", text: $selectedName)
                    .focused($nameFocused)
                    .textInputAutocapitalization(.words)
                    .disableAutocorrection(true)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                    .foregroundColor(.white)
                if !selectedName.isEmpty {
                    Button { selectedName = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray.opacity(0.7))
                    }
                }
            }
        }
        .padding(.horizontal, 24)
    }

    var mainElementPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Main Element")
                .font(.headline)
                .foregroundColor(.white.opacity(0.85))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(elements, id: \.self) { e in
                        Button { withAnimation(.spring()) { selectedElement = e } } label: {
                            Text(e.capitalized)
                                .font(.subheadline.bold())
                                .padding(.vertical, 10)
                                .padding(.horizontal, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedElement == e ? accentColor(for: e) : .gray.opacity(0.3))
                                )
                                .foregroundColor(.white)
                                .shadow(color: selectedElement == e ? accentColor(for: e).opacity(0.7) : .clear, radius: 8)
                        }
                    }
                }.padding(.horizontal, 16)
            }
        }
    }

 
    // ⚔️ Skill-Vorschau mit Gruppen und Akkordeon
    var skillPreview: some View {
        VStack(spacing: 14) {
            Text("Available Skills")
                .font(.headline)
                .foregroundColor(.white.opacity(0.9))
            if loadedSkills.isEmpty {
                Text("Select elements to see available skills.")
                    .foregroundColor(.white.opacity(0.5))
                    .font(.subheadline)
                    .padding(.top, 6)
            } else {
                let grouped = Dictionary(grouping: loadedSkills, by: { $0.element })
                VStack(spacing: 12) {
                    ForEach(grouped.keys.sorted(), id: \.self) { element in
                        SkillGroupView(
                            element: element,
                            skills: grouped[element] ?? [],
                            accent: accentColor(for: element)
                        )
                    }
                }
                .padding(.horizontal, 20)
                .transition(.opacity.combined(with: .scale))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: loadedSkills.count)
    }

    var createButton: some View {
        Button(action: createCharacter) {
            Label("Create Character", systemImage: "sparkles")
                .font(.headline.bold())
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(colors: [accentColor(for: selectedElement),
                                            accentColor(for: selectedElement).opacity(0.7)],
                                   startPoint: .topLeading,
                                   endPoint: .bottomTrailing)
                )
                .cornerRadius(14)
                .shadow(color: accentColor(for: selectedElement).opacity(0.7), radius: 10, y: 4)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 24)
        .disabled(selectedName.trimmingCharacters(in: .whitespaces).isEmpty)
        .opacity(selectedName.isEmpty ? 0.5 : 1)
    }

    func previewBox(for element: String) -> some View {
        VStack(spacing: 12) {
            Text("Preview")
                .font(.headline)
                .foregroundColor(.white.opacity(0.8))
            ZStack {
                RoundedRectangle(cornerRadius: 22)
                    .fill(LinearGradient(colors: [accentColor(for: element).opacity(0.85),
                                                  .black.opacity(0.85)],
                                         startPoint: .topLeading,
                                         endPoint: .bottomTrailing))
                    .shadow(color: accentColor(for: element).opacity(0.6), radius: 12)
                    .frame(height: 220)
                VStack(spacing: 10) {
                    Image(previewImageName(for: element))
                        .resizable()
                        .scaledToFit()
                        .frame(height: 120)
                        .scaleEffect(imageScale)
                        .shadow(color: accentColor(for: element).opacity(0.7), radius: 10)
                        .onAppear { withAnimation(.easeInOut(duration: 0.6)) { imageScale = 1.0 } }
                    Text(element.capitalized)
                        .font(.title2.bold())
                        .foregroundColor(.white)
                        .shadow(color: accentColor(for: element), radius: 10)
                }
            }
            .padding(.horizontal, 24)
        }
    }
}

// MARK: - SkillGroupView
private struct SkillGroupView: View {
    let element: String
    let skills: [Skill]
    let accent: Color
    @State private var isExpanded = true

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) { isExpanded.toggle() }
            } label: {
                HStack {
                    LinearGradient(colors: [accent.opacity(0.9), accent.opacity(0.6)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                        .frame(width: 6)
                        .cornerRadius(3)
                    Text(element.capitalized)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.leading, 8)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                        .foregroundColor(accent.opacity(0.9))
                        .imageScale(.large)
                        .padding(.trailing, 6)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.black.opacity(0.25))
                .cornerRadius(12)
                .shadow(color: accent.opacity(0.5), radius: 6, y: 3)
            }

            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(skills, id: \.id) { skill in
                        HStack(alignment: .top, spacing: 8) {
                            Circle()
                                .fill(accent)
                                .frame(width: 10, height: 10)
                                .shadow(color: accent.opacity(0.8), radius: 5)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(skill.name)
                                    .font(.subheadline.bold())
                                    .foregroundColor(accent)
                                Text(skill.description)
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                                    .lineLimit(2)
                            }
                            Spacer()
                            Text("\(Int(skill.cooldown))s")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(8)
                    }
                }
                .padding(.top, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Farb- & Effektlogik
private extension CreateCharacterView {
    func accentColor(for element: String) -> Color {
        switch element {
        case "fire": return .orange
        case "ice": return .cyan
        case "void": return .purple
        case "thunder": return .yellow
        case "nature": return .green
        case "wind": return .mint
        case "water": return .blue
        case "shadow": return .indigo
        case "shadowclone": return Color(red: 0.4, green: 0.3, blue: 0.7)
        case "tornado": return Color(red: 0.7, green: 1.0, blue: 0.9)
        case "beamstrike": return Color(red: 1.0, green: 0.8, blue: 0.6)
        default: return .gray
        }
    }

    func gradient(for element: String) -> GradientColors {
        switch element {
        case "fire": return .init(top: "#FF8000", bottom: "#400000")
        case "ice": return .init(top: "#A0E8FF", bottom: "#002040")
        case "void": return .init(top: "#5A00A0", bottom: "#0C0018")
        case "thunder": return .init(top: "#FFF176", bottom: "#2B1A00")
        case "nature": return .init(top: "#33FF99", bottom: "#003300")
        case "wind": return .init(top: "#C2F2FF", bottom: "#002C33")
        case "water": return .init(top: "#33BFFF", bottom: "#001933")
        case "shadow": return .init(top: "#660099", bottom: "#000000")
        case "shadowclone": return .init(top: "#4A0072", bottom: "#000000")
        case "tornado": return .init(top: "#B2FFF5", bottom: "#003333")
        case "beamstrike": return .init(top: "#FFD6A3", bottom: "#3B1C00")
        default: return .init(top: "#222", bottom: "#000")
        }
    }

    func particle(for element: String) -> ParticleEffect {
        switch element {
        case "fire": return .init(type: "flame", speed: 1.2, size: 6.0)
        case "ice": return .init(type: "snow", speed: 0.6, size: 5.0)
        case "void": return .init(type: "dark", speed: 0.8, size: 7.0)
        case "thunder": return .init(type: "lightning", speed: 1.4, size: 6.0)
        case "nature": return .init(type: "leaf", speed: 0.7, size: 5.5)
        case "wind": return .init(type: "wind", speed: 1.0, size: 5.0)
        case "water": return .init(type: "wave", speed: 0.9, size: 5.5)
        case "shadow": return .init(type: "shadow", speed: 1.1, size: 7.0)
        case "shadowclone": return .init(type: "shadowclone", speed: 1.0, size: 7.5)
        case "tornado": return .init(type: "tornado", speed: 1.3, size: 8.0)
        case "beamstrike": return .init(type: "beamstrike", speed: 1.5, size: 9.0)
        default: return .init(type: "none", speed: 1.0, size: 5.0)
        }
    }

    func background(for element: String) -> LinearGradient {
        let g = gradient(for: element)
        return LinearGradient(colors: [Color(hex: g.top), Color(hex: g.bottom)],
                              startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    func previewImageName(for element: String) -> String {
        switch element {
        case "fire": return "character1"
        case "ice": return "character2"
        case "void": return "character3"
        case "thunder": return "character4"
        case "nature": return "character5"
        case "wind": return "character6"
        case "water": return "character7"
        case "shadow": return "character8"
        case "shadowclone": return "character9"
        case "tornado": return "character10"
        case "beamstrike": return "character11"
        default: return "character1"
        }
    }
}

#Preview {
    CreateCharacterView()
        .environmentObject(CharacterManager.shared)
        .preferredColorScheme(.dark)
}

