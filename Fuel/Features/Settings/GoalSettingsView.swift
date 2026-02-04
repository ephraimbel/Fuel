import SwiftUI

/// Goal Settings View
/// Edit calorie and macro targets

struct GoalSettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var calorieGoal: Double = 2000
    @State private var proteinGoal: Double = 150
    @State private var carbsGoal: Double = 200
    @State private var fatGoal: Double = 65

    @State private var proteinPercent: Double = 30
    @State private var carbsPercent: Double = 40
    @State private var fatPercent: Double = 30

    @State private var usePercentages = false
    @State private var hasChanges = false

    var body: some View {
        ScrollView {
            VStack(spacing: FuelSpacing.xl) {
                // Calorie goal
                calorieGoalSection

                // Macro goals
                macroGoalsSection

                // Info
                infoSection
            }
            .padding(.horizontal, FuelSpacing.screenHorizontal)
            .padding(.vertical, FuelSpacing.lg)
        }
        .background(FuelColors.background)
        .navigationTitle("Calorie & Macro Goals")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if hasChanges {
                    Button("Save") {
                        saveGoals()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Calorie Goal Section

    private var calorieGoalSection: some View {
        VStack(alignment: .leading, spacing: FuelSpacing.sm) {
            Text("DAILY CALORIE GOAL")
                .font(FuelTypography.caption)
                .foregroundStyle(FuelColors.textTertiary)

            VStack(spacing: FuelSpacing.md) {
                // Value display
                HStack(alignment: .firstTextBaseline) {
                    Text("\(Int(calorieGoal))")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(FuelColors.primary)

                    Text("calories")
                        .font(FuelTypography.headline)
                        .foregroundStyle(FuelColors.textSecondary)
                }

                // Slider
                Slider(value: $calorieGoal, in: 1000...4000, step: 50)
                    .tint(FuelColors.primary)
                    .onChange(of: calorieGoal) { _, _ in
                        hasChanges = true
                        FuelHaptics.shared.tick()
                        updateMacrosFromPercentages()
                    }

                // Quick adjust buttons
                HStack(spacing: FuelSpacing.sm) {
                    quickAdjustButton(value: -100)
                    quickAdjustButton(value: -50)
                    quickAdjustButton(value: +50)
                    quickAdjustButton(value: +100)
                }
            }
            .padding(FuelSpacing.md)
            .background(FuelColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
        }
    }

    private func quickAdjustButton(value: Int) -> some View {
        Button {
            let newValue = calorieGoal + Double(value)
            if newValue >= 1000 && newValue <= 4000 {
                calorieGoal = newValue
                hasChanges = true
                FuelHaptics.shared.tap()
                updateMacrosFromPercentages()
            }
        } label: {
            Text(value > 0 ? "+\(value)" : "\(value)")
                .font(FuelTypography.caption)
                .foregroundStyle(FuelColors.textSecondary)
                .padding(.horizontal, FuelSpacing.md)
                .padding(.vertical, FuelSpacing.sm)
                .background(FuelColors.surfaceSecondary)
                .clipShape(Capsule())
        }
    }

    // MARK: - Macro Goals Section

    private var macroGoalsSection: some View {
        VStack(alignment: .leading, spacing: FuelSpacing.sm) {
            HStack {
                Text("MACRO GOALS")
                    .font(FuelTypography.caption)
                    .foregroundStyle(FuelColors.textTertiary)

                Spacer()

                // Toggle for percentages vs grams
                Button {
                    usePercentages.toggle()
                    FuelHaptics.shared.tap()
                } label: {
                    Text(usePercentages ? "Show Grams" : "Show Percentages")
                        .font(FuelTypography.caption)
                        .foregroundStyle(FuelColors.primary)
                }
            }

            VStack(spacing: FuelSpacing.md) {
                // Protein
                macroRow(
                    name: "Protein",
                    color: FuelColors.protein,
                    grams: $proteinGoal,
                    percent: $proteinPercent,
                    caloriesPerGram: 4
                )

                Divider()
                    .padding(.horizontal, FuelSpacing.md)

                // Carbs
                macroRow(
                    name: "Carbs",
                    color: FuelColors.carbs,
                    grams: $carbsGoal,
                    percent: $carbsPercent,
                    caloriesPerGram: 4
                )

                Divider()
                    .padding(.horizontal, FuelSpacing.md)

                // Fat
                macroRow(
                    name: "Fat",
                    color: FuelColors.fat,
                    grams: $fatGoal,
                    percent: $fatPercent,
                    caloriesPerGram: 9
                )

                // Total percentage
                if usePercentages {
                    let total = proteinPercent + carbsPercent + fatPercent
                    HStack {
                        Text("Total")
                            .font(FuelTypography.subheadline)
                            .foregroundStyle(FuelColors.textSecondary)

                        Spacer()

                        Text("\(Int(total))%")
                            .font(FuelTypography.subheadlineMedium)
                            .foregroundStyle(total == 100 ? FuelColors.success : FuelColors.error)
                    }
                    .padding(.horizontal, FuelSpacing.md)
                }
            }
            .padding(.vertical, FuelSpacing.md)
            .background(FuelColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
        }
    }

    private func macroRow(
        name: String,
        color: Color,
        grams: Binding<Double>,
        percent: Binding<Double>,
        caloriesPerGram: Double
    ) -> some View {
        HStack(spacing: FuelSpacing.md) {
            // Color indicator
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)

            // Name
            Text(name)
                .font(FuelTypography.subheadlineMedium)
                .foregroundStyle(FuelColors.textPrimary)
                .frame(width: 70, alignment: .leading)

            Spacer()

            if usePercentages {
                // Percentage stepper
                HStack(spacing: FuelSpacing.sm) {
                    Button {
                        if percent.wrappedValue > 5 {
                            percent.wrappedValue -= 5
                            updateGramsFromPercentage(name: name)
                            hasChanges = true
                            FuelHaptics.shared.select()
                        }
                    } label: {
                        Image(systemName: "minus")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(FuelColors.textSecondary)
                            .frame(width: 28, height: 28)
                            .background(FuelColors.surfaceSecondary)
                            .clipShape(Circle())
                    }

                    Text("\(Int(percent.wrappedValue))%")
                        .font(FuelTypography.headline)
                        .foregroundStyle(FuelColors.textPrimary)
                        .frame(width: 50)

                    Button {
                        if percent.wrappedValue < 70 {
                            percent.wrappedValue += 5
                            updateGramsFromPercentage(name: name)
                            hasChanges = true
                            FuelHaptics.shared.select()
                        }
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(FuelColors.primary)
                            .frame(width: 28, height: 28)
                            .background(FuelColors.surfaceSecondary)
                            .clipShape(Circle())
                    }
                }
            } else {
                // Grams stepper
                HStack(spacing: FuelSpacing.sm) {
                    Button {
                        if grams.wrappedValue > 10 {
                            grams.wrappedValue -= 10
                            updatePercentageFromGrams()
                            hasChanges = true
                            FuelHaptics.shared.select()
                        }
                    } label: {
                        Image(systemName: "minus")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(FuelColors.textSecondary)
                            .frame(width: 28, height: 28)
                            .background(FuelColors.surfaceSecondary)
                            .clipShape(Circle())
                    }

                    Text("\(Int(grams.wrappedValue))g")
                        .font(FuelTypography.headline)
                        .foregroundStyle(FuelColors.textPrimary)
                        .frame(width: 60)

                    Button {
                        grams.wrappedValue += 10
                        updatePercentageFromGrams()
                        hasChanges = true
                        FuelHaptics.shared.select()
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(FuelColors.primary)
                            .frame(width: 28, height: 28)
                            .background(FuelColors.surfaceSecondary)
                            .clipShape(Circle())
                    }
                }
            }
        }
        .padding(.horizontal, FuelSpacing.md)
    }

    // MARK: - Info Section

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: FuelSpacing.sm) {
            HStack(spacing: FuelSpacing.sm) {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(FuelColors.gold)

                Text("Tip")
                    .font(FuelTypography.subheadlineMedium)
                    .foregroundStyle(FuelColors.textPrimary)
            }

            Text("Your goals are calculated based on your profile and activity level. Adjust them here if you have specific targets in mind.")
                .font(FuelTypography.caption)
                .foregroundStyle(FuelColors.textSecondary)
        }
        .padding(FuelSpacing.md)
        .background(FuelColors.gold.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
    }

    // MARK: - Helpers

    private func updateMacrosFromPercentages() {
        guard usePercentages else { return }
        proteinGoal = (proteinPercent / 100 * calorieGoal) / 4
        carbsGoal = (carbsPercent / 100 * calorieGoal) / 4
        fatGoal = (fatPercent / 100 * calorieGoal) / 9
    }

    private func updateGramsFromPercentage(name: String) {
        switch name {
        case "Protein":
            proteinGoal = (proteinPercent / 100 * calorieGoal) / 4
        case "Carbs":
            carbsGoal = (carbsPercent / 100 * calorieGoal) / 4
        case "Fat":
            fatGoal = (fatPercent / 100 * calorieGoal) / 9
        default:
            break
        }
    }

    private func updatePercentageFromGrams() {
        let proteinCals = proteinGoal * 4
        let carbsCals = carbsGoal * 4
        let fatCals = fatGoal * 9
        let total = proteinCals + carbsCals + fatCals

        if total > 0 {
            proteinPercent = (proteinCals / total) * 100
            carbsPercent = (carbsCals / total) * 100
            fatPercent = (fatCals / total) * 100
        }
    }

    private func saveGoals() {
        FuelHaptics.shared.success()
        // TODO: Save goals via service
        hasChanges = false
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        GoalSettingsView()
    }
}
