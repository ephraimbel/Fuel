import SwiftUI

/// Gender Selection Screen
/// User selects their biological sex for accurate TDEE calculation

struct GenderSelectionScreen: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        OnboardingScreenLayout(
            title: "What's your biological sex?",
            subtitle: "This helps us calculate your metabolism more accurately."
        ) {
            VStack(spacing: FuelSpacing.md) {
                ForEach(Gender.allCases, id: \.self) { gender in
                    SelectionCard(
                        title: gender.displayName,
                        subtitle: gender.description,
                        icon: gender.icon,
                        isSelected: viewModel.selectedGender == gender
                    ) {
                        viewModel.selectedGender = gender
                    }
                }
            }
            .padding(.horizontal, FuelSpacing.screenHorizontal)
        } footer: {
            VStack(spacing: FuelSpacing.md) {
                FuelButton("Continue") {
                    viewModel.nextStep()
                }

                Text("We use this for metabolic calculations only")
                    .font(FuelTypography.caption)
                    .foregroundStyle(FuelColors.textTertiary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, FuelSpacing.screenHorizontal)
        }
    }
}

// MARK: - Gender Extension

extension Gender {
    var icon: String {
        switch self {
        case .male: return "figure.stand"
        case .female: return "figure.stand.dress"
        case .notSpecified: return "person.fill.questionmark"
        }
    }

    var description: String {
        switch self {
        case .male: return "Male metabolism calculation"
        case .female: return "Female metabolism calculation"
        case .notSpecified: return "Use averaged calculation"
        }
    }
}

#Preview {
    GenderSelectionScreen(viewModel: OnboardingViewModel())
}
