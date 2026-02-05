import SwiftUI

/// Progress Screen
/// Premium analytics and progress tracking with glassmorphism design

struct ProgressScreen: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = ProgressViewModel()
    @State private var showingAchievements = false
    @State private var showAnalyticsPaywall = false
    @State private var showingLogWeight = false
    @State private var scrollOffset: CGFloat = 0

    var body: some View {
        NavigationStack {
            ZStack {
                // Gradient background
                backgroundGradient

                ScrollView {
                    VStack(spacing: 0) {
                        // Hero section
                        heroSection
                            .padding(.bottom, FuelSpacing.xl)

                        // Content sections
                        VStack(spacing: FuelSpacing.lg) {
                            // Time range selector
                            timeRangeSelector
                                .padding(.horizontal, FuelSpacing.screenHorizontal)

                            // Weekly overview (horizontal scroll)
                            if viewModel.selectedTimeRange == .week {
                                weeklyOverviewSection
                            }

                            // Stats cards row
                            statsCardsRow
                                .padding(.horizontal, FuelSpacing.screenHorizontal)

                            // Calorie trends
                            calorieTrendsCard
                                .padding(.horizontal, FuelSpacing.screenHorizontal)

                            // Macros
                            macrosCard
                                .padding(.horizontal, FuelSpacing.screenHorizontal)

                            // Weight
                            weightCard
                                .padding(.horizontal, FuelSpacing.screenHorizontal)

                            // Achievements
                            if !viewModel.recentAchievements.isEmpty {
                                achievementsSection
                                    .padding(.horizontal, FuelSpacing.screenHorizontal)
                            }
                        }
                        .padding(.bottom, FuelSpacing.screenBottom + 100)
                    }
                }
                .scrollIndicators(.hidden)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Progress")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .refreshable {
                await refreshData()
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
                .presentationDetents([.height(360)])
                .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                FuelColors.primary.opacity(0.15),
                FuelColors.background,
                FuelColors.background
            ],
            startPoint: .top,
            endPoint: .center
        )
        .ignoresSafeArea()
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: FuelSpacing.lg) {
            // Main calorie display
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                FuelColors.primary.opacity(0.3),
                                FuelColors.primary.opacity(0.1),
                                .clear
                            ],
                            center: .center,
                            startRadius: 60,
                            endRadius: 120
                        )
                    )
                    .frame(width: 240, height: 240)
                    .blur(radius: 20)

                // Progress ring
                ZStack {
                    // Background ring
                    Circle()
                        .stroke(
                            FuelColors.primary.opacity(0.15),
                            lineWidth: 12
                        )

                    // Progress arc
                    Circle()
                        .trim(from: 0, to: calorieProgress)
                        .stroke(
                            AngularGradient(
                                colors: [
                                    FuelColors.primary,
                                    FuelColors.primary.opacity(0.8),
                                    FuelColors.primaryDark
                                ],
                                center: .center,
                                startAngle: .degrees(-90),
                                endAngle: .degrees(270)
                            ),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .shadow(color: FuelColors.primary.opacity(0.5), radius: 8)

                    // Center content
                    VStack(spacing: 4) {
                        Text("\(viewModel.averageCalories)")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        Text("avg calories")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white.opacity(0.7))

                        // Goal comparison
                        HStack(spacing: 4) {
                            Image(systemName: calorieProgress <= 1 ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                                .font(.system(size: 12))
                            Text(calorieProgress <= 1 ? "On track" : "Over goal")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundStyle(calorieProgress <= 1 ? FuelColors.success : FuelColors.error)
                        .padding(.top, 4)
                    }
                }
                .frame(width: 180, height: 180)
            }
            .padding(.top, FuelSpacing.xl)

            // Streak badge
            HStack(spacing: FuelSpacing.sm) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.orange)

                Text("\(viewModel.currentStreak) day streak")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, FuelSpacing.lg)
            .padding(.vertical, FuelSpacing.sm)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Capsule()
                            .stroke(.white.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }

    private var calorieProgress: Double {
        guard viewModel.calorieGoal > 0 else { return 0 }
        return min(Double(viewModel.averageCalories) / Double(viewModel.calorieGoal), 1.2)
    }

    // MARK: - Time Range Selector

    private var timeRangeSelector: some View {
        HStack(spacing: 8) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                let isSelected = viewModel.selectedTimeRange == range

                Button {
                    if range.requiresPremium && !FeatureGateService.shared.canAccessFullAnalytics() {
                        FuelHaptics.shared.error()
                        showAnalyticsPaywall = true
                        return
                    }
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        viewModel.selectTimeRange(range)
                    }
                    FuelHaptics.shared.select()
                } label: {
                    HStack(spacing: 4) {
                        Text(range.rawValue)
                            .font(.system(size: 13, weight: isSelected ? .semibold : .medium))

                        if range.requiresPremium && !FeatureGateService.shared.canAccessFullAnalytics() {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 9))
                        }
                    }
                    .foregroundStyle(isSelected ? .white : .white.opacity(0.6))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(isSelected ? FuelColors.primary : .white.opacity(0.1))
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
        )
    }

    // MARK: - Weekly Overview

    private var weeklyOverviewSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(viewModel.calorieEntries) { entry in
                    WeekDayCard(entry: entry, goal: viewModel.calorieGoal)
                }
            }
            .padding(.horizontal, FuelSpacing.screenHorizontal)
        }
    }

    // MARK: - Stats Cards Row

    private var statsCardsRow: some View {
        HStack(spacing: 12) {
            // Days logged
            GlassStatCard(
                icon: "calendar",
                iconColor: FuelColors.primary,
                value: "\(viewModel.totalDaysLogged)",
                label: "Days Logged"
            )

            // On track
            GlassStatCard(
                icon: "checkmark.circle.fill",
                iconColor: FuelColors.success,
                value: "\(viewModel.daysUnderGoal)",
                label: "On Track"
            )

            // Best streak
            GlassStatCard(
                icon: "trophy.fill",
                iconColor: FuelColors.gold,
                value: "\(viewModel.longestStreak)",
                label: "Best Streak"
            )
        }
    }

    // MARK: - Calorie Trends Card

    private var calorieTrendsCard: some View {
        ProgressGlassCard {
            VStack(alignment: .leading, spacing: FuelSpacing.md) {
                // Header
                HStack {
                    Label("Calories", systemImage: "flame.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)

                    Spacer()

                    Text("\(viewModel.averageCalories) avg")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                }

                // Chart
                CalorieChartView(
                    entries: viewModel.calorieEntries,
                    goal: viewModel.calorieGoal
                )
                .frame(height: 140)

                // Legend
                HStack(spacing: FuelSpacing.lg) {
                    LegendItem(color: FuelColors.success, label: "Under goal")
                    LegendItem(color: FuelColors.error, label: "Over goal")
                }
            }
            .padding(FuelSpacing.lg)
        }
    }

    // MARK: - Macros Card

    private var macrosCard: some View {
        ProgressGlassCard {
            VStack(alignment: .leading, spacing: FuelSpacing.md) {
                // Header
                Label("Macros", systemImage: "chart.pie.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)

                // Macro bars
                VStack(spacing: FuelSpacing.md) {
                    MacroBar(
                        name: "Protein",
                        value: viewModel.averageProtein,
                        goal: viewModel.proteinGoal,
                        color: FuelColors.protein
                    )

                    MacroBar(
                        name: "Carbs",
                        value: viewModel.averageCarbs,
                        goal: viewModel.carbsGoal,
                        color: FuelColors.carbs
                    )

                    MacroBar(
                        name: "Fat",
                        value: viewModel.averageFat,
                        goal: viewModel.fatGoal,
                        color: FuelColors.fat
                    )
                }
            }
            .padding(FuelSpacing.lg)
        }
    }

    // MARK: - Weight Card

    private var weightCard: some View {
        ProgressGlassCard {
            VStack(alignment: .leading, spacing: FuelSpacing.md) {
                // Header with log button
                HStack {
                    Label("Weight", systemImage: "scalemass.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)

                    Spacer()

                    Button {
                        FuelHaptics.shared.impact()
                        showingLogWeight = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                                .font(.system(size: 11, weight: .bold))
                            Text("Log")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundStyle(FuelColors.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(FuelColors.primary.opacity(0.15))
                        )
                    }
                }

                if viewModel.hasWeightData {
                    // Weight stats
                    HStack(spacing: 0) {
                        WeightStatItem(
                            value: String(format: "%.1f", viewModel.currentWeight),
                            label: "Current",
                            unit: "lbs"
                        )

                        Divider()
                            .frame(height: 40)
                            .background(.white.opacity(0.2))

                        WeightStatItem(
                            value: String(format: "%+.1f", viewModel.weightChange),
                            label: "Change",
                            unit: "lbs",
                            valueColor: viewModel.weightChange < 0 ? FuelColors.success : FuelColors.error
                        )

                        Divider()
                            .frame(height: 40)
                            .background(.white.opacity(0.2))

                        WeightStatItem(
                            value: String(format: "%.1f", viewModel.goalWeight),
                            label: "Goal",
                            unit: "lbs"
                        )
                    }

                    // Chart
                    WeightChartView(
                        entries: viewModel.weightEntries,
                        goalWeight: viewModel.goalWeight
                    )
                    .frame(height: 160)
                } else {
                    // Empty state
                    VStack(spacing: FuelSpacing.sm) {
                        Image(systemName: "scalemass")
                            .font(.system(size: 32))
                            .foregroundStyle(.white.opacity(0.4))

                        Text("No weight data yet")
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.6))

                        Text("Log your weight to track progress")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, FuelSpacing.xl)
                }
            }
            .padding(FuelSpacing.lg)
        }
    }

    // MARK: - Achievements Section

    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: FuelSpacing.md) {
            // Header
            HStack {
                Label("Achievements", systemImage: "star.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)

                Spacer()

                Button {
                    FuelHaptics.shared.tap()
                    showingAchievements = true
                } label: {
                    Text("See All")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(FuelColors.primary)
                }
            }

            // Achievement cards
            VStack(spacing: 10) {
                ForEach(viewModel.recentAchievements) { achievement in
                    GlassAchievementRow(achievement: achievement)
                }
            }
        }
    }

    // MARK: - Refresh

    private func refreshData() async {
        FuelHaptics.shared.tap()
        viewModel.loadData()
        try? await Task.sleep(nanoseconds: 300_000_000)
        FuelHaptics.shared.success()
    }
}

// MARK: - Progress Glass Card

struct ProgressGlassCard<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.3), .white.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
    }
}

// MARK: - Glass Stat Card

struct GlassStatCard: View {
    let icon: String
    let iconColor: Color
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(iconColor)

            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.15), lineWidth: 1)
                )
        )
    }
}

// MARK: - Week Day Card

struct WeekDayCard: View {
    let entry: CalorieDataPoint
    let goal: Int

    private var progress: Double {
        guard goal > 0 else { return 0 }
        return min(Double(entry.calories) / Double(goal), 1.0)
    }

    private var isOverGoal: Bool {
        entry.calories > goal
    }

    var body: some View {
        VStack(spacing: 8) {
            // Day
            Text(entry.dayOfWeek)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))

            // Ring
            ZStack {
                Circle()
                    .stroke(.white.opacity(0.15), lineWidth: 4)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        isOverGoal ? FuelColors.error : FuelColors.success,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                if entry.calories > 0 {
                    Image(systemName: isOverGoal ? "exclamationmark" : "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(isOverGoal ? FuelColors.error : FuelColors.success)
                }
            }
            .frame(width: 36, height: 36)

            // Calories
            Text("\(entry.calories)")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

// MARK: - Macro Bar

struct MacroBar: View {
    let name: String
    let value: Double
    let goal: Double
    let color: Color

    private var progress: Double {
        guard goal > 0 else { return 0 }
        return min(value / goal, 1.0)
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text(name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))

                Spacer()

                Text("\(Int(value))g / \(Int(goal))g")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.white.opacity(0.15))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress)
                }
            }
            .frame(height: 8)
        }
    }
}

// MARK: - Weight Stat Item

struct WeightStatItem: View {
    let value: String
    let label: String
    let unit: String
    var valueColor: Color = .white

    var body: some View {
        VStack(spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(valueColor)

                Text(unit)
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.5))
            }

            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Legend Item

struct LegendItem: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.6))
        }
    }
}

// MARK: - Glass Achievement Row

struct GlassAchievementRow: View {
    let achievement: ProgressAchievement

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: achievement.icon)
                .font(.system(size: 16))
                .foregroundStyle(achievement.color)
                .frame(width: 36, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(achievement.color.opacity(0.15))
                )

            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(achievement.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)

                Text(achievement.description)
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.5))
                    .lineLimit(1)
            }

            Spacer()

            Text(achievement.formattedDate)
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.4))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

// MARK: - Log Weight Sheet

struct LogWeightSheet: View {
    let currentWeight: Double
    let onSave: (Double) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var weightText: String = ""
    @State private var hasAppeared = false
    @State private var showSuccess = false
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
                        .frame(width: 80, height: 80)

                    Image(systemName: "scalemass.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(FuelColors.primary)
                }
                .scaleEffect(hasAppeared ? 1 : 0.5)
                .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1), value: hasAppeared)
                .padding(.top, FuelSpacing.lg)

                Text("Log Your Weight")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(FuelColors.textPrimary)

                // Weight input
                HStack(spacing: FuelSpacing.md) {
                    Button {
                        adjustWeight(by: -0.1)
                    } label: {
                        Image(systemName: "minus")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(FuelColors.primary)
                            .frame(width: 44, height: 44)
                            .background(FuelColors.primary.opacity(0.1))
                            .clipShape(Circle())
                    }

                    VStack(spacing: 4) {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            TextField("0.0", text: $weightText)
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundStyle(FuelColors.textPrimary)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.center)
                                .focused($isTextFieldFocused)
                                .frame(width: 140)

                            Text("lbs")
                                .font(.system(size: 18))
                                .foregroundStyle(FuelColors.textSecondary)
                        }

                        if let diff = weightDifference, abs(diff) > 0.05 {
                            HStack(spacing: 4) {
                                Image(systemName: diff > 0 ? "arrow.up.right" : "arrow.down.right")
                                    .font(.system(size: 12, weight: .semibold))
                                Text(String(format: "%+.1f lbs", diff))
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundStyle(diff < 0 ? FuelColors.success : FuelColors.textSecondary)
                        }
                    }

                    Button {
                        adjustWeight(by: 0.1)
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(FuelColors.primary)
                            .frame(width: 44, height: 44)
                            .background(FuelColors.primary.opacity(0.1))
                            .clipShape(Circle())
                    }
                }

                Spacer()

                // Save button
                Button {
                    saveWeight()
                } label: {
                    HStack {
                        if showSuccess {
                            Image(systemName: "checkmark")
                                .font(.system(size: 18, weight: .bold))
                        }
                        Text(showSuccess ? "Saved!" : "Save Weight")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(showSuccess ? FuelColors.success : FuelColors.primary)
                    )
                }
                .disabled(!isValidWeight)
                .opacity(isValidWeight ? 1 : 0.5)
                .padding(.horizontal, FuelSpacing.screenHorizontal)
                .padding(.bottom, FuelSpacing.lg)
            }
            .background(FuelColors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(FuelColors.textSecondary)
                }
            }
            .onAppear {
                hasAppeared = true
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
        FuelHaptics.shared.select()
    }

    private func saveWeight() {
        guard let weight = enteredWeight else { return }
        withAnimation {
            showSuccess = true
        }
        FuelHaptics.shared.success()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            onSave(weight)
        }
    }
}

// MARK: - Preview

#Preview {
    ProgressScreen()
}
