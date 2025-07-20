import Foundation
import Combine
import FirebaseFunctions
import FirebaseAuth
import FirebaseAppCheck

/// Manages subscription status and feature access
@MainActor
class SubscriptionManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var subscriptionStatus: SubscriptionStatus = .free(storiesRemaining: 2)
    @Published var isPurchasing = false
    @Published var purchaseError: String?
    
    // MARK: - Dependencies
    private let storeManager = StoreManager()
    private let userDefaults = UserDefaults.standard
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - UserDefaults Keys
    private let storiesCountKey = "remaining_stories_count"
    private let unlimitedKey = "has_unlimited_purchase"
    private let firstLaunchKey = "first_launch_completed"
    
    // MARK: - Initialization
    init() {
        setupFirstLaunch()
        loadSubscriptionStatus()
        observeStoreUpdates()
        
        // Sync subscription status to Firebase on startup
        Task {
            // Wait a bit for store updates to complete
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            await syncSubscriptionStatusToFirebase()
        }
    }
    
    // MARK: - Subscription Status Management
    
    /// Load subscription status from UserDefaults and StoreKit
    private func loadSubscriptionStatus() {
        // Check StoreKit purchases first (authoritative)
        if storeManager.hasUnlimitedStories {
            subscriptionStatus = .unlimited
            userDefaults.set(true, forKey: unlimitedKey)
        } else if userDefaults.bool(forKey: unlimitedKey) {
            // Local says unlimited but StoreKit doesn't - reset to free
            print("⚠️ Local unlimited flag found but no StoreKit purchase - resetting to free")
            resetToFreeAccount()
        } else {
            // Free account - load remaining stories
            let remaining = userDefaults.object(forKey: storiesCountKey) as? Int ?? 2
            subscriptionStatus = .free(storiesRemaining: max(0, remaining))
        }
        
        print("📱 Loaded subscription status: \(subscriptionStatus)")
    }
    
    /// Save subscription status to UserDefaults
    private func saveSubscriptionStatus() {
        switch subscriptionStatus {
        case .free(let remaining):
            userDefaults.set(remaining, forKey: storiesCountKey)
            userDefaults.set(false, forKey: unlimitedKey)
        case .unlimited:
            userDefaults.set(true, forKey: unlimitedKey)
            userDefaults.removeObject(forKey: storiesCountKey) // Not needed for unlimited
        }
        
        print("💾 Saved subscription status: \(subscriptionStatus)")
    }
    
    /// Reset to free account with default story count
    private func resetToFreeAccount() {
        subscriptionStatus = .free(storiesRemaining: 2)
        userDefaults.set(false, forKey: unlimitedKey)
        userDefaults.set(2, forKey: storiesCountKey)
    }
    
    /// Setup first launch experience
    private func setupFirstLaunch() {
        if !userDefaults.bool(forKey: firstLaunchKey) {
            // First launch - ensure user gets 2 free stories
            userDefaults.set(2, forKey: storiesCountKey)
            userDefaults.set(false, forKey: unlimitedKey)
            userDefaults.set(true, forKey: firstLaunchKey)
            print("🎉 First launch setup completed - user gets 2 free stories")
        }
    }
    
    // MARK: - Store Integration
    
    /// Observe StoreKit updates
    private func observeStoreUpdates() {
        // Watch for purchase updates
        storeManager.$purchasedProductIDs
            .sink { [weak self] purchasedIDs in
                self?.handlePurchaseUpdate(purchasedIDs)
            }
            .store(in: &cancellables)
        
        // Watch for purchase errors
        storeManager.$purchaseError
            .sink { [weak self] error in
                self?.purchaseError = error
            }
            .store(in: &cancellables)
        
        // Watch for purchasing state
        storeManager.$isPurchasing
            .sink { [weak self] isPurchasing in
                self?.isPurchasing = isPurchasing
            }
            .store(in: &cancellables)
    }
    
    /// Handle purchase updates from StoreManager
    private func handlePurchaseUpdate(_ purchasedIDs: Set<String>) {
        if purchasedIDs.contains(StoreManager.unlimitedStoriesProductID) {
            subscriptionStatus = .unlimited
            saveSubscriptionStatus()
            
            // Sync to Firebase
            Task {
                await syncSubscriptionStatusToFirebase()
            }
            
            print("🎉 Unlimited stories activated!")
        } else if case .unlimited = subscriptionStatus {
            // Was unlimited but no longer purchased - reset to free
            print("⚠️ Unlimited purchase no longer found - resetting to free")
            resetToFreeAccount()
            saveSubscriptionStatus()
            
            // Sync to Firebase
            Task {
                await syncSubscriptionStatusToFirebase()
            }
        }
    }
    
    // MARK: - Feature Access Control
    
    /// Attempt to create a story - returns true if allowed
    func canCreateStory() -> Bool {
        switch subscriptionStatus {
        case .free(let remaining):
            return remaining > 0
        case .unlimited:
            return true
        }
    }
    
    /// Use a story credit (for free users)
    func useStoryCredit() -> Bool {
        switch subscriptionStatus {
        case .free(let remaining) where remaining > 0:
            let newRemaining = remaining - 1
            subscriptionStatus = .free(storiesRemaining: newRemaining)
            saveSubscriptionStatus()
            print("📖 Story created - \(newRemaining) stories remaining")
            return true
        case .unlimited:
            print("📖 Story created - unlimited account")
            return true
        default:
            print("🚫 Cannot create story - no credits remaining")
            return false
        }
    }
    
    /// Check if cloud TTS is available
    func canUseCloudTTS() -> Bool {
        switch subscriptionStatus {
        case .unlimited:
            return true
        case .free(let remaining):
            return remaining > 0 // Free users get cloud TTS for their first 2 stories!
        }
    }
    
    /// Check if premium voices are available
    func canUsePremiumVoices() -> Bool {
        return canUseCloudTTS()
    }
    
    // MARK: - Purchase Actions
    
    /// Purchase unlimited stories
    func purchaseUnlimitedStories() async {
        do {
            try await storeManager.purchaseUnlimitedStories()
            // StoreManager will trigger the purchase update automatically
        } catch {
            print("❌ Purchase failed: \(error)")
            purchaseError = error.localizedDescription
        }
    }
    
    /// Restore previous purchases
    func restorePurchases() async {
        await storeManager.restorePurchases()
        
        // Force reload subscription status after restore
        loadSubscriptionStatus()
    }
    
    // MARK: - Getters
    
    /// Get the current store manager for direct access if needed
    var store: StoreManager {
        return storeManager
    }
    
    // MARK: - Firebase Sync
    
    /// Sync subscription status to Firebase Firestore
    private func syncSubscriptionStatusToFirebase() async {
        do {
            let functions = Functions.functions()
            let syncFunction = functions.httpsCallable("syncSubscriptionStatus")
            
            let subscriptionStatusString = subscriptionStatus == .unlimited ? "unlimited" : "free"
            
            var requestData: [String: Any] = [
                "subscriptionStatus": subscriptionStatusString
            ]
            
            // Add purchase info if unlimited
            if case .unlimited = subscriptionStatus {
                requestData["purchaseInfo"] = [
                    "productId": StoreManager.unlimitedStoriesProductID,
                    "purchaseDate": Date().timeIntervalSince1970
                ]
            }
            
            let result = try await syncFunction.call(requestData)
            
            if let data = result.data as? [String: Any],
               let success = data["success"] as? Bool,
               success {
                print("✅ Subscription status synced to Firebase: \(subscriptionStatusString)")
            } else {
                print("⚠️ Firebase sync responded but with unknown format")
            }
            
        } catch {
            print("❌ Failed to sync subscription status to Firebase: \(error)")
            // Don't throw - this is a background sync operation
        }
    }
    
    /// Manually sync subscription status (useful for troubleshooting)
    func forceSyncToFirebase() async {
        await syncSubscriptionStatusToFirebase()
    }
}

