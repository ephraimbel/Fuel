import Foundation
import StoreKit

/// Subscription Service
/// Handles in-app purchases and subscription management using StoreKit 2

@Observable
public final class SubscriptionService {
    // MARK: - Singleton

    public static let shared = SubscriptionService()

    // MARK: - Product IDs

    public enum ProductID: String, CaseIterable {
        case weeklyPremium = "com.fuel.premium.weekly"
        case monthlyPremium = "com.fuel.premium.monthly"
        case yearlyPremium = "com.fuel.premium.yearly"
        case lifetime = "com.fuel.premium.lifetime"

        var isSubscription: Bool {
            self != .lifetime
        }
    }

    // MARK: - State

    public private(set) var products: [Product] = []
    public private(set) var purchasedProductIDs: Set<String> = []
    public private(set) var subscriptionStatus: SubscriptionStatus = .none
    public private(set) var isLoading = false
    public private(set) var error: SubscriptionError?

    // MARK: - Computed

    public var isPremium: Bool {
        subscriptionStatus == .premium || subscriptionStatus == .lifetime
    }

    public var hasActiveSubscription: Bool {
        !purchasedProductIDs.isEmpty
    }

    // MARK: - Private

    private var updateListenerTask: Task<Void, Error>?

    // MARK: - Initialization

    private init() {
        updateListenerTask = listenForTransactions()
        Task {
            await loadProducts()
            await updateSubscriptionStatus()
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Public Methods

    /// Load available products
    @MainActor
    public func loadProducts() async {
        isLoading = true
        error = nil

        do {
            let productIDs = ProductID.allCases.map { $0.rawValue }
            products = try await Product.products(for: productIDs)
            products.sort { $0.price < $1.price }
            isLoading = false
        } catch {
            self.error = .productLoadFailed(error)
            isLoading = false
        }
    }

    /// Purchase a product
    @MainActor
    public func purchase(_ product: Product) async throws -> Transaction? {
        isLoading = true
        error = nil

        defer { isLoading = false }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)

            // Update purchased products
            purchasedProductIDs.insert(product.id)
            await updateSubscriptionStatus()

            // Finish transaction
            await transaction.finish()

            FuelHaptics.shared.celebration()

            return transaction

        case .pending:
            throw SubscriptionError.purchasePending

        case .userCancelled:
            throw SubscriptionError.userCancelled

        @unknown default:
            throw SubscriptionError.unknown
        }
    }

    /// Restore purchases
    @MainActor
    public func restorePurchases() async throws {
        isLoading = true
        error = nil

        defer { isLoading = false }

        try await AppStore.sync()
        await updateSubscriptionStatus()

        if purchasedProductIDs.isEmpty {
            throw SubscriptionError.noPurchasesToRestore
        }

        FuelHaptics.shared.success()
    }

    /// Check if user can make purchases
    public func canMakePurchases() -> Bool {
        AppStore.canMakePayments
    }

    /// Get product by ID
    public func product(for productID: ProductID) -> Product? {
        products.first { $0.id == productID.rawValue }
    }

    // MARK: - Private Methods

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                do {
                    let transaction = try self?.checkVerified(result)
                    await self?.updateSubscriptionStatus()
                    await transaction?.finish()
                } catch {
                    print("Transaction verification failed: \(error)")
                }
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw SubscriptionError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }

    @MainActor
    private func updateSubscriptionStatus() async {
        var newPurchasedIDs: Set<String> = []

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }

            if transaction.revocationDate == nil {
                newPurchasedIDs.insert(transaction.productID)
            }
        }

        purchasedProductIDs = newPurchasedIDs

        // Determine subscription status
        if purchasedProductIDs.contains(ProductID.lifetime.rawValue) {
            subscriptionStatus = .lifetime
        } else if !purchasedProductIDs.isEmpty {
            subscriptionStatus = .premium
        } else {
            subscriptionStatus = .none
        }
    }
}

// MARK: - Subscription Status

public enum SubscriptionStatus: String {
    case none
    case premium
    case lifetime

    public var displayName: String {
        switch self {
        case .none: return "Free"
        case .premium: return "Premium"
        case .lifetime: return "Lifetime"
        }
    }

    public var aiScansPerDay: Int {
        switch self {
        case .none: return 3
        case .premium, .lifetime: return .max
        }
    }
}

// MARK: - Subscription Error

public enum SubscriptionError: LocalizedError {
    case productLoadFailed(Error)
    case purchasePending
    case purchaseFailed(Error)
    case verificationFailed
    case userCancelled
    case noPurchasesToRestore
    case unknown

    public var errorDescription: String? {
        switch self {
        case .productLoadFailed(let error):
            return "Failed to load products: \(error.localizedDescription)"
        case .purchasePending:
            return "Purchase is pending approval"
        case .purchaseFailed(let error):
            return "Purchase failed: \(error.localizedDescription)"
        case .verificationFailed:
            return "Transaction verification failed"
        case .userCancelled:
            return "Purchase was cancelled"
        case .noPurchasesToRestore:
            return "No previous purchases found"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}

// MARK: - Subscription Product Helper

public struct SubscriptionProduct: Identifiable {
    public let id: String
    public let product: Product
    public let productID: SubscriptionService.ProductID

    public var name: String {
        product.displayName
    }

    public var description: String {
        product.description
    }

    public var price: String {
        product.displayPrice
    }

    public var pricePerMonth: String? {
        guard let subscription = product.subscription else { return nil }

        let months: Decimal
        switch subscription.subscriptionPeriod.unit {
        case .week:
            months = Decimal(subscription.subscriptionPeriod.value) / 4
        case .month:
            months = Decimal(subscription.subscriptionPeriod.value)
        case .year:
            months = Decimal(subscription.subscriptionPeriod.value) * 12
        default:
            return nil
        }

        let monthlyPrice = product.price / months
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = product.priceFormatStyle.locale

        return formatter.string(from: monthlyPrice as NSDecimalNumber)
    }

    public var periodLabel: String {
        guard let subscription = product.subscription else { return "One-time" }

        switch subscription.subscriptionPeriod.unit {
        case .week:
            return subscription.subscriptionPeriod.value == 1 ? "week" : "\(subscription.subscriptionPeriod.value) weeks"
        case .month:
            return subscription.subscriptionPeriod.value == 1 ? "month" : "\(subscription.subscriptionPeriod.value) months"
        case .year:
            return subscription.subscriptionPeriod.value == 1 ? "year" : "\(subscription.subscriptionPeriod.value) years"
        default:
            return ""
        }
    }

    public var isPopular: Bool {
        productID == .yearlyPremium
    }

    public var savings: String? {
        guard productID == .yearlyPremium,
              let monthlyProduct = SubscriptionService.shared.product(for: .monthlyPremium) else {
            return nil
        }

        let yearlyMonthly = product.price / 12
        let savings = ((monthlyProduct.price - yearlyMonthly) / monthlyProduct.price) * 100

        return "Save \(Int(truncating: savings as NSDecimalNumber))%"
    }

    public init?(product: Product) {
        guard let productID = SubscriptionService.ProductID(rawValue: product.id) else {
            return nil
        }
        self.id = product.id
        self.product = product
        self.productID = productID
    }
}
