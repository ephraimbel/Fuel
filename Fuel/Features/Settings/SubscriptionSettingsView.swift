import SwiftUI

/// Subscription Settings View
/// Manage premium subscription

struct SubscriptionSettingsView: View {
    @State private var isPremium = false
    @State private var subscriptionType: SubscriptionType = .monthly
    @State private var expirationDate: Date? = nil
    @State private var showingPlanOptions = false

    var body: some View {
        ScrollView {
            VStack(spacing: FuelSpacing.xl) {
                // Current status
                currentStatusSection

                // Features
                featuresSection

                // Plans (if not premium)
                if !isPremium {
                    plansSection
                }

                // Manage subscription
                if isPremium {
                    manageSection
                }

                // Restore purchases
                restoreSection
            }
            .padding(.horizontal, FuelSpacing.screenHorizontal)
            .padding(.vertical, FuelSpacing.lg)
        }
        .background(FuelColors.background)
        .navigationTitle("Subscription")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Current Status Section

    private var currentStatusSection: some View {
        VStack(spacing: FuelSpacing.lg) {
            // Crown icon
            ZStack {
                Circle()
                    .fill(isPremium ? FuelColors.gold.opacity(0.2) : FuelColors.surfaceSecondary)
                    .frame(width: 80, height: 80)

                Image(systemName: "crown.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(isPremium ? FuelColors.gold : FuelColors.textTertiary)
            }

            // Status text
            VStack(spacing: FuelSpacing.xs) {
                Text(isPremium ? "Premium Member" : "Free Plan")
                    .font(FuelTypography.title2)
                    .foregroundStyle(FuelColors.textPrimary)

                if isPremium, let expiration = expirationDate {
                    Text("Renews \(expiration.formatted(date: .abbreviated, time: .omitted))")
                        .font(FuelTypography.subheadline)
                        .foregroundStyle(FuelColors.textSecondary)
                } else if !isPremium {
                    Text("Upgrade for unlimited features")
                        .font(FuelTypography.subheadline)
                        .foregroundStyle(FuelColors.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, FuelSpacing.lg)
    }

    // MARK: - Features Section

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: FuelSpacing.sm) {
            Text("PREMIUM FEATURES")
                .font(FuelTypography.caption)
                .foregroundStyle(FuelColors.textTertiary)

            VStack(spacing: 0) {
                featureRow(
                    icon: "sparkles",
                    title: "Unlimited AI Scans",
                    subtitle: "Scan any meal, unlimited times",
                    included: isPremium
                )

                Divider()
                    .padding(.leading, FuelSpacing.md + 32 + FuelSpacing.md)

                featureRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Advanced Analytics",
                    subtitle: "Detailed nutrition insights",
                    included: isPremium
                )

                Divider()
                    .padding(.leading, FuelSpacing.md + 32 + FuelSpacing.md)

                featureRow(
                    icon: "icloud.fill",
                    title: "Cloud Sync",
                    subtitle: "Sync across all your devices",
                    included: isPremium
                )

                Divider()
                    .padding(.leading, FuelSpacing.md + 32 + FuelSpacing.md)

                featureRow(
                    icon: "square.and.arrow.up",
                    title: "Data Export",
                    subtitle: "Export your data anytime",
                    included: isPremium
                )
            }
            .background(FuelColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
        }
    }

    private func featureRow(
        icon: String,
        title: String,
        subtitle: String,
        included: Bool
    ) -> some View {
        HStack(spacing: FuelSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(included ? FuelColors.primary : FuelColors.textTertiary)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: FuelSpacing.xxxs) {
                Text(title)
                    .font(FuelTypography.subheadlineMedium)
                    .foregroundStyle(FuelColors.textPrimary)

                Text(subtitle)
                    .font(FuelTypography.caption)
                    .foregroundStyle(FuelColors.textTertiary)
            }

            Spacer()

            Image(systemName: included ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(included ? FuelColors.success : FuelColors.textTertiary)
        }
        .padding(FuelSpacing.md)
    }

    // MARK: - Plans Section

    private var plansSection: some View {
        VStack(alignment: .leading, spacing: FuelSpacing.sm) {
            Text("CHOOSE A PLAN")
                .font(FuelTypography.caption)
                .foregroundStyle(FuelColors.textTertiary)

            VStack(spacing: FuelSpacing.sm) {
                planCard(
                    type: .yearly,
                    price: "$49.99",
                    period: "per year",
                    savings: "Save 58%",
                    isSelected: subscriptionType == .yearly
                )

                planCard(
                    type: .monthly,
                    price: "$9.99",
                    period: "per month",
                    savings: nil,
                    isSelected: subscriptionType == .monthly
                )
            }

            // Subscribe button
            Button {
                subscribe()
            } label: {
                Text("Start Free Trial")
                    .font(FuelTypography.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, FuelSpacing.md)
                    .background(FuelColors.primary)
                    .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
            }
            .padding(.top, FuelSpacing.sm)

            Text("7-day free trial, then \(subscriptionType == .yearly ? "$49.99/year" : "$9.99/month"). Cancel anytime.")
                .font(FuelTypography.caption)
                .foregroundStyle(FuelColors.textTertiary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
    }

    private func planCard(
        type: SubscriptionType,
        price: String,
        period: String,
        savings: String?,
        isSelected: Bool
    ) -> some View {
        Button {
            subscriptionType = type
            FuelHaptics.shared.select()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: FuelSpacing.xxs) {
                    HStack(spacing: FuelSpacing.sm) {
                        Text(type.displayName)
                            .font(FuelTypography.headline)
                            .foregroundStyle(FuelColors.textPrimary)

                        if let savings {
                            Text(savings)
                                .font(FuelTypography.caption)
                                .foregroundStyle(.white)
                                .padding(.horizontal, FuelSpacing.sm)
                                .padding(.vertical, 2)
                                .background(FuelColors.success)
                                .clipShape(Capsule())
                        }
                    }

                    Text("\(price) \(period)")
                        .font(FuelTypography.subheadline)
                        .foregroundStyle(FuelColors.textSecondary)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundStyle(isSelected ? FuelColors.primary : FuelColors.textTertiary)
            }
            .padding(FuelSpacing.md)
            .background(FuelColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
            .overlay(
                RoundedRectangle(cornerRadius: FuelSpacing.radiusMd)
                    .stroke(isSelected ? FuelColors.primary : Color.clear, lineWidth: 2)
            )
        }
    }

    // MARK: - Manage Section

    private var manageSection: some View {
        VStack(alignment: .leading, spacing: FuelSpacing.sm) {
            Text("MANAGE SUBSCRIPTION")
                .font(FuelTypography.caption)
                .foregroundStyle(FuelColors.textTertiary)

            Button {
                openSubscriptionManagement()
            } label: {
                HStack(spacing: FuelSpacing.md) {
                    Image(systemName: "gear")
                        .font(.system(size: 18))
                        .foregroundStyle(FuelColors.textSecondary)
                        .frame(width: 32)

                    Text("Manage in App Store")
                        .font(FuelTypography.subheadline)
                        .foregroundStyle(FuelColors.textPrimary)

                    Spacer()

                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 12))
                        .foregroundStyle(FuelColors.textTertiary)
                }
                .padding(FuelSpacing.md)
                .background(FuelColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
            }
        }
    }

    // MARK: - Restore Section

    private var restoreSection: some View {
        Button {
            restorePurchases()
        } label: {
            Text("Restore Purchases")
                .font(FuelTypography.subheadline)
                .foregroundStyle(FuelColors.primary)
        }
        .padding(.top, FuelSpacing.md)
    }

    // MARK: - Actions

    private func subscribe() {
        FuelHaptics.shared.tap()
        // TODO: Implement subscription via StoreKit
    }

    private func restorePurchases() {
        FuelHaptics.shared.tap()
        // TODO: Implement restore via StoreKit
    }

    private func openSubscriptionManagement() {
        if let url = URL(string: "itms-apps://apps.apple.com/account/subscriptions") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Subscription Type

enum SubscriptionType: String {
    case monthly
    case yearly

    var displayName: String {
        switch self {
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SubscriptionSettingsView()
    }
}
