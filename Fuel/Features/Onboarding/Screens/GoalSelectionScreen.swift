import SwiftUI

/// Goal Selection Screen
/// User selects their primary fitness goal

struct GoalSelectionScreen: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        OnboardingScreenLayout(
            title: "What's your goal?",
            subtitle: "This helps us personalize your calorie and macro targets."
        ) {
            VStack(spacing: FuelSpacing.md) {
                ForEach(FitnessGoal.allCases, id: \.self) { goal in
                    GoalCard(
                        goal: goal,
                        isSelected: viewModel.selectedGoal == goal
                    ) {
                        FuelHaptics.shared.select()
                        withAnimation(FuelAnimations.spring) {
                            viewModel.selectedGoal = goal
                        }
                    }
                }
            }
            .padding(.horizontal, FuelSpacing.screenHorizontal)
        } footer: {
            FuelButton("Continue") {
                viewModel.nextStep()
            }
            .padding(.horizontal, FuelSpacing.screenHorizontal)
        }
    }
}

// MARK: - Goal Card

struct GoalCard: View {
    let goal: FitnessGoal
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: FuelSpacing.md) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isSelected ? FuelColors.primary : FuelColors.surfaceSecondary)
                        .frame(width: 56, height: 56)

                    Image(systemName: goal.icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(isSelected ? .white : FuelColors.textSecondary)
                }

                // Text
                VStack(alignment: .leading, spacing: FuelSpacing.xxxs) {
                    Text(goal.displayName)
                        .font(FuelTypography.headline)
                        .foregroundStyle(FuelColors.textPrimary)

                    Text(goal.description)
                        .font(FuelTypography.subheadline)
                        .foregroundStyle(FuelColors.textSecondary)
                        .lineLimit(2)
                }

                Spacer()

                // Checkmark
                ZStack {
                    Circle()
                        .stroke(isSelected ? FuelColors.primary : FuelColors.border, lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(FuelColors.primary)
                            .frame(width: 24, height: 24)

                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .padding(FuelSpacing.md)
            .background(isSelected ? FuelColors.primaryLight : FuelColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusLg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: FuelSpacing.radiusLg, style: .continuous)
                    .stroke(isSelected ? FuelColors.primary : FuelColors.border, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PressableButtonStyle(scale: 0.98))
        .animation(FuelAnimations.spring, value: isSelected)
    }
}

#Preview {
    GoalSelectionScreen(viewModel: OnboardingViewModel())
}
