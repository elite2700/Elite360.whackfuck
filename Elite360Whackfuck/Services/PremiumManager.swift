import Foundation
import RevenueCat

@MainActor
final class PremiumManager: ObservableObject {
    static let shared = PremiumManager()

    @Published var isPremium = false
    @Published var currentOffering: Offering?
    @Published var availablePackages: [Package] = []

    private init() {}

    func configure() {
        // Configure RevenueCat with your API key
        Purchases.configure(withAPIKey: "YOUR_REVENUECAT_API_KEY")
    }

    func checkPremiumStatus() async {
        do {
            let info = try await Purchases.shared.customerInfo()
            isPremium = info.entitlements["premium"]?.isActive == true
        } catch {
            isPremium = false
        }
    }

    func loadOfferings() async {
        do {
            let offerings = try await Purchases.shared.offerings()
            currentOffering = offerings.current
            availablePackages = offerings.current?.availablePackages ?? []
        } catch {
            availablePackages = []
        }
    }

    func purchase(_ package: Package) async throws -> Bool {
        let result = try await Purchases.shared.purchase(package: package)
        isPremium = result.customerInfo.entitlements["premium"]?.isActive == true
        return isPremium
    }

    func restorePurchases() async throws -> Bool {
        let info = try await Purchases.shared.restorePurchases()
        isPremium = info.entitlements["premium"]?.isActive == true
        return isPremium
    }
}
