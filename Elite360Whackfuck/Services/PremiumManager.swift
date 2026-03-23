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
        let apiKey = "YOUR_REVENUECAT_API_KEY"
        guard apiKey != "YOUR_REVENUECAT_API_KEY" else {
            print("⚠️ RevenueCat API key not set — premium features disabled. Replace YOUR_REVENUECAT_API_KEY in PremiumManager.swift.")
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
