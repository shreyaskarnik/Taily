import SwiftUI
import Lottie

struct StoryInputView: View {
    @StateObject private var storyGenerator = StoryGenerator()
    @StateObject private var profileManager = ChildProfileManager()
    @State private var useProfile = true
    @State private var childName = ""
    @State private var selectedAgeGroup = AgeGroup.preschool
    @State private var selectedGender: ChildGender? = nil
    @State private var storyDescription = ""
    @State private var selectedLength = StoryLength.short
    @State private var showingStoryView = false
    @State private var showingProfileManager = false
    @State private var showingProfileCreatedAlert = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    // Welcome Header
                    VStack(spacing: 8) {
                        HStack {
                            Text("✨")
                                .font(.system(size: 40))
                            Text("Let's make bedtime extra special!")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.purple)
                            Text("✨")
                                .font(.system(size: 40))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.purple.opacity(0.1))
                    )

                    // Profile Selection Section
                    if !profileManager.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("👨‍👩‍👧‍👦")
                                    .font(.title2)
                                Text("Choose a child profile")
                                    .font(.headline)
                                    .foregroundColor(.purple)

                                Spacer()

                                Button("Manage") {
                                    showingProfileManager = true
                                }
                                .font(.caption)
                                .foregroundColor(.blue)
                            }

                            Toggle("Use saved profile", isOn: $useProfile)
                                .onChange(of: useProfile) {
                                    updateFromProfile()
                                }

                            if useProfile {
                                if let selectedProfile = profileManager.selectedProfile {
                                    ProfileSummaryCard(profile: selectedProfile)

                                    HStack {
                                        Text("Select different profile:")
                                            .font(.caption)
                                            .foregroundColor(.secondary)

                                        Picker("Profile", selection: Binding(
                                            get: { profileManager.selectedProfile?.id ?? UUID() },
                                            set: { id in
                                                if let profile = profileManager.profile(withId: id) {
                                                    profileManager.selectProfile(profile)
                                                    updateFromProfile()
                                                }
                                            }
                                        )) {
                                            ForEach(profileManager.profiles) { profile in
                                                Text(profile.name).tag(profile.id)
                                            }
                                        }
                                        .pickerStyle(MenuPickerStyle())
                                    }
                                } else {
                                    Text("No profile selected")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.purple.opacity(0.1))
                        )
                    }

                    // Child Information Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("👶")
                                .font(.title2)
                            Text(useProfile && profileManager.selectedProfile != nil ? "Story customization" : "Who's the star of this story?")
                                .font(.headline)
                                .foregroundColor(.blue)

                            if profileManager.isEmpty || !useProfile {
                                Spacer()
                                Button(action: {
                                    createProfileFromCurrentInput()
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "person.badge.plus")
                                            .font(.caption2)
                                        Text("Save as Profile")
                                    }
                                }
                                .font(.caption)
                                .foregroundColor(.blue)
                                .disabled(childName.isEmpty)
                            }
                        }

                        if !useProfile || profileManager.selectedProfile == nil {
                            TextField("Enter your child's name", text: $childName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .font(.title3)
                        }

                        if !useProfile || profileManager.selectedProfile == nil {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("How old are they?")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                Picker("Age Group", selection: $selectedAgeGroup) {
                                    ForEach(AgeGroup.allCases, id: \.self) { age in
                                        Text(age.rawValue).tag(age)
                                    }
                                }
                                .pickerStyle(SegmentedPickerStyle())
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Would you like to specify gender? (Optional)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                Picker("Gender", selection: $selectedGender) {
                                    Text("Not specified").tag(nil as ChildGender?)
                                    ForEach(ChildGender.allCases, id: \.self) { gender in
                                        Text(gender.displayName).tag(gender as ChildGender?)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())

                                if let selectedGender = selectedGender {
                                    Text("Will use \(selectedGender.pronouns) pronouns")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.top, 2)
                                } else {
                                    Text("Will use they/them pronouns")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.top, 2)
                                }
                            }
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.blue.opacity(0.05))
                    )

                    // Story Description Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("✨")
                                .font(.title2)
                            Text("What story would you like?")
                                .font(.headline)
                                .foregroundColor(.blue)
                        }

                        Text("Tell us about the story you'd like to create")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Examples:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fontWeight(.medium)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("• \"A brave little girl who helps forest animals\"")
                                Text("• \"An adventure in space with friendly robots\"")
                                Text("• \"A magical unicorn who teaches about kindness\"")
                                Text("• \"A pirate who finds treasure and learns to share\"")
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                            .italic()
                        }
                        .padding(12)
                        .background(Color.blue.opacity(0.05))
                        .cornerRadius(8)

                        VStack(alignment: .leading, spacing: 8) {
                            TextEditor(text: $storyDescription)
                                .frame(minHeight: 100)
                                .padding(12)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                                )

                            if storyDescription.isEmpty {
                                Text("Describe the story you'd like to create for \(useProfile && profileManager.selectedProfile != nil ? profileManager.selectedProfile!.name : (childName.isEmpty ? "your child" : childName))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 4)
                            }
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Story Length")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Picker("Length", selection: $selectedLength) {
                                ForEach(StoryLength.allCases, id: \.self) { length in
                                    Text(length.rawValue).tag(length)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())

                            Text(selectedLength.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.blue.opacity(0.05))
                    )

                    // Create Story Button
                    Button(action: generateStory) {
                        HStack(spacing: 12) {
                            if storyGenerator.isGenerating {
                                LottieView(animation: .named("curious_dog"))
                                    .playing(loopMode: .loop)
                                    .animationSpeed(1.2)
                                    .frame(width: 20, height: 20)
                            } else {
                                Text("📚")
                                    .font(.title2)
                            }
                            Text(storyGenerator.isGenerating ? "Creating Your Story..." : "Create My Bedtime Story!")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(
                            LinearGradient(
                                colors: canGenerateStory ? [.blue, .purple] : [.gray, .gray],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .shadow(color: canGenerateStory ? .blue.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
                    }
                    .disabled(!canGenerateStory || storyGenerator.isGenerating)
                    .scaleEffect(canGenerateStory ? 1.0 : 0.95)
                    .animation(.easeInOut(duration: 0.2), value: canGenerateStory)
                }
                .padding(20)
            }
            .navigationTitle("Create Story")
            .navigationBarTitleDisplayMode(.large)
            .alert("Error", isPresented: .constant(storyGenerator.errorMessage != nil)) {
                Button("OK") {
                    storyGenerator.errorMessage = nil
                }
            } message: {
                Text(storyGenerator.errorMessage ?? "")
            }
            .alert("Profile Created!", isPresented: $showingProfileCreatedAlert) {
                Button("OK") { }
            } message: {
                Text("Profile for \(childName) has been saved! You can now easily create stories with their preferences.")
            }
            .sheet(isPresented: $showingStoryView) {
                StoryView(
                    storyGenerator: storyGenerator,
                    parameters: currentStoryParameters
                )
            }
            .sheet(isPresented: $showingProfileManager) {
                ChildProfileView(profileManager: profileManager)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            // If profiles exist but none is selected, select the first one
            if !profileManager.isEmpty && profileManager.selectedProfile == nil {
                profileManager.selectProfile(profileManager.profiles.first!)
            }
            updateFromProfile()
        }
    }

    private var canGenerateStory: Bool {
        if useProfile {
            // If using profile mode, we need either a selected profile OR fall back to manual input
            if let _ = profileManager.selectedProfile {
                return !storyDescription.isEmpty
            } else if !profileManager.isEmpty {
                // Profiles exist but none selected - should not happen in normal flow
                return false
            } else {
                // No profiles exist, fall back to manual input
                return !childName.isEmpty && !storyDescription.isEmpty
            }
        } else {
            // Manual input mode
            return !childName.isEmpty && !storyDescription.isEmpty
        }
    }

    private var currentStoryParameters: StoryParameters {
        if useProfile, let profile = profileManager.selectedProfile {
            return StoryParameters(
                from: profile,
                customLength: selectedLength,
                customNotes: storyDescription
            )
        } else {
            return StoryParameters(
                childName: childName,
                ageGroup: selectedAgeGroup,
                gender: selectedGender,
                values: [],
                themes: [],
                setting: .forest,
                tone: .calming,
                length: selectedLength,
                customNotes: storyDescription
            )
        }
    }

    private func generateStory() {
        // Immediately show the story view when generation starts
        showingStoryView = true

        // Start story generation in the background
        Task {
            await storyGenerator.generateStory(with: currentStoryParameters)
        }
    }


    private func updateFromProfile() {
        guard useProfile, let profile = profileManager.selectedProfile else { return }

        // Pre-fill length preference
        if let preferredLength = profile.preferredLength {
            selectedLength = preferredLength
        }
    }

    private func createProfileFromCurrentInput() {
        // Create a new profile with current input values
        let newProfile = ChildProfile(
            name: childName,
            ageGroup: selectedAgeGroup,
            gender: selectedGender,
            favoriteValues: [],
            favoriteThemes: [],
            preferredSetting: nil,
            preferredTone: nil,
            preferredLength: selectedLength,
            customNotes: storyDescription
        )

        profileManager.addProfile(newProfile)

        // Switch to using the newly created profile
        useProfile = true

        // Show success feedback
        showingProfileCreatedAlert = true
    }
}

