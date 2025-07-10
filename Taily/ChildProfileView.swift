import SwiftUI

struct ChildProfileView: View {
    @ObservedObject var profileManager: ChildProfileManager
    @State private var showingProfileEditor = false
    @State private var editingProfile: ChildProfile?
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if profileManager.isEmpty {
                    emptyProfilesView
                } else {
                    profilesListView
                }
            }
            .navigationTitle("Child Profiles")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarItems(
                leading: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button(action: {
                    editingProfile = nil
                    showingProfileEditor = true
                }) {
                    Image(systemName: "plus")
                }
            )
            .sheet(isPresented: $showingProfileEditor) {
                ProfileEditorView(
                    profile: editingProfile,
                    profileManager: profileManager
                )
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private var emptyProfilesView: some View {
        VStack(spacing: 30) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: 16) {
                Text("No Child Profiles")
                    .font(.title)
                    .fontWeight(.semibold)
                
                Text("Create profiles for your children to personalize their stories")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Button(action: {
                    editingProfile = nil
                    showingProfileEditor = true
                }) {
                    Label("Create First Profile", systemImage: "plus")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.top, 8)
            }
            
            Spacer()
        }
        .padding()
    }
    
    private var profilesListView: some View {
        List {
            ForEach(profileManager.profiles) { profile in
                ChildProfileRow(
                    profile: profile,
                    isSelected: profileManager.selectedProfile?.id == profile.id,
                    onSelect: {
                        profileManager.selectProfile(profile)
                    },
                    onEdit: {
                        editingProfile = profile
                        showingProfileEditor = true
                    },
                    onDelete: {
                        profileManager.deleteProfile(profile)
                    }
                )
            }
            .onDelete(perform: profileManager.deleteProfile)
        }
        .listStyle(PlainListStyle())
    }
}

