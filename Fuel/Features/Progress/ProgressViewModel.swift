import SwiftUI
import SwiftData

/// Progress View Model
/// Manages progress data and analytics from SwiftData

@Observable
final class ProgressViewModel {
    // MARK: - State

    var selectedTimeRange: TimeRange = .week
    var isLoading = false

    // MARK: - Weight Data

    var weightEntries: [WeightDataPoint] = []
    var currentWeight: Double = 0
    var startingWeight: Double = 0
    var goalWeight: Double = 0

    var weightChange: Double {
        guard startingWeight > 0 else { return 0 }
        return currentWeight - startingWeight
    }

    var weightToGoal: Double {
        guard goalWeight > 0 else { return 0 }
        return currentWeight - goalWeight
    }

    var weightProgressPercent: Double {
        let totalToLose = startingWeight - goalWeight
        guard totalToLose > 0 else { return 0 }
        let lost = startingWeight - currentWeight
        return min(max(lost / totalToLose, 0), 1.0)
    }

    var hasWeightData: Bool {
        !weightEntries.isEmpty
    }

    // MARK: - Calorie Data

    var calorieEntries: [CalorieDataPoint] = []
    var averageCalories: Int = 0
    var calorieGoal: Int = 2000

    var daysUnderGoal: Int {
        calorieEntries.filter { $0.calories <= calorieGoal && $0.calories > 0 }.count
    }

    var daysOverGoal: Int {
        calorieEntries.filter { $0.calories > calorieGoal }.count
    }

    var hasCalorieData: Bool {
        calorieEntries.contains { $0.calories > 0 }
    }

    // MARK: - Macro Data

    var averageProtein: Double = 0
    var averageCarbs: Double = 0
    var averageFat: Double = 0
    var proteinGoal: Double = 150
    var carbsGoal: Double = 200
    var fatGoal: Double = 65

    // MARK: - Streak Data

    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var totalDaysLogged: Int = 0

    // MARK: - Achievements

    var recentAchievements: [ProgressAchievement] = []

    // MARK: - Model Context

    private var modelContext: ModelContext?

    // MARK: - Initialization

    init() {}

    // MARK: - Setup

    func setup(with context: ModelContext) {
        self.modelContext = context
        loadData()
    }

    // MARK: - Data Loading

    func loadData() {
        guard let context = modelContext else { return }

        isLoading = true

        // Load user goals
        loadUserGoals(from: context)

        // Load weight data
        loadWeightData(from: context)

        // Load calorie/meal data
        loadCalorieData(from: context)

        // Calculate streaks
        calculateStreaks(from: context)

        // Load achievements
        loadAchievements(from: context)

        isLoading = false
    }

    func selectTimeRange(_ range: TimeRange) {
        guard range != selectedTimeRange else { return }
        selectedTimeRange = range
        loadData()
    }

    // MARK: - Log Weight

    func logWeight(_ weight: Double, in context: ModelContext) {
        // Create new weight entry
        let entry = WeightEntry(weightKg: weight, recordedAt: Date())
        context.insert(entry)

        // Update user's current weight
        let descriptor = FetchDescriptor<User>()
        if let user = try? context.fetch(descriptor).first {
            user.currentWeightKg = weight
        }

        // Save context
        try? context.save()

        // Update local state
        currentWeight = weight

        // Reload data to refresh charts
        loadData()

        FuelHaptics.shared.success()
    }

    // MARK: - Load User Goals

    private func loadUserGoals(from context: ModelContext) {
        let descriptor = FetchDescriptor<User>()
        if let user = try? context.fetch(descriptor).first {
            calorieGoal = user.dailyCalorieTarget
            proteinGoal = Double(user.dailyProteinTarget)
            carbsGoal = Double(user.dailyCarbsTarget)
            fatGoal = Double(user.dailyFatTarget)
            goalWeight = user.targetWeightKg
            startingWeight = user.currentWeightKg // Use current as starting if no history
            currentWeight = user.currentWeightKg
        }
    }

    // MARK: - Load Weight Data

    private func loadWeightData(from context: ModelContext) {
        let calendar = Calendar.current
        let today = Date()
        let startDate = calendar.date(byAdding: .day, value: -getDaysForRange(), to: today)!

        let descriptor = FetchDescriptor<WeightEntry>(
            predicate: #Predicate<WeightEntry> { $0.recordedAt >= startDate },
            sortBy: [SortDescriptor(\WeightEntry.recordedAt, order: .forward)]
        )

        if let entries = try? context.fetch(descriptor) {
            weightEntries = entries.map { entry in
                WeightDataPoint(date: entry.recordedAt, weight: entry.weightKg)
            }

            // Set current weight from most recent entry
            if let latest = entries.last {
                currentWeight = latest.weightKg
            }

            // Set starting weight from first entry in range
            if let first = entries.first, startingWeight == 0 {
                startingWeight = first.weightKg
            }
        }
    }

    // MARK: - Load Calorie Data

