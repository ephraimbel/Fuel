import SwiftUI
import SwiftData

/// Progress View Model
/// Manages progress data and analytics

@Observable
final class ProgressViewModel {
    // MARK: - State

    var selectedTimeRange: TimeRange = .week
    var isLoading = false

    // MARK: - Weight Data

    var weightEntries: [WeightDataPoint] = []
    var currentWeight: Double = 165.0
    var startingWeight: Double = 175.0
    var goalWeight: Double = 155.0

    var weightChange: Double {
        currentWeight - startingWeight
    }

    var weightToGoal: Double {
        currentWeight - goalWeight
    }

    var weightProgressPercent: Double {
        let totalToLose = startingWeight - goalWeight
        guard totalToLose > 0 else { return 0 }
        let lost = startingWeight - currentWeight
        return min(max(lost / totalToLose, 0), 1.0)
    }

    // MARK: - Calorie Data

    var calorieEntries: [CalorieDataPoint] = []
    var averageCalories: Int = 0
    var calorieGoal: Int = 2000

    var daysUnderGoal: Int {
        calorieEntries.filter { $0.calories <= calorieGoal }.count
    }

    var daysOverGoal: Int {
        calorieEntries.filter { $0.calories > calorieGoal }.count
    }

    // MARK: - Macro Data

    var averageProtein: Double = 0
    var averageCarbs: Double = 0
    var averageFat: Double = 0
    var proteinGoal: Double = 150
    var carbsGoal: Double = 200
    var fatGoal: Double = 65

    // MARK: - Streak Data

    var currentStreak: Int = 7
    var longestStreak: Int = 14
    var totalDaysLogged: Int = 45

    // MARK: - Achievements

    var recentAchievements: [ProgressAchievement] = []

    // MARK: - Initialization

    init() {
        loadData()
    }

    // MARK: - Data Loading

    func loadData() {
        isLoading = true

        // Simulate loading delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.loadSampleData()
            self?.calculateAverages()
            self?.isLoading = false
        }
    }

    func selectTimeRange(_ range: TimeRange) {
        guard range != selectedTimeRange else { return }
        selectedTimeRange = range
        FuelHaptics.shared.tap()
        loadData()
    }

    private func loadSampleData() {
        let calendar = Calendar.current
        let today = Date()

        // Generate weight data
        weightEntries = (0..<getDaysForRange()).map { daysAgo in
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            let weight = 165.0 + Double.random(in: -2...2) + (Double(daysAgo) * 0.1)
            return WeightDataPoint(date: date, weight: weight)
        }.reversed()

        // Generate calorie data
        calorieEntries = (0..<getDaysForRange()).map { daysAgo in
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            let calories = Int.random(in: 1600...2400)
            return CalorieDataPoint(date: date, calories: calories, goal: calorieGoal)
        }.reversed()

        // Sample achievements
        recentAchievements = [
            ProgressAchievement(
                id: "1",
                title: "7 Day Streak",
                description: "Logged meals for 7 days in a row",
                icon: "flame.fill",
                color: .orange,
                earnedDate: calendar.date(byAdding: .day, value: -1, to: today)!
            ),
            ProgressAchievement(
                id: "2",
                title: "First 5 lbs",
                description: "Lost your first 5 pounds",
                icon: "scalemass.fill",
                color: FuelColors.primary,
                earnedDate: calendar.date(byAdding: .day, value: -3, to: today)!
            ),
            ProgressAchievement(
                id: "3",
                title: "Protein Pro",
                description: "Hit protein goal 5 days in a row",
                icon: "bolt.fill",
                color: FuelColors.protein,
                earnedDate: calendar.date(byAdding: .day, value: -5, to: today)!
            )
        ]
    }

    private func calculateAverages() {
        guard !calorieEntries.isEmpty else { return }

        averageCalories = calorieEntries.reduce(0) { $0 + $1.calories } / calorieEntries.count

        // Sample macro averages
        averageProtein = 120
        averageCarbs = 180
        averageFat = 55
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
