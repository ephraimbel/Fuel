import SwiftUI
import SwiftData

/// Dashboard View Model
/// Manages dashboard state and data

@Observable
final class DashboardViewModel {
    // MARK: - State

    var selectedDate: Date = Date()
    var isLoading = false
    var showingDatePicker = false

    // MARK: - User Data

    var calorieGoal: Int = 2000
    var proteinGoal: Double = 150
    var carbsGoal: Double = 200
    var fatGoal: Double = 65

    // MARK: - Daily Data

    var meals: [MealType: [DashboardFoodItem]] = [
        .breakfast: [],
        .lunch: [],
        .dinner: [],
        .snack: []
    ]

    var currentStreak: Int = 7
    var longestStreak: Int = 14

    // MARK: - Computed Properties

    var totalCalories: Int {
        allFoodItems.reduce(0) { $0 + $1.calories }
    }

    var totalProtein: Double {
        allFoodItems.reduce(0) { $0 + $1.protein }
    }

    var totalCarbs: Double {
        allFoodItems.reduce(0) { $0 + $1.carbs }
    }

    var totalFat: Double {
        allFoodItems.reduce(0) { $0 + $1.fat }
    }

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

    var allFoodItems: [DashboardFoodItem] {
        meals.values.flatMap { $0 }
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

    init() {
        loadSampleData()
    }

    // MARK: - Data Loading

    func loadData(for date: Date) {
        isLoading = true
        selectedDate = date

        // TODO: Load actual data from SwiftData
        // For now, use sample data
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.loadSampleData()
            self?.isLoading = false
        }
    }

    func refresh() {
        loadData(for: selectedDate)
    }

    private func loadSampleData() {
        // Sample breakfast
        meals[.breakfast] = [
            DashboardFoodItem(
                id: UUID().uuidString,
                name: "Greek Yogurt with Berries",
                calories: 180,
                protein: 15,
                carbs: 20,
                fat: 4,
                servingSize: "1 cup"
            ),
            DashboardFoodItem(
                id: UUID().uuidString,
                name: "Scrambled Eggs",
                calories: 220,
                protein: 14,
                carbs: 2,
                fat: 17,
                servingSize: "2 eggs"
            )
        ]

        // Sample lunch
        meals[.lunch] = [
            DashboardFoodItem(
                id: UUID().uuidString,
                name: "Grilled Chicken Salad",
                calories: 420,
                protein: 38,
                carbs: 15,
                fat: 22,
                servingSize: "1 bowl"
            )
        ]

        // Sample dinner (empty for demo)
        meals[.dinner] = []

        // Sample snacks
        meals[.snack] = [
            DashboardFoodItem(
                id: UUID().uuidString,
                name: "Almonds",
                calories: 160,
                protein: 6,
                carbs: 6,
                fat: 14,
                servingSize: "1 oz"
            )
        ]
    }

    // MARK: - Actions

    func goToPreviousDay() {
        if let newDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) {
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

    func deleteFoodItem(_ item: DashboardFoodItem, from mealType: MealType) {
        meals[mealType]?.removeAll { $0.id == item.id }
        FuelHaptics.shared.tap()
    }

    func getMealCalories(for mealType: MealType) -> Int {
        meals[mealType]?.reduce(0) { $0 + $1.calories } ?? 0
    }
}

// MARK: - Dashboard Food Item

struct DashboardFoodItem: Identifiable, Equatable {
    let id: String
    let name: String
    let calories: Int
    let protein: Double
    let carbs: Double
    let fat: Double
    let servingSize: String

    static func == (lhs: DashboardFoodItem, rhs: DashboardFoodItem) -> Bool {
        lhs.id == rhs.id
    }
}
