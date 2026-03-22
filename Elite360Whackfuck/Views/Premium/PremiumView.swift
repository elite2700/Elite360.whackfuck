import SwiftUI

struct PremiumView: View {
    @EnvironmentObject var premiumManager: PremiumManager
    @Environment(\.dismiss) private var dismiss
    @State private var isPurchasing = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.yellow)
                        Text("Elite360 Premium")
                            .font(.title.bold())
                        Text("Unlock the full experience")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 40)

                    // Features
                    VStack(alignment: .leading, spacing: 16) {
                        PremiumFeatureRow(icon: "trophy.fill", title: "All Golf Games",
                                        description: "Nassau, Skins, Wolf, Bingo Bango Bongo, and 10+ more")
                        PremiumFeatureRow(icon: "wrench.and.screwdriver.fill", title: "Custom Game Creator",
                                        description: "Build and save your own game formats")
                        PremiumFeatureRow(icon: "brain", title: "AI Caddy",
                                        description: "Smart club and strategy recommendations")
                        PremiumFeatureRow(icon: "chart.bar.fill", title: "Advanced Analytics",
                                        description: "Strokes gained, trends, head-to-head stats")
                        PremiumFeatureRow(icon: "person.3.fill", title: "Unlimited Groups",
                                        description: "Create unlimited groups and leagues")
                        PremiumFeatureRow(icon: "xmark.circle", title: "Ad-Free",
                                        description: "No ads, no interruptions")
                    }
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)

                    // Pricing
                    VStack(spacing: 12) {
                        // Monthly
                        PricingCard(
                            title: "Monthly",
                            price: "$9.99/mo",
                            isPopular: false
                        ) {
                            Task { await purchase(index: 0) }
                        }

                        // Annual
                        PricingCard(
                            title: "Annual",
                            price: "$79.99/yr",
                            isPopular: true,
                            badge: "Save 33%"
                        ) {
                            Task { await purchase(index: 1) }
                        }
                    }
                    .padding(.horizontal)

                    if isPurchasing {
                        ProgressView("Processing...")
                            .padding()
                    }

                    // Restore
                    Button("Restore Purchases") {
                        Task {
                            _ = try? await premiumManager.restorePurchases()
                            if premiumManager.isPremium { dismiss() }
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    // Terms
                    VStack(spacing: 4) {
                        Text("Payment will be charged to your Apple ID account at confirmation of purchase.")
                        Text("Subscription automatically renews unless cancelled at least 24 hours before end of current period.")
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
            .task {
                await premiumManager.loadOfferings()
            }
        }
    }

    private func purchase(index: Int) async {
        guard index < premiumManager.availablePackages.count else { return }
        isPurchasing = true
        _ = try? await premiumManager.purchase(premiumManager.availablePackages[index])
        isPurchasing = false
        if premiumManager.isPremium { dismiss() }
    }
}

struct PremiumFeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .foregroundStyle(.yellow)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        }
    }
}

struct PricingCard: View {
    let title: String
    let price: String
    var isPopular: Bool = false
    var badge: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                if let badge {
                    Text(badge)
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(.orange)
                        .clipShape(Capsule())
                }
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                Text(price)
                    .font(.title2.bold())
                    .foregroundStyle(.green)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isPopular ? .green.opacity(0.1) : .regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isPopular ? .green : .clear, lineWidth: 2)
            )
        }
    }
}
