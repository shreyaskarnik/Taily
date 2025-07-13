# Dozzi Freemium IAP Implementation Plan

## Overview

This document outlines the complete implementation plan for converting Dozzi from a local-only bedtime story app to a freemium model with In-App Purchases for unlimited stories.

## Current Architecture Status

### ✅ **Already Implemented**
- Complete Foundation Models integration (iOS 26.0+)
- Robust local TTS with word highlighting and age-appropriate voices
- Full child profile management with persistent storage
- Story library with local persistence
- Modern SwiftUI architecture with proper separation of concerns
- Real-time streaming story generation with live updates
- SSML support and image generation via Apple ImagePlayground

### ❌ **Missing Components**
- Firebase Authentication and cloud storage
- Google Cloud TTS for premium voices
- In-App Purchase integration
- Usage tracking and subscription management
- Network layer infrastructure

## Freemium Model Design

### **Subscription Tiers**

| Tier | Stories Included | Price | Features |
|------|------------------|-------|----------|
| **Free** | 2 stories | $0.00 | Basic voices, full personalization |
| **Unlimited** | Unlimited | $2.99 | Premium voices, unlimited stories |

### **Revenue Projections**

```
Cost per story: $0.012 (Google Cloud TTS)
Free tier cost: 2 stories = $0.024
Conversion rate: 3-5% (industry standard for kids apps)
Revenue per download: ~$0.09-0.15
Break-even: ~12-16 conversions per 100 downloads
```

### **Business Logic**

```swift
enum SubscriptionStatus {
    case free(storiesRemaining: Int)  // 2 stories
    case unlimited                    // $2.99 one-time purchase
    
    var canCreateStory: Bool {
        switch self {
        case .free(let remaining): return remaining > 0
        case .unlimited: return true
        }
    }
    
    var displayText: String {
        switch self {
        case .free(let remaining): return "\(remaining) stories remaining"
        case .unlimited: return "Unlimited stories"
        }
    }
}
```

## Technical Implementation Plan

### **Phase 1: Core IAP Infrastructure**

#### **1.1 StoreKit 2 Integration**

```swift
import StoreKit

class StoreManager: ObservableObject {
    private let productId = "com.dozzi.unlimited_stories"
    @Published var products: [Product] = []
    @Published var purchasedProductIDs = Set<String>()
    @Published var transactionListener: Task<Void, Error>?
    
    init() {
        transactionListener = listenForTransactions()
        Task {
            await requestProducts()
            await updatePurchasedProducts()
        }
    }
    
    deinit {
        transactionListener?.cancel()
    }
    
    @MainActor
    func requestProducts() async {
        do {
            products = try await Product.products(for: [productId])
        } catch {
            print("Failed to load products: \(error)")
        }
    }
    
    func purchase(_ product: Product) async throws -> Transaction? {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updatePurchasedProducts()
            await transaction.finish()
            return transaction
        case .userCancelled, .pending:
            return nil
        default:
            return nil
        }
    }
    
    func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    @MainActor
    func updatePurchasedProducts() async {
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                if transaction.productID == productId && transaction.revocationDate == nil {
                    purchasedProductIDs.insert(transaction.productID)
                }
            } catch {
                print("Failed to verify transaction: \(error)")
            }
        }
    }
    
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    await self.updatePurchasedProducts()
                    await transaction.finish()
                } catch {
                    print("Transaction failed verification: \(error)")
                }
            }
        }
    }
}

enum StoreError: Error {
    case failedVerification
}
```

#### **1.2 Subscription Management**

