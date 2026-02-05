import SwiftUI
import SwiftData
import OSLog

/// Meal History View Model
/// Handles fetching, pagination, and filtering of meal history

private let logger = Logger(subsystem: "com.fuel.app", category: "MealHistory")

@Observable
final class MealHistoryViewModel {
    // MARK: - State

    var isLoading = false
    var hasMoreData = true
    private(set) var mealsByDate: [Date: [Meal]] = [:]
    private(set) var sortedDates: [Date] = []

    // MARK: - Filters

    var selectedMealType: MealType?
    var startDate: Date?
    var endDate: Date?

    // MARK: - Pagination

    private var currentPage = 0
    private let pageSize = 30
    private var lastFetchedDate: Date?

    // MARK: - Model Context

    private var modelContext: ModelContext?

    // MARK: - Initialization

    init() {}

    // MARK: - Setup

    func setup(with context: ModelContext) {
        self.modelContext = context
        loadInitialData()
    }

    // MARK: - Data Loading

    func loadInitialData() {
        guard let context = modelContext else { return }

        isLoading = true
        mealsByDate = [:]
        sortedDates = []
        currentPage = 0
        hasMoreData = true

        // Fetch meals for the last 30 days initially
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        guard let startOfRange = calendar.date(byAdding: .day, value: -pageSize, to: today) else {
            logger.error("Failed to calculate start date for initial load")
            isLoading = false
            return
        }

        fetchMeals(from: startOfRange, to: today, in: context)

        lastFetchedDate = startOfRange
        isLoading = false
    }

    func loadMoreData() {
        guard let context = modelContext,
              hasMoreData,
              !isLoading,
              let lastDate = lastFetchedDate else { return }

        isLoading = true

        let calendar = Calendar.current

        guard let newEndDate = calendar.date(byAdding: .day, value: -1, to: lastDate),
              let newStartDate = calendar.date(byAdding: .day, value: -pageSize, to: newEndDate) else {
            logger.error("Failed to calculate date range for pagination")
            isLoading = false
            return
        }

        fetchMeals(from: newStartDate, to: newEndDate, in: context)

        lastFetchedDate = newStartDate
        currentPage += 1
        isLoading = false
    }

    private func fetchMeals(from startDate: Date, to endDate: Date, in context: ModelContext) {
        let predicate = #Predicate<Meal> { meal in
            meal.loggedAt >= startDate && meal.loggedAt <= endDate && !meal.isDeleted
        }

        let descriptor = FetchDescriptor<Meal>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.loggedAt, order: .reverse)]
        )

        do {
            var fetchedMeals = try context.fetch(descriptor)

            // Apply meal type filter if set
            if let mealTypeFilter = selectedMealType {
                fetchedMeals = fetchedMeals.filter { $0.mealType == mealTypeFilter }
            }

            // Filter to only meals with content
            fetchedMeals = fetchedMeals.filter { $0.totalCalories > 0 || ($0.foodItems?.isEmpty == false) }

            // Group by date
            let calendar = Calendar.current
            for meal in fetchedMeals {
                let dayStart = calendar.startOfDay(for: meal.loggedAt)

                if mealsByDate[dayStart] != nil {
                    mealsByDate[dayStart]?.append(meal)
                } else {
                    mealsByDate[dayStart] = [meal]
                }
            }

            // Update sorted dates
            sortedDates = mealsByDate.keys.sorted(by: >)

            // Check if we have more data
            if fetchedMeals.isEmpty {
                hasMoreData = false
            }

        } catch {
            logger.error("Failed to fetch meal history: \(error.localizedDescription)")
        }
    }

    // MARK: - Refresh

    func refresh() {
        loadInitialData()
    }

    // MARK: - Helpers

    func meals(for date: Date) -> [Meal] {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        return mealsByDate[dayStart] ?? []
    }

    func formattedDate(_ date: Date) -> String {
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            if calendar.isDate(date, equalTo: Date(), toGranularity: .year) {
                formatter.dateFormat = "EEEE, MMMM d"
            } else {
                formatter.dateFormat = "EEEE, MMMM d, yyyy"
            }
            return formatter.string(from: date)
        }
    }

    func totalCalories(for date: Date) -> Int {
        meals(for: date).reduce(0) { $0 + $1.totalCalories }
    }

    // MARK: - Delete

    func deleteMeal(_ meal: Meal) {
        guard let context = modelContext else { return }

        MealService.shared.deleteMeal(meal, in: context)
        FuelHaptics.shared.tap()

        // Remove from local state
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: meal.loggedAt)

        if var mealsForDay = mealsByDate[dayStart] {
            mealsForDay.removeAll { $0.id == meal.id }
            if mealsForDay.isEmpty {
                mealsByDate.removeValue(forKey: dayStart)
                sortedDates.removeAll { $0 == dayStart }
            } else {
                mealsByDate[dayStart] = mealsForDay
            }
        }
    }
}
