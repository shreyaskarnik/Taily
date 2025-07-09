import Foundation
import SwiftUI
import Combine

// MARK: - Child Profile Model

struct ChildProfile: Identifiable, Codable {
    let id: UUID
    var name: String
    var ageGroup: AgeGroup
    var gender: ChildGender?
    var favoriteValues: [StoryValue]
    var favoriteThemes: [CharacterTheme]
    var preferredSetting: StorySetting?
    var preferredTone: StoryTone?
    var preferredLength: StoryLength?
    var customNotes: String
    let dateCreated: Date
    var dateModified: Date
    
    init(
        name: String,
        ageGroup: AgeGroup,
        gender: ChildGender? = nil,
        favoriteValues: [StoryValue] = [],
        favoriteThemes: [CharacterTheme] = [],
        preferredSetting: StorySetting? = nil,
        preferredTone: StoryTone? = nil,
        preferredLength: StoryLength? = nil,
        customNotes: String = ""
    ) {
        self.id = UUID()
        self.name = name
        self.ageGroup = ageGroup
        self.gender = gender
        self.favoriteValues = favoriteValues
        self.favoriteThemes = favoriteThemes
        self.preferredSetting = preferredSetting
        self.preferredTone = preferredTone
        self.preferredLength = preferredLength
        self.customNotes = customNotes
        self.dateCreated = Date()
        self.dateModified = Date()
    }
    
    mutating func update(
        name: String,
        ageGroup: AgeGroup,
        gender: ChildGender?,
        favoriteValues: [StoryValue],
        favoriteThemes: [CharacterTheme],
        preferredSetting: StorySetting?,
        preferredTone: StoryTone?,
        preferredLength: StoryLength?,
        customNotes: String
    ) {
        self.name = name
        self.ageGroup = ageGroup
        self.gender = gender
        self.favoriteValues = favoriteValues
        self.favoriteThemes = favoriteThemes
        self.preferredSetting = preferredSetting
        self.preferredTone = preferredTone
        self.preferredLength = preferredLength
        self.customNotes = customNotes
        self.dateModified = Date()
    }
    
    func toStoryParameters(
        values: [StoryValue]? = nil,
        themes: [CharacterTheme]? = nil,
        setting: StorySetting? = nil,
        tone: StoryTone? = nil,
        length: StoryLength? = nil
    ) -> StoryParameters {
        return StoryParameters(
            childName: name,
            ageGroup: ageGroup,
            gender: gender,
            values: values ?? favoriteValues,
            themes: themes ?? favoriteThemes,
            setting: setting ?? preferredSetting ?? .forest,
            tone: tone ?? preferredTone ?? .calming,
            length: length ?? preferredLength ?? .medium
        )
    }
}

// MARK: - Profile Manager

class ChildProfileManager: ObservableObject {
    @Published var profiles: [ChildProfile] = []
    @Published var selectedProfile: ChildProfile?
    
    private let userDefaults = UserDefaults.standard
    private let profilesKey = "ChildProfiles"
    
    init() {
        loadProfiles()
    }
    
    // MARK: - Persistence
    
    private func loadProfiles() {
        guard let data = userDefaults.data(forKey: profilesKey),
              let profiles = try? JSONDecoder().decode([ChildProfile].self, from: data) else {
            return
        }
        self.profiles = profiles.sorted { $0.dateModified > $1.dateModified }
        if let firstProfile = self.profiles.first {
            self.selectedProfile = firstProfile
        }
    }
    
    private func saveProfiles() {
        guard let data = try? JSONEncoder().encode(profiles) else { return }
        userDefaults.set(data, forKey: profilesKey)
    }
    
    // MARK: - Profile Management
    
    func addProfile(_ profile: ChildProfile) {
        profiles.append(profile)
        selectedProfile = profile
        saveProfiles()
    }
    
    func updateProfile(_ profile: ChildProfile) {
        guard let index = profiles.firstIndex(where: { $0.id == profile.id }) else { return }
        profiles[index] = profile
        profiles.sort { $0.dateModified > $1.dateModified }
        if selectedProfile?.id == profile.id {
            selectedProfile = profile
        }
        saveProfiles()
    }
    
    func deleteProfile(_ profile: ChildProfile) {
        profiles.removeAll { $0.id == profile.id }
        if selectedProfile?.id == profile.id {
            selectedProfile = profiles.first
        }
        saveProfiles()
    }
    
    func deleteProfile(at indexSet: IndexSet) {
        let profilesToDelete = indexSet.map { profiles[$0] }
        for profile in profilesToDelete {
            if selectedProfile?.id == profile.id {
                selectedProfile = profiles.first { existingProfile in
                    !profilesToDelete.contains { deleteProfile in deleteProfile.id == existingProfile.id }
                }
            }
        }
        profiles.remove(atOffsets: indexSet)
        saveProfiles()
    }
    
    func selectProfile(_ profile: ChildProfile) {
        selectedProfile = profile
    }
    
    // MARK: - Utility
    
    var isEmpty: Bool {
        profiles.isEmpty
    }
    
    var count: Int {
        profiles.count
    }
    
    func profile(withId id: UUID) -> ChildProfile? {
        profiles.first { $0.id == id }
    }
}

// MARK: - Enhanced Story Parameters

extension StoryParameters {
    init(from profile: ChildProfile, customLength: StoryLength? = nil, customNotes: String? = nil) {
        self.init(
            childName: profile.name,
            ageGroup: profile.ageGroup,
            gender: profile.gender,
            values: profile.favoriteValues,
            themes: profile.favoriteThemes,
            setting: profile.preferredSetting ?? .forest,
            tone: profile.preferredTone ?? .calming,
            length: customLength ?? profile.preferredLength ?? .medium,
            customNotes: customNotes ?? (profile.customNotes.isEmpty ? nil : profile.customNotes)
        )
    }
    
    var hasCustomNotes: Bool {
        customNotes != nil && !customNotes!.isEmpty
    }
}