```swift
class SubscriptionManager: ObservableObject {
    @Published var subscriptionStatus: SubscriptionStatus = .free(storiesRemaining: 2)
    @Published var isPurchasing = false
    
    private let storeManager = StoreManager()
    private let userDefaults = UserDefaults.standard
    
    private let storiesCountKey = "remaining_stories_count"
    private let unlimitedKey = "has_unlimited_purchase"
    
    init() {
        loadSubscriptionStatus()
        
        // Listen for purchase updates
        storeManager.$purchasedProductIDs
            .sink { [weak self] purchasedIDs in
                if purchasedIDs.contains("com.dozzi.unlimited_stories") {
                    self?.subscriptionStatus = .unlimited
                    self?.saveSubscriptionStatus()
                }
            }
            .store(in: &cancellables)
    }
    
    func createStory() -> Bool {
        switch subscriptionStatus {
        case .free(let remaining) where remaining > 0:
            let newRemaining = remaining - 1
            subscriptionStatus = .free(storiesRemaining: newRemaining)
            saveSubscriptionStatus()
            return true
        case .unlimited:
            return true
        default:
            return false
        }
    }
    
    func purchaseUnlimited() async throws {
        guard let product = storeManager.products.first(where: { $0.id == "com.dozzi.unlimited_stories" }) else {
            throw SubscriptionError.productNotFound
        }
        
        isPurchasing = true
        defer { isPurchasing = false }
        
        if let transaction = try await storeManager.purchase(product) {
            subscriptionStatus = .unlimited
            saveSubscriptionStatus()
        }
    }
    
    func restorePurchases() async {
        try? await AppStore.sync()
        await storeManager.updatePurchasedProducts()
    }
    
    private func loadSubscriptionStatus() {
        if userDefaults.bool(forKey: unlimitedKey) {
            subscriptionStatus = .unlimited
        } else {
            let remaining = userDefaults.object(forKey: storiesCountKey) as? Int ?? 2
            subscriptionStatus = .free(storiesRemaining: remaining)
        }
    }
    
    private func saveSubscriptionStatus() {
        switch subscriptionStatus {
        case .free(let remaining):
            userDefaults.set(remaining, forKey: storiesCountKey)
            userDefaults.set(false, forKey: unlimitedKey)
        case .unlimited:
            userDefaults.set(true, forKey: unlimitedKey)
        }
    }
}

enum SubscriptionError: Error {
    case productNotFound
    case purchaseFailed
}
```

#### **1.3 Paywall UI Components**

```swift
struct PaywallView: View {
    @StateObject private var subscriptionManager = SubscriptionManager()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Header with character
                    PaywallHeaderView()
                    
                    // Benefits section
                    PaywallBenefitsView()
                    
                    // Pricing section
                    PaywallPricingView(subscriptionManager: subscriptionManager)
                    
                    // Trust indicators
                    PaywallTrustView()
                }
                .padding()
            }
            .navigationTitle("Unlock Unlimited Stories")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Maybe Later") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct PaywallHeaderView: View {
    var body: some View {
        VStack(spacing: 16) {
            // Animated character here (SpriteKit integration)
            DozziCharacterView()
                .frame(height: 120)
            
            Text("Hi! I'm Dozzi!")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("I can create unlimited magical bedtime stories just for your little one")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
    }
}

struct PaywallBenefitsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What you'll get:")
                .font(.headline)
            
            PaywallBenefitRow(
                icon: "infinity",
                title: "Unlimited Stories",
                description: "Create as many personalized stories as you want"
            )
            
            PaywallBenefitRow(
                icon: "speaker.wave.3.fill",
                title: "Premium Voices",
                description: "High-quality, age-appropriate narration"
            )
            
            PaywallBenefitRow(
                icon: "heart.fill",
                title: "Always Personalized",
                description: "Every story features your child as the hero"
            )
            
            PaywallBenefitRow(
                icon: "shield.fill",
                title: "Safe & Private",
                description: "Stories generated on-device, no data shared"
            )
        }
        .padding(.horizontal)
    }
}

struct PaywallBenefitRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .fontWeight(.semibold)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct PaywallPricingView: View {
    @ObservedObject var subscriptionManager: SubscriptionManager
    
    var body: some View {
        VStack(spacing: 16) {
            // Main purchase button
            if let product = subscriptionManager.storeManager.products.first {
                Button(action: {
                    Task {
                        try? await subscriptionManager.purchaseUnlimited()
                    }
                }) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Unlock Unlimited Stories")
                                .fontWeight(.semibold)
                            Text("One-time purchase")
                                .font(.caption)
                                .opacity(0.8)
                        }
                        
                        Spacer()
                        
                        Text(product.displayPrice)
                            .fontWeight(.bold)
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(subscriptionManager.isPurchasing)
                .opacity(subscriptionManager.isPurchasing ? 0.6 : 1.0)
            }
            
            // Restore purchases
            Button("Restore Purchases") {
                Task {
                    await subscriptionManager.restorePurchases()
                }
            }
            .foregroundColor(.secondary)
            .font(.caption)
        }
    }
}

struct PaywallTrustView: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("✨ Join thousands of happy families")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("No subscriptions • No recurring charges • No ads")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .multilineTextAlignment(.center)
    }
}
```

