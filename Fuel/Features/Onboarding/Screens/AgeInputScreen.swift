import SwiftUI

/// Age Input Screen
/// User enters their birth year

struct AgeInputScreen: View {
    @Bindable var viewModel: OnboardingViewModel

    private let currentYear = Calendar.current.component(.year, from: Date())
    private var yearRange: [Int] {
        Array((currentYear - 100)...(currentYear - 13)).reversed()
    }

    var body: some View {
        OnboardingScreenLayout(
            title: "When were you born?",
            subtitle: "Your age affects your daily calorie needs."
        ) {
            VStack(spacing: FuelSpacing.xl) {
                // Age display
                VStack(spacing: FuelSpacing.xs) {
                    Text("\(viewModel.age)")
                        .font(FuelTypography.hero)
                        .foregroundStyle(FuelColors.textPrimary)
                        .contentTransition(.numericText())

                    Text("years old")
                        .font(FuelTypography.body)
                        .foregroundStyle(FuelColors.textSecondary)
                }
                .animation(FuelAnimations.spring, value: viewModel.birthYear)

                // Year picker
                Picker("Birth Year", selection: $viewModel.birthYear) {
                    ForEach(yearRange, id: \.self) { year in
                        Text(String(year))
                            .tag(year)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 200)
                .onChange(of: viewModel.birthYear) { _, _ in
                    FuelHaptics.shared.select()
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

#Preview {
    AgeInputScreen(viewModel: OnboardingViewModel())
}
