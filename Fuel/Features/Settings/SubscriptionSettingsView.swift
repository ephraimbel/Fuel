import SwiftUI

/// Subscription Settings View
/// Manage premium subscription

struct SubscriptionSettingsView: View {
    @State private var subscriptionType: SubscriptionType = .yearly
    @State private var expirationDate: Date? = nil
    @State private var showingPlanOptions = false
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""

    private var isPremium: Bool {
        FeatureGateService.shared.isPremium
    }

    private var remainingScans: Int {
        FeatureGateService.shared.remainingAIScans
    }

    private var isInTrial: Bool {
        FeatureGateService.shared.isInTrial
    }

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
            // Icon - Fuel+ branding for premium
            ZStack {
                Circle()
                    .fill(isPremium ? FuelColors.primary.opacity(0.2) : FuelColors.surfaceSecondary)
                    .frame(width: 80, height: 80)

                Image(systemName: isPremium ? "flame.fill" : "flame")
                    .font(.system(size: 36))
                    .foregroundStyle(isPremium ? FuelColors.primary : FuelColors.textTertiary)
            }

            // Status text
            VStack(spacing: FuelSpacing.xs) {
                if isPremium {
                    // Fuel+ branding
                    HStack(spacing: 0) {
                        Text("Fuel")
                            .font(FuelTypography.title2)
                            .foregroundStyle(FuelColors.textPrimary)

                        Text("+")
                            .font(FuelTypography.title2)
                            .foregroundStyle(Color.red)

                        Text(" Member")
                            .font(FuelTypography.title2)
                            .foregroundStyle(FuelColors.textPrimary)
                    }

                    if isInTrial {
                        Text("\(FeatureGateService.shared.trialDaysRemaining) days left in trial")
                            .font(FuelTypography.subheadline)
                            .foregroundStyle(FuelColors.warning)
                    } else if let expiration = expirationDate {
                        Text("Renews \(expiration.formatted(date: .abbreviated, time: .omitted))")
                            .font(FuelTypography.subheadline)
                            .foregroundStyle(FuelColors.textSecondary)
                    }
                } else {
                    Text("Free Plan")
                        .font(FuelTypography.title2)
                        .foregroundStyle(FuelColors.textPrimary)

                    Text("Upgrade for unlimited features")
                        .font(FuelTypography.subheadline)
                        .foregroundStyle(FuelColors.textSecondary)
                }
            }

            // Scan usage for free users
            if !isPremium {
                scanUsageIndicator
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, FuelSpacing.lg)
    }

    // MARK: - Scan Usage Indicator

    private var scanUsageIndicator: some View {
        VStack(spacing: FuelSpacing.sm) {
            HStack {
                Image(systemName: "camera.viewfinder")
                    .foregroundStyle(FuelColors.primary)

                Text("AI Scans This Week")
                    .font(FuelTypography.subheadline)
                    .foregroundStyle(FuelColors.textPrimary)

                Spacer()

                Text("\(remainingScans) of 3 remaining")
                    .font(FuelTypography.subheadlineMedium)
                    .foregroundStyle(remainingScans == 0 ? FuelColors.error : FuelColors.textSecondary)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(FuelColors.surfaceSecondary)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(remainingScans == 0 ? FuelColors.error : FuelColors.primary)
                        .frame(width: geometry.size.width * CGFloat(3 - remainingScans) / 3)
                }
            }
            .frame(height: 8)
        }
        .padding(FuelSpacing.md)
        .background(FuelColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
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
                    price: "$59.99",
                    period: "per year",
                    savings: "Save 62%",
                    isSelected: subscriptionType == .yearly
                )

                planCard(
                    type: .monthly,
                    price: "$12.99",
                    period: "per month",
                    savings: nil,
                    isSelected: subscriptionType == .monthly
                )
            }

            // Subscribe button
            Button {
                subscribe()
            } label: {
                HStack(spacing: FuelSpacing.sm) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.9)
                    }

                    Text(FeatureGateService.shared.hasUsedTrial ? "Subscribe Now" : "Start 3-Day Free Trial")
                        .font(FuelTypography.headline)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, FuelSpacing.md)
                .background(FuelColors.primary)
                .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
            }
            .disabled(isLoading)
            .padding(.top, FuelSpacing.sm)

            Text("3-day free trial, then \(subscriptionType == .yearly ? "$59.99/year" : "$12.99/month"). Cancel anytime.")
                .font(FuelTypography.caption)
                .foregroundStyle(FuelColors.textTertiary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
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
        FuelHaptics.shared.impact()
        isLoading = true

        Task {
            do {
                // Start trial if not used yet
                if !FeatureGateService.shared.hasUsedTrial {
                    FeatureGateService.shared.startTrial()
                }

                // Get the appropriate product
                let productID: SubscriptionService.ProductID = subscriptionType == .yearly
                    ? .yearlyPremium
                    : .monthlyPremium

                guard let product = SubscriptionService.shared.product(for: productID) else {
                    throw SubscriptionError.productLoadFailed(NSError(domain: "", code: -1))
                }

                _ = try await SubscriptionService.shared.purchase(product)

                await MainActor.run {
                    isLoading = false
                }
            } catch SubscriptionError.userCancelled {
                await MainActor.run {
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }

    private func restorePurchases() {
        FuelHaptics.shared.tap()
        isLoading = true

        Task {
            do {
                try await SubscriptionService.shared.restorePurchases()
                await MainActor.run {
                    isLoading = false
                }
            } catch SubscriptionError.noPurchasesToRestore {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "No previous purchases found."
                    showError = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
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
