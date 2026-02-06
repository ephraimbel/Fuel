import SwiftUI
import SwiftData

/// Recipe View Model
/// Manages recipe list and creation state

@Observable
final class RecipeViewModel {
    // MARK: - State

    var recipes: [Recipe] = []
    var isLoading = false
    var searchText = ""
    var selectedCategory: RecipeCategory? = nil

    // MARK: - Filtered Recipes

    var filteredRecipes: [Recipe] {
        var result = recipes

        // Filter by category
        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }

        // Filter by search
        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.recipeDescription.localizedCaseInsensitiveContains(searchText)
            }
        }

        return result
    }

    var favoriteRecipes: [Recipe] {
        recipes.filter { $0.isFavorite }
    }

    // MARK: - Initialization

    init() {}

    // MARK: - Data Loading

    func loadRecipes() {
        isLoading = true

        // TODO: Load from SwiftData
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.isLoading = false
        }
    }

    // MARK: - Actions

    func toggleFavorite(_ recipe: Recipe) {
        recipe.isFavorite.toggle()
        recipe.updatedAt = Date()
        FuelHaptics.shared.tap()
    }

    func deleteRecipe(_ recipe: Recipe) {
        recipes.removeAll { $0.id == recipe.id }
        FuelHaptics.shared.tap()
    }

    /// Result of attempting to add a recipe
    enum AddRecipeResult {
        case success
        case limitReached
    }

    func addRecipe(_ recipe: Recipe) -> AddRecipeResult {
        // Check recipe limit for free users
        guard FeatureGateService.shared.canSaveRecipe(currentCount: recipes.count) else {
            FuelHaptics.shared.error()
            return .limitReached
        }

        recipes.insert(recipe, at: 0)
        FuelHaptics.shared.success()
        return .success
    }

    func updateRecipe(_ recipe: Recipe) {
        recipe.updatedAt = Date()
        FuelHaptics.shared.success()
    }

    func selectCategory(_ category: RecipeCategory?) {
        selectedCategory = category
        FuelHaptics.shared.tap()
    }
}

// MARK: - Create Recipe View Model

@Observable
final class CreateRecipeViewModel {
    // MARK: - State

    var name = ""
    var recipeDescription = ""
    var ingredients: [RecipeIngredient] = []
    var servings = 1
    var prepTime: Int? = nil
    var cookTime: Int? = nil
    var instructions: [String] = []
    var category: RecipeCategory = .other
    var imageData: Data? = nil

    var isEditing = false
    var editingRecipe: Recipe? = nil

    // MARK: - Validation

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !ingredients.isEmpty &&
        servings > 0
    }

    // MARK: - Computed Nutrition

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

    // MARK: - Initialization

    init(recipe: Recipe? = nil) {
        if let recipe = recipe {
            self.isEditing = true
            self.editingRecipe = recipe
            self.name = recipe.name
            self.recipeDescription = recipe.recipeDescription
            self.ingredients = recipe.ingredients
            self.servings = recipe.servings
            self.prepTime = recipe.prepTime
            self.cookTime = recipe.cookTime
            self.instructions = recipe.instructions
            self.category = recipe.category
            self.imageData = recipe.imageData
        }
    }

    // MARK: - Actions

    func addIngredient(_ ingredient: RecipeIngredient) {
        ingredients.append(ingredient)
        FuelHaptics.shared.tap()
    }

    func removeIngredient(at index: Int) {
        guard index < ingredients.count else { return }
        ingredients.remove(at: index)
        FuelHaptics.shared.tap()
    }

    func updateIngredientQuantity(at index: Int, quantity: Double) {
        guard index < ingredients.count else { return }
        ingredients[index] = ingredients[index].withUpdatedQuantity(quantity)
    }

    func addInstruction(_ instruction: String) {
        guard !instruction.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        instructions.append(instruction)
        FuelHaptics.shared.tap()
    }

    func removeInstruction(at index: Int) {
        guard index < instructions.count else { return }
        instructions.remove(at: index)
        FuelHaptics.shared.tap()
    }

    func moveInstruction(from source: IndexSet, to destination: Int) {
        instructions.move(fromOffsets: source, toOffset: destination)
    }

    func createRecipe() -> Recipe {
        if let recipe = editingRecipe {
            recipe.name = name
            recipe.recipeDescription = recipeDescription
            recipe.ingredients = ingredients
            recipe.servings = servings
            recipe.prepTime = prepTime
            recipe.cookTime = cookTime
            recipe.instructions = instructions
            recipe.category = category
            recipe.imageData = imageData
            recipe.updatedAt = Date()
            return recipe
        }

        return Recipe(
            name: name,
            recipeDescription: recipeDescription,
            ingredients: ingredients,
            servings: servings,
            prepTime: prepTime,
            cookTime: cookTime,
            instructions: instructions,
            imageData: imageData,
            category: category
        )
    }
}
