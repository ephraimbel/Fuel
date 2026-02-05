import Foundation
import SwiftData

/// Meal entry model
/// Represents a single meal entry with food items and metadata

@Model
public final class Meal {
    // MARK: - Identifiers

    @Attribute(.unique) public var id: UUID
    public var cloudKitRecordID: String?

    // MARK: - Basic Info

    public var mealType: MealType
    public var loggedAt: Date
    public var notes: String?

    // MARK: - Photo Data

    public var photoURL: String?
    public var photoLocalPath: String?
    public var photoThumbnailData: Data?

    // MARK: - AI Analysis

    public var isAIAnalyzed: Bool
    public var aiConfidenceScore: Double?
    public var aiRawResponse: String?

    // MARK: - Totals (Denormalized for performance)

    public var totalCalories: Int
    public var totalProtein: Double
    public var totalCarbs: Double
    public var totalFat: Double
    public var totalFiber: Double?
    public var totalSugar: Double?
    public var totalSodium: Double?

    // MARK: - Relationships

    public var user: User?

    @Relationship(deleteRule: .cascade, inverse: \FoodItem.meal)
    public var foodItems: [FoodItem]?

    // MARK: - Metadata

    public var createdAt: Date
    public var updatedAt: Date
    public var isFavorite: Bool
    public var isDeleted: Bool

    // MARK: - Initialization

    public init(
        id: UUID = UUID(),
        mealType: MealType,
        loggedAt: Date = Date()
    ) {
        self.id = id
        self.mealType = mealType
        self.loggedAt = loggedAt

        self.isAIAnalyzed = false
        self.totalCalories = 0
        self.totalProtein = 0
        self.totalCarbs = 0
        self.totalFat = 0

        self.createdAt = Date()
        self.updatedAt = Date()
        self.isFavorite = false
        self.isDeleted = false
    }

    // MARK: - Computed Properties

    public var displayTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: loggedAt)
    }

    public var displayDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: loggedAt)
    }

    public var foodItemCount: Int {
        foodItems?.count ?? 0
    }

    public var foodItemNames: [String] {
        foodItems?.map { $0.name } ?? []
    }

    public var hasPhoto: Bool {
        photoURL != nil || photoLocalPath != nil
    }

    // MARK: - Methods

    /// Recalculate totals from food items
    public func recalculateTotals() {
        guard let items = foodItems else {
            totalCalories = 0
            totalProtein = 0
            totalCarbs = 0
            totalFat = 0
            return
        }

        totalCalories = items.reduce(0) { $0 + $1.calories }
        totalProtein = items.reduce(0) { $0 + $1.protein }
        totalCarbs = items.reduce(0) { $0 + $1.carbs }
        totalFat = items.reduce(0) { $0 + $1.fat }
        totalFiber = items.reduce(0) { $0 + ($1.fiber ?? 0) }
        totalSugar = items.reduce(0) { $0 + ($1.sugar ?? 0) }
        totalSodium = items.reduce(0) { $0 + ($1.sodium ?? 0) }

        updatedAt = Date()
    }

    /// Add a food item to this meal
    public func addFoodItem(_ item: FoodItem) {
        if foodItems == nil {
            foodItems = []
        }
        item.meal = self
        foodItems?.append(item)
        recalculateTotals()
    }

    /// Remove a food item from this meal
    public func removeFoodItem(_ item: FoodItem) {
        foodItems?.removeAll { $0.id == item.id }
        recalculateTotals()
    }

    /// Mark meal as deleted (soft delete)
    public func markDeleted() {
        isDeleted = true
        updatedAt = Date()
    }
}

// MARK: - Meal Type

public enum MealType: String, Codable, CaseIterable {
    case breakfast = "breakfast"
    case lunch = "lunch"
    case dinner = "dinner"
    case snack = "snack"

    public var displayName: String {
        switch self {
        case .breakfast: return "Breakfast"
        case .lunch: return "Lunch"
        case .dinner: return "Dinner"
        case .snack: return "Snack"
        }
    }

    public var icon: String {
        switch self {
        case .breakfast: return "sunrise.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "moon.stars.fill"
        case .snack: return "popcorn.fill"
        }
    }

    public var suggestedTimeRange: ClosedRange<Int> {
        switch self {
        case .breakfast: return 6...10
        case .lunch: return 11...14
        case .dinner: return 17...21
        case .snack: return 0...23
        }
    }

    /// Get suggested meal type based on current time
    public static func suggested(for date: Date = Date()) -> MealType {
        let hour = Calendar.current.component(.hour, from: date)

        switch hour {
        case 6...10:
            return .breakfast
        case 11...14:
            return .lunch
        case 17...21:
            return .dinner
        default:
            return .snack
        }
    }
}

// MARK: - Meal Summary

/// Lightweight meal summary for lists and previews
public struct MealSummary: Identifiable, Hashable {
    public let id: UUID
    public let mealType: MealType
    public let loggedAt: Date
    public let calories: Int
    public let foodNames: [String]
    public let thumbnailData: Data?
    public let isFavorite: Bool

    public init(from meal: Meal) {
        self.id = meal.id
        self.mealType = meal.mealType
        self.loggedAt = meal.loggedAt
        self.calories = meal.totalCalories
        self.foodNames = meal.foodItemNames
        self.thumbnailData = meal.photoThumbnailData
        self.isFavorite = meal.isFavorite
    }
}
