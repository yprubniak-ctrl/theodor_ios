import Foundation
import StoreKit

/// Manages Theodore+ subscription state.
/// Replace with RevenueCat SDK for production — this is a clean StoreKit 2 fallback.
@MainActor
final class SubscriptionService: ObservableObject {

    static let shared = SubscriptionService()

    // Product ID — must match App Store Connect
    static let annualProductID = "com.yourapp.theodore.annual"
    static let freeChapterLimit = 1

    @Published var isSubscribed: Bool = false
    @Published var isLoading: Bool = false

    private var product: Product?

    init() {
        Task { await refresh() }
    }

    // ── MARK: State ───────────────────────────────────────────

    func canCreateChapter(existingCount: Int) -> Bool {
        isSubscribed || existingCount < Self.freeChapterLimit
    }

    // ── MARK: Purchase ────────────────────────────────────────

    func purchase() async throws {
        isLoading = true
        defer { isLoading = false }

        if product == nil { try await loadProduct() }
        guard let product else { throw SubscriptionError.productNotFound }

        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            isSubscribed = true
        case .userCancelled:
            break
        case .pending:
            break
        @unknown default:
            break
        }
    }

    func restore() async {
        isLoading = true
        defer { isLoading = false }
        try? await AppStore.sync()
        await refresh()
    }

    // ── MARK: Internal ────────────────────────────────────────

    func refresh() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.annualProductID,
               transaction.revocationDate == nil {
                isSubscribed = true
                return
            }
        }
        isSubscribed = false
    }

    private func loadProduct() async throws {
        let products = try await Product.products(for: [Self.annualProductID])
        product = products.first
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified: throw SubscriptionError.verificationFailed
        case .verified(let value): return value
        }
    }
}

enum SubscriptionError: LocalizedError {
    case productNotFound
    case verificationFailed

    var errorDescription: String? {
        switch self {
        case .productNotFound: return "Theodore+ not found in the App Store."
        case .verificationFailed: return "Purchase verification failed. Please try again."
        }
    }
}
