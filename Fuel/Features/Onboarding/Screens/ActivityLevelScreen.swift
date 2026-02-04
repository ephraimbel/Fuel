import SwiftUI

/// Activity Level Screen
/// User selects their daily activity level

struct ActivityLevelScreen: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        OnboardingScreenLayout(
            title: "How active are you?",
            subtitle: "This doesn't include workouts - just your daily activity."
        ) {
            VStack(spacing: FuelSpacing.sm) {
                ForEach(ActivityLevel.allCases, id: \.self) { level in
                    ActivityLevelCard(
                        level: level,
                        isSelected: viewModel.activityLevel == level
                    ) {
                        FuelHaptics.shared.select()
                        withAnimation(FuelAnimations.spring) {
                            viewModel.activityLevel = level
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

// MARK: - Activity Level Card

struct ActivityLevelCard: View {
    let level: ActivityLevel
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: FuelSpacing.md) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: FuelSpacing.radiusMd, style: .continuous)
                        .fill(isSelected ? FuelColors.primaryLight : FuelColors.surfaceSecondary)
                        .frame(width: 48, height: 48)

                    Image(systemName: level.icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(isSelected ? FuelColors.primary : FuelColors.textSecondary)
                }

                // Text
                VStack(alignment: .leading, spacing: FuelSpacing.xxxs) {
                    Text(level.displayName)
                        .font(FuelTypography.headline)
                        .foregroundStyle(FuelColors.textPrimary)

                    Text(level.description)
                        .font(FuelTypography.caption)
                        .foregroundStyle(FuelColors.textSecondary)
                        .lineLimit(1)
                }

                Spacer()

                // Checkmark
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(FuelColors.primary)
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

// MARK: - Activity Level Extension

extension ActivityLevel {
    var icon: String {
        switch self {
        case .sedentary: return "figure.seated.side"
        case .light: return "figure.walk"
        case .moderate: return "figure.run"
        case .active: return "figure.hiking"
        case .veryActive: return "figure.highintensity.intervaltraining"
        }
    }
}

#Preview {
    ActivityLevelScreen(viewModel: OnboardingViewModel())
}