### **Phase 2: Usage Tracking Integration**

#### **2.1 Modify Existing Story Creation Flow**

```swift
// Update your existing StoryCreationView
struct StoryCreationView: View {
    @StateObject private var subscriptionManager = SubscriptionManager()
    @State private var showPaywall = false
    
    // Your existing properties...
    
    var body: some View {
        VStack {
            // Subscription status indicator
            SubscriptionStatusView(status: subscriptionManager.subscriptionStatus)
            
            // Your existing UI...
            
            Button("Create Story") {
                createStoryWithSubscriptionCheck()
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .onDisappear {
                    // Refresh subscription status when paywall closes
                    Task {
                        await subscriptionManager.restorePurchases()
                    }
                }
        }
    }
    
    private func createStoryWithSubscriptionCheck() {
        guard subscriptionManager.createStory() else {
            showPaywall = true
            return
        }
        
        // Your existing story creation logic
        createStory()
    }
}

struct SubscriptionStatusView: View {
    let status: SubscriptionStatus
    
    var body: some View {
        HStack {
            Image(systemName: iconName)
                .foregroundColor(iconColor)
            
            Text(status.displayText)
                .font(.caption)
                .foregroundColor(textColor)
            
            Spacer()
            
            if case .unlimited = status {
                Text("PREMIUM")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private var iconName: String {
        switch status {
        case .free: return "clock"
        case .unlimited: return "infinity"
        }
    }
    
    private var iconColor: Color {
        switch status {
        case .free: return .orange
        case .unlimited: return .blue
        }
    }
    
    private var textColor: Color {
        switch status {
        case .free: return .primary
        case .unlimited: return .blue
        }
    }
    
    private var backgroundColor: Color {
        switch status {
        case .free: return Color.orange.opacity(0.1)
        case .unlimited: return Color.blue.opacity(0.1)
        }
    }
}
```

### **Phase 3: Backend Integration**

#### **3.1 Firebase Cloud Functions for Purchase Verification**

