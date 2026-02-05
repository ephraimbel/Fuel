import SwiftUI

/// Premium Trial Screen
/// Offers free trial of premium features

struct PremiumTrialScreen: View {
    @Bindable var viewModel: OnboardingViewModel

    @State private var selectedPlan: PlanOption = .yearly
    @State private var isLoading = false

    enum PlanOption {
        case monthly
        case yearly
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: FuelSpacing.lg) {
                // Header with Fuel+ branding
                VStack(spacing: FuelSpacing.md) {
                    // Flame icon
                    ZStack {
                        Circle()
                            .fill(FuelColors.primaryGradient)
                            .frame(width: 80, height: 80)

                        Image(systemName: "flame.fill")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .shadow(color: FuelColors.primary.opacity(0.4), radius: 12, y: 6)

                    // Fuel+ logo
                    HStack(spacing: 0) {
                        Text("Fuel")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(FuelColors.textPrimary)

                        Text("+")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.red)
                    }

                    Text("Start your 3-day free trial")
                        .font(FuelTypography.body)
                        .foregroundStyle(FuelColors.textSecondary)
                }
                .padding(.top, FuelSpacing.xl)

                // Features
                VStack(spacing: FuelSpacing.sm) {
                    premiumFeature(icon: "camera.viewfinder", title: "Unlimited AI Scans", description: "Analyze unlimited meals with AI")
                    premiumFeature(icon: "chart.xyaxis.line", title: "Advanced Analytics", description: "Detailed insights and trends")
                    premiumFeature(icon: "bell.badge.fill", title: "Smart Reminders", description: "Personalized notification timing")
                    premiumFeature(icon: "rectangle.stack.fill", title: "Custom Recipes", description: "Save and track your recipes")
                    premiumFeature(icon: "person.3.fill", title: "Family Sharing", description: "Share with up to 5 family members")
                }
                .padding(.horizontal, FuelSpacing.screenHorizontal)

                // Plan selection
                VStack(spacing: FuelSpacing.sm) {
                    planCard(
                        plan: .yearly,
                        title: "Yearly",
                        price: "$59.99/year",
                        detail: "Just $5/month",
                        badge: "SAVE 62%",
                        isSelected: selectedPlan == .yearly
                    )

                    planCard(
                        plan: .monthly,
                        title: "Monthly",
                        price: "$12.99/month",
                        detail: "Billed monthly",
                        badge: nil,
                        isSelected: selectedPlan == .monthly
                    )
                }
                .padding(.horizontal, FuelSpacing.screenHorizontal)

                // Trial note
                HStack(spacing: FuelSpacing.xs) {
                    Image(systemName: "checkmark.shield.fill")
                        .foregroundStyle(FuelColors.success)

                    Text("3-day free trial, cancel anytime")
                        .font(FuelTypography.caption)
                        .foregroundStyle(FuelColors.textSecondary)
                }

                Spacer()
                    .frame(height: FuelSpacing.lg)
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: FuelSpacing.sm) {
                // Primary CTA
                Button {
                    startTrial()
                } label: {
                    HStack(spacing: FuelSpacing.sm) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.9)
                        }
                        Text("Start 3-Day Free Trial")
                            .font(FuelTypography.headline)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, FuelSpacing.md)
                    .background(FuelColors.primary)
                    .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
                }
                .disabled(isLoading)

                Button {
                    FuelHaptics.shared.tap()
                    viewModel.nextStep()
                } label: {
                    Text("Continue with free plan")
                        .font(FuelTypography.subheadline)
                        .foregroundStyle(FuelColors.textSecondary)
                }

                // Legal
                Text("After your free trial, you'll be charged \(selectedPlan == .yearly ? "$59.99/year" : "$12.99/month"). Cancel anytime.")
                    .font(FuelTypography.caption)
                    .foregroundStyle(FuelColors.textTertiary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, FuelSpacing.screenHorizontal)
            .padding(.vertical, FuelSpacing.lg)
            .background(FuelColors.background)
        }
    }

    // MARK: - Actions

    private func startTrial() {
        FuelHaptics.shared.impact()
        isLoading = true

        Task {
            // Start the trial
            FeatureGateService.shared.startTrial()

            // Get the appropriate product
            let productID: SubscriptionService.ProductID = selectedPlan == .yearly
                ? .yearlyPremium
                : .monthlyPremium

            if let product = SubscriptionService.shared.product(for: productID) {
                do {
                    _ = try await SubscriptionService.shared.purchase(product)
                } catch SubscriptionError.userCancelled {
                    // User cancelled, still continue with trial
                } catch {
                    // Purchase failed, still continue with trial
                    #if DEBUG
                    print("Purchase error: \(error)")
                    #endif
                }
            }

            await MainActor.run {
                isLoading = false
                viewModel.nextStep()
            }
        }
    }

    private func premiumFeature(icon: String, title: String, description: String) -> some View {
        HStack(spacing: FuelSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: FuelSpacing.radiusMd, style: .continuous)
                    .fill(FuelColors.primaryLight)
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(FuelColors.primary)
            }

            VStack(alignment: .leading, spacing: FuelSpacing.xxxs) {
                Text(title)
                    .font(FuelTypography.headline)
                    .foregroundStyle(FuelColors.textPrimary)

                Text(description)
                    .font(FuelTypography.caption)
                    .foregroundStyle(FuelColors.textSecondary)
            }

            Spacer()

            Image(systemName: "checkmark")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(FuelColors.success)
        }
        .padding(FuelSpacing.sm)
    }

    private func planCard(
        plan: PlanOption,
        title: String,
        price: String,
        detail: String,
        badge: String?,
        isSelected: Bool
    ) -> some View {
        Button {
            FuelHaptics.shared.select()
            withAnimation(FuelAnimations.spring) {
                selectedPlan = plan
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: FuelSpacing.xxxs) {
                    HStack(spacing: FuelSpacing.xs) {
                        Text(title)
                            .font(FuelTypography.headline)
                            .foregroundStyle(FuelColors.textPrimary)

                        if let badge {
                            Text(badge)
                                .font(FuelTypography.caption)
                                .foregroundStyle(.white)
                                .padding(.horizontal, FuelSpacing.xs)
                                .padding(.vertical, FuelSpacing.xxxs)
                                .background(FuelColors.success)
                                .clipShape(Capsule())
                        }
                    }

                    Text(detail)
                        .font(FuelTypography.caption)
                        .foregroundStyle(FuelColors.textSecondary)
                }

                Spacer()

                Text(price)
                    .font(FuelTypography.headline)
                    .foregroundStyle(FuelColors.textPrimary)

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
            }
            .padding(FuelSpacing.md)
            .background(isSelected ? FuelColors.primaryLight : FuelColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: FuelSpacing.radiusMd, style: .continuous)
                    .stroke(isSelected ? FuelColors.primary : FuelColors.border, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .animation(FuelAnimations.spring, value: isSelected)
    }
}

#Preview {
    PremiumTrialScreen(viewModel: OnboardingViewModel())
}