    private func loadCalorieData(from context: ModelContext) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let daysCount = getDaysForRange()

        var entries: [CalorieDataPoint] = []
        var totalCalories = 0
        var totalProtein: Double = 0
        var totalCarbs: Double = 0
        var totalFat: Double = 0
        var daysWithData = 0

        for dayOffset in 0..<daysCount {
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
            let totals = MealService.shared.getDailyTotals(for: date, in: context)

            entries.append(CalorieDataPoint(
                date: date,
                calories: totals.calories,
                goal: calorieGoal,
                protein: totals.protein,
                carbs: totals.carbs,
                fat: totals.fat
            ))

            if totals.calories > 0 {
                totalCalories += totals.calories
                totalProtein += totals.protein
                totalCarbs += totals.carbs
                totalFat += totals.fat
                daysWithData += 1
            }
        }

        calorieEntries = entries.reversed()
        if daysWithData > 0 {
            averageCalories = totalCalories / daysWithData
            averageProtein = totalProtein / Double(daysWithData)
            averageCarbs = totalCarbs / Double(daysWithData)
            averageFat = totalFat / Double(daysWithData)
        }

        totalDaysLogged = daysWithData
    }

    // MARK: - Calculate Streaks

    private func calculateStreaks(from context: ModelContext) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        var streak = 0
        var maxStreak = 0
        var currentStreakCount = 0
        var checkingCurrentStreak = true

        // Check last 365 days for streaks
        for dayOffset in 0..<365 {
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
            let totals = MealService.shared.getDailyTotals(for: date, in: context)

            if totals.calories > 0 {
                streak += 1
                if checkingCurrentStreak {
                    currentStreakCount += 1
                }
                maxStreak = max(maxStreak, streak)
            } else {
                if checkingCurrentStreak && dayOffset > 0 {
                    // Allow today to be empty (user might not have logged yet)
                    checkingCurrentStreak = false
                }
                streak = 0
            }
        }

        currentStreak = currentStreakCount
        longestStreak = maxStreak
    }

    // MARK: - Load Achievements

    private func loadAchievements(from context: ModelContext) {
        var descriptor = FetchDescriptor<Achievement>(
            predicate: #Predicate<Achievement> { $0.isUnlocked },
            sortBy: [SortDescriptor(\Achievement.unlockedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 3

        if let achievements = try? context.fetch(descriptor) {
            recentAchievements = achievements.map { achievement in
                ProgressAchievement(
                    id: achievement.id.uuidString,
                    title: achievement.title,
                    description: achievement.achievementDescription,
                    icon: achievement.icon,
                    color: tierColor(for: achievement.tier),
                    earnedDate: achievement.unlockedAt ?? Date()
                )
            }
        }
    }

    private func tierColor(for tier: AchievementTier) -> Color {
        switch tier {
        case .bronze: return FuelColors.bronze
        case .silver: return FuelColors.silver
        case .gold: return FuelColors.gold
        case .platinum: return FuelColors.platinum
        }
    }

    private func getDaysForRange() -> Int {
        switch selectedTimeRange {
        case .week:
            return 7
        case .month:
            return 30
        case .threeMonths:
            return 90
        case .year:
            return 365
        }
    }
}

// MARK: - Time Range

enum TimeRange: String, CaseIterable {
    case week = "Week"
    case month = "Month"
    case threeMonths = "3 Months"
    case year = "Year"

    /// Whether this time range requires premium access
    var requiresPremium: Bool {
        switch self {
        case .week:
            return false
        case .month, .threeMonths, .year:
            return true
        }
    }
}

// MARK: - Data Points

struct WeightDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let weight: Double

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    var shortDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
}

struct CalorieDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let calories: Int
    let goal: Int
    let protein: Double
    let carbs: Double
    let fat: Double

    init(date: Date, calories: Int, goal: Int, protein: Double = 0, carbs: Double = 0, fat: Double = 0) {
        self.date = date
        self.calories = calories
        self.goal = goal
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
    }

    var isUnderGoal: Bool {
        calories <= goal
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    // Calculate calories from each macro
    var proteinCalories: Double {
        protein * 4.0 // 4 cal per gram of protein
    }

    var carbsCalories: Double {
        carbs * 4.0 // 4 cal per gram of carbs
    }

    var fatCalories: Double {
        fat * 9.0 // 9 cal per gram of fat
    }

    // Calculate percentage of total calories from each macro
    var proteinPercent: Double {
        guard calories > 0 else { return 0 }
        return min(proteinCalories / Double(calories), 1.0)
    }

    var carbsPercent: Double {
        guard calories > 0 else { return 0 }
        return min(carbsCalories / Double(calories), 1.0)
    }

    var fatPercent: Double {
        guard calories > 0 else { return 0 }
        return min(fatCalories / Double(calories), 1.0)
    }
}

// MARK: - Progress Achievement

struct ProgressAchievement: Identifiable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let color: Color
    let earnedDate: Date

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: earnedDate)
    }
}