// MARK: - Subscription Status

enum SubscriptionStatus: Equatable {
    case free(storiesRemaining: Int)
    case unlimited
    
    var canCreateStory: Bool {
        switch self {
        case .free(let remaining):
            return remaining > 0
        case .unlimited:
            return true
        }
    }
    
    var displayText: String {
        switch self {
        case .free(let remaining):
            if remaining == 0 {
                return "No stories remaining"
            } else {
                return "\(remaining) \(remaining == 1 ? "story" : "stories") remaining"
            }
        case .unlimited:
            return "Unlimited stories"
        }
    }
    
    var statusIcon: String {
        switch self {
        case .free:
            return "clock"
        case .unlimited:
            return "infinity"
        }
    }
    
    var isPremium: Bool {
        switch self {
        case .unlimited:
            return true
        case .free:
            return false
        }
    }
}

// MARK: - Subscription Errors

enum SubscriptionError: LocalizedError {
    case noCreditsRemaining
    case productNotFound
    case purchaseFailed
    
    var errorDescription: String? {
        switch self {
        case .noCreditsRemaining:
            return "No story credits remaining. Upgrade to create unlimited stories."
        case .productNotFound:
            return "Unlimited stories product not found in App Store."
        case .purchaseFailed:
            return "Purchase failed. Please try again."
        }
    }
}