import SwiftUI

/// Workout Frequency Screen
/// User selects how many times they workout per week

struct WorkoutFrequencyScreen: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        OnboardingScreenLayout(
            title: "How often do you exercise?",
            subtitle: "Include any structured workouts like gym, sports, or classes."
        ) {
            VStack(spacing: FuelSpacing.xxl) {
                // Workout display
                VStack(spacing: FuelSpacing.sm) {
                    Text("\(viewModel.workoutsPerWeek)")
                        .font(FuelTypography.hero)
                        .foregroundStyle(FuelColors.textPrimary)
                        .contentTransition(.numericText())

                    Text(viewModel.workoutsPerWeek == 1 ? "workout per week" : "workouts per week")
                        .font(FuelTypography.body)
                        .foregroundStyle(FuelColors.textSecondary)
                }
                .animation(FuelAnimations.spring, value: viewModel.workoutsPerWeek)

                // Workout selector
                VStack(spacing: FuelSpacing.md) {
                    ForEach(workoutOptions, id: \.value) { option in
                        WorkoutOptionButton(
                            label: option.label,
                            description: option.description,
                            value: option.value,
                            isSelected: viewModel.workoutsPerWeek == option.value
                        ) {
                            FuelHaptics.shared.select()
                            withAnimation(FuelAnimations.spring) {
                                viewModel.workoutsPerWeek = option.value
                            }
                        }
                    }
                }
                .padding(.horizontal, FuelSpacing.screenHorizontal)
            }
        } footer: {
            FuelButton("Continue") {
                viewModel.nextStep()
            }
            .padding(.horizontal, FuelSpacing.screenHorizontal)
        }
    }

    private var workoutOptions: [(value: Int, label: String, description: String)] {
        [
            (0, "None", "No structured exercise"),
            (1, "1-2 times", "Light activity"),
            (3, "3-4 times", "Regular exerciser"),
            (5, "5-6 times", "Very active"),
            (7, "Daily", "Intense training")
        ]
    }
}

// MARK: - Workout Option Button

struct WorkoutOptionButton: View {
    let label: String
    let description: String
    let value: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: FuelSpacing.xxxs) {
                    Text(label)
                        .font(FuelTypography.headline)
                        .foregroundStyle(FuelColors.textPrimary)

                    Text(description)
                        .font(FuelTypography.caption)
                        .foregroundStyle(FuelColors.textSecondary)
                }

                Spacer()

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
        .buttonStyle(PressableButtonStyle(scale: 0.98))
        .animation(FuelAnimations.spring, value: isSelected)
    }
}

#Preview {
    WorkoutFrequencyScreen(viewModel: OnboardingViewModel())
}
