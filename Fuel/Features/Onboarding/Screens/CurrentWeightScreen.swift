import SwiftUI

/// Current Weight Screen
/// User enters their current weight

struct CurrentWeightScreen: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        OnboardingScreenLayout(
            title: "What's your current weight?",
            subtitle: "Be as accurate as possible for the best results."
        ) {
            VStack(spacing: FuelSpacing.xl) {
                // Unit toggle
                FuelSegmentedControl(
                    options: ["Kilograms", "Pounds"],
                    selectedIndex: Binding(
                        get: { viewModel.useMetricWeight ? 0 : 1 },
                        set: {
                            viewModel.useMetricWeight = $0 == 0
                            syncWeights()
                        }
                    )
                )
                .padding(.horizontal, FuelSpacing.screenHorizontal)
                .onChange(of: viewModel.useMetricWeight) { _, _ in
                    FuelHaptics.shared.select()
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

                    // BMI indicator
                    let bmi = calculateBMI()
                    Text("BMI: \(String(format: "%.1f", bmi)) - \(bmiCategory(bmi))")
                        .font(FuelTypography.subheadline)
                        .foregroundStyle(bmiColor(bmi))
                }
                .animation(FuelAnimations.spring, value: viewModel.useMetricWeight)

                // Weight picker
                if viewModel.useMetricWeight {
                    WeightPicker(
                        value: $viewModel.currentWeightKg,
                        range: 30...250,
                        unit: "kg"
                    )
                    .onChange(of: viewModel.currentWeightKg) { _, newValue in
                        viewModel.currentWeightLbs = newValue * 2.20462
                        // Set initial target weight if not set
                        if viewModel.targetWeightKg == 70 {
                            viewModel.targetWeightKg = newValue
                            viewModel.targetWeightLbs = newValue * 2.20462
                        }
                    }
                } else {
                    WeightPicker(
                        value: $viewModel.currentWeightLbs,
                        range: 66...550,
                        unit: "lbs"
                    )
                    .onChange(of: viewModel.currentWeightLbs) { _, newValue in
                        viewModel.currentWeightKg = newValue / 2.20462
                        // Set initial target weight if not set
                        if viewModel.targetWeightLbs == 154 {
                            viewModel.targetWeightLbs = newValue
                            viewModel.targetWeightKg = newValue / 2.20462
                        }
                    }
                }
            }
        } footer: {
            FuelButton("Continue") {
                viewModel.nextStep()
            }
            .padding(.horizontal, FuelSpacing.screenHorizontal)
        }
    }

    private var weightDisplayValue: String {
        if viewModel.useMetricWeight {
            return String(format: "%.1f", viewModel.currentWeightKg)
        } else {
            return String(format: "%.0f", viewModel.currentWeightLbs)
        }
    }

    private func syncWeights() {
        if viewModel.useMetricWeight {
            viewModel.currentWeightKg = viewModel.currentWeightLbs / 2.20462
        } else {
            viewModel.currentWeightLbs = viewModel.currentWeightKg * 2.20462
        }
    }

    private func calculateBMI() -> Double {
        let heightM = viewModel.heightForCalculation / 100
        return viewModel.currentWeightForCalculation / (heightM * heightM)
    }

    private func bmiCategory(_ bmi: Double) -> String {
        switch bmi {
        case ..<18.5: return "Underweight"
        case 18.5..<25: return "Normal"
        case 25..<30: return "Overweight"
        default: return "Obese"
        }
    }

    private func bmiColor(_ bmi: Double) -> Color {
        switch bmi {
        case ..<18.5: return FuelColors.warning
        case 18.5..<25: return FuelColors.success
        case 25..<30: return FuelColors.warning
        default: return FuelColors.error
        }
    }
}

// MARK: - Weight Picker

struct WeightPicker: View {
    @Binding var value: Double
    let range: ClosedRange<Int>
    let unit: String

    var body: some View {
        Picker("Weight", selection: Binding(
            get: { Int(value * 10) },
            set: { value = Double($0) / 10 }
        )) {
            ForEach(range.map { $0 * 10 }, id: \.self) { weightTenths in
                let displayValue = Double(weightTenths) / 10
                Text(unit == "kg" ? String(format: "%.1f", displayValue) : String(format: "%.0f", displayValue))
                    .tag(weightTenths)
            }
        }
        .pickerStyle(.wheel)
        .frame(height: 180)
        .onChange(of: value) { _, _ in
            FuelHaptics.shared.select()
        }
    }
}

#Preview {
    CurrentWeightScreen(viewModel: OnboardingViewModel())
}