```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

// Verify App Store purchases
exports.verifyPurchase = functions.https.onCall(async (data, context) => {
    // Verify user is authenticated
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    
    const { receiptData, productId } = data;
    const userId = context.auth.uid;
    
    try {
        // Verify with App Store (implement App Store receipt validation)
        const isValid = await verifyWithAppStore(receiptData, productId);
        
        if (isValid) {
            // Update user subscription status in Firestore
            await admin.firestore()
                .collection('users')
                .doc(userId)
                .update({
                    subscription: 'unlimited',
                    productId: productId,
                    purchaseDate: admin.firestore.FieldValue.serverTimestamp(),
                    platform: 'ios'
                });
            
            return { success: true, status: 'unlimited' };
        } else {
            return { success: false, error: 'Invalid receipt' };
        }
    } catch (error) {
        console.error('Purchase verification error:', error);
        throw new functions.https.HttpsError('internal', 'Purchase verification failed');
    }
});

// Get user subscription status
exports.getSubscriptionStatus = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    
    const userId = context.auth.uid;
    
    try {
        const userDoc = await admin.firestore()
            .collection('users')
            .doc(userId)
            .get();
        
        if (!userDoc.exists) {
            // New user - create with free tier
            await admin.firestore()
                .collection('users')
                .doc(userId)
                .set({
                    subscription: 'free',
                    storiesRemaining: 2,
                    createdAt: admin.firestore.FieldValue.serverTimestamp()
                });
            
            return { status: 'free', storiesRemaining: 2 };
        }
        
        const userData = userDoc.data();
        return {
            status: userData.subscription || 'free',
            storiesRemaining: userData.storiesRemaining || 0,
            purchaseDate: userData.purchaseDate
        };
    } catch (error) {
        console.error('Get subscription status error:', error);
        throw new functions.https.HttpsError('internal', 'Failed to get subscription status');
    }
});

// Track story creation
exports.trackStoryCreation = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    
    const userId = context.auth.uid;
    
    try {
        const userRef = admin.firestore().collection('users').doc(userId);
        const userDoc = await userRef.get();
        
        if (!userDoc.exists) {
            throw new functions.https.HttpsError('not-found', 'User not found');
        }
        
        const userData = userDoc.data();
        
        if (userData.subscription === 'unlimited') {
            // Unlimited users can always create stories
            return { success: true, canCreate: true };
        }
        
        const remaining = userData.storiesRemaining || 0;
        if (remaining <= 0) {
            return { success: false, canCreate: false, error: 'No stories remaining' };
        }
        
        // Decrement remaining stories
        await userRef.update({
            storiesRemaining: remaining - 1,
            lastStoryCreated: admin.firestore.FieldValue.serverTimestamp()
        });
        
        return { 
            success: true, 
            canCreate: true, 
            storiesRemaining: remaining - 1 
        };
        
    } catch (error) {
        console.error('Track story creation error:', error);
        throw new functions.https.HttpsError('internal', 'Failed to track story creation');
    }
});

// Helper function for App Store receipt validation
async function verifyWithAppStore(receiptData, productId) {
    // Implement App Store receipt validation
    // This is a simplified example - use a proper library like node-app-store-receipt-verify
    
    const https = require('https');
    const querystring = require('querystring');
    
    const postData = JSON.stringify({
        'receipt-data': receiptData,
        'password': functions.config().appstore.shared_secret // Set this in Firebase config
    });
    
    const options = {
        hostname: 'buy.itunes.apple.com', // Use sandbox.itunes.apple.com for testing
        port: 443,
        path: '/verifyReceipt',
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Content-Length': Buffer.byteLength(postData)
        }
    };
    
    return new Promise((resolve, reject) => {
        const req = https.request(options, (res) => {
            let data = '';
            res.on('data', (chunk) => {
                data += chunk;
            });
            res.on('end', () => {
                try {
                    const response = JSON.parse(data);
                    if (response.status === 0) {
                        // Check if the product ID matches
                        const hasValidPurchase = response.receipt.in_app.some(
                            purchase => purchase.product_id === productId
                        );
                        resolve(hasValidPurchase);
                    } else {
                        resolve(false);
                    }
                } catch (error) {
                    reject(error);
                }
            });
        });
        
        req.on('error', (error) => {
            reject(error);
        });
        
        req.write(postData);
        req.end();
    });
}
```

#### **3.2 iOS Backend Integration**

```swift
class BackendManager: ObservableObject {
    private let functions = Functions.functions()
    
    func verifyPurchase(receiptData: Data, productId: String) async throws -> Bool {
        let receiptString = receiptData.base64EncodedString()
        
        let result = try await functions.httpsCallable("verifyPurchase").call([
            "receiptData": receiptString,
            "productId": productId
        ])
        
        guard let data = result.data as? [String: Any],
              let success = data["success"] as? Bool else {
            throw BackendError.invalidResponse
        }
        
        return success
    }
    
    func getSubscriptionStatus() async throws -> SubscriptionStatus {
        let result = try await functions.httpsCallable("getSubscriptionStatus").call()
        
        guard let data = result.data as? [String: Any],
              let status = data["status"] as? String else {
            throw BackendError.invalidResponse
        }
        
        switch status {
        case "unlimited":
            return .unlimited
        case "free":
            let remaining = data["storiesRemaining"] as? Int ?? 0
            return .free(storiesRemaining: remaining)
        default:
            return .free(storiesRemaining: 2)
        }
    }
    
    func trackStoryCreation() async throws -> Bool {
        let result = try await functions.httpsCallable("trackStoryCreation").call()
        
        guard let data = result.data as? [String: Any],
              let canCreate = data["canCreate"] as? Bool else {
            throw BackendError.invalidResponse
        }
        
        return canCreate
    }
}

enum BackendError: Error {
    case invalidResponse
    case networkError
    case authenticationRequired
}
```

### **Phase 4: App Store Connect Configuration**

#### **4.1 Product Setup**

1. **Create In-App Purchase**
   - Product ID: `com.dozzi.unlimited_stories`
   - Type: Non-Consumable
   - Reference Name: "Unlimited Bedtime Stories"
   - Price Tier: Tier 3 ($2.99)

2. **Localizations**
   - Display Name: "Unlimited Stories"
   - Description: "Create unlimited personalized bedtime stories with premium voices for your child"

3. **Review Information**
   - Screenshot showing paywall
   - Review notes explaining the freemium model

#### **4.2 App Privacy Configuration**

