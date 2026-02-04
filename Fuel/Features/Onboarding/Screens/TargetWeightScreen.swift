import SwiftUI

/// Target Weight Screen
/// User sets their goal weight

struct TargetWeightScreen: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        OnboardingScreenLayout(
            title: "What's your goal weight?",
            subtitle: goalSubtitle
        ) {
            VStack(spacing: FuelSpacing.xl) {
                // Weight change indicator
                if viewModel.selectedGoal != .maintain {
                    weightChangeIndicator
                        .padding(.horizontal, FuelSpacing.screenHorizontal)
                }

                // Weight display
                VStack(spacing: FuelSpacing.xs) {
                    HStack(alignment: .firstTextBaseline, spacing: FuelSpacing.xs) {
                        Text(weightDisplayValue)
                            .font(FuelTypography.hero)
                            .foregroundStyle(FuelColors.textPrimary)
                            .contentTransition(.numericText())

                        Text(viewModel.useMetricWeight ? "kg" : "lbs")
                            .font(FuelTypography.title2)
                            .foregroundStyle(FuelColors.textSecondary)
                    }

                    // Time estimate
                    if viewModel.selectedGoal != .maintain && weightDifferenceDisplay != "0" {
                        Text("Estimated time: ~\(viewModel.estimatedWeeks) weeks")
                            .font(FuelTypography.subheadline)
                            .foregroundStyle(FuelColors.textSecondary)
                    }
                }
                .animation(FuelAnimations.spring, value: viewModel.useMetricWeight)

                // Weight picker
                if viewModel.useMetricWeight {
                    WeightPicker(
                        value: $viewModel.targetWeightKg,
                        range: 30...250,
                        unit: "kg"
                    )
                    .onChange(of: viewModel.targetWeightKg) { _, newValue in
                        viewModel.targetWeightLbs = newValue * 2.20462
                    }
                } else {
                    WeightPicker(
                        value: $viewModel.targetWeightLbs,
                        range: 66...550,
                        unit: "lbs"
                    )
                    .onChange(of: viewModel.targetWeightLbs) { _, newValue in
                        viewModel.targetWeightKg = newValue / 2.20462
                    }
                }
            }
        } footer: {
            VStack(spacing: FuelSpacing.sm) {
                FuelButton("Continue") {
                    viewModel.nextStep()
                }

                if viewModel.selectedGoal == .maintain {
                    Button {
                        FuelHaptics.shared.tap()
                        if viewModel.useMetricWeight {
                            viewModel.targetWeightKg = viewModel.currentWeightKg
                        } else {
                            viewModel.targetWeightLbs = viewModel.currentWeightLbs
                        }
                    } label: {
                        Text("Keep my current weight")
                            .font(FuelTypography.subheadline)
                            .foregroundStyle(FuelColors.primary)
                    }
                }
            }
            .padding(.horizontal, FuelSpacing.screenHorizontal)
        }
    }

    private var goalSubtitle: String {
        switch viewModel.selectedGoal {
        case .lose:
            return "Set a realistic target. Healthy weight loss is 0.5-1kg per week."
        case .maintain:
            return "Keep your current weight or adjust slightly."
        case .gain:
            return "Set a lean bulk target. 0.25-0.5kg gain per week is ideal."
        }
    }

    private var weightDisplayValue: String {
        if viewModel.useMetricWeight {
            return String(format: "%.1f", viewModel.targetWeightKg)
        } else {
            return String(format: "%.0f", viewModel.targetWeightLbs)
        }
    }

    private var weightDifferenceDisplay: String {
        let diff = abs(viewModel.weightDifference)
        if viewModel.useMetricWeight {
            return String(format: "%.1f", diff)
        } else {
            return String(format: "%.0f", diff * 2.20462)
        }
    }

    private var weightChangeIndicator: some View {
        let isLosing = viewModel.currentWeightForCalculation > viewModel.targetWeightForCalculation
        let diff = abs(viewModel.weightDifference)
        let displayDiff = viewModel.useMetricWeight ? diff : diff * 2.20462
        let unit = viewModel.useMetricWeight ? "kg" : "lbs"

        return HStack(spacing: FuelSpacing.sm) {
            Image(systemName: isLosing ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                .font(.system(size: 24))
                .foregroundStyle(isLosing ? FuelColors.success : FuelColors.primary)

            VStack(alignment: .leading, spacing: FuelSpacing.xxxs) {
                Text(isLosing ? "Weight to lose" : "Weight to gain")
                    .font(FuelTypography.caption)
                    .foregroundStyle(FuelColors.textSecondary)

                Text("\(String(format: "%.1f", displayDiff)) \(unit)")
                    .font(FuelTypography.headline)
                    .foregroundStyle(FuelColors.textPrimary)
            }

            Spacer()
        }
        .padding(FuelSpacing.md)
        .background(FuelColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd, style: .continuous))
    }
}

#Preview {
    TargetWeightScreen(viewModel: OnboardingViewModel())
}