// MARK: - Profile Summary Card

struct ProfileSummaryCard: View {
    let profile: ChildProfile

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(profile.name)
                    .font(.title3)
                    .fontWeight(.semibold)

                Spacer()

                Text(profile.ageGroup.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
            }

            if let gender = profile.gender {
                Text(gender.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if !profile.customNotes.isEmpty {
                Text("\"" + profile.customNotes + "\"")
                    .font(.caption)
                    .foregroundColor(.purple)
                    .italic()
                    .padding(.top, 4)
            }

            if !profile.favoriteThemes.isEmpty {
                HStack {
                    Text("Loves:")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    ForEach(profile.favoriteThemes.prefix(3), id: \.self) { theme in
                        Text(theme.rawValue)
                            .font(.caption2)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.2))
                            .foregroundColor(.green)
                            .cornerRadius(4)
                    }

                    if profile.favoriteThemes.count > 3 {
                        Text("+\(profile.favoriteThemes.count - 3) more")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 2)
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.purple.opacity(0.3), lineWidth: 1)
        )
    }
}


// MARK: - Reusable Chip

struct SelectableChip<T: Hashable & RawRepresentable>: View where T.RawValue == String {
    let option: T
    @Binding var selection: Set<T>

    var body: some View {
        let isSelected = selection.contains(option)
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                if isSelected {
                    selection.remove(option)
                } else {
                    selection.insert(option)
                }
            }
        } label: {
            HStack(spacing: 4) {
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.white)
                }
                Text(option.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        isSelected
                        ? LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
                        : LinearGradient(colors: [Color.gray.opacity(0.1)], startPoint: .leading, endPoint: .trailing)
                    )
            )
            .foregroundColor(isSelected ? .white : .primary)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        isSelected ? Color.clear : Color.gray.opacity(0.3),
                        lineWidth: 1
                    )
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .shadow(
                color: isSelected ? .blue.opacity(0.3) : .clear,
                radius: isSelected ? 4 : 0,
                x: 0,
                y: 2
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}


struct WrapLayout<T: Hashable, Content: View>: View {
    let items: [T]
    let spacing: CGFloat
    let content: (T) -> Content

    var body: some View {
        GeometryReader { geometry in
            createContent(in: geometry.size.width)
        }
    }

    private func createContent(in width: CGFloat) -> some View {
        var rows: [[T]] = []
        var currentRow: [T] = []

        // Simple approach: estimate item width for wrapping
        let estimatedItemWidth: CGFloat = 100 // Rough estimate for chip width
        let itemsPerRow = max(1, Int(width / estimatedItemWidth))

        // Group items into rows
        for (index, item) in items.enumerated() {
            if index > 0 && index % itemsPerRow == 0 {
                rows.append(currentRow)
                currentRow = [item]
            } else {
                currentRow.append(item)
            }
        }

        if !currentRow.isEmpty {
            rows.append(currentRow)
        }

        return VStack(alignment: .leading, spacing: spacing) {
            ForEach(Array(rows.enumerated()), id: \.offset) { rowIndex, row in
                HStack(spacing: spacing) {
                    ForEach(row, id: \.self) { item in
                        content(item)
                    }
                    Spacer()
                }
            }
        }
    }
}


#Preview {
    StoryInputView()
}
