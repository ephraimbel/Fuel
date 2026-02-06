import SwiftUI

/// Daily Nutrition Detail View
/// Shows comprehensive nutrition breakdown with health score
/// Presented as a sheet when tapping the DailyProgressCard

struct DailyNutritionDetailView: View {
    // MARK: - Properties

    let date: Date
    let calories: Int
    let calorieGoal: Int
    let protein: Double
    let proteinGoal: Double
    let carbs: Double
    let carbsGoal: Double
    let fat: Double
    let fatGoal: Double
    let fiber: Double
    let sugar: Double
    let sodium: Double
    let saturatedFat: Double
    let cholesterol: Double
    let mealsLogged: Int

    @Environment(\.dismiss) private var dismiss

    // MARK: - Computed Properties

    private var remainingCalories: Int {
        calorieGoal - calories
    }

    private var isOverGoal: Bool {
        calories > calorieGoal
    }

    private var calorieProgress: Double {
        guard calorieGoal > 0 else { return 0 }
        return min(Double(calories) / Double(calorieGoal), 1.0)
    }

    // Health Score Calculation (0-100)
    private var healthScore: Int {
        var score: Double = 0

        // Calorie adherence (40 points max)
        let calorieRatio = Double(calories) / Double(max(1, calorieGoal))
        if calorieRatio >= 0.85 && calorieRatio <= 1.1 {
            score += 40 // Perfect range
        } else if calorieRatio >= 0.7 && calorieRatio <= 1.2 {
            score += 30 // Good range
        } else if calorieRatio >= 0.5 && calorieRatio <= 1.3 {
            score += 15 // Okay range
        }

        // Protein goal (25 points max)
        let proteinRatio = protein / max(1, proteinGoal)
        score += min(25, proteinRatio * 25)

        // Macro balance (20 points max)
        let carbsRatio = carbs / max(1, carbsGoal)
        let fatRatio = fat / max(1, fatGoal)
        let macroBalance = (min(1, carbsRatio) + min(1, fatRatio)) / 2
        score += macroBalance * 20

        // Logging consistency (15 points max)
        if mealsLogged >= 3 {
            score += 15
        } else if mealsLogged >= 2 {
            score += 10
        } else if mealsLogged >= 1 {
            score += 5
        }

        return min(100, Int(score))
    }

    private var healthScoreLabel: String {
        switch healthScore {
        case 90...100: return "Excellent"
        case 75..<90: return "Great"
        case 60..<75: return "Good"
        case 40..<60: return "Fair"
        default: return "Needs Work"
        }
    }

    private var healthScoreColor: Color {
        switch healthScore {
        case 90...100: return FuelColors.success
        case 75..<90: return Color.green
        case 60..<75: return FuelColors.primary
        case 40..<60: return .orange
        default: return .red
        }
    }

