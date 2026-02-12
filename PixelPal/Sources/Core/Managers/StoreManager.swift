import Foundation
import StoreKit

/// Manages StoreKit 2 subscriptions for PixelPal Premium.
@MainActor
class StoreManager: ObservableObject {
    /// Shared instance.
    static let shared = StoreManager()

    /// Product identifiers.
    enum ProductID: String, CaseIterable {
        case monthlyPremium = "com.pixelpal.premium.monthly"
        case yearlyPremium = "com.pixelpal.premium.yearly"
    }

    /// Available subscription products.
    @Published var products: [Product] = []

    /// Whether the user has an active premium subscription.
    @Published var isPremium: Bool = false

    /// Currently purchased product ID.
    @Published var purchasedProductID: String?

    /// Whether products are loading.
    @Published var isLoading: Bool = false

    /// Error message if something went wrong.
    @Published var errorMessage: String?

    /// Transaction listener task.
    private var updateListenerTask: Task<Void, Error>?

    private init() {
        // Start listening for transactions (lightweight, non-blocking)
        updateListenerTask = listenForTransactions()
        // Products loaded on demand via setup() to avoid blocking app launch
    }

    /// Call after app launch to load products and check entitlements.
    func setup() async {
        guard products.isEmpty else { return }
        await loadProducts()
        await updatePurchasedProducts()
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Product Loading

    /// Loads available subscription products from App Store with timeout.
    func loadProducts() async {
        isLoading = true
        errorMessage = nil

        do {
            let productIDs = ProductID.allCases.map { $0.rawValue }
            let storeProducts = try await withTimeout(seconds: 15) {
                try await Product.products(for: productIDs)
            }
            products = storeProducts.sorted { $0.price < $1.price }
        } catch is TimeoutError {
            errorMessage = "Loading timed out. Please check your connection."
            print("StoreManager: Product loading timed out")
        } catch {
            errorMessage = "Failed to load products: \(error.localizedDescription)"
            print("StoreManager: \(errorMessage ?? "")")
        }

        isLoading = false
    }

    /// Runs an async operation with a timeout.
    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw TimeoutError()
            }
            guard let result = try await group.next() else {
                throw TimeoutError()
            }
            group.cancelAll()
            return result
        }
    }

    // MARK: - Purchasing

    /// Purchases a subscription product.
    /// - Parameter product: The product to purchase.
    /// - Returns: Whether the purchase was successful.
    @discardableResult
    func purchase(_ product: Product) async -> Bool {
        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await updatePurchasedProducts()
                await transaction.finish()
                return true

            case .userCancelled:
                return false

            case .pending:
                // Transaction requires approval (e.g., Ask to Buy)
                return false

            @unknown default:
                return false
            }
        } catch {
            errorMessage = "Purchase failed: \(error.localizedDescription)"
            print("StoreManager: \(errorMessage ?? "")")
            return false
        }
    }

    // MARK: - Restore Purchases

    /// Restores previous purchases.
    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await updatePurchasedProducts()
        } catch {
            errorMessage = "Restore failed: \(error.localizedDescription)"
            print("StoreManager: \(errorMessage ?? "")")
        }
    }

    // MARK: - Entitlement Checking

    /// Updates purchased products and premium status.
    func updatePurchasedProducts() async {
        var foundPremium = false
        var foundProductID: String?

        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)

                // Check if this is one of our subscription products
                if ProductID(rawValue: transaction.productID) != nil {
                    foundPremium = true
                    foundProductID = transaction.productID
                }
            } catch {
                print("StoreManager: Failed to verify transaction: \(error)")
            }
        }

        isPremium = foundPremium
        purchasedProductID = foundProductID

        // Update persistence
        if foundPremium {
            PersistenceManager.shared.updateEntitlements { entitlements in
                entitlements.activatePremium()
            }
        } else {
            PersistenceManager.shared.updateEntitlements { entitlements in
                entitlements.deactivatePremium()
            }
        }
    }

    // MARK: - Transaction Listener

    /// Listens for transaction updates (renewals, revocations, etc.).
    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    await self.updatePurchasedProducts()
                    await transaction.finish()
                } catch {
                    print("StoreManager: Transaction update failed verification: \(error)")
                }
            }
        }
    }

    // MARK: - Verification

    /// Verifies a transaction result.
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    // MARK: - Helper Properties

    /// Monthly subscription product.
    var monthlyProduct: Product? {
        products.first { $0.id == ProductID.monthlyPremium.rawValue }
    }

    /// Yearly subscription product.
    var yearlyProduct: Product? {
        products.first { $0.id == ProductID.yearlyPremium.rawValue }
    }

    /// Formatted price for monthly subscription.
    var monthlyPriceString: String {
        monthlyProduct?.displayPrice ?? "$2.99/month"
    }

    /// Formatted price for yearly subscription.
    var yearlyPriceString: String {
        yearlyProduct?.displayPrice ?? "$19.99/year"
    }

    /// Whether the user is eligible for a free trial on a given product.
    func isTrialEligible(for product: Product) async -> Bool {
        guard let subscription = product.subscription else { return false }
        let status = await subscription.isEligibleForIntroOffer
        return status
    }

    /// Gets the trial period description (e.g. "7 days free") for a product.
    func trialDescription(for product: Product) -> String? {
        guard let subscription = product.subscription,
              let introOffer = subscription.introductoryOffer,
              introOffer.paymentMode == .freeTrial else { return nil }

        let period = introOffer.period
        switch period.unit {
        case .day:
            return "\(period.value) day\(period.value > 1 ? "s" : "") free"
        case .week:
            return "\(period.value) week\(period.value > 1 ? "s" : "") free"
        case .month:
            return "\(period.value) month\(period.value > 1 ? "s" : "") free"
        case .year:
            return "\(period.value) year\(period.value > 1 ? "s" : "") free"
        @unknown default:
            return "Free trial"
        }
    }
}

// MARK: - Errors

enum StoreError: LocalizedError {
    case failedVerification
    case productNotFound

    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "Transaction verification failed."
        case .productNotFound:
            return "Product not found."
        }
    }
}

/// Error thrown when an async operation exceeds its timeout.
struct TimeoutError: Error {}