struct ChildProfileRow: View {
    let profile: ChildProfile
    let isSelected: Bool
    let onSelect: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var showingDeleteAlert = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Profile info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(profile.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                            .font(.caption)
                    }
                }
                
                HStack {
                    Text(profile.ageGroup.rawValue)
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    
                    if let gender = profile.gender {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text(gender.displayName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                if !profile.customNotes.isEmpty {
                    Text(profile.customNotes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .padding(.top, 2)
                }
                
                // Favorite themes preview
                if !profile.favoriteThemes.isEmpty {
                    HStack {
                        ForEach(profile.favoriteThemes.prefix(3), id: \.self) { theme in
                            Text(theme.rawValue)
                                .font(.caption2)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.1))
                                .foregroundColor(.green)
                                .cornerRadius(4)
                        }
                        
                        if profile.favoriteThemes.count > 3 {
                            Text("+\(profile.favoriteThemes.count - 3)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 2)
                }
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 16) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .buttonStyle(BorderlessButtonStyle())
                
                Button(action: {
                    showingDeleteAlert = true
                }) {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .buttonStyle(BorderlessButtonStyle())
                
                Button(action: onSelect) {
                    Text(isSelected ? "Selected" : "Select")
                        .font(.caption2)
                        .foregroundColor(isSelected ? .green : .blue)
                }
                .buttonStyle(BorderlessButtonStyle())
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            onEdit()
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                showingDeleteAlert = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
            
            Button {
                onEdit()
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(.blue)
        }
        .alert("Delete Profile", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                onDelete()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete \(profile.name)'s profile? This action cannot be undone.")
        }
    }
}

struct ProfileEditorView: View {
    let profile: ChildProfile?
    @ObservedObject var profileManager: ChildProfileManager
    
    @State private var name: String
    @State private var selectedAgeGroup: AgeGroup
    @State private var selectedGender: ChildGender?
    @State private var selectedValues: Set<StoryValue>
    @State private var selectedThemes: Set<CharacterTheme>
    @State private var preferredSetting: StorySetting?
    @State private var preferredTone: StoryTone?
    @State private var preferredLength: StoryLength?
    @State private var customNotes: String
    
    @Environment(\.presentationMode) var presentationMode
    
    init(profile: ChildProfile?, profileManager: ChildProfileManager) {
        self.profile = profile
        self.profileManager = profileManager
        
        if let profile = profile {
            _name = State(initialValue: profile.name)
            _selectedAgeGroup = State(initialValue: profile.ageGroup)
            _selectedGender = State(initialValue: profile.gender)
            _selectedValues = State(initialValue: Set(profile.favoriteValues))
            _selectedThemes = State(initialValue: Set(profile.favoriteThemes))
            _preferredSetting = State(initialValue: profile.preferredSetting)
            _preferredTone = State(initialValue: profile.preferredTone)
            _preferredLength = State(initialValue: profile.preferredLength)
            _customNotes = State(initialValue: profile.customNotes)
        } else {
            _name = State(initialValue: "")
            _selectedAgeGroup = State(initialValue: .preschool)
            _selectedGender = State(initialValue: nil)
            _selectedValues = State(initialValue: Set())
            _selectedThemes = State(initialValue: Set())
            _preferredSetting = State(initialValue: nil)
            _preferredTone = State(initialValue: nil)
            _preferredLength = State(initialValue: nil)
            _customNotes = State(initialValue: "")
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Basic Info
                    VStack(alignment: .leading, spacing: 16) {
                        Text("👤 Basic Information")
                            .font(.headline)
                            .foregroundColor(.blue)
                        
                        TextField("Child's name", text: $name)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.title3)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Age Group")
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
                            Text("Gender (Optional)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Picker("Gender", selection: $selectedGender) {
                                Text("Not specified").tag(nil as ChildGender?)
                                ForEach(ChildGender.allCases, id: \.self) { gender in
                                    Text(gender.displayName).tag(gender as ChildGender?)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(12)
                    
                    // Custom Notes
                    VStack(alignment: .leading, spacing: 16) {
                        Text("📝 Personal Notes")
                            .font(.headline)
                            .foregroundColor(.purple)
                        
                        Text("Add details about your child's interests, favorite things, or special notes that can make stories more personal")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("Examples: \"Loves unicorns and rainbow colors\", \"Has a pet dog named Max\", \"Enjoys building with blocks\"")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .italic()
                        
                        TextEditor(text: $customNotes)
                            .frame(minHeight: 100)
                            .padding(8)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .padding()
                    .background(Color.purple.opacity(0.05))
                    .cornerRadius(12)
                    
                    // Favorite Values
                    VStack(alignment: .leading, spacing: 16) {
                        Text("💝 Favorite Values")
                            .font(.headline)
                            .foregroundColor(.green)
                        
                        Text("Select values your child enjoys learning about")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                            ForEach(StoryValue.allCases, id: \.self) { value in
                                SelectableChip(option: value, selection: $selectedValues)
                            }
                        }
                    }
                    .padding()
                    .background(Color.green.opacity(0.05))
                    .cornerRadius(12)
                    
                    // Favorite Themes
                    VStack(alignment: .leading, spacing: 16) {
                        Text("🦸‍♀️ Favorite Characters")
                            .font(.headline)
                            .foregroundColor(.orange)
                        
                        Text("Choose character types your child loves")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                            ForEach(CharacterTheme.allCases, id: \.self) { theme in
                                SelectableChip(option: theme, selection: $selectedThemes)
                            }
                        }
                    }
                    .padding()
                    .background(Color.orange.opacity(0.05))
                    .cornerRadius(12)
                    
                    // Preferred Defaults (Optional)
                    VStack(alignment: .leading, spacing: 16) {
                        Text("⚙️ Story Preferences (Optional)")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text("Set default preferences for this child's stories")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Default Setting:")
                                    .font(.subheadline)
                                Spacer()
                                Picker("Setting", selection: $preferredSetting) {
                                    Text("No preference").tag(nil as StorySetting?)
                                    ForEach(StorySetting.allCases, id: \.self) { setting in
                                        Text(setting.rawValue).tag(setting as StorySetting?)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                            }
                            
                            HStack {
                                Text("Default Tone:")
                                    .font(.subheadline)
                                Spacer()
                                Picker("Tone", selection: $preferredTone) {
                                    Text("No preference").tag(nil as StoryTone?)
                                    ForEach(StoryTone.allCases, id: \.self) { tone in
                                        Text(tone.rawValue).tag(tone as StoryTone?)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                            }
                            
                            HStack {
                                Text("Default Length:")
                                    .font(.subheadline)
                                Spacer()
                                Picker("Length", selection: $preferredLength) {
                                    Text("No preference").tag(nil as StoryLength?)
                                    ForEach(StoryLength.allCases, id: \.self) { length in
                                        Text(length.rawValue).tag(length as StoryLength?)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                            }
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle(profile == nil ? "New Profile" : "Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    saveProfile()
                }
                .disabled(name.isEmpty)
            )
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func saveProfile() {
        if let existingProfile = profile {
            var updatedProfile = existingProfile
            updatedProfile.update(
                name: name,
                ageGroup: selectedAgeGroup,
                gender: selectedGender,
                favoriteValues: Array(selectedValues),
                favoriteThemes: Array(selectedThemes),
                preferredSetting: preferredSetting,
                preferredTone: preferredTone,
                preferredLength: preferredLength,
                customNotes: customNotes
            )
            profileManager.updateProfile(updatedProfile)
        } else {
            let newProfile = ChildProfile(
                name: name,
                ageGroup: selectedAgeGroup,
                gender: selectedGender,
                favoriteValues: Array(selectedValues),
                favoriteThemes: Array(selectedThemes),
                preferredSetting: preferredSetting,
                preferredTone: preferredTone,
                preferredLength: preferredLength,
                customNotes: customNotes
            )
            profileManager.addProfile(newProfile)
        }
        presentationMode.wrappedValue.dismiss()
    }
}

#Preview {
    ChildProfileView(profileManager: ChildProfileManager())
}