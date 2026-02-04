import SwiftUI
import SwiftData

/// Recipe Models
/// Data structures for recipe management

// MARK: - Recipe

@Model
final class Recipe {
    var id: String
    var name: String
    var recipeDescription: String
    var ingredients: [RecipeIngredient]
    var servings: Int
    var prepTime: Int? // minutes
    var cookTime: Int? // minutes
    var instructions: [String]
    var imageData: Data?
    var category: RecipeCategory
    var isFavorite: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        id: String = UUID().uuidString,
        name: String,
        recipeDescription: String = "",
        ingredients: [RecipeIngredient] = [],
        servings: Int = 1,
        prepTime: Int? = nil,
        cookTime: Int? = nil,
        instructions: [String] = [],
        imageData: Data? = nil,
        category: RecipeCategory = .other,
        isFavorite: Bool = false
    ) {
        self.id = id
        self.name = name
        self.recipeDescription = recipeDescription
        self.ingredients = ingredients
        self.servings = servings
        self.prepTime = prepTime
        self.cookTime = cookTime
        self.instructions = instructions
        self.imageData = imageData
        self.category = category
        self.isFavorite = isFavorite
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: - Nutrition Calculations

    var totalCalories: Int {
        ingredients.reduce(0) { $0 + $1.calories }
    }

    var totalProtein: Double {
        ingredients.reduce(0) { $0 + $1.protein }
    }

    var totalCarbs: Double {
        ingredients.reduce(0) { $0 + $1.carbs }
    }

    var totalFat: Double {
        ingredients.reduce(0) { $0 + $1.fat }
    }

    var caloriesPerServing: Int {
        guard servings > 0 else { return 0 }
        return totalCalories / servings
    }

    var proteinPerServing: Double {
        guard servings > 0 else { return 0 }
        return totalProtein / Double(servings)
    }

    var carbsPerServing: Double {
        guard servings > 0 else { return 0 }
        return totalCarbs / Double(servings)
    }

    var fatPerServing: Double {
        guard servings > 0 else { return 0 }
        return totalFat / Double(servings)
    }

    var totalTime: Int? {
        guard prepTime != nil || cookTime != nil else { return nil }
        return (prepTime ?? 0) + (cookTime ?? 0)
    }

    var formattedTotalTime: String? {
        guard let total = totalTime else { return nil }
        if total < 60 {
            return "\(total) min"
        } else {
            let hours = total / 60
            let mins = total % 60
            if mins == 0 {
                return "\(hours) hr"
            }
            return "\(hours) hr \(mins) min"
        }
    }
}

// MARK: - Recipe Ingredient

struct RecipeIngredient: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let quantity: Double
    let unit: IngredientUnit
    let calories: Int
    let protein: Double
    let carbs: Double
    let fat: Double

    // Base values per 100g or per unit
    let baseCalories: Int
    let baseProtein: Double
    let baseCarbs: Double
    let baseFat: Double

    init(
        id: String = UUID().uuidString,
        name: String,
        quantity: Double,
        unit: IngredientUnit,
        baseCalories: Int,
        baseProtein: Double,
        baseCarbs: Double,
        baseFat: Double
    ) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.baseCalories = baseCalories
        self.baseProtein = baseProtein
        self.baseCarbs = baseCarbs
        self.baseFat = baseFat

        // Calculate actual nutrition based on quantity
        let multiplier = quantity / 100.0 // Assuming base values are per 100g
        self.calories = Int(Double(baseCalories) * multiplier)
        self.protein = baseProtein * multiplier
        self.carbs = baseCarbs * multiplier
        self.fat = baseFat * multiplier
    }

    func withUpdatedQuantity(_ newQuantity: Double) -> RecipeIngredient {
        RecipeIngredient(
            id: id,
            name: name,
            quantity: newQuantity,
            unit: unit,
            baseCalories: baseCalories,
            baseProtein: baseProtein,
            baseCarbs: baseCarbs,
            baseFat: baseFat
        )
    }
}

// MARK: - Ingredient Unit

enum IngredientUnit: String, Codable, CaseIterable {
    case gram = "g"
    case kilogram = "kg"
    case ounce = "oz"
    case pound = "lb"
    case cup = "cup"
    case tablespoon = "tbsp"
    case teaspoon = "tsp"
    case milliliter = "ml"
    case liter = "L"
    case piece = "piece"
    case slice = "slice"

    var displayName: String {
        switch self {
        case .gram: return "grams"
        case .kilogram: return "kilograms"
        case .ounce: return "ounces"
        case .pound: return "pounds"
        case .cup: return "cups"
        case .tablespoon: return "tablespoons"
        case .teaspoon: return "teaspoons"
        case .milliliter: return "milliliters"
        case .liter: return "liters"
        case .piece: return "pieces"
        case .slice: return "slices"
        }
    }
}

// MARK: - Recipe Category

enum RecipeCategory: String, Codable, CaseIterable {
    case breakfast
    case lunch
    case dinner
    case snack
    case dessert
    case beverage
    case salad
    case soup
    case smoothie
    case other

    var displayName: String {
        rawValue.capitalized
    }

    var icon: String {
        switch self {
        case .breakfast: return "sunrise.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "moon.stars.fill"
        case .snack: return "carrot.fill"
        case .dessert: return "birthday.cake.fill"
        case .beverage: return "cup.and.saucer.fill"
        case .salad: return "leaf.fill"
        case .soup: return "flame.fill"
        case .smoothie: return "drop.fill"
        case .other: return "fork.knife"
        }
    }

    var color: Color {
        switch self {
        case .breakfast: return .orange
        case .lunch: return .yellow
        case .dinner: return .purple
        case .snack: return FuelColors.primary
        case .dessert: return .pink
        case .beverage: return .brown
        case .salad: return FuelColors.success
        case .soup: return .red
        case .smoothie: return .cyan
        case .other: return FuelColors.textSecondary
        }
    }
}
