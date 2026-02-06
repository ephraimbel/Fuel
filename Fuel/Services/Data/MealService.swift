import Foundation
import SwiftData
import OSLog

/// Meal Service
/// Handles all meal-related data operations with SwiftData

private let logger = Logger(subsystem: "com.fuel.app", category: "MealService")

@Observable
final class MealService {
    // MARK: - Singleton

    static let shared = MealService()

    // MARK: - State

    private(set) var isLoading = false

    // MARK: - Initialization

    private init() {}

    // MARK: - Fetch Operations

    /// Get all meals for a specific date
    func getMeals(for date: Date, in context: ModelContext) -> [Meal] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)

        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            logger.error("Failed to calculate end of day for date: \(date)")
            return []
        }

        let predicate = #Predicate<Meal> { meal in
            meal.loggedAt >= startOfDay && meal.loggedAt < endOfDay && !meal.isDeleted
        }

        let descriptor = FetchDescriptor<Meal>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.loggedAt)]
        )

        do {
            return try context.fetch(descriptor)
        } catch {
            logger.error("Failed to fetch meals: \(error.localizedDescription)")
            return []
        }
    }

    /// Get or create meal for a specific meal type and date
    func getOrCreateMeal(type: MealType, date: Date, in context: ModelContext) -> Meal {
        // Use the day-level fetch and filter by type in memory to avoid SwiftData predicate issues with enums
        let meals = getMeals(for: date, in: context)
        if let existingMeal = meals.first(where: { $0.mealType == type }) {
            return existingMeal
        }

        // Create new meal
        let newMeal = Meal(mealType: type, loggedAt: date)
        context.insert(newMeal)

        return newMeal
    }

    // MARK: - Create Operations

    /// Add a food item to a meal
    func addFoodItem(_ foodItem: FoodItem, to mealType: MealType, date: Date, in context: ModelContext) {
        let meal = getOrCreateMeal(type: mealType, date: date, in: context)

        // Insert the food item
        context.insert(foodItem)

        // Add to meal
        meal.addFoodItem(foodItem)

        // Save
        save(context)
    }

    /// Create a new meal with food items
    func createMeal(type: MealType, date: Date, foodItems: [FoodItem], in context: ModelContext) -> Meal {
        let meal = Meal(mealType: type, loggedAt: date)
        context.insert(meal)

        for item in foodItems {
            context.insert(item)
            meal.addFoodItem(item)
        }

        save(context)

        return meal
    }

    // MARK: - Update Operations

    /// Update food item servings
    func updateFoodItemServings(_ foodItem: FoodItem, servings: Double, in context: ModelContext) {
        foodItem.updateServings(servings)
        foodItem.meal?.recalculateTotals()
        save(context)
    }

    // MARK: - Delete Operations

    /// Remove a food item from its meal
    func removeFoodItem(_ foodItem: FoodItem, in context: ModelContext) {
        if let meal = foodItem.meal {
            meal.removeFoodItem(foodItem)
        }
        context.delete(foodItem)
        save(context)
    }

    /// Delete a meal (soft delete)
    func deleteMeal(_ meal: Meal, in context: ModelContext) {
        meal.markDeleted()
        save(context)
    }

    /// Permanently delete a meal
    func permanentlyDeleteMeal(_ meal: Meal, in context: ModelContext) {
        // Delete all food items first
        if let items = meal.foodItems {
            for item in items {
                context.delete(item)
            }
        }
        context.delete(meal)
        save(context)
    }

    // MARK: - Aggregation

    /// Get daily nutrition totals for a date
    func getDailyTotals(for date: Date, in context: ModelContext) -> DailyNutritionTotals {
        let meals = getMeals(for: date, in: context)

        var totalCalories = 0
        var totalProtein: Double = 0
        var totalCarbs: Double = 0
        var totalFat: Double = 0
        var totalFiber: Double = 0
        var totalSugar: Double = 0
        var totalSodium: Double = 0
        var totalSaturatedFat: Double = 0
        var totalCholesterol: Double = 0

        for meal in meals {
            totalCalories += meal.totalCalories
            totalProtein += meal.totalProtein
            totalCarbs += meal.totalCarbs
            totalFat += meal.totalFat

            // Aggregate micronutrients from food items
            if let items = meal.foodItems {
                for item in items {
                    totalFiber += item.fiber ?? 0
                    totalSugar += item.sugar ?? 0
                    totalSodium += item.sodium ?? 0
                    totalSaturatedFat += (item.saturatedFatPerServing ?? 0) * item.numberOfServings
                    totalCholesterol += (item.cholesterolPerServing ?? 0) * item.numberOfServings
                }
            }
        }

        return DailyNutritionTotals(
            calories: totalCalories,
            protein: totalProtein,
            carbs: totalCarbs,
            fat: totalFat,
            fiber: totalFiber,
            sugar: totalSugar,
            sodium: totalSodium,
            saturatedFat: totalSaturatedFat,
            cholesterol: totalCholesterol
        )
    }

    /// Get meals grouped by type for a date
    func getMealsGroupedByType(for date: Date, in context: ModelContext) -> [MealType: Meal] {
        let meals = getMeals(for: date, in: context)
        var grouped: [MealType: Meal] = [:]

        for meal in meals {
            grouped[meal.mealType] = meal
        }

        return grouped
    }

    // MARK: - Previous Meals

    /// Get recent meals with food items from the last N days
    func getRecentMeals(days: Int = 7, limit: Int = 20, in context: ModelContext) -> [Meal] {
        let calendar = Calendar.current
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: calendar.startOfDay(for: Date())) else {
            logger.error("Failed to calculate start date for recent meals")
            return []
        }

        let predicate = #Predicate<Meal> { meal in
            meal.loggedAt >= startDate && !meal.isDeleted && meal.totalCalories > 0
        }

        var descriptor = FetchDescriptor<Meal>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.loggedAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit

        do {
            let meals = try context.fetch(descriptor)
            return meals.filter { ($0.foodItems?.isEmpty == false) }
        } catch {
            logger.error("Failed to fetch recent meals: \(error.localizedDescription)")
            return []
        }
    }

    /// Get frequently eaten meals (meals with the same food combination logged 2+ times)
    func getFrequentMeals(days: Int = 30, limit: Int = 10, in context: ModelContext) -> [Meal] {
        let calendar = Calendar.current
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: calendar.startOfDay(for: Date())) else {
            logger.error("Failed to calculate start date for frequent meals")
            return []
        }

        let predicate = #Predicate<Meal> { meal in
            meal.loggedAt >= startDate && !meal.isDeleted && meal.totalCalories > 0
        }

        let descriptor = FetchDescriptor<Meal>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.loggedAt, order: .reverse)]
        )

        do {
            let allMeals = try context.fetch(descriptor)
                .filter { ($0.foodItems?.isEmpty == false) }

            // Group by fingerprint (sorted lowercase food names joined by |)
            var groups: [String: [Meal]] = [:]
            for meal in allMeals {
                let fingerprint = (meal.foodItems ?? [])
                    .map { $0.name.lowercased() }
                    .sorted()
                    .joined(separator: "|")
                groups[fingerprint, default: []].append(meal)
            }

            // Return one representative meal per group where count >= 2, sorted by frequency
            return groups
                .filter { $0.value.count >= 2 }
                .sorted { $0.value.count > $1.value.count }
                .prefix(limit)
                .compactMap { $0.value.first }
        } catch {
            logger.error("Failed to fetch frequent meals: \(error.localizedDescription)")
            return []
        }
    }

    /// Log a meal again by duplicating its food items to a target meal type and date
    func logMealAgain(_ sourceMeal: Meal, to mealType: MealType, date: Date = Date(), in context: ModelContext) {
        guard let foodItems = sourceMeal.foodItems, !foodItems.isEmpty else { return }

        for item in foodItems {
            let newItem = item.duplicate()
            addFoodItem(newItem, to: mealType, date: date, in: context)
        }

        // Copy photo to the target meal so it shows in the dashboard
        let targetMeal = getOrCreateMeal(type: mealType, date: date, in: context)
        if targetMeal.photoURL == nil {
            targetMeal.photoURL = sourceMeal.photoURL
            targetMeal.photoLocalPath = sourceMeal.photoLocalPath
            targetMeal.photoThumbnailData = sourceMeal.photoThumbnailData
        }

        save(context)
        logger.info("Logged meal again: \(foodItems.count) items to \(mealType.rawValue)")
    }

    // MARK: - Helper

    private func save(_ context: ModelContext) {
        do {
            try context.save()
        } catch {
            logger.error("Failed to save context: \(error.localizedDescription)")
        }
    }
}

// MARK: - Daily Nutrition Totals

struct DailyNutritionTotals {
    let calories: Int
    let protein: Double
    let carbs: Double
    let fat: Double

    // Micronutrients
    let fiber: Double
    let sugar: Double
    let sodium: Double
    let saturatedFat: Double
    let cholesterol: Double

    static let zero = DailyNutritionTotals(
        calories: 0,
        protein: 0,
        carbs: 0,
        fat: 0,
        fiber: 0,
        sugar: 0,
        sodium: 0,
        saturatedFat: 0,
        cholesterol: 0
    )
}
