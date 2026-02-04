import SwiftUI

/// Diet Preference Screen
/// User selects their dietary preferences (optional)

struct DietPreferenceScreen: View {
    @Bindable var viewModel: OnboardingViewModel

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        OnboardingScreenLayout(
            title: "Any dietary preferences?",
            subtitle: "This helps us suggest relevant foods. You can skip this."
        ) {
            LazyVGrid(columns: columns, spacing: FuelSpacing.md) {
                ForEach(DietPreference.allCases, id: \.self) { diet in
                    DietOptionCard(
                        diet: diet,
                        isSelected: viewModel.dietPreference == diet
                    ) {
                        FuelHaptics.shared.select()
                        withAnimation(FuelAnimations.spring) {
                            viewModel.dietPreference = diet
                        }
                    }
                }
            }
            .padding(.horizontal, FuelSpacing.screenHorizontal)
        } footer: {
            VStack(spacing: FuelSpacing.sm) {
                FuelButton("Continue") {
                    viewModel.nextStep()
                }

                Button {
                    FuelHaptics.shared.tap()
                    viewModel.dietPreference = .none
                    viewModel.nextStep()
                } label: {
                    Text("Skip for now")
                        .font(FuelTypography.subheadline)
                        .foregroundStyle(FuelColors.textSecondary)
                }
            }
            .padding(.horizontal, FuelSpacing.screenHorizontal)
        }
    }
}

// MARK: - Diet Option Card

struct DietOptionCard: View {
    let diet: DietPreference
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: FuelSpacing.sm) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isSelected ? FuelColors.primary : FuelColors.surfaceSecondary)
                        .frame(width: 56, height: 56)

                    Image(systemName: diet.icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(isSelected ? .white : FuelColors.textSecondary)
                }

                // Label
                Text(diet.displayName)
                    .font(FuelTypography.subheadlineMedium)
                    .foregroundStyle(FuelColors.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, FuelSpacing.md)
            .padding(.horizontal, FuelSpacing.sm)
            .background(isSelected ? FuelColors.primaryLight : FuelColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusLg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: FuelSpacing.radiusLg, style: .continuous)
                    .stroke(isSelected ? FuelColors.primary : FuelColors.border, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PressableButtonStyle(scale: 0.96))
        .animation(FuelAnimations.spring, value: isSelected)
    }
}

#Preview {
    DietPreferenceScreen(viewModel: OnboardingViewModel())
}