```
Data Types Collected:
- Purchase History (for IAP validation)
- User ID (for Firebase Authentication)
- App Usage Data (story creation tracking)

Data Not Collected:
- Story Content (generated on-device)
- Child Names/Personal Info (stored locally only)
- Location Data
- Contact Information
```

### **Phase 5: Testing Strategy**

#### **5.1 StoreKit Testing**

```swift
// StoreKit testing configuration in Xcode
// Create StoreKitTest.storekit file with:
{
    "identifier": "com.dozzi.unlimited_stories",
    "type": "NonConsumable",
    "displayName": "Unlimited Stories",
    "description": "Create unlimited personalized bedtime stories",
    "price": "2.99",
    "familyShareable": false,
    "locale": "en_US"
}
```

#### **5.2 Test Cases**

1. **Free Tier Testing**
   - Verify 2 stories limit
   - Test paywall trigger on 3rd story
   - Verify story counter persistence

2. **Purchase Flow Testing**
   - Test successful purchase
   - Test purchase cancellation
   - Test network failure scenarios
   - Test restore purchases

3. **Edge Cases**
   - App backgrounding during purchase
   - Multiple rapid story creations
   - Offline usage scenarios

### **Phase 6: Analytics & Monitoring**

#### **6.1 Key Metrics to Track**

```swift
// Analytics events to implement
enum AnalyticsEvent {
    case paywallShown
    case paywallDismissed
    case purchaseStarted
    case purchaseCompleted
    case purchaseFailed
    case storyCreatedFree
    case storyCreatedPremium
    case appLaunched
}
```

#### **6.2 Conversion Optimization**

- A/B test paywall copy and design
- Track drop-off points in purchase flow
- Monitor free story engagement before paywall
- Test different pricing points

## Timeline & Milestones

### **Week 1-2: Core IAP Infrastructure**
- [ ] Implement StoreKit 2 integration
- [ ] Create subscription management system
- [ ] Build basic paywall UI
- [ ] Set up App Store Connect products

### **Week 3-4: UI Integration**
- [ ] Integrate paywall into story creation flow
- [ ] Add subscription status indicators
- [ ] Implement purchase restoration
- [ ] Add SpriteKit character integration

### **Week 5-6: Backend Integration**
- [ ] Set up Firebase Cloud Functions
- [ ] Implement purchase verification
- [ ] Add usage tracking
- [ ] Test cloud synchronization

### **Week 7-8: Testing & Polish**
- [ ] Comprehensive StoreKit testing
- [ ] Beta testing with real users
- [ ] Performance optimization
- [ ] App Store submission

## Risk Mitigation

### **Technical Risks**
- **StoreKit failures**: Implement robust error handling and retry logic
- **Backend downtime**: Graceful degradation to local-only mode
- **Purchase validation issues**: Client-side backup verification

### **Business Risks**
- **Low conversion rate**: A/B test paywall design and pricing
- **High refund rate**: Ensure clear value proposition and no misleading claims
- **App Store rejection**: Follow guidelines strictly, especially for kids category

### **User Experience Risks**
- **Confusing paywall**: Clear benefit communication and simple purchase flow
- **Technical barriers**: Comprehensive testing on various devices and iOS versions
- **Trust issues**: Transparent pricing and no hidden charges

## Success Metrics

### **Technical KPIs**
- Purchase completion rate > 85%
- App crash rate < 0.1%
- Backend API response time < 500ms
- StoreKit integration success rate > 99%

### **Business KPIs**
- Free-to-paid conversion rate: 3-5%
- Average revenue per user (ARPU): $0.09-0.15
- Monthly active users growth: 20%+
- User retention (Day 7): 30%+

### **Quality KPIs**
- App Store rating: 4.5+ stars
- Customer support tickets: < 2% of users
- Refund rate: < 5%
- Feature adoption rate: 70%+

## Conclusion

This freemium IAP implementation transforms Dozzi from a local-only app into a scalable, revenue-generating platform while maintaining the core value proposition of personalized, AI-generated bedtime stories. The strategy leverages the existing robust Foundation Models integration while adding cloud capabilities for premium features.

The key to success will be demonstrating clear value in the free tier (2 high-quality personalized stories) before presenting the paywall, ensuring users understand the premium benefits, and maintaining a smooth, trustworthy purchase experience.