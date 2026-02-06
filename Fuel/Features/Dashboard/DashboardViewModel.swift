import SwiftUI
import SwiftData

/// Dashboard View Model
/// Manages dashboard state and data with SwiftData persistence

@Observable
final class DashboardViewModel {
    // MARK: - State

    var selectedDate: Date = Date()
    var isLoading = false

    // MARK: - User Goals

    var calorieGoal: Int = 2000
    var proteinGoal: Double = 150
    var carbsGoal: Double = 200
    var fatGoal: Double = 65

    // MARK: - Daily Data

    private(set) var meals: [MealType: Meal] = [:]
    private(set) var dailyTotals: DailyNutritionTotals = .zero

    var currentStreak: Int = 0
    var longestStreak: Int = 0

    // MARK: - Model Context

    private var modelContext: ModelContext?

    // MARK: - Computed Properties

    var totalCalories: Int { dailyTotals.calories }
    var totalProtein: Double { dailyTotals.protein }
    var totalCarbs: Double { dailyTotals.carbs }
    var totalFat: Double { dailyTotals.fat }

    // Micronutrients
    var totalFiber: Double { dailyTotals.fiber }
    var totalSugar: Double { dailyTotals.sugar }
    var totalSodium: Double { dailyTotals.sodium }
    var totalSaturatedFat: Double { dailyTotals.saturatedFat }
    var totalCholesterol: Double { dailyTotals.cholesterol }

    var remainingCalories: Int {
        max(0, calorieGoal - totalCalories)
    }

    var calorieProgress: Double {
        guard calorieGoal > 0 else { return 0 }
        return min(Double(totalCalories) / Double(calorieGoal), 1.5)
    }

    var proteinProgress: Double {
        guard proteinGoal > 0 else { return 0 }
        return min(totalProtein / proteinGoal, 1.0)
    }

    var carbsProgress: Double {
        guard carbsGoal > 0 else { return 0 }
        return min(totalCarbs / carbsGoal, 1.0)
    }

    var fatProgress: Double {
        guard fatGoal > 0 else { return 0 }
        return min(totalFat / fatGoal, 1.0)
    }

    var isOverGoal: Bool {
        totalCalories > calorieGoal
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }

