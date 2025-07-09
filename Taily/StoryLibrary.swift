import Foundation
import SwiftUI
import Combine

// MARK: - Saved Story Model

struct SavedStory: Identifiable, Codable {
    let id: UUID
    let story: GeneratedStory
    let parameters: StoryParameters
    let dateCreated: Date
    let dateModified: Date
    
    init(story: GeneratedStory, parameters: StoryParameters) {
        self.id = UUID()
        self.story = story
        self.parameters = parameters
        self.dateCreated = Date()
        self.dateModified = Date()
    }
    
    init(story: GeneratedStory, parameters: StoryParameters, dateCreated: Date, dateModified: Date) {
        self.id = UUID()
        self.story = story
        self.parameters = parameters
        self.dateCreated = dateCreated
        self.dateModified = dateModified
    }
    
    func updated(with newStory: GeneratedStory) -> SavedStory {
        return SavedStory(
            story: newStory,
            parameters: self.parameters,
            dateCreated: self.dateCreated,
            dateModified: Date()
        )
    }
}

// MARK: - Story Library Manager

class StoryLibraryManager: ObservableObject {
    @Published var savedStories: [SavedStory] = []
    
    private let userDefaults = UserDefaults.standard
    private let storiesKey = "SavedStories"
    
    init() {
        loadStories()
    }
    
    // MARK: - Persistence
    
    private func loadStories() {
        guard let data = userDefaults.data(forKey: storiesKey) else {
            return
        }
        
        do {
            let stories = try JSONDecoder().decode([SavedStory].self, from: data)
            savedStories = stories.sorted { $0.dateModified > $1.dateModified }
        } catch {
            print("Failed to decode saved stories: \(error)")
            // Clear corrupted data and start fresh
            userDefaults.removeObject(forKey: storiesKey)
            savedStories = []
        }
    }
    
    private func saveStories() {
        guard let data = try? JSONEncoder().encode(savedStories) else { return }
        userDefaults.set(data, forKey: storiesKey)
    }
    
    // MARK: - Story Management
    
    func saveStory(_ story: GeneratedStory, parameters: StoryParameters) {
        let savedStory = SavedStory(story: story, parameters: parameters)
        savedStories.insert(savedStory, at: 0)
        saveStories()
    }
    
    func updateStory(_ savedStory: SavedStory, with newStory: GeneratedStory) {
        guard let index = savedStories.firstIndex(where: { $0.id == savedStory.id }) else { return }
        savedStories[index] = savedStory.updated(with: newStory)
        savedStories.sort { $0.dateModified > $1.dateModified }
        saveStories()
    }
    
    func deleteStory(_ savedStory: SavedStory) {
        savedStories.removeAll { $0.id == savedStory.id }
        saveStories()
    }
    
    func deleteStory(at indexSet: IndexSet) {
        savedStories.remove(atOffsets: indexSet)
        saveStories()
    }
    
    // MARK: - Utility
    
    var isEmpty: Bool {
        savedStories.isEmpty
    }
    
    var count: Int {
        savedStories.count
    }
}
