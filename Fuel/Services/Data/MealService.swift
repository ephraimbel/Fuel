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
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)

        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            logger.error("Failed to calculate end of day, creating new meal")
            let newMeal = Meal(mealType: type, loggedAt: date)
            context.insert(newMeal)
            return newMeal
        }

        let mealTypeRaw = type.rawValue

        let predicate = #Predicate<Meal> { meal in
            meal.loggedAt >= startOfDay &&
            meal.loggedAt < endOfDay &&
            meal.mealType.rawValue == mealTypeRaw &&
            !meal.isDeleted
        }

        let descriptor = FetchDescriptor<Meal>(predicate: predicate)

        do {
            let existingMeals = try context.fetch(descriptor)
            if let existingMeal = existingMeals.first {
                return existingMeal
            }
        } catch {
            logger.error("Failed to fetch existing meal: \(error.localizedDescription)")
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

        for meal in meals {
            totalCalories += meal.totalCalories
            totalProtein += meal.totalProtein
            totalCarbs += meal.totalCarbs
            totalFat += meal.totalFat
        }

        return DailyNutritionTotals(
            calories: totalCalories,
            protein: totalProtein,
            carbs: totalCarbs,
            fat: totalFat
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

    static let zero = DailyNutritionTotals(calories: 0, protein: 0, carbs: 0, fat: 0)
}
