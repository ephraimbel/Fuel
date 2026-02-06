import SwiftUI

/// Progress Screen
/// Main analytics and progress tracking screen

struct ProgressScreen: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = ProgressViewModel()
    @State private var showingAchievements = false
    @State private var showAnalyticsPaywall = false
    @State private var showingLogWeight = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: FuelSpacing.sectionSpacing) {
                    // Time range selector
                    timeRangeSelector

                    // Weekly overview (only show for week view)
                    if viewModel.selectedTimeRange == .week {
                        WeeklyOverviewCard(
                            entries: viewModel.calorieEntries,
                            goal: viewModel.calorieGoal
                        )
                    }

                    // Calorie trends section (moved up)
                    calorieTrendsSection

                    // Macro averages section (moved up)
                    macroAveragesSection

                    // Weight progress section
                    weightProgressSection

                    // Stats summary
                    statsSummarySection

                    // Recent achievements
                    if !viewModel.recentAchievements.isEmpty {
                        achievementsSection
                    }
                }
                .padding(.horizontal, FuelSpacing.screenHorizontal)
                .padding(.bottom, FuelSpacing.screenBottom + 80) // Tab bar space
            }
            .scrollIndicators(.hidden)
            .background(FuelColors.backgroundGradient)
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                viewModel.loadData()
            }
            .onAppear {
                viewModel.setup(with: modelContext)
            }
            .navigationDestination(isPresented: $showingAchievements) {
                AchievementsView()
            }
            .fullScreenCover(isPresented: $showAnalyticsPaywall) {
                PaywallView(context: .analyticsLimit)
            }
            .sheet(isPresented: $showingLogWeight) {
                LogWeightSheet(
                    currentWeight: viewModel.currentWeight,
                    onSave: { weight in
                        viewModel.logWeight(weight, in: modelContext)
                        showingLogWeight = false
                    }
                )
                .presentationDetents([.height(320)])
                .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Time Range Selector

    private var timeRangeSelector: some View {
        HStack(spacing: FuelSpacing.xs) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Button {
                    // Check if premium range requires upgrade
                    if range.requiresPremium && !FeatureGateService.shared.canAccessFullAnalytics() {
                        FuelHaptics.shared.error()
                        showAnalyticsPaywall = true
                        return
                    }

                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.selectTimeRange(range)
                    }
                    FuelHaptics.shared.tap()
                } label: {
                    HStack(spacing: FuelSpacing.xxs) {
                        Text(range.rawValue)
                            .font(FuelTypography.subheadlineMedium)

                        // Show lock icon for premium ranges if not premium
                        if range.requiresPremium && !FeatureGateService.shared.canAccessFullAnalytics() {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 10))
                        }
                    }
                    .foregroundStyle(
                        viewModel.selectedTimeRange == range
                            ? .white
                            : FuelColors.textSecondary
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, FuelSpacing.sm)
                    .background(
                        viewModel.selectedTimeRange == range
                            ? FuelColors.primary
                            : FuelColors.surface
                    )
                    .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusSm))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(FuelSpacing.xxs)
        .background(FuelColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
    }

    // MARK: - Section Header

    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: FuelSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(FuelColors.textTertiary)

            Text(title)
                .font(FuelTypography.caption)
                .fontWeight(.semibold)
                .foregroundStyle(FuelColors.textTertiary)
                .textCase(.uppercase)
                .tracking(0.5)

            Spacer()
        }
        .padding(.bottom, FuelSpacing.xs)
    }

    // MARK: - Weight Progress Section

    private var weightProgressSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header with Log Weight button
            HStack {
                sectionHeader(title: "Weight", icon: "scalemass.fill")

                Spacer()

                Button {
                    FuelHaptics.shared.tap()
                    showingLogWeight = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 10, weight: .semibold))
                        Text("Log")
                            .font(FuelTypography.captionMedium)
                    }
                    .foregroundStyle(FuelColors.primary)
                    .padding(.horizontal, FuelSpacing.sm)
                    .padding(.vertical, FuelSpacing.xs)
                    .background(FuelColors.primary.opacity(0.1))
                    .clipShape(Capsule())
                }
            }

            VStack(spacing: FuelSpacing.lg) {
                // Weight summary stats
                HStack(spacing: 0) {
                    weightStatBox(
                        label: "Current",
                        value: String(format: "%.1f", viewModel.currentWeight),
                        unit: "lbs"
                    )

                    Divider()
                        .frame(height: 40)
                        .background(FuelColors.surfaceSecondary)

                    weightStatBox(
                        label: "Change",
                        value: String(format: "%+.1f", viewModel.weightChange),
                        unit: "lbs",
                        color: viewModel.weightChange < 0 ? FuelColors.success : FuelColors.error
                    )

                    Divider()
                        .frame(height: 40)
                        .background(FuelColors.surfaceSecondary)

                    weightStatBox(
                        label: "To Goal",
                        value: String(format: "%.1f", abs(viewModel.weightToGoal)),
                        unit: "lbs"
                    )
                }
                .padding(.vertical, FuelSpacing.md)

                // Weight chart
                WeightChartView(
                    entries: viewModel.weightEntries,
                    goalWeight: viewModel.goalWeight,
                    timeRange: viewModel.selectedTimeRange
                )
                .frame(height: 200)

                Divider()
                    .background(FuelColors.surfaceSecondary)
                    .padding(.horizontal, -FuelSpacing.cardPadding)
                    .padding(.horizontal, FuelSpacing.cardPadding)

                // Progress bar to goal
                progressToGoalBar
            }
            .padding(FuelSpacing.cardPadding)
            .background(FuelColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusLg))
            .overlay(
                RoundedRectangle(cornerRadius: FuelSpacing.radiusLg)
                    .stroke(FuelColors.border.opacity(0.3), lineWidth: 0.5)
            )
            .cardShadow()
        }
    }

    private var progressToGoalBar: some View {
        VStack(alignment: .leading, spacing: FuelSpacing.sm) {
            HStack {
                Text("Progress to Goal")
                    .font(FuelTypography.subheadline)
                    .foregroundStyle(FuelColors.textSecondary)

                Spacer()

                Text("\(Int(viewModel.weightProgressPercent * 100))%")
                    .font(FuelTypography.subheadlineMedium)
                    .foregroundStyle(FuelColors.primary)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: FuelSpacing.progressBarHeight / 2)
                        .fill(FuelColors.surfaceSecondary)

                    RoundedRectangle(cornerRadius: FuelSpacing.progressBarHeight / 2)
                        .fill(FuelColors.primary)
                        .frame(width: max(0, geometry.size.width * min(viewModel.weightProgressPercent, 1.0)))
                }
            }
            .frame(height: FuelSpacing.progressBarHeight)

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

    private func weightStatBox(
        label: String,
        value: String,
        unit: String,
        color: Color = FuelColors.textPrimary
    ) -> some View {
        VStack(spacing: FuelSpacing.xxs) {
            Text(label)
                .font(FuelTypography.caption)
                .foregroundStyle(FuelColors.textTertiary)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
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
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader(title: "Calories", icon: "flame.fill")

            VStack(spacing: FuelSpacing.lg) {
                // Average calories header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: FuelSpacing.xxs) {
                        Text("Daily Average")
                            .font(FuelTypography.caption)
                            .foregroundStyle(FuelColors.textTertiary)

                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(viewModel.averageCalories)")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
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
                    goal: viewModel.calorieGoal,
                    timeRange: viewModel.selectedTimeRange
                )
                .frame(height: 160)

                // Macro legend
                MacroLegend()
                    .padding(.top, FuelSpacing.xs)
            }
            .padding(FuelSpacing.cardPadding)
            .background(FuelColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusLg))
            .overlay(
                RoundedRectangle(cornerRadius: FuelSpacing.radiusLg)
                    .stroke(FuelColors.border.opacity(0.3), lineWidth: 0.5)
            )
            .cardShadow()
        }
    }

    // MARK: - Macro Averages Section

    private var macroAveragesSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader(title: "Macros", icon: "chart.pie.fill")

            HStack(spacing: FuelSpacing.cardSpacing) {
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
        let progress = goal > 0 ? min(average / goal, 1.0) : 0

        return VStack(spacing: FuelSpacing.sm) {
            // Circular progress
            ZStack {
                Circle()
                    .stroke(color.opacity(0.15), lineWidth: 5)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.5), value: progress)

                Text("\(Int(progress * 100))%")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(FuelColors.textPrimary)
            }
            .frame(width: 56, height: 56)

            VStack(spacing: 2) {
                Text("\(Int(average))g")
                    .font(FuelTypography.subheadlineMedium)
                    .foregroundStyle(FuelColors.textPrimary)

                Text(name)
                    .font(FuelTypography.caption)
                    .foregroundStyle(FuelColors.textTertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, FuelSpacing.md)
        .padding(.horizontal, FuelSpacing.sm)
        .background(FuelColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
        .cardShadow()
    }

    // MARK: - Stats Summary Section

    private var statsSummarySection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader(title: "Stats", icon: "chart.bar.fill")

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: FuelSpacing.cardSpacing),
                GridItem(.flexible(), spacing: FuelSpacing.cardSpacing)
            ], spacing: FuelSpacing.cardSpacing) {
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
                    icon: "checkmark.circle.fill",
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
                .font(.system(size: 18))
                .foregroundStyle(iconColor)
                .frame(width: 36, height: 36)
                .background(iconColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusSm))

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(FuelColors.textPrimary)

                Text(label)
                    .font(FuelTypography.caption)
                    .foregroundStyle(FuelColors.textTertiary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(FuelSpacing.md)
        .background(FuelColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
        .cardShadow()
    }

    // MARK: - Achievements Section

    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                sectionHeader(title: "Recent Achievements", icon: "star.fill")

                Spacer()

                Button {
                    FuelHaptics.shared.tap()
                    showingAchievements = true
                } label: {
                    HStack(spacing: FuelSpacing.xxs) {
                        Text("See All")
                            .font(FuelTypography.captionMedium)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                    }
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
                .font(.system(size: 18))
                .foregroundStyle(achievement.color)
                .frame(width: 40, height: 40)
                .background(achievement.color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusSm))

            VStack(alignment: .leading, spacing: 2) {
                Text(achievement.title)
                    .font(FuelTypography.subheadlineMedium)
                    .foregroundStyle(FuelColors.textPrimary)

                Text(achievement.description)
                    .font(FuelTypography.caption)
                    .foregroundStyle(FuelColors.textTertiary)
                    .lineLimit(1)
            }

            Spacer()

            Text(achievement.formattedDate)
                .font(FuelTypography.caption)
                .foregroundStyle(FuelColors.textTertiary)
        }
        .padding(FuelSpacing.md)
        .background(FuelColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
        .cardShadow()
    }
}

