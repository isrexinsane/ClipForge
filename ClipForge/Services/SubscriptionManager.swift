//
//  SubscriptionManager.swift
//  ClipForge
//
//  Manages StoreKit 2 subscription lifecycle: product loading, purchase,
//  restore, and entitlement verification. Syncs premium status with
//  FreemiumGatekeeper.
//
//  STORY-8.1: SubscriptionManager Service
//

import StoreKit
import Foundation

/// Purchase flow state.
enum PurchaseState: Equatable {
    case idle
    case purchasing
    case success
    case failed(String)
}

/// Handles the ClipForge Premium yearly subscription via StoreKit 2.
///
/// On init and on each app-foreground event, checks `Transaction.currentEntitlements`
/// to determine whether the user has an active subscription. Syncs the result
/// to `FreemiumGatekeeper.isPremium`.
///
/// The product ID must be configured in App Store Connect before real purchases
/// work. In the Simulator, `product` will be nil and purchases will fail
/// gracefully — this is expected.
@MainActor
final class SubscriptionManager: ObservableObject {

    // MARK: - Singleton

    static let shared = SubscriptionManager()

    // MARK: - Constants

    static let productID = "com.roninart.clipforge.premium.yearly"

    // MARK: - Published State

    @Published private(set) var product: Product?
    @Published var purchaseState: PurchaseState = .idle
    @Published private(set) var isPremium: Bool = false

    // MARK: - Private

    private var transactionListener: Task<Void, Never>?

    // MARK: - Init

    private init() {
        // Listen for transaction updates (renewals, revocations, external purchases)
        transactionListener = Task {
            await listenForTransactions()
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Product Loading

    /// Loads the subscription product from the App Store.
    /// Call this early (e.g., on SubscriptionView appear).
    func loadProduct() async {
        do {
            let products = try await Product.products(for: [Self.productID])
            product = products.first
        } catch {
            // Product not found — expected in Simulator without StoreKit config.
            #if DEBUG
            print("[SubscriptionManager] Failed to load product: \(error.localizedDescription)")
            #endif
        }
    }

    // MARK: - Purchase

    /// Initiates a purchase of the yearly subscription.
    func purchase() async {
        guard let product else {
            purchaseState = .failed("Subscription not available. Please try again later.")
            return
        }

        purchaseState = .purchasing

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerification(verification)
                await transaction.finish()
                syncPremiumStatus(true)
                purchaseState = .success

            case .userCancelled:
                purchaseState = .idle

            case .pending:
                // Transaction requires approval (e.g., Ask to Buy).
                purchaseState = .failed("Purchase is pending approval.")

            @unknown default:
                purchaseState = .failed("An unexpected error occurred.")
            }
        } catch {
            purchaseState = .failed("Purchase failed. Please try again.")
        }
    }

    // MARK: - Restore

    /// Restores previous purchases by checking current entitlements.
    /// Returns true if an active subscription was found.
    @discardableResult
    func restorePurchases() async -> Bool {
        // Sync with the App Store to pick up purchases from other devices.
        try? await AppStore.sync()

        let found = await checkEntitlements()
        return found
    }

    // MARK: - Entitlement Check

    /// Checks Transaction.currentEntitlements for an active subscription.
    /// Call on app launch to sync premium state.
    @discardableResult
    func checkEntitlements() async -> Bool {
        var hasPremium = false

        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerification(result) {
                if transaction.productID == Self.productID,
                   transaction.revocationDate == nil {
                    hasPremium = true
                }
            }
        }

        syncPremiumStatus(hasPremium)
        return hasPremium
    }

    // MARK: - Private

    /// Listens for real-time transaction updates (renewals, revocations).
    private func listenForTransactions() async {
        for await result in Transaction.updates {
            if let transaction = try? checkVerification(result) {
                await transaction.finish()
                // Re-check all entitlements to get the full picture
                await checkEntitlements()
            }
        }
    }

    /// Verifies a StoreKit transaction result.
    private func checkVerification<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let value):
            return value
        }
    }

    /// Syncs premium status to both this manager and FreemiumGatekeeper.
    private func syncPremiumStatus(_ premium: Bool) {
        isPremium = premium
        FreemiumGatekeeper.shared.isPremium = premium
    }
}