    var formattedDate: String {
        if isToday {
            return "Today"
        } else if Calendar.current.isDateInYesterday(selectedDate) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMM d"
            return formatter.string(from: selectedDate)
        }
    }

    // MARK: - Initialization

    init() {}

    // MARK: - Setup

    func setup(with context: ModelContext) {
        self.modelContext = context
        loadUserGoals()
        loadData(for: selectedDate)
        calculateStreaks()
    }

    // MARK: - Data Loading

    func loadData(for date: Date) {
        guard let context = modelContext else { return }

        isLoading = true
        selectedDate = date

        // Load meals grouped by type
        meals = MealService.shared.getMealsGroupedByType(for: date, in: context)

        // Calculate totals
        let totals = MealService.shared.getDailyTotals(for: date, in: context)

        dailyTotals = totals

        isLoading = false
    }

    private func loadUserGoals() {
        guard let context = modelContext else { return }

        let descriptor = FetchDescriptor<User>()
        if let user = try? context.fetch(descriptor).first {
            calorieGoal = user.dailyCalorieTarget
            proteinGoal = Double(user.dailyProteinTarget)
            carbsGoal = Double(user.dailyCarbsTarget)
            fatGoal = Double(user.dailyFatTarget)
        }
    }

    private func calculateStreaks() {
        guard let context = modelContext else { return }

        // Run streak calculation in background to avoid blocking UI
        Task.detached(priority: .userInitiated) { [weak self] in
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())

            guard let startDate = calendar.date(byAdding: .day, value: -365, to: today) else {
                return
            }

            // Fetch all meals in date range with single query (more efficient)
            let predicate = #Predicate<Meal> { meal in
                meal.loggedAt >= startDate && meal.loggedAt <= today && !meal.isDeleted
            }
            let descriptor = FetchDescriptor<Meal>(predicate: predicate)

            var daysWithMeals: Set<Date> = []

            do {
                let meals = try context.fetch(descriptor)
                // Group meals by day
                for meal in meals where meal.totalCalories > 0 {
                    let dayStart = calendar.startOfDay(for: meal.loggedAt)
                    daysWithMeals.insert(dayStart)
                }
            } catch {
                // Silently fail - streaks are not critical
                return
            }

            // Calculate streaks from the set of days
            var streak = 0
            var maxStreak = 0
            var currentStreakCount = 0
            var checkingCurrentStreak = true

            for dayOffset in 0..<365 {
                guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else {
                    continue
                }
                let dayStart = calendar.startOfDay(for: date)

                if daysWithMeals.contains(dayStart) {
                    streak += 1
                    if checkingCurrentStreak {
                        currentStreakCount += 1
                    }
                    maxStreak = max(maxStreak, streak)
                } else {
                    if checkingCurrentStreak && dayOffset > 0 {
                        checkingCurrentStreak = false
                    }
                    streak = 0
                }
            }

            // Capture final values for thread-safe passing to main actor
            let finalCurrentStreak = currentStreakCount
            let finalLongestStreak = maxStreak

            // Update UI on main thread
            await MainActor.run { [weak self] in
                self?.currentStreak = finalCurrentStreak
                self?.longestStreak = finalLongestStreak
            }
        }
    }

    func refresh() {
        loadData(for: selectedDate)
    }

    // MARK: - Food Item Actions

    /// Add a food item to a meal
    func addFoodItem(_ foodItem: FoodItem, to mealType: MealType) {
        guard let context = modelContext else { return }

        MealService.shared.addFoodItem(foodItem, to: mealType, date: selectedDate, in: context)

        // Reload data
        loadData(for: selectedDate)
    }

    /// Delete a food item from a meal
    func deleteFoodItem(_ foodItem: FoodItem) {
        guard let context = modelContext else { return }

        MealService.shared.removeFoodItem(foodItem, in: context)
        FuelHaptics.shared.tap()

        // Reload data
        loadData(for: selectedDate)
    }

    // MARK: - Paywall State

    var showHistoryPaywall = false

    // MARK: - Navigation

    func goToPreviousDay() {
        if let newDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) {
            // Check if date is within free limit
            if !FeatureGateService.shared.canAccessDate(newDate) {
                // Notify view to show paywall
                showHistoryPaywall = true
                FuelHaptics.shared.error()
                return
            }
            loadData(for: newDate)
            FuelHaptics.shared.tap()
        }
    }

    func goToNextDay() {
        if let newDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) {
            // Don't go past today
            if newDate <= Date() {
                loadData(for: newDate)
                FuelHaptics.shared.tap()
            }
        }
    }

    func goToToday() {
        loadData(for: Date())
        FuelHaptics.shared.tap()
    }

    // MARK: - Meal Helpers

    func getMeal(for type: MealType) -> Meal? {
        meals[type]
    }

    func getFoodItems(for mealType: MealType) -> [FoodItem] {
        meals[mealType]?.foodItems ?? []
    }

    func getMealCalories(for mealType: MealType) -> Int {
        meals[mealType]?.totalCalories ?? 0
    }

    // MARK: - Today's Meals (New Visual Design)

    /// Get all meals for selected date as a flat array sorted by time
    var todaysMeals: [Meal] {
        guard let context = modelContext else { return [] }
        return MealService.shared.getMeals(for: selectedDate, in: context)
            .filter { $0.totalCalories > 0 || ($0.foodItems?.isEmpty == false) }
    }

    /// Delete an entire meal
    func deleteMeal(_ meal: Meal) {
        guard let context = modelContext else { return }

        MealService.shared.deleteMeal(meal, in: context)
        FuelHaptics.shared.tap()

        // Reload data
        loadData(for: selectedDate)
    }
}
