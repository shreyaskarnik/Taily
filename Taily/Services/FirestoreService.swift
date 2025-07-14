import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

/// Service for managing user data and usage tracking in Firestore
/// Handles story saving, usage limits, and user preferences
@MainActor
class FirestoreService: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var monthlyUsage: UsageInfo?
    
    private let db = Firestore.firestore()
    private var usageListener: ListenerRegistration?
    
    init() {
        // Listen to current user's usage updates
        startUsageListener()
    }
    
    deinit {
        usageListener?.remove()
    }
    
    // MARK: - Usage Tracking
    
    /// Get current user's usage information
    func getCurrentUsage() async throws -> UsageInfo {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw FirestoreError.notAuthenticated
        }
        
        let document = try await db.collection("users").document(userId).getDocument()
        
        if document.exists {
            let data = document.data() ?? [:]
            return UsageInfo(
                monthlyStories: data["monthlyStories"] as? Int ?? 0,
                monthlyCharacters: data["monthlyCharacters"] as? Int ?? 0,
                lastStoryDate: (data["lastStoryDate"] as? Timestamp)?.dateValue(),
                maxStoriesPerMonth: 30 // Free tier limit
            )
        } else {
            // First time user - create initial document
            let newUsage = UsageInfo(monthlyStories: 0, monthlyCharacters: 0, lastStoryDate: nil, maxStoriesPerMonth: 30)
            try await createUserDocument(userId: userId)
            return newUsage
        }
    }
    
    /// Check if user can generate another story
    func canGenerateStory() async throws -> Bool {
        let usage = try await getCurrentUsage()
        return usage.monthlyStories < usage.maxStoriesPerMonth
    }
    
    private func createUserDocument(userId: String) async throws {
        let userData: [String: Any] = [
            "createdAt": FieldValue.serverTimestamp(),
            "lastLoginAt": FieldValue.serverTimestamp(),
            "monthlyStories": 0,
            "monthlyCharacters": 0
        ]
        
        try await db.collection("users").document(userId).setData(userData, merge: true)
    }
    
    private func startUsageListener() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        usageListener = db.collection("users").document(userId)
            .addSnapshotListener { [weak self] snapshot, error in
                Task { @MainActor in
                    if let error = error {
                        print("❌ Usage listener error: \(error)")
                        return
                    }
                    
                    guard let document = snapshot, document.exists else { return }
                    
                    let data = document.data() ?? [:]
                    self?.monthlyUsage = UsageInfo(
                        monthlyStories: data["monthlyStories"] as? Int ?? 0,
                        monthlyCharacters: data["monthlyCharacters"] as? Int ?? 0,
                        lastStoryDate: (data["lastStoryDate"] as? Timestamp)?.dateValue(),
                        maxStoriesPerMonth: 30
                    )
                }
            }
    }
    
    // MARK: - Story Management
    
    /// Save a generated story to user's library
    func saveStory(_ story: GeneratedStory, parameters: StoryParameters) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw FirestoreError.notAuthenticated
        }
        
        isLoading = true
        errorMessage = nil
        
        defer {
            isLoading = false
        }
        
        do {
            let storyData: [String: Any] = [
                "title": story.title,
                "content": story.content,
                "emoji": story.emoji,
                "childName": parameters.childName,
                "theme": parameters.themes.map { $0.rawValue },
                "ageGroup": parameters.ageGroup.rawValue,
                "tone": parameters.tone.rawValue,
                "createdAt": FieldValue.serverTimestamp(),
                "userId": userId
            ]
            
            // Save to user's stories subcollection
            try await db.collection("users")
                .document(userId)
                .collection("stories")
                .addDocument(data: storyData)
            
            print("✅ Story saved to Firestore library")
            
        } catch {
            print("❌ Failed to save story: \(error)")
            errorMessage = "Failed to save story: \(error.localizedDescription)"
            throw error
        }
    }
    
    /// Get user's saved stories
    func getSavedStories() async throws -> [SavedStoryData] {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw FirestoreError.notAuthenticated
        }
        
        let snapshot = try await db.collection("users")
            .document(userId)
            .collection("stories")
            .order(by: "createdAt", descending: true)
            .limit(to: 50)
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            let data = document.data()
            
            guard let title = data["title"] as? String,
                  let content = data["content"] as? String,
                  let emoji = data["emoji"] as? String,
                  let childName = data["childName"] as? String,
                  let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() else {
                return nil
            }
            
            return SavedStoryData(
                id: document.documentID,
                title: title,
                content: content,
                emoji: emoji,
                childName: childName,
                theme: data["theme"] as? [String] ?? [],
                createdAt: createdAt
            )
        }
    }
    
    /// Delete a saved story
    func deleteStory(storyId: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw FirestoreError.notAuthenticated
        }
        
        try await db.collection("users")
            .document(userId)
            .collection("stories")
            .document(storyId)
            .delete()
        
        print("✅ Story deleted from Firestore")
    }
    
    // MARK: - User Preferences
    
    /// Update user's last login timestamp
    func updateLastLogin() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        do {
            try await db.collection("users").document(userId).setData([
                "lastLoginAt": FieldValue.serverTimestamp()
            ], merge: true)
        } catch {
            print("⚠️ Failed to update last login: \(error)")
        }
    }
}

// MARK: - Data Models

struct UsageInfo {
    let monthlyStories: Int
    let monthlyCharacters: Int
    let lastStoryDate: Date?
    let maxStoriesPerMonth: Int
    
    var remainingStories: Int {
        max(0, maxStoriesPerMonth - monthlyStories)
    }
    
    var isAtLimit: Bool {
        monthlyStories >= maxStoriesPerMonth
    }
    
    var usagePercentage: Double {
        guard maxStoriesPerMonth > 0 else { return 0 }
        return Double(monthlyStories) / Double(maxStoriesPerMonth)
    }
}

struct SavedStoryData: Identifiable {
    let id: String
    let title: String
    let content: String
    let emoji: String
    let childName: String
    let theme: [String]
    let createdAt: Date
}

// MARK: - Error Types

enum FirestoreError: LocalizedError {
    case notAuthenticated
    case documentNotFound
    case invalidData
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User not authenticated"
        case .documentNotFound:
            return "Document not found"
        case .invalidData:
            return "Invalid data format"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
