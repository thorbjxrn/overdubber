import Foundation
import StoreKit

@Observable
@MainActor
final class PurchaseManager {
    static let productID = "com.thorbjxrn.overdubber.premium"

    private(set) var product: Product?
    private(set) var isPremium: Bool = false
    private(set) var isLoading: Bool = false
    private(set) var productLoadFailed: Bool = false
    var errorMessage: String?

    @ObservationIgnored
    private var transactionListener: Task<Void, Never>?

    init() {
        isPremium = false
        transactionListener = listenForTransactions()
        Task {
            await loadProducts()
            await verifyEntitlement()
        }
    }

    deinit {
        let listener = transactionListener
        listener?.cancel()
    }

    func loadProducts() async {
        productLoadFailed = false
        do {
            let products = try await Product.products(for: [Self.productID])
            product = products.first
            if product == nil {
                productLoadFailed = true
            }
        } catch {
            print("Failed to load products: \(error)")
            productLoadFailed = true
        }
    }

    func purchase() async throws {
        guard let product else {
            errorMessage = "Product not available. Please try again later."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                isPremium = true
            case .userCancelled:
                break
            case .pending:
                errorMessage = "Purchase is pending approval."
            @unknown default:
                errorMessage = "An unexpected error occurred."
            }
        } catch {
            errorMessage = "Purchase failed: \(error.localizedDescription)"
            throw error
        }

        isLoading = false
    }

    func restorePurchases() async {
        isLoading = true
        errorMessage = nil

        do {
            try await AppStore.sync()
            await verifyEntitlement()
        } catch {
            errorMessage = "Restore failed: \(error.localizedDescription)"
        }

        isLoading = false
    }

    private func verifyEntitlement() async {
        do {
            let result = await Transaction.currentEntitlement(for: Self.productID)
            if let result {
                let transaction = try checkVerified(result)
                _ = transaction
                isPremium = true
            } else {
                isPremium = false
            }
        } catch {
            print("Entitlement verification error: \(error)")
        }
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                do {
                    let transaction = try self?.checkVerified(result)
                    if let transaction {
                        await transaction.finish()
                        await self?.verifyEntitlement()
                    }
                } catch {
                    print("Transaction verification failed: \(error)")
                }
            }
        }
    }

    nonisolated private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error): throw error
        case .verified(let value): return value
        }
    }

    #if DEBUG
    func debugTogglePremium() {
        isPremium.toggle()
    }
    #endif
}
