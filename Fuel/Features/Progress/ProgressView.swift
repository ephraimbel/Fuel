import SwiftUI

/// Progress View
/// Main analytics and progress tracking screen

struct ProgressView: View {
    @State private var viewModel = ProgressViewModel()
    @State private var showingAchievements = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: FuelSpacing.lg) {
                    // Time range selector
                    timeRangeSelector

                    // Weekly overview (only show for week view)
                    if viewModel.selectedTimeRange == .week {
                        WeeklyOverviewCard(
                            entries: viewModel.calorieEntries,
                            goal: viewModel.calorieGoal
                        )
                    }

                    // Weight progress section
                    weightProgressSection

                    // Calorie trends section
                    calorieTrendsSection

                    // Macro averages section
                    macroAveragesSection

                    // Stats summary
                    statsSummarySection

                    // Recent achievements
                    if !viewModel.recentAchievements.isEmpty {
                        achievementsSection
                    }
                }
                .padding(.horizontal, FuelSpacing.screenHorizontal)
                .padding(.vertical, FuelSpacing.lg)
            }
            .background(FuelColors.background)
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                viewModel.loadData()
            }
            .navigationDestination(isPresented: $showingAchievements) {
                AchievementsView()
            }
        }
    }

    // MARK: - Time Range Selector

    private var timeRangeSelector: some View {
        HStack(spacing: FuelSpacing.xs) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Button {
                    viewModel.selectTimeRange(range)
                } label: {
                    Text(range.rawValue)
                        .font(FuelTypography.subheadlineMedium)
                        .foregroundStyle(
                            viewModel.selectedTimeRange == range
                                ? .white
                                : FuelColors.textSecondary
                        )
                        .padding(.horizontal, FuelSpacing.md)
                        .padding(.vertical, FuelSpacing.sm)
                        .background(
                            viewModel.selectedTimeRange == range
                                ? FuelColors.primary
                                : FuelColors.surface
                        )
                        .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusSm))
                }
            }
        }
    }

    // MARK: - Weight Progress Section

    private var weightProgressSection: some View {
        VStack(alignment: .leading, spacing: FuelSpacing.md) {
            sectionHeader(title: "WEIGHT", icon: "scalemass.fill")

            VStack(spacing: FuelSpacing.lg) {
                // Weight summary
                HStack(spacing: FuelSpacing.xl) {
                    weightStatBox(
                        label: "Current",
                        value: String(format: "%.1f", viewModel.currentWeight),
                        unit: "lbs"
                    )

                    weightStatBox(
                        label: "Change",
                        value: String(format: "%+.1f", viewModel.weightChange),
                        unit: "lbs",
                        color: viewModel.weightChange < 0 ? FuelColors.success : FuelColors.error
                    )

                    weightStatBox(
                        label: "To Goal",
                        value: String(format: "%.1f", abs(viewModel.weightToGoal)),
                        unit: "lbs"
                    )
                }

                // Weight chart
                WeightChartView(
                    entries: viewModel.weightEntries,
                    goalWeight: viewModel.goalWeight
                )
                .frame(height: 180)

                // Progress bar to goal
                VStack(alignment: .leading, spacing: FuelSpacing.sm) {
                    HStack {
                        Text("Progress to Goal")
                            .font(FuelTypography.caption)
                            .foregroundStyle(FuelColors.textSecondary)

                        Spacer()

                        Text("\(Int(viewModel.weightProgressPercent * 100))%")
                            .font(FuelTypography.captionMedium)
                            .foregroundStyle(FuelColors.primary)
                    }

                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(FuelColors.surfaceSecondary)
                                .frame(height: 8)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(FuelColors.primary)
                                .frame(width: geometry.size.width * viewModel.weightProgressPercent, height: 8)
                        }
                    }
                    .frame(height: 8)

                    HStack {
                        Text(String(format: "%.0f lbs", viewModel.startingWeight))
                            .font(FuelTypography.caption)
                            .foregroundStyle(FuelColors.textTertiary)

                        Spacer()

                        Text(String(format: "%.0f lbs", viewModel.goalWeight))
                            .font(FuelTypography.caption)
                            .foregroundStyle(FuelColors.textTertiary)
                    }
                }
            }
            .padding(FuelSpacing.lg)
            .background(FuelColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusLg))
        }
    }

    private func weightStatBox(
        label: String,
        value: String,
        unit: String,
        color: Color = FuelColors.textPrimary
    ) -> some View {
        VStack(spacing: FuelSpacing.xxxs) {
            Text(label)
                .font(FuelTypography.caption)
                .foregroundStyle(FuelColors.textTertiary)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(color)

                Text(unit)
                    .font(FuelTypography.caption)
                    .foregroundStyle(FuelColors.textTertiary)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Calorie Trends Section

    private var calorieTrendsSection: some View {
        VStack(alignment: .leading, spacing: FuelSpacing.md) {
            sectionHeader(title: "CALORIES", icon: "flame.fill")

            VStack(spacing: FuelSpacing.lg) {
                // Average calories
                HStack {
                    VStack(alignment: .leading, spacing: FuelSpacing.xxxs) {
                        Text("Daily Average")
                            .font(FuelTypography.caption)
                            .foregroundStyle(FuelColors.textTertiary)

                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(viewModel.averageCalories)")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundStyle(FuelColors.textPrimary)

                            Text("cal")
                                .font(FuelTypography.subheadline)
                                .foregroundStyle(FuelColors.textSecondary)
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: FuelSpacing.xs) {
                        HStack(spacing: FuelSpacing.xs) {
                            Circle()
                                .fill(FuelColors.success)
                                .frame(width: 8, height: 8)
                            Text("\(viewModel.daysUnderGoal) under")
                                .font(FuelTypography.caption)
                                .foregroundStyle(FuelColors.textSecondary)
                        }

                        HStack(spacing: FuelSpacing.xs) {
                            Circle()
                                .fill(FuelColors.error)
                                .frame(width: 8, height: 8)
                            Text("\(viewModel.daysOverGoal) over")
                                .font(FuelTypography.caption)
                                .foregroundStyle(FuelColors.textSecondary)
                        }
                    }
                }

                // Calorie chart
                CalorieChartView(
                    entries: viewModel.calorieEntries,
                    goal: viewModel.calorieGoal
                )
                .frame(height: 160)
            }
            .padding(FuelSpacing.lg)
            .background(FuelColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusLg))
        }
    }

    // MARK: - Macro Averages Section

    private var macroAveragesSection: some View {
        VStack(alignment: .leading, spacing: FuelSpacing.md) {
            sectionHeader(title: "MACROS", icon: "chart.pie.fill")

            HStack(spacing: FuelSpacing.md) {
                macroCard(
                    name: "Protein",
                    average: viewModel.averageProtein,
                    goal: viewModel.proteinGoal,
                    color: FuelColors.protein
                )

                macroCard(
                    name: "Carbs",
                    average: viewModel.averageCarbs,
                    goal: viewModel.carbsGoal,
                    color: FuelColors.carbs
                )

                macroCard(
                    name: "Fat",
                    average: viewModel.averageFat,
                    goal: viewModel.fatGoal,
                    color: FuelColors.fat
                )
            }
        }
    }

    private func macroCard(
        name: String,
        average: Double,
        goal: Double,
        color: Color
    ) -> some View {
        let progress = min(average / goal, 1.0)

        return VStack(spacing: FuelSpacing.sm) {
            // Circular progress
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 6)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                Text("\(Int(progress * 100))%")
                    .font(FuelTypography.captionMedium)
                    .foregroundStyle(FuelColors.textPrimary)
            }
            .frame(width: 60, height: 60)

            VStack(spacing: FuelSpacing.xxxs) {
                Text("\(Int(average))g")
                    .font(FuelTypography.subheadlineMedium)
                    .foregroundStyle(FuelColors.textPrimary)

                Text(name)
                    .font(FuelTypography.caption)
                    .foregroundStyle(FuelColors.textTertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(FuelSpacing.md)
        .background(FuelColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
    }

    // MARK: - Stats Summary Section

    private var statsSummarySection: some View {
        VStack(alignment: .leading, spacing: FuelSpacing.md) {
            sectionHeader(title: "STATS", icon: "chart.bar.fill")

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: FuelSpacing.md) {
                statCard(
                    icon: "flame.fill",
                    iconColor: .orange,
                    value: "\(viewModel.currentStreak)",
                    label: "Current Streak"
                )

                statCard(
                    icon: "trophy.fill",
                    iconColor: FuelColors.gold,
                    value: "\(viewModel.longestStreak)",
                    label: "Best Streak"
                )

                statCard(
                    icon: "calendar",
                    iconColor: FuelColors.primary,
                    value: "\(viewModel.totalDaysLogged)",
                    label: "Days Logged"
                )

                statCard(
                    icon: "target",
                    iconColor: FuelColors.success,
                    value: "\(viewModel.daysUnderGoal)",
                    label: "Days on Track"
                )
            }
        }
    }

    private func statCard(
        icon: String,
        iconColor: Color,
        value: String,
        label: String
    ) -> some View {
        HStack(spacing: FuelSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(iconColor)
                .frame(width: 40, height: 40)
                .background(iconColor.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusSm))

            VStack(alignment: .leading, spacing: FuelSpacing.xxxs) {
                Text(value)
                    .font(FuelTypography.title3)
                    .foregroundStyle(FuelColors.textPrimary)

                Text(label)
                    .font(FuelTypography.caption)
                    .foregroundStyle(FuelColors.textTertiary)
            }

            Spacer()
        }
        .padding(FuelSpacing.md)
        .background(FuelColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
    }

    // MARK: - Achievements Section

    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: FuelSpacing.md) {
            HStack {
                sectionHeader(title: "RECENT ACHIEVEMENTS", icon: "star.fill")

                Spacer()

                Button {
                    FuelHaptics.shared.tap()
                    showingAchievements = true
                } label: {
                    Text("See All")
                        .font(FuelTypography.captionMedium)
                        .foregroundStyle(FuelColors.primary)
                }
            }

            VStack(spacing: FuelSpacing.sm) {
                ForEach(viewModel.recentAchievements) { achievement in
                    achievementRow(achievement)
                }
            }
        }
    }

    private func achievementRow(_ achievement: ProgressAchievement) -> some View {
        HStack(spacing: FuelSpacing.md) {
            Image(systemName: achievement.icon)
                .font(.system(size: 20))
                .foregroundStyle(achievement.color)
                .frame(width: 44, height: 44)
                .background(achievement.color.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusSm))

            VStack(alignment: .leading, spacing: FuelSpacing.xxxs) {
                Text(achievement.title)
                    .font(FuelTypography.subheadlineMedium)
                    .foregroundStyle(FuelColors.textPrimary)

                Text(achievement.description)
                    .font(FuelTypography.caption)
                    .foregroundStyle(FuelColors.textTertiary)
            }

            Spacer()

            Text(achievement.formattedDate)
                .font(FuelTypography.caption)
                .foregroundStyle(FuelColors.textTertiary)
        }
        .padding(FuelSpacing.md)
        .background(FuelColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
    }

    // MARK: - Helpers

    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: FuelSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(FuelColors.textTertiary)

            Text(title)
                .font(FuelTypography.caption)
                .foregroundStyle(FuelColors.textTertiary)
        }
    }
}

// MARK: - Preview

#Preview {
    ProgressView()
}
