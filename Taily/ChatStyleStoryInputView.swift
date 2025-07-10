import SwiftUI

struct ChatStyleStoryInputView: View {
    @StateObject private var storyGenerator = StoryGenerator()
    @StateObject private var profileManager = ChildProfileManager()
    @State private var inputText = ""
    @State private var selectedLength = StoryLength.short
    @State private var showingStoryView = false
    @State private var showingProfilePicker = false
    @State private var mentionedProfile: ChildProfile?
    @State private var cursorPosition = 0

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Check if profiles exist, show creation prompt if empty
                if profileManager.isEmpty {
                    createProfilePrompt
                } else {
                    mainContent
                }
            }
            .navigationBarHidden(true)
            .animation(.easeInOut(duration: 0.3), value: showingProfilePicker)
            .animation(.easeInOut(duration: 0.3), value: inputText.isEmpty)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .navigationDestination(isPresented: $showingStoryView) {
            if let profile = mentionedProfile {
                StoryView(
                    storyGenerator: storyGenerator,
                    parameters: createStoryParameters(for: profile)
                )
            }
        }
    }

    private var createProfilePrompt: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 24) {
                // Icon
                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)

                // Title and description
                VStack(spacing: 16) {
                    Text("Create Your First Child Profile")
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text("Tell us about your little one to create personalized bedtime stories just for them!")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                // Create profile button
                NavigationLink(destination: ChildProfileView(profileManager: profileManager)) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Create Child Profile")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(Color.blue)
                    .cornerRadius(25)
                }
            }

            Spacer()
            Spacer()
        }
        .padding()
    }

    private var mainContent: some View {
        VStack(spacing: 0) {
            // Main content area
            ScrollView {
                    VStack(spacing: 32) {
                        // Welcome header
                        VStack(spacing: 16) {
                            Text("✨ Taily")
                                .font(.system(size: 42, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)

                            Text("Your magical bedtime story companion")
                                .font(.title3)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 40)

                        Spacer(minLength: 100)

                        // Recent stories or suggestions could go here
                        if !profileManager.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Quick suggestions:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.leading, 4)

                                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 8) {
                                    ForEach(quickSuggestions, id: \.self) { suggestion in
                                        Button(action: {
                                            inputText = suggestion
                                            handleInputChange(suggestion)
                                        }) {
                                            Text(suggestion)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 8)
                                                .background(Color(.systemGray6))
                                                .cornerRadius(16)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                }

                // Input area
                VStack(spacing: 16) {
                    // Length selection chips
                    if !inputText.isEmpty {
                        HStack(spacing: 12) {
                            Text("Length:")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            ForEach(StoryLength.allCases, id: \.self) { length in
                                Button(action: {
                                    selectedLength = length
                                }) {
                                    HStack(spacing: 4) {
                                        Text(length.rawValue)
                                        Text(length.description)
                                            .font(.caption2)
                                    }
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(selectedLength == length ? .white : .primary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(selectedLength == length ? Color.blue : Color(.systemGray6))
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                .animation(.spring(response: 0.3), value: selectedLength)
                            }

                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    // Main input area
                    HStack(spacing: 12) {
                        HStack(spacing: 8) {
                            TextField("Generate a bedtime story for...", text: $inputText, axis: .vertical)
                                .textFieldStyle(PlainTextFieldStyle())
                                .font(.body)
                                .lineLimit(1...4)
                                .onChange(of: inputText) { _, newValue in
                                    handleInputChange(newValue)
                                }

                            if !inputText.isEmpty {
                                Button(action: {
                                    inputText = ""
                                    mentionedProfile = nil
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color(.systemGray6))
                        )

                        Button(action: generateStory) {
                            Image(systemName: storyGenerator.isGenerating ? "stop.fill" : "arrow.up")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(
                                    Circle()
                                        .fill(canGenerateStory ? Color.blue : Color.gray)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(!canGenerateStory)
                        .animation(.spring(response: 0.3), value: canGenerateStory)
                    }
                    .padding(.horizontal, 20)

                    // Profile picker
                    if showingProfilePicker {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Select a child:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.leading, 4)

                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 8) {
                                ForEach(profileManager.profiles) { profile in
                                    Button(action: {
                                        selectProfile(profile)
                                    }) {
                                        HStack {
                                            Text(profile.name)
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                            Spacer()
                                            Text(profile.ageGroup.rawValue)
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(12)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }

                            Button("+ Add new child") {
                                // Handle adding new child
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 4)
                        }
                        .padding(.horizontal, 20)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .padding(.bottom, 20)
                .background(Color(.systemBackground))
        }
    }

    private var quickSuggestions: [String] {
        guard !profileManager.isEmpty else { return [] }

        let profiles = profileManager.profiles.prefix(2)
        return profiles.flatMap { profile in
            [
                "Generate a bedtime story for @\(profile.name) about a magical adventure",
                "Create a story for @\(profile.name) with friendly animals"
            ]
        }
    }

    private var canGenerateStory: Bool {
        !inputText.isEmpty && mentionedProfile != nil && !storyGenerator.isGenerating
    }

    private func handleInputChange(_ newValue: String) {
        // Check for @ mentions anywhere in the text
        let words = newValue.components(separatedBy: " ")

        // Find any word that starts with @
        if let mentionWord = words.first(where: { $0.hasPrefix("@") }) {
            let nameQuery = String(mentionWord.dropFirst())

            // Try to find a matching profile
            if let profile = profileManager.profiles.first(where: { $0.name.lowercased() == nameQuery.lowercased() }) {
                mentionedProfile = profile
                showingProfilePicker = false
                return
            }

            // If no exact match, check for partial matches
            if !nameQuery.isEmpty {
                if let profile = profileManager.profiles.first(where: { $0.name.lowercased().hasPrefix(nameQuery.lowercased()) }) {
                    mentionedProfile = profile
                    showingProfilePicker = false
                    return
                }
            }

            // Show picker if we have an @ but no match
            if nameQuery.isEmpty {
                showingProfilePicker = true
            }
        } else {
            // No @ mention found, clear the mentioned profile
            mentionedProfile = nil
            showingProfilePicker = false
        }
    }

    private func selectProfile(_ profile: ChildProfile) {
        // Replace the @ mention with the profile name
        let words = inputText.components(separatedBy: " ")
        if let atIndex = words.firstIndex(where: { $0.hasPrefix("@") }) {
            var newWords = words
            newWords[atIndex] = "@\(profile.name)"
            inputText = newWords.joined(separator: " ")
        } else {
            inputText += " @\(profile.name)"
        }

        mentionedProfile = profile
        showingProfilePicker = false
    }

    private func generateStory() {
        guard let profile = mentionedProfile else { return }

        showingStoryView = true

        Task {
            await storyGenerator.generateStory(with: createStoryParameters(for: profile))
        }
    }

    private func createStoryParameters(for profile: ChildProfile) -> StoryParameters {
        // Extract the story description (everything that's not the @mention)
        let cleanDescription = inputText.replacingOccurrences(of: "@\(profile.name)", with: "").trimmingCharacters(in: .whitespacesAndNewlines)

        // Try to detect setting from user input
        let detectedSetting = detectStorySettingFromInput(cleanDescription)

        return StoryParameters(
            from: profile,
            customLength: selectedLength,
            customNotes: cleanDescription,
            overrideSetting: detectedSetting
        )
    }

    private func detectStorySettingFromInput(_ input: String) -> StorySetting? {
        let lowercaseInput = input.lowercased()

        // Define keywords for each setting
        let settingKeywords: [StorySetting: [String]] = [
            .city: ["city", "town", "urban", "street", "building", "skyscraper", "downtown", "metropolis", "neighborhood"],
            .forest: ["forest", "woods", "trees", "woodland", "jungle", "rainforest"],
            .ocean: ["ocean", "sea", "underwater", "beach", "waves", "marine", "aquatic", "submarine"],
            .space: ["space", "planet", "rocket", "alien", "galaxy", "star", "astronaut", "cosmic"],
            .castle: ["castle", "kingdom", "royal", "princess", "prince", "knight", "medieval", "palace"],
            .jungle: ["jungle", "safari", "tropical", "vine", "expedition", "adventure"],
            .farm: ["farm", "barn", "tractor", "animals", "countryside", "rural", "harvest"],
            .mountain: ["mountain", "peak", "climb", "cave", "hiking", "alpine", "summit"]
        ]

        // Check each setting's keywords
        for (setting, keywords) in settingKeywords {
            if keywords.contains(where: { lowercaseInput.contains($0) }) {
                return setting
            }
        }

        return nil
    }
}

#Preview {
    ChatStyleStoryInputView()
}
