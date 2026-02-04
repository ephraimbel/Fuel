import SwiftUI

/// Weekly Overview Card
/// Shows a week at a glance with mini calorie rings

struct WeeklyOverviewCard: View {
    let entries: [CalorieDataPoint]
    let goal: Int

    var body: some View {
        VStack(alignment: .leading, spacing: FuelSpacing.md) {
            // Header
            HStack {
                Text("This Week")
                    .font(FuelTypography.headline)
                    .foregroundStyle(FuelColors.textPrimary)

                Spacer()

                Text("\(daysOnTrack)/\(entries.count) on track")
                    .font(FuelTypography.caption)
                    .foregroundStyle(FuelColors.textSecondary)
            }

            // Day rings
            HStack(spacing: FuelSpacing.sm) {
                ForEach(entries.suffix(7)) { entry in
                    dayRing(entry)
                }
            }
        }
        .padding(FuelSpacing.lg)
        .background(FuelColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusLg))
    }

    private var daysOnTrack: Int {
        entries.suffix(7).filter { $0.isUnderGoal }.count
    }

    private func dayRing(_ entry: CalorieDataPoint) -> some View {
        let progress = min(Double(entry.calories) / Double(goal), 1.0)
        let isToday = Calendar.current.isDateInToday(entry.date)

        return VStack(spacing: FuelSpacing.xs) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(FuelColors.surfaceSecondary, lineWidth: 4)
                    .frame(width: 36, height: 36)

                // Progress ring
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        entry.isUnderGoal ? FuelColors.success : FuelColors.error,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 36, height: 36)
                    .rotationEffect(.degrees(-90))

                // Center indicator
                if entry.isUnderGoal {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(FuelColors.success)
                }
            }

            Text(entry.dayOfWeek)
                .font(FuelTypography.caption)
                .foregroundStyle(isToday ? FuelColors.primary : FuelColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Insights Card

struct InsightsCard: View {
    let title: String
    let insight: String
    let icon: String
    let iconColor: Color

    var body: some View {
        HStack(spacing: FuelSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(iconColor)
                .frame(width: 48, height: 48)
                .background(iconColor.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))

            VStack(alignment: .leading, spacing: FuelSpacing.xxxs) {
                Text(title)
                    .font(FuelTypography.captionMedium)
                    .foregroundStyle(FuelColors.textTertiary)

                Text(insight)
                    .font(FuelTypography.body)
                    .foregroundStyle(FuelColors.textPrimary)
            }

            Spacer()
        }
        .padding(FuelSpacing.md)
        .background(FuelColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
    }
}

// MARK: - Trend Indicator

struct TrendIndicator: View {
    let value: Double
    let isPositiveGood: Bool

    private var isPositive: Bool {
        value >= 0
    }

    private var color: Color {
        if isPositiveGood {
            return isPositive ? FuelColors.success : FuelColors.error
        } else {
            return isPositive ? FuelColors.error : FuelColors.success
        }
    }

    var body: some View {
        HStack(spacing: FuelSpacing.xxxs) {
            Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                .font(.system(size: 10, weight: .bold))

            Text(String(format: "%+.1f%%", value))
                .font(FuelTypography.captionMedium)
        }
        .foregroundStyle(color)
        .padding(.horizontal, FuelSpacing.sm)
        .padding(.vertical, FuelSpacing.xxxs)
        .background(color.opacity(0.15))
        .clipShape(Capsule())
    }
}

// MARK: - Macro Distribution Chart

struct MacroDistributionChart: View {
    let protein: Double
    let carbs: Double
    let fat: Double

    private var total: Double {
        protein + carbs + fat
    }

    private var proteinPercent: Double {
        guard total > 0 else { return 0 }
        return protein / total
    }

    private var carbsPercent: Double {
        guard total > 0 else { return 0 }
        return carbs / total
    }

    private var fatPercent: Double {
        guard total > 0 else { return 0 }
        return fat / total
    }

    var body: some View {
        VStack(spacing: FuelSpacing.md) {
            // Pie chart
            ZStack {
                // Protein
                Circle()
                    .trim(from: 0, to: proteinPercent)
                    .stroke(FuelColors.protein, style: StrokeStyle(lineWidth: 20, lineCap: .butt))
                    .rotationEffect(.degrees(-90))

                // Carbs
                Circle()
                    .trim(from: proteinPercent, to: proteinPercent + carbsPercent)
                    .stroke(FuelColors.carbs, style: StrokeStyle(lineWidth: 20, lineCap: .butt))
                    .rotationEffect(.degrees(-90))

                // Fat
                Circle()
                    .trim(from: proteinPercent + carbsPercent, to: 1)
                    .stroke(FuelColors.fat, style: StrokeStyle(lineWidth: 20, lineCap: .butt))
                    .rotationEffect(.degrees(-90))

                // Center
                VStack(spacing: FuelSpacing.xxxs) {
                    Text("\(Int(total))g")
                        .font(FuelTypography.headline)
                        .foregroundStyle(FuelColors.textPrimary)

                    Text("total")
                        .font(FuelTypography.caption)
                        .foregroundStyle(FuelColors.textTertiary)
                }
            }
            .frame(width: 120, height: 120)

            // Legend
            HStack(spacing: FuelSpacing.lg) {
                macroLegendItem(
                    name: "Protein",
                    value: protein,
                    percent: proteinPercent,
                    color: FuelColors.protein
                )

                macroLegendItem(
                    name: "Carbs",
                    value: carbs,
                    percent: carbsPercent,
                    color: FuelColors.carbs
                )

                macroLegendItem(
                    name: "Fat",
                    value: fat,
                    percent: fatPercent,
                    color: FuelColors.fat
                )
            }
        }
    }

    private func macroLegendItem(
        name: String,
        value: Double,
        percent: Double,
        color: Color
    ) -> some View {
        VStack(spacing: FuelSpacing.xxxs) {
            HStack(spacing: FuelSpacing.xxxs) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)

                Text(name)
                    .font(FuelTypography.caption)
                    .foregroundStyle(FuelColors.textSecondary)
            }

            Text("\(Int(percent * 100))%")
                .font(FuelTypography.subheadlineMedium)
                .foregroundStyle(FuelColors.textPrimary)
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: FuelSpacing.lg) {
            WeeklyOverviewCard(
                entries: [
                    CalorieDataPoint(date: Date().addingTimeInterval(-6 * 24 * 3600), calories: 1850, goal: 2000),
                    CalorieDataPoint(date: Date().addingTimeInterval(-5 * 24 * 3600), calories: 2100, goal: 2000),
                    CalorieDataPoint(date: Date().addingTimeInterval(-4 * 24 * 3600), calories: 1950, goal: 2000),
                    CalorieDataPoint(date: Date().addingTimeInterval(-3 * 24 * 3600), calories: 1780, goal: 2000),
                    CalorieDataPoint(date: Date().addingTimeInterval(-2 * 24 * 3600), calories: 2200, goal: 2000),
                    CalorieDataPoint(date: Date().addingTimeInterval(-1 * 24 * 3600), calories: 1900, goal: 2000),
                    CalorieDataPoint(date: Date(), calories: 1650, goal: 2000)
                ],
                goal: 2000
            )

            InsightsCard(
                title: "Weekly Insight",
                insight: "You're eating 15% less on weekdays vs weekends",
                icon: "lightbulb.fill",
                iconColor: .yellow
            )

            MacroDistributionChart(
                protein: 120,
                carbs: 180,
                fat: 55
            )
            .padding()
            .background(FuelColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusLg))

            TrendIndicator(value: -5.2, isPositiveGood: false)
        }
        .padding()
    }
    .background(FuelColors.background)
}