    private var formattedDate: String {
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMM d"
            return formatter.string(from: date)
        }
    }

    // Macro percentages
    private var proteinPercent: Int {
        guard calories > 0 else { return 0 }
        return Int((protein * 4 / Double(calories)) * 100)
    }

    private var carbsPercent: Int {
        guard calories > 0 else { return 0 }
        return Int((carbs * 4 / Double(calories)) * 100)
    }

    private var fatPercent: Int {
        guard calories > 0 else { return 0 }
        return Int((fat * 9 / Double(calories)) * 100)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: FuelSpacing.lg) {
                    // Health Score Card
                    healthScoreCard

                    // Calories Section
                    caloriesSection

                    // Macros Section
                    macrosSection

                    // Micronutrients Section
                    micronutrientsSection

                    // Tips Section
                    tipsSection
                }
                .padding(.horizontal, FuelSpacing.screenHorizontal)
                .padding(.bottom, FuelSpacing.screenBottom)
            }
            .scrollIndicators(.hidden)
            .background(FuelColors.background)
            .navigationTitle(formattedDate)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        FuelHaptics.shared.tap()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(FuelColors.textTertiary)
                    }
                }
            }
        }
    }

    // MARK: - Health Score Card

    private var healthScoreCard: some View {
        VStack(spacing: FuelSpacing.md) {
            // Score Ring
            ZStack {
                // Background ring
                Circle()
                    .stroke(FuelColors.surfaceSecondary, lineWidth: 12)
                    .frame(width: 120, height: 120)

                // Progress ring
                Circle()
                    .trim(from: 0, to: Double(healthScore) / 100)
                    .stroke(
                        healthScoreColor,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(duration: 0.8), value: healthScore)

                // Score text
                VStack(spacing: 2) {
                    Text("\(healthScore)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(FuelColors.textPrimary)

                    Text("/ 100")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(FuelColors.textTertiary)
                }
            }

            // Label
            Text(healthScoreLabel)
                .font(FuelTypography.headline)
                .foregroundStyle(healthScoreColor)

            Text("Daily Health Score")
                .font(FuelTypography.caption)
                .foregroundStyle(FuelColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, FuelSpacing.xl)
        .background(FuelColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusLg))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    // MARK: - Calories Section

    private var caloriesSection: some View {
        VStack(alignment: .leading, spacing: FuelSpacing.md) {
            sectionHeader(title: "CALORIES", icon: "flame.fill")

            VStack(spacing: FuelSpacing.md) {
                // Main calorie display
                HStack(alignment: .bottom, spacing: FuelSpacing.xs) {
                    Text("\(calories)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(FuelColors.textPrimary)

                    Text("/ \(calorieGoal)")
                        .font(.system(size: 24, weight: .medium, design: .rounded))
                        .foregroundStyle(FuelColors.textTertiary)
                        .padding(.bottom, 6)
                }

                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 6)
                            .fill(FuelColors.surfaceSecondary)
                            .frame(height: 12)

                        // Progress
                        RoundedRectangle(cornerRadius: 6)
                            .fill(isOverGoal ? FuelColors.error : FuelColors.primary)
                            .frame(width: geometry.size.width * min(calorieProgress, 1.0), height: 12)
                            .animation(.spring(duration: 0.5), value: calorieProgress)
                    }
                }
                .frame(height: 12)

                // Remaining/Over label
                HStack {
                    if isOverGoal {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(FuelColors.error)
                        Text("\(abs(remainingCalories)) over goal")
                            .font(FuelTypography.subheadlineMedium)
                            .foregroundStyle(FuelColors.error)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(FuelColors.success)
                        Text("\(remainingCalories) remaining")
                            .font(FuelTypography.subheadlineMedium)
                            .foregroundStyle(FuelColors.success)
                    }

                    Spacer()

                    Text("\(Int(calorieProgress * 100))%")
                        .font(FuelTypography.subheadlineMedium)
                        .foregroundStyle(FuelColors.textSecondary)
                }
            }
            .padding(FuelSpacing.md)
            .background(FuelColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
        }
    }

    // MARK: - Macros Section

    private var macrosSection: some View {
        VStack(alignment: .leading, spacing: FuelSpacing.md) {
            sectionHeader(title: "MACROS", icon: "chart.pie.fill")

            VStack(spacing: FuelSpacing.sm) {
                // Macro rows with SF Symbol icons
                macroRow(
                    macro: .protein,
                    value: protein,
                    goal: proteinGoal,
                    percent: proteinPercent
                )

                macroRow(
                    macro: .carbs,
                    value: carbs,
                    goal: carbsGoal,
                    percent: carbsPercent
                )

                macroRow(
                    macro: .fat,
                    value: fat,
                    goal: fatGoal,
                    percent: fatPercent
                )
            }
            .padding(FuelSpacing.md)
            .background(FuelColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))

            // Macro distribution mini chart
            macroDistributionBar
        }
    }

    private func macroRow(macro: MacroType, value: Double, goal: Double, percent: Int) -> some View {
        VStack(spacing: FuelSpacing.xs) {
            HStack {
                MacroIconView(type: macro, size: 14)
                    .frame(width: 24)

                Text(macro.label)
                    .font(FuelTypography.subheadlineMedium)
                    .foregroundStyle(FuelColors.textPrimary)

                Spacer()

                Text("\(Int(value))g")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(FuelColors.textPrimary)

                Text("/ \(Int(goal))g")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(FuelColors.textTertiary)

                Text("(\(percent)%)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(FuelColors.textSecondary)
                    .frame(width: 40, alignment: .trailing)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(macro.color.opacity(0.2))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(macro.color)
                        .frame(width: geometry.size.width * min(value / max(1, goal), 1.0), height: 8)
                        .animation(.spring(duration: 0.5), value: value)
                }
            }
            .frame(height: 8)
        }
    }

    private var macroDistributionBar: some View {
        VStack(alignment: .leading, spacing: FuelSpacing.xs) {
            Text("Calorie Distribution")
                .font(FuelTypography.caption)
                .foregroundStyle(FuelColors.textSecondary)

            GeometryReader { geometry in
                HStack(spacing: 2) {
                    if proteinPercent + carbsPercent + fatPercent > 0 {
                        // Protein
                        RoundedRectangle(cornerRadius: 4)
                            .fill(FuelColors.protein)
                            .frame(width: geometry.size.width * CGFloat(proteinPercent) / 100)

                        // Carbs
                        RoundedRectangle(cornerRadius: 4)
                            .fill(FuelColors.carbs)
                            .frame(width: geometry.size.width * CGFloat(carbsPercent) / 100)

                        // Fat
                        RoundedRectangle(cornerRadius: 4)
                            .fill(FuelColors.fat)
                            .frame(width: geometry.size.width * CGFloat(fatPercent) / 100)
                    } else {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(FuelColors.surfaceSecondary)
                    }
                }
            }
            .frame(height: 24)
            .clipShape(RoundedRectangle(cornerRadius: 4))

            // Legend
            HStack(spacing: FuelSpacing.md) {
                legendItem(color: FuelColors.protein, label: "Protein \(proteinPercent)%")
                legendItem(color: FuelColors.carbs, label: "Carbs \(carbsPercent)%")
                legendItem(color: FuelColors.fat, label: "Fat \(fatPercent)%")
            }
            .font(FuelTypography.caption)
        }
        .padding(FuelSpacing.md)
        .background(FuelColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .foregroundStyle(FuelColors.textSecondary)
        }
    }

    // MARK: - Micronutrients Section

    private var micronutrientsSection: some View {
        VStack(alignment: .leading, spacing: FuelSpacing.md) {
            sectionHeader(title: "MICRONUTRIENTS", icon: "leaf.fill")

            VStack(spacing: 0) {
                micronutrientRow(name: "Fiber", value: fiber, unit: "g", goal: 25, icon: "tree.fill", iconColor: .green)
                Divider().padding(.horizontal, FuelSpacing.md)
                micronutrientRow(name: "Sugar", value: sugar, unit: "g", goal: 50, icon: "cube.fill", iconColor: .pink)
                Divider().padding(.horizontal, FuelSpacing.md)
                micronutrientRow(name: "Sodium", value: sodium, unit: "mg", goal: 2300, icon: "drop.triangle.fill", iconColor: .blue)
                Divider().padding(.horizontal, FuelSpacing.md)
                micronutrientRow(name: "Saturated Fat", value: saturatedFat, unit: "g", goal: 20, icon: "drop.halffull", iconColor: .orange)
                Divider().padding(.horizontal, FuelSpacing.md)
                micronutrientRow(name: "Cholesterol", value: cholesterol, unit: "mg", goal: 300, icon: "heart.fill", iconColor: .red)
            }
            .background(FuelColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
        }
    }

    private func micronutrientRow(name: String, value: Double, unit: String, goal: Double, icon: String, iconColor: Color) -> some View {
        let progress = min(value / max(1, goal), 1.0)
        let isHigh = value > goal

        return HStack {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(iconColor)
                .frame(width: 24)

            Text(name)
                .font(FuelTypography.body)
                .foregroundStyle(FuelColors.textPrimary)

            Spacer()

            Text("\(Int(value))\(unit)")
                .font(FuelTypography.bodyMedium)
                .foregroundStyle(isHigh ? FuelColors.error : FuelColors.textPrimary)

            Text("/ \(Int(goal))\(unit)")
                .font(FuelTypography.caption)
                .foregroundStyle(FuelColors.textTertiary)

            // Mini progress indicator
            Circle()
                .trim(from: 0, to: progress)
                .stroke(isHigh ? FuelColors.error : FuelColors.success, lineWidth: 3)
                .frame(width: 20, height: 20)
                .rotationEffect(.degrees(-90))
                .background(
                    Circle()
                        .stroke(FuelColors.surfaceSecondary, lineWidth: 3)
                )
        }
        .padding(.horizontal, FuelSpacing.md)
        .padding(.vertical, FuelSpacing.sm)
    }

    // MARK: - Tips Section

    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: FuelSpacing.sm) {
            sectionHeader(title: "TIPS", icon: "lightbulb.fill")

            VStack(alignment: .leading, spacing: FuelSpacing.sm) {
                ForEach(generateTips(), id: \.self) { tip in
                    HStack(alignment: .top, spacing: FuelSpacing.sm) {
                        Image(systemName: "sparkle")
                            .font(.system(size: 12))
                            .foregroundStyle(FuelColors.gold)
                            .padding(.top, 2)

                        Text(tip)
                            .font(FuelTypography.subheadline)
                            .foregroundStyle(FuelColors.textSecondary)
                    }
                }
            }
            .padding(FuelSpacing.md)
            .background(FuelColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
        }
    }

    private func generateTips() -> [String] {
        var tips: [String] = []

        // Protein tip
        if protein < proteinGoal * 0.8 {
            tips.append("Try adding more protein at your next meal to hit your goal. Great sources: chicken, fish, eggs, or Greek yogurt.")
        }

        // Calorie tip
        if isOverGoal {
            tips.append("You're over your calorie goal today. Consider lighter options for your remaining meals.")
        } else if remainingCalories > 500 {
            tips.append("You have \(remainingCalories) calories remaining. Don't skip meals - consistent eating helps maintain energy.")
        }

        // Fiber tip
        if fiber < 15 {
            tips.append("Boost your fiber intake with vegetables, fruits, or whole grains for better digestion.")
        }

        // Sodium tip
        if sodium > 2000 {
            tips.append("Your sodium intake is high today. Try to limit processed foods and add more fresh ingredients.")
        }

        // Default tip if doing well
        if tips.isEmpty {
            tips.append("Great job! You're on track with your nutrition goals today. Keep it up!")
        }

        return Array(tips.prefix(3))
    }

    // MARK: - Helpers

    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: FuelSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(FuelColors.textTertiary)

            Text(title)
                .font(FuelTypography.caption)
                .fontWeight(.semibold)
                .foregroundStyle(FuelColors.textTertiary)
                .tracking(0.5)

            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    DailyNutritionDetailView(
        date: Date(),
        calories: 1680,
        calorieGoal: 2100,
        protein: 120,
        proteinGoal: 165,
        carbs: 180,
        carbsGoal: 210,
        fat: 52,
        fatGoal: 70,
        fiber: 18,
        sugar: 32,
        sodium: 1800,
        saturatedFat: 12,
        cholesterol: 180,
        mealsLogged: 3
    )
}