// MARK: - Log Weight Sheet

struct LogWeightSheet: View {
    let currentWeight: Double
    let onSave: (Double) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var weightText: String = ""
    @FocusState private var isTextFieldFocused: Bool

    init(currentWeight: Double, onSave: @escaping (Double) -> Void) {
        self.currentWeight = currentWeight
        self.onSave = onSave
        self._weightText = State(initialValue: currentWeight > 0 ? String(format: "%.1f", currentWeight) : "")
    }

    private var enteredWeight: Double? {
        Double(weightText)
    }

    private var isValidWeight: Bool {
        if let weight = enteredWeight {
            return weight > 50 && weight < 500
        }
        return false
    }

    private var weightDifference: Double? {
        guard let entered = enteredWeight, currentWeight > 0 else { return nil }
        return entered - currentWeight
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: FuelSpacing.lg) {
                // Icon
                ZStack {
                    Circle()
                        .fill(FuelColors.primary.opacity(0.1))
                        .frame(width: 72, height: 72)

                    Image(systemName: "scalemass.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(FuelColors.primary)
                }
                .padding(.top, FuelSpacing.lg)

                // Weight input
                HStack(spacing: FuelSpacing.md) {
                    Button {
                        adjustWeight(by: -0.1)
                    } label: {
                        Image(systemName: "minus")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(FuelColors.primary)
                            .frame(width: 44, height: 44)
                            .background(FuelColors.primary.opacity(0.1))
                            .clipShape(Circle())
                    }

                    VStack(spacing: 4) {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            TextField("0.0", text: $weightText)
                                .font(.system(size: 44, weight: .bold, design: .rounded))
                                .foregroundStyle(FuelColors.textPrimary)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.center)
                                .focused($isTextFieldFocused)
                                .frame(width: 120)

                            Text("lbs")
                                .font(FuelTypography.body)
                                .foregroundStyle(FuelColors.textSecondary)
                        }

                        if let diff = weightDifference, abs(diff) > 0.05 {
                            HStack(spacing: 4) {
                                Image(systemName: diff > 0 ? "arrow.up.right" : "arrow.down.right")
                                    .font(.system(size: 12, weight: .semibold))
                                Text(String(format: "%+.1f lbs", diff))
                                    .font(FuelTypography.captionMedium)
                            }
                            .foregroundStyle(diff < 0 ? FuelColors.success : FuelColors.textSecondary)
                        }
                    }

                    Button {
                        adjustWeight(by: 0.1)
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(FuelColors.primary)
                            .frame(width: 44, height: 44)
                            .background(FuelColors.primary.opacity(0.1))
                            .clipShape(Circle())
                    }
                }

                Spacer()

                // Save button
                Button {
                    if let weight = enteredWeight {
                        FuelHaptics.shared.success()
                        onSave(weight)
                    }
                } label: {
                    Text("Save Weight")
                        .font(FuelTypography.bodyMedium)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(FuelColors.primary)
                        .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
                }
                .disabled(!isValidWeight)
                .opacity(isValidWeight ? 1 : 0.5)
                .padding(.horizontal, FuelSpacing.screenHorizontal)
                .padding(.bottom, FuelSpacing.md)
            }
            .background(FuelColors.background)
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Log Weight")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(FuelColors.textSecondary)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isTextFieldFocused = true
                }
            }
        }
    }

    private func adjustWeight(by amount: Double) {
        guard let current = enteredWeight else { return }
        let newWeight = max(50, min(500, current + amount))
        weightText = String(format: "%.1f", newWeight)
        FuelHaptics.shared.tap()
    }
}

// MARK: - Preview

#Preview {
    ProgressScreen()
}
