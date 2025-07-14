import Foundation
import StoreKit
import Combine

/// Manages StoreKit 2 purchases and transactions
@MainActor
class StoreManager: ObservableObject {
    
    // MARK: - Product Configuration
    static let unlimitedStoriesProductID = "com.dozzi.unlimited_stories"
    
    // MARK: - Published Properties
    @Published var products: [Product] = []
    @Published var purchasedProductIDs = Set<String>()
    @Published var isPurchasing = false
    @Published var purchaseError: String?
    
    // MARK: - Private Properties
    private var transactionListener: Task<Void, Error>?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        // Start listening for transactions
        transactionListener = listenForTransactions()
        
        // Load products and update purchased products
        Task {
            await requestProducts()
            await updatePurchasedProducts()
        }
    }
    
    deinit {
        transactionListener?.cancel()
    }
    
    // MARK: - Product Management
    
    /// Request products from the App Store
    func requestProducts() async {
        do {
            let requestedProducts = try await Product.products(for: [Self.unlimitedStoriesProductID])
            products = requestedProducts
            print("✅ Loaded \(products.count) products from App Store")
        } catch {
            print("❌ Failed to load products: \(error)")
            purchaseError = "Unable to load products from App Store"
        }
    }
    
    /// Get the unlimited stories product
    var unlimitedStoriesProduct: Product? {
        products.first { $0.id == Self.unlimitedStoriesProductID }
    }
    
    /// Check if unlimited stories is purchased
    var hasUnlimitedStories: Bool {
        purchasedProductIDs.contains(Self.unlimitedStoriesProductID)
    }
    
    // MARK: - Purchase Management
    
    /// Purchase a product
    func purchase(_ product: Product) async throws -> Transaction? {
        isPurchasing = true
        purchaseError = nil
        
        defer {
            isPurchasing = false
        }
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                
                // Update purchased products
                await updatePurchasedProducts()
                
                // Finish the transaction
                await transaction.finish()
                
                print("✅ Purchase successful: \(product.displayName)")
                return transaction
                
            case .userCancelled:
                print("🚫 Purchase cancelled by user")
                return nil
                
            case .pending:
                print("⏳ Purchase pending approval")
                return nil
                
            @unknown default:
                print("⚠️ Unknown purchase result")
                return nil
            }
        } catch {
            print("❌ Purchase failed: \(error)")
            purchaseError = "Purchase failed: \(error.localizedDescription)"
            throw StoreError.purchaseFailed(error.localizedDescription)
        }
    }
    
    /// Purchase unlimited stories
    func purchaseUnlimitedStories() async throws {
        guard let product = unlimitedStoriesProduct else {
            throw StoreError.productNotFound
        }
        
        _ = try await purchase(product)
    }
    
    /// Restore purchases
    func restorePurchases() async {
        do {
            // Sync with App Store
            try await AppStore.sync()
            
            // Update our local state
            await updatePurchasedProducts()
            
            print("✅ Purchases restored successfully")
        } catch {
            print("❌ Failed to restore purchases: \(error)")
            purchaseError = "Failed to restore purchases: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Transaction Management
    
    /// Update purchased products based on current entitlements
    func updatePurchasedProducts() async {
        var newPurchasedIDs = Set<String>()
        
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                // Only include non-revoked transactions
                if transaction.revocationDate == nil {
                    newPurchasedIDs.insert(transaction.productID)
                }
            } catch {
                print("❌ Failed to verify transaction: \(error)")
            }
        }
        
        // Update published property
        purchasedProductIDs = newPurchasedIDs
        print("📱 Updated purchased products: \(purchasedProductIDs)")
    }
    
    /// Listen for transaction updates
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached { @MainActor in
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    
                    // Update purchased products
                    await self.updatePurchasedProducts()
                    
                    // Finish the transaction
                    await transaction.finish()
                    
                    print("✅ Transaction updated: \(transaction.productID)")
                } catch {
                    print("❌ Transaction verification failed: \(error)")
                }
            }
        }
    }
    
    /// Verify a transaction result
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            // This transaction couldn't be verified by StoreKit
            throw StoreError.failedVerification
        case .verified(let safe):
            // This transaction was verified by StoreKit
            return safe
        }
    }
}

// MARK: - Store Errors

enum StoreError: LocalizedError {
    case failedVerification
    case productNotFound
    case purchaseFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "Transaction verification failed"
        case .productNotFound:
            return "Product not found in App Store"
        case .purchaseFailed(let message):
            return "Purchase failed: \(message)"
        }
    }
}

// MARK: - Product Extensions

extension Product {
    /// Formatted price for display
    var formattedPrice: String {
        return displayPrice
    }
}