import Foundation
import RevenueCat

@MainActor
final class PremiumManager: ObservableObject {
    static let shared = PremiumManager()

    @Published var isPremium = false
    @Published var currentOffering: Offering?
    @Published var availablePackages: [Package] = []

    private var isConfigured = false

    private init() {}

    func configure() {
        guard let apiKey = SecretsManager.revenueCatAPIKey else {
            print("⚠️ RevenueCat API key not found in Secrets.plist — premium features disabled.")
            return
        }
        Purchases.configure(withAPIKey: apiKey)
        isConfigured = true
    }

    func checkPremiumStatus() async {
        guard isConfigured else { return }
        do {
            let info = try await Purchases.shared.customerInfo()
            isPremium = info.entitlements["premium"]?.isActive == true
        } catch {
            isPremium = false
        }
    }

    func loadOfferings() async {
        guard isConfigured else { return }
        do {
            let offerings = try await Purchases.shared.offerings()
            currentOffering = offerings.current
            availablePackages = offerings.current?.availablePackages ?? []
        } catch {
            availablePackages = []
        }
    }

    func purchase(_ package: Package) async throws -> Bool {
        guard isConfigured else { return false }
        let result = try await Purchases.shared.purchase(package: package)
        isPremium = result.customerInfo.entitlements["premium"]?.isActive == true
        return isPremium
    }

    func restorePurchases() async throws -> Bool {
        guard isConfigured else { return false }
        let info = try await Purchases.shared.restorePurchases()
        isPremium = info.entitlements["premium"]?.isActive == true
        return isPremium
    }
}
