import SwiftUI

/// Daily Progress Card
/// Shows calorie ring and macro progress bars

struct DailyProgressCard: View {
    let totalCalories: Int
    let calorieGoal: Int
    let remainingCalories: Int
    let calorieProgress: Double
    let proteinProgress: Double
    let carbsProgress: Double
    let fatProgress: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let proteinGoal: Double
    let carbsGoal: Double
    let fatGoal: Double
    let isOverGoal: Bool

    @State private var animatedProgress: Double = 0
    @State private var showCalories = false

    var body: some View {
        VStack(spacing: FuelSpacing.lg) {
            // Calorie ring section
            HStack(spacing: FuelSpacing.xl) {
                // Calorie ring
                calorieRing

                // Calorie stats
                calorieStats
            }

            // Macro progress bars
            macroProgressSection
        }
        .padding(FuelSpacing.lg)
        .background(FuelColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusLg))
        .onAppear {
            animateProgress()
        }
    }

    // MARK: - Calorie Ring

    private var calorieRing: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(FuelColors.surfaceSecondary, lineWidth: 12)
                .frame(width: 120, height: 120)

            // Progress ring
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    isOverGoal ? FuelColors.error : FuelColors.primary,
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .frame(width: 120, height: 120)
                .rotationEffect(.degrees(-90))

            // Center content
            VStack(spacing: FuelSpacing.xxxs) {
                if showCalories {
                    Text("\(totalCalories)")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(isOverGoal ? FuelColors.error : FuelColors.textPrimary)
                        .contentTransition(.numericText())

                    Text("eaten")
                        .font(FuelTypography.caption)
                        .foregroundStyle(FuelColors.textTertiary)
                } else {
                    ProgressView()
                }
            }
        }
    }

    // MARK: - Calorie Stats

    private var calorieStats: some View {
        VStack(alignment: .leading, spacing: FuelSpacing.md) {
            // Remaining
            VStack(alignment: .leading, spacing: FuelSpacing.xxxs) {
                HStack(spacing: FuelSpacing.xs) {
                    Circle()
                        .fill(isOverGoal ? FuelColors.error : FuelColors.primary)
                        .frame(width: 8, height: 8)

                    Text(isOverGoal ? "Over by" : "Remaining")
                        .font(FuelTypography.caption)
                        .foregroundStyle(FuelColors.textSecondary)
                }

                Text("\(isOverGoal ? totalCalories - calorieGoal : remainingCalories)")
                    .font(FuelTypography.title2)
                    .foregroundStyle(isOverGoal ? FuelColors.error : FuelColors.textPrimary)
                + Text(" cal")
                    .font(FuelTypography.subheadline)
                    .foregroundStyle(FuelColors.textSecondary)
            }

            Divider()

            // Goal
            VStack(alignment: .leading, spacing: FuelSpacing.xxxs) {
                Text("Daily Goal")
                    .font(FuelTypography.caption)
                    .foregroundStyle(FuelColors.textTertiary)

                Text("\(calorieGoal) cal")
                    .font(FuelTypography.subheadlineMedium)
                    .foregroundStyle(FuelColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Macro Progress Section

    private var macroProgressSection: some View {
        HStack(spacing: FuelSpacing.md) {
            macroProgressBar(
                name: "Protein",
                current: protein,
                goal: proteinGoal,
                progress: proteinProgress,
                color: FuelColors.protein
            )

            macroProgressBar(
                name: "Carbs",
                current: carbs,
                goal: carbsGoal,
                progress: carbsProgress,
                color: FuelColors.carbs
            )

            macroProgressBar(
                name: "Fat",
                current: fat,
                goal: fatGoal,
                progress: fatProgress,
                color: FuelColors.fat
            )
        }
    }

    private func macroProgressBar(
        name: String,
        current: Double,
        goal: Double,
        progress: Double,
        color: Color
    ) -> some View {
        VStack(spacing: FuelSpacing.sm) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color.opacity(0.2))
                        .frame(height: 8)

                    // Progress
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * min(progress, 1.0), height: 8)
                }
            }
            .frame(height: 8)

            // Label
            VStack(spacing: FuelSpacing.xxxs) {
                Text("\(Int(current))g")
                    .font(FuelTypography.subheadlineMedium)
                    .foregroundStyle(FuelColors.textPrimary)

                Text(name)
                    .font(FuelTypography.caption)
                    .foregroundStyle(FuelColors.textTertiary)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Animation

    private func animateProgress() {
        withAnimation(.easeOut(duration: 0.8)) {
            animatedProgress = min(calorieProgress, 1.0)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 0.5)) {
                showCalories = true
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack {
        DailyProgressCard(
            totalCalories: 1420,
            calorieGoal: 2000,
            remainingCalories: 580,
            calorieProgress: 0.71,
            proteinProgress: 0.6,
            carbsProgress: 0.45,
            fatProgress: 0.8,
            protein: 73,
            carbs: 90,
            fat: 52,
            proteinGoal: 150,
            carbsGoal: 200,
            fatGoal: 65,
            isOverGoal: false
        )

        DailyProgressCard(
            totalCalories: 2200,
            calorieGoal: 2000,
            remainingCalories: 0,
            calorieProgress: 1.1,
            proteinProgress: 0.9,
            carbsProgress: 1.0,
            fatProgress: 1.0,
            protein: 135,
            carbs: 200,
            fat: 65,
            proteinGoal: 150,
            carbsGoal: 200,
            fatGoal: 65,
            isOverGoal: true
        )
    }
    .padding()
    .background(FuelColors.background)
}
