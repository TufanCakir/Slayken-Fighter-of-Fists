//
//  CreateCharacterView.swift
//  Slayken Fighter of Fists
//

import SwiftUI
import os

@MainActor
struct CreateCharacterView: View {

    // MARK: - Logger
    private let logger = Logger(subsystem: "Slayken", category: "CreateCharacterView")

    // MARK: - Environment
    @EnvironmentObject private var characterManager: CharacterManager
    @EnvironmentObject private var templateManager: CharacterTemplateManager
    @Environment(\.dismiss) private var dismiss

    // MARK: - State
    @State private var selectedTemplateID: String?
    @State private var selectedName: String = ""
    @State private var loadedSkills: [Skill] = []
    @State private var showResult = false

    @FocusState private var nameFocused: Bool
    @State private var imageScale: CGFloat = 0.9

    // Orb Animation
    @State private var orbGlow = false
    @State private var orbRotation = 0.0


    // MARK: - View
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundLayer
                    .ignoresSafeArea()
                
                contentScroll
            }
            .navigationDestination(isPresented: $showResult) {
                CharacterOverView()
                    .environmentObject(characterManager)
            }
            .onChange(of: selectedTemplateID) { oldValue, newValue in
                logger.info("Selected template changed from \(oldValue ?? "nil") to \(newValue ?? "nil")")
                updateSkillPreview()
            }
        }
        .preferredColorScheme(.dark)
        .onAppear(perform: logInitialState)
    }
}

// MARK: - Main Content
private extension CreateCharacterView {

    var contentScroll: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 32) {
                titleSection
                nameInputSection
                characterTemplatePicker
                previewBox
                skillPreview
                createButton
            }
            .padding(.bottom, 80)
        }
    }
}


// MARK: - Background
private extension CreateCharacterView {
        var backgroundLayer: some View {
            ZStack {

                // 🌑 DARK → BLUE → DARK Gradient
                LinearGradient(
                    colors: [
                        .black,
                        Color.white.opacity(0.3),
                        .black
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

            }
        }
    }

// MARK: - UI Sections
private extension CreateCharacterView {

    var titleSection: some View {
        VStack(spacing: 6) {
            Text("Create Your Hero")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.white)

            Text("Choose a template to forge your legend.")
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(.top, 16)
    }


    var nameInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {

            Text("Hero Name")
                .font(.headline)
                .foregroundColor(.white.opacity(0.85))

            HStack {
                TextField("Enter name", text: $selectedName)
                    .focused($nameFocused)
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                    .foregroundColor(.white)

                if !selectedName.isEmpty {
                    Button { selectedName = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
        }
        .padding(.horizontal, 24)
    }


    var characterTemplatePicker: some View {
        VStack(alignment: .leading, spacing: 12) {

            Text("Choose a Base Character")
                .font(.headline)
                .foregroundColor(.white.opacity(0.85))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {

                    ForEach(templateManager.templates) { template in
                        Button {
                            selectedTemplateID = template.id
                            selectedName = template.name
                            logger.info("Template tapped: \(template.id) - \(template.name)")
                        } label: {
                            templateCard(template)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }


    func templateCard(_ template: CharacterTemplate) -> some View {
        VStack(spacing: 8) {
            Image(template.image)
                .resizable()
                .scaledToFit()
                .frame(width: 90, height: 90)
                .cornerRadius(12)

            Text(template.name)
                .font(.caption)
                .foregroundColor(.white)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(selectedTemplateID == template.id ?
                      Color.white.opacity(0.18) :
                      Color.white.opacity(0.05))
        )
    }


    var previewBox: some View {
        VStack(spacing: 12) {

            Text("Preview")
                .font(.headline)
                .foregroundColor(.white.opacity(0.9))

            ZStack {
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color.black.opacity(0.55))
                    .frame(height: 240)

                if let id = selectedTemplateID,
                   let template = templateManager.template(id: id) {
                    VStack(spacing: 10) {
                        Image(template.image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 130)

                        Text(template.name)
                            .font(.title3.bold())
                            .foregroundColor(.white)
                    }
                } else {
                    Text("No Template Selected")
                        .foregroundColor(.white.opacity(0.4))
                }
            }
            .padding(.horizontal, 24)
        }
    }


    var skillPreview: some View {
        VStack(spacing: 14) {

            Text("Skills")
                .font(.headline)
                .foregroundColor(.white.opacity(0.95))

            if loadedSkills.isEmpty {
                Text("Select a character template to see skills.")
                    .foregroundColor(.white.opacity(0.5))
            } else {
                skillsList
            }
        }
    }


    var skillsList: some View {
        VStack(spacing: 10) {
            ForEach(loadedSkills) { skill in
                HStack {
                    Circle()
                        .fill(.blue)
                        .frame(width: 10, height: 10)

                    VStack(alignment: .leading) {
                        Text(skill.name).foregroundColor(.white)
                        Text(skill.description)
                            .foregroundColor(.white.opacity(0.5))
                            .font(.caption)
                    }

                    Spacer()

                    Text("\(Int(skill.cooldown))s")
                        .foregroundColor(.white.opacity(0.6))
                        .font(.caption2)
                }
                .padding(8)
                .background(Color.white.opacity(0.05))
                .cornerRadius(8)
            }
        }
        .padding(.horizontal, 20)
    }


    var createButton: some View {
        Button(action: createCharacter) {
            Label("Create Character", systemImage: "sparkles")
                .frame(maxWidth: .infinity)
                .padding()
                .background(.blue.opacity(0.7))
                .cornerRadius(14)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 24)
        .disabled(selectedTemplateID == nil || selectedName.isEmpty)
        .opacity(selectedTemplateID == nil || selectedName.isEmpty ? 0.45 : 1)
    }
}






// MARK: - Logic
private extension CreateCharacterView {

    func logInitialState() {
        logger.info("CreateCharacterView loaded")
        print("📘 CreateCharacterView geladen")

        let count = templateManager.templates.count
        logger.info("Loaded templates: \(count)")
        print("📁 Templates verfügbar: \(count)")

        templateManager.templates.forEach {
            print(" → ID:\($0.id) | Name:\($0.name) | Bild:\($0.image)")
        }
    }


    func updateSkillPreview() {
        guard let id = selectedTemplateID,
              let template = templateManager.template(id: id)
        else {
            logger.warning("SkillPreview → Template not found for id: \(selectedTemplateID ?? "nil")")
            loadedSkills = []
            return
        }

        logger.info("Loading skills for template: \(template.id)")

        loadedSkills = template.skillIDs.compactMap { sid in
            let skill = SkillManager.shared.skill(id: sid)

            if skill == nil {
                logger.error("Missing skill: \(sid)")
                print("❌ Skill fehlt im JSON: \(sid)")
            }

            return skill
        }
    }


    func createCharacter() {
        guard let id = selectedTemplateID,
              let template = templateManager.template(id: id) else {
            logger.error("createCharacter() → Template not found")
            return
        }

        logger.info("Creating character: \(selectedName) using \(template.id)")

        let newChar = GameCharacter(
            name: selectedName,
            image: template.image,
            element: template.element,
            auraColor: template.auraColor,
            gradient: template.gradient,
            particle: template.particle,
            skillIDs: template.skillIDs
        )

        characterManager.addCharacter(newChar)
        showResult = true
    }
}






#Preview {
    CreateCharacterView()
        .environmentObject(CharacterManager.shared)
        .environmentObject(CharacterTemplateManager.shared)
        .preferredColorScheme(.dark)
}

