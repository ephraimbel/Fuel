import SwiftUI

/// Height Input Screen
/// User enters their height with unit toggle

struct HeightInputScreen: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        OnboardingScreenLayout(
            title: "How tall are you?",
            subtitle: "Height is used to calculate your body mass index."
        ) {
            VStack(spacing: FuelSpacing.xl) {
                // Unit toggle
                FuelSegmentedControl(
                    options: ["Metric (cm)", "Imperial (ft)"],
                    selectedIndex: Binding(
                        get: { viewModel.useMetricHeight ? 0 : 1 },
                        set: { viewModel.useMetricHeight = $0 == 0 }
                    )
                )
                .padding(.horizontal, FuelSpacing.screenHorizontal)
                .onChange(of: viewModel.useMetricHeight) { _, _ in
                    FuelHaptics.shared.select()
                }

                // Height display
                VStack(spacing: FuelSpacing.xs) {
                    if viewModel.useMetricHeight {
                        Text("\(Int(viewModel.heightCm))")
                            .font(FuelTypography.hero)
                            .foregroundStyle(FuelColors.textPrimary)
                            .contentTransition(.numericText())

                        Text("centimeters")
                            .font(FuelTypography.body)
                            .foregroundStyle(FuelColors.textSecondary)
                    } else {
                        HStack(alignment: .firstTextBaseline, spacing: FuelSpacing.sm) {
                            Text("\(viewModel.heightFeet)")
                                .font(FuelTypography.hero)
                                .foregroundStyle(FuelColors.textPrimary)

                            Text("ft")
                                .font(FuelTypography.title2)
                                .foregroundStyle(FuelColors.textSecondary)

                            Text("\(viewModel.heightInches)")
                                .font(FuelTypography.hero)
                                .foregroundStyle(FuelColors.textPrimary)

                            Text("in")
                                .font(FuelTypography.title2)
                                .foregroundStyle(FuelColors.textSecondary)
                        }
                        .contentTransition(.numericText())
                    }
                }
                .animation(FuelAnimations.spring, value: viewModel.useMetricHeight)

                // Height picker
                if viewModel.useMetricHeight {
                    Picker("Height", selection: $viewModel.heightCm) {
                        ForEach(100...250, id: \.self) { cm in
                            Text("\(cm) cm")
                                .tag(Double(cm))
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 180)
                    .onChange(of: viewModel.heightCm) { _, _ in
                        FuelHaptics.shared.select()
                    }
                } else {
                    HStack(spacing: FuelSpacing.md) {
                        // Feet picker
                        Picker("Feet", selection: $viewModel.heightFeet) {
                            ForEach(4...7, id: \.self) { feet in
                                Text("\(feet) ft")
                                    .tag(feet)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity)
                        .onChange(of: viewModel.heightFeet) { _, _ in
                            FuelHaptics.shared.select()
                            syncHeightFromImperial()
                        }

                        // Inches picker
                        Picker("Inches", selection: $viewModel.heightInches) {
                            ForEach(0...11, id: \.self) { inches in
                                Text("\(inches) in")
                                    .tag(inches)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity)
                        .onChange(of: viewModel.heightInches) { _, _ in
                            FuelHaptics.shared.select()
                            syncHeightFromImperial()
                        }
                    }
                    .frame(height: 180)
                }
            }
        } footer: {
            FuelButton("Continue") {
                viewModel.nextStep()
            }
            .padding(.horizontal, FuelSpacing.screenHorizontal)
        }
    }

    private func syncHeightFromImperial() {
        let totalInches = viewModel.heightFeet * 12 + viewModel.heightInches
        viewModel.heightCm = Double(totalInches) * 2.54
    }
}

#Preview {
    HeightInputScreen(viewModel: OnboardingViewModel())
}
