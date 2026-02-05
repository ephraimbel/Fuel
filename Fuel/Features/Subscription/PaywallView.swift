import SwiftUI

/// Paywall View
/// Premium upgrade screen with Fuel+ branding

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss

    var context: PaywallContext = .general

    @State private var selectedPlan: PlanType = .yearly
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""

    enum PlanType {
        case monthly
        case yearly
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: FuelSpacing.xl) {
                    // Logo and header
                    headerSection

                    // Context headline
                    contextHeadline

                    // Features list
                    featuresSection

                    // Plan selection
                    planSelectionSection

                    // CTA button
                    ctaSection

                    // Legal links
                    legalSection
                }
                .padding(.horizontal, FuelSpacing.screenHorizontal)
                .padding(.bottom, FuelSpacing.xxl)
            }
            .background(FuelColors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        FuelHaptics.shared.tap()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(FuelColors.textSecondary)
                            .frame(width: 32, height: 32)
                            .background(FuelColors.surfaceSecondary)
                            .clipShape(Circle())
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: FuelSpacing.lg) {
            // App icon
            ZStack {
                Circle()
                    .fill(FuelColors.primaryGradient)
                    .frame(width: 80, height: 80)

                Image(systemName: "flame.fill")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(.white)
            }
            .shadow(color: FuelColors.primary.opacity(0.3), radius: 12, y: 6)

            // Fuel+ logo
            fuelPlusLogo
        }
        .padding(.top, FuelSpacing.xl)
    }

    /// Fuel+ branded logo with red "+" accent
    private var fuelPlusLogo: some View {
        HStack(spacing: 0) {
            Text("Fuel")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(FuelColors.textPrimary)

            Text("+")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(Color.red)
        }
    }

    // MARK: - Context Headline

    private var contextHeadline: some View {
        VStack(spacing: FuelSpacing.sm) {
            Text(context.headline)
                .font(FuelTypography.title2)
                .foregroundStyle(FuelColors.textPrimary)
                .multilineTextAlignment(.center)

            Text(context.subheadline)
                .font(FuelTypography.body)
                .foregroundStyle(FuelColors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Features Section

    private var featuresSection: some View {
        VStack(spacing: FuelSpacing.sm) {
            ForEach(PaywallFeature.allFeatures) { feature in
                featureRow(icon: feature.icon, text: feature.title)
            }
        }
        .padding(FuelSpacing.lg)
        .background(FuelColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusLg))
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: FuelSpacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18))
                .foregroundStyle(FuelColors.success)

            Text(text)
                .font(FuelTypography.body)
                .foregroundStyle(FuelColors.textPrimary)

            Spacer()
        }
    }

    // MARK: - Plan Selection Section

    private var planSelectionSection: some View {
        VStack(spacing: FuelSpacing.sm) {
            // Monthly plan
            planCard(
                type: .monthly,
                title: "$12.99/month",
                subtitle: nil,
                badge: nil,
                isSelected: selectedPlan == .monthly
            )

            // Yearly plan (pre-selected, with savings)
            planCard(
                type: .yearly,
                title: "$59.99/year",
                subtitle: "Just $5/month",
                badge: "SAVE 62%",
                isSelected: selectedPlan == .yearly
            )
        }
    }

    private func planCard(
        type: PlanType,
        title: String,
        subtitle: String?,
        badge: String?,
        isSelected: Bool
    ) -> some View {
        Button {
            FuelHaptics.shared.select()
            withAnimation(FuelAnimations.spring) {
                selectedPlan = type
            }
        } label: {
            HStack {
                // Radio button
                ZStack {
                    Circle()
                        .stroke(isSelected ? FuelColors.primary : FuelColors.border, lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(FuelColors.primary)
                            .frame(width: 14, height: 14)
                    }
                }

                VStack(alignment: .leading, spacing: FuelSpacing.xxxs) {
                    HStack(spacing: FuelSpacing.sm) {
                        Text(title)
                            .font(FuelTypography.headline)
                            .foregroundStyle(FuelColors.textPrimary)

                        if let badge {
                            Text(badge)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, FuelSpacing.xs)
                                .padding(.vertical, 3)
                                .background(FuelColors.success)
                                .clipShape(Capsule())
                        }
                    }

                    if let subtitle {
                        Text(subtitle)
                            .font(FuelTypography.caption)
                            .foregroundStyle(FuelColors.textSecondary)
                    }
                }

                Spacer()
            }
            .padding(FuelSpacing.md)
            .background(isSelected ? FuelColors.primaryLight : FuelColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
            .overlay(
                RoundedRectangle(cornerRadius: FuelSpacing.radiusMd)
                    .stroke(isSelected ? FuelColors.primary : FuelColors.border, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - CTA Section

    private var ctaSection: some View {
        VStack(spacing: FuelSpacing.md) {
            // Primary CTA
            Button {
                handlePurchase()
            } label: {
                HStack(spacing: FuelSpacing.sm) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.9)
                    }

                    Text(context.showTrialOption ? "Start 3-Day Free Trial" : context.primaryCTA)
                        .font(FuelTypography.headline)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, FuelSpacing.md)
                .background(FuelColors.primary)
                .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
            }
            .disabled(isLoading)

            // Dismiss option
            Button {
                FuelHaptics.shared.tap()
                dismiss()
            } label: {
                Text("Maybe Later")
                    .font(FuelTypography.subheadline)
                    .foregroundStyle(FuelColors.textSecondary)
            }
        }
    }

    // MARK: - Legal Section

    private var legalSection: some View {
        VStack(spacing: FuelSpacing.md) {
            Divider()

            HStack(spacing: FuelSpacing.lg) {
                Button {
                    restorePurchases()
                } label: {
                    Text("Restore Purchases")
                        .font(FuelTypography.caption)
                        .foregroundStyle(FuelColors.textSecondary)
                }

                Text("•")
                    .foregroundStyle(FuelColors.textTertiary)

                Button {
                    // Open terms
                } label: {
                    Text("Terms")
                        .font(FuelTypography.caption)
                        .foregroundStyle(FuelColors.textSecondary)
                }

                Text("•")
                    .foregroundStyle(FuelColors.textTertiary)

                Button {
                    // Open privacy
                } label: {
                    Text("Privacy")
                        .font(FuelTypography.caption)
                        .foregroundStyle(FuelColors.textSecondary)
                }
            }

            if context.showTrialOption {
                Text("After your free trial, you'll be charged \(selectedPlan == .yearly ? "$59.99/year" : "$12.99/month"). Cancel anytime.")
                    .font(FuelTypography.caption)
                    .foregroundStyle(FuelColors.textTertiary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Actions

    private func handlePurchase() {
        FuelHaptics.shared.impact()
        isLoading = true

        Task {
            do {
                // Get the appropriate product
                let productID: SubscriptionService.ProductID = selectedPlan == .yearly
                    ? .yearlyPremium
                    : .monthlyPremium

                guard let product = SubscriptionService.shared.product(for: productID) else {
                    throw SubscriptionError.productLoadFailed(NSError(domain: "", code: -1))
                }

                // Start trial if eligible and selected
                if context.showTrialOption && !FeatureGateService.shared.hasUsedTrial {
                    FeatureGateService.shared.startTrial()
                }

                // Attempt purchase
                _ = try await SubscriptionService.shared.purchase(product)

                await MainActor.run {
                    isLoading = false
                    dismiss()
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
                    dismiss()
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
}

// MARK: - Preview

#Preview {
    PaywallView(context: .scanLimit)
}

#Preview("Trial Ended") {
    PaywallView(context: .trialEnded)
}
