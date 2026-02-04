import SwiftUI

/// Premium Trial Screen
/// Offers free trial of premium features

struct PremiumTrialScreen: View {
    @Bindable var viewModel: OnboardingViewModel

    @State private var selectedPlan: PlanOption = .yearly

    enum PlanOption {
        case weekly
        case yearly
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: FuelSpacing.lg) {
                // Header
                VStack(spacing: FuelSpacing.md) {
                    // Crown icon
                    ZStack {
                        Circle()
                            .fill(FuelColors.goldGradient)
                            .frame(width: 80, height: 80)

                        Image(systemName: "crown.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(.white)
                    }
                    .shadow(color: FuelColors.gold.opacity(0.4), radius: 12, y: 6)

                    Text("Try Fuel Premium Free")
                        .font(FuelTypography.title1)
                        .foregroundStyle(FuelColors.textPrimary)

                    Text("Start your 7-day free trial")
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
                        price: "$49.99/year",
                        detail: "Just $4.17/month",
                        badge: "Best Value",
                        isSelected: selectedPlan == .yearly
                    )

                    planCard(
                        plan: .weekly,
                        title: "Weekly",
                        price: "$2.99/week",
                        detail: "Billed weekly",
                        badge: nil,
                        isSelected: selectedPlan == .weekly
                    )
                }
                .padding(.horizontal, FuelSpacing.screenHorizontal)

                // Trial note
                HStack(spacing: FuelSpacing.xs) {
                    Image(systemName: "checkmark.shield.fill")
                        .foregroundStyle(FuelColors.success)

                    Text("7-day free trial, cancel anytime")
                        .font(FuelTypography.caption)
                        .foregroundStyle(FuelColors.textSecondary)
                }

                Spacer()
                    .frame(height: FuelSpacing.lg)
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: FuelSpacing.sm) {
                FuelButton("Start Free Trial") {
                    FuelHaptics.shared.impact()
                    // Start trial flow
                    viewModel.nextStep()
                }

                Button {
                    FuelHaptics.shared.tap()
                    viewModel.nextStep()
                } label: {
                    Text("Continue with free plan")
                        .font(FuelTypography.subheadline)
                        .foregroundStyle(FuelColors.textSecondary)
                }

                // Legal
                Text("Payment will be charged after trial ends. Cancel anytime in Settings.")
                    .font(FuelTypography.caption)
                    .foregroundStyle(FuelColors.textTertiary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, FuelSpacing.screenHorizontal)
            .padding(.vertical, FuelSpacing.lg)
            .background(FuelColors.background)
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
