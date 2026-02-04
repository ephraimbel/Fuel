import Foundation
import SwiftData

/// Food item model
/// Represents a single food within a meal

@Model
public final class FoodItem {
    // MARK: - Identifiers

    @Attribute(.unique) public var id: UUID
    public var externalID: String? // Barcode, database ID, etc.

    // MARK: - Basic Info

    public var name: String
    public var brandName: String?
    public var itemDescription: String?

    // MARK: - Serving Info

    public var servingSize: Double
    public var servingUnit: String
    public var numberOfServings: Double

    // MARK: - Nutrition (per serving)

    public var caloriesPerServing: Int
    public var proteinPerServing: Double
    public var carbsPerServing: Double
    public var fatPerServing: Double
    public var fiberPerServing: Double?
    public var sugarPerServing: Double?
    public var sodiumPerServing: Double?
    public var saturatedFatPerServing: Double?
    public var cholesterolPerServing: Double?

    // MARK: - Source

    public var source: FoodSource
    public var barcode: String?
    public var isVerified: Bool
    public var isCustom: Bool

    // MARK: - Relationships

    public var meal: Meal?

    // MARK: - Metadata

    public var createdAt: Date
    public var updatedAt: Date

    // MARK: - Initialization

    public init(
        id: UUID = UUID(),
        name: String,
        servingSize: Double = 100,
        servingUnit: String = "g",
        numberOfServings: Double = 1,
        calories: Int = 0,
        protein: Double = 0,
        carbs: Double = 0,
        fat: Double = 0,
        source: FoodSource = .manual
    ) {
        self.id = id
        self.name = name
        self.servingSize = servingSize
        self.servingUnit = servingUnit
        self.numberOfServings = numberOfServings
        self.caloriesPerServing = calories
        self.proteinPerServing = protein
        self.carbsPerServing = carbs
        self.fatPerServing = fat
        self.source = source
        self.isVerified = false
        self.isCustom = source == .manual
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: - Computed Properties (Total based on servings)

    public var calories: Int {
        Int(Double(caloriesPerServing) * numberOfServings)
    }

    public var protein: Double {
        proteinPerServing * numberOfServings
    }

    public var carbs: Double {
        carbsPerServing * numberOfServings
    }

    public var fat: Double {
        fatPerServing * numberOfServings
    }

    public var fiber: Double? {
        guard let fiberPerServing else { return nil }
        return fiberPerServing * numberOfServings
    }

    public var sugar: Double? {
        guard let sugarPerServing else { return nil }
        return sugarPerServing * numberOfServings
    }

    public var sodium: Double? {
        guard let sodiumPerServing else { return nil }
        return sodiumPerServing * numberOfServings
    }

    public var displayServing: String {
        let servingText = servingSize == 1 ? "" : "\(Int(servingSize))"
        return "\(servingText) \(servingUnit)"
    }

    public var fullDisplayServing: String {
        if numberOfServings == 1 {
            return displayServing
        }
        return "\(numberOfServings) x \(displayServing)"
    }

    // MARK: - Methods

    /// Update serving count
    public func updateServings(_ count: Double) {
        numberOfServings = max(0.25, count)
        updatedAt = Date()
    }

    /// Create a copy of this food item
    public func duplicate() -> FoodItem {
        let copy = FoodItem(
            name: name,
            servingSize: servingSize,
            servingUnit: servingUnit,
            numberOfServings: numberOfServings,
            calories: caloriesPerServing,
            protein: proteinPerServing,
            carbs: carbsPerServing,
            fat: fatPerServing,
            source: source
        )

        copy.brandName = brandName
        copy.itemDescription = itemDescription
        copy.fiberPerServing = fiberPerServing
        copy.sugarPerServing = sugarPerServing
        copy.sodiumPerServing = sodiumPerServing
        copy.barcode = barcode
        copy.externalID = externalID

        return copy
    }
}

// MARK: - Food Source

public enum FoodSource: String, Codable {
    case manual = "manual"
    case aiScan = "ai_scan"
    case barcode = "barcode"
    case database = "database"
    case recipe = "recipe"
    case quickAdd = "quick_add"

    public var displayName: String {
        switch self {
        case .manual: return "Manual Entry"
        case .aiScan: return "AI Scan"
        case .barcode: return "Barcode"
        case .database: return "Food Database"
        case .recipe: return "Recipe"
        case .quickAdd: return "Quick Add"
        }
    }

    public var icon: String {
        switch self {
        case .manual: return "pencil"
        case .aiScan: return "camera.viewfinder"
        case .barcode: return "barcode.viewfinder"
        case .database: return "magnifyingglass"
        case .recipe: return "book"
        case .quickAdd: return "bolt"
        }
    }
}

// MARK: - Food Search Result

/// Lightweight food data for search results
public struct FoodSearchResult: Identifiable, Hashable {
    public let id: String
    public let name: String
    public let brandName: String?
    public let calories: Int
    public let servingSize: String
    public let source: FoodSource
    public let isVerified: Bool

    public init(
        id: String,
        name: String,
        brandName: String? = nil,
        calories: Int,
        servingSize: String,
        source: FoodSource,
        isVerified: Bool = false
    ) {
        self.id = id
        self.name = name
        self.brandName = brandName
        self.calories = calories
        self.servingSize = servingSize
        self.source = source
        self.isVerified = isVerified
    }

    /// Convert to FoodItem for adding to meal
    public func toFoodItem() -> FoodItem {
        let item = FoodItem(
            name: name,
            calories: calories,
            source: source
        )
        item.brandName = brandName
        item.externalID = id
        item.isVerified = isVerified
        return item
    }
}

// MARK: - Quick Add Item

/// Preset for quick calorie/macro additions
public struct QuickAddItem: Identifiable, Codable, Hashable {
    public let id: UUID
    public let name: String
    public let calories: Int
    public let protein: Double
    public let carbs: Double
    public let fat: Double

    public init(
        id: UUID = UUID(),
        name: String,
        calories: Int,
        protein: Double = 0,
        carbs: Double = 0,
        fat: Double = 0
    ) {
        self.id = id
        self.name = name
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
    }

    /// Convert to FoodItem
    public func toFoodItem() -> FoodItem {
        FoodItem(
            name: name,
            servingSize: 1,
            servingUnit: "serving",
            numberOfServings: 1,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            source: .quickAdd
        )
    }

    // MARK: - Presets

    public static let presets: [QuickAddItem] = [
        QuickAddItem(name: "100 Calories", calories: 100),
        QuickAddItem(name: "200 Calories", calories: 200),
        QuickAddItem(name: "300 Calories", calories: 300),
        QuickAddItem(name: "500 Calories", calories: 500),
        QuickAddItem(name: "Protein Shake", calories: 150, protein: 25, carbs: 5, fat: 3),
        QuickAddItem(name: "Energy Bar", calories: 200, protein: 10, carbs: 25, fat: 8)
    ]
}
