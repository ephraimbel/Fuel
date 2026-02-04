import SwiftUI

/// Add Ingredient Sheet
/// Search and add ingredients to a recipe

struct AddIngredientSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedIngredient: CommonIngredient? = nil
    @State private var quantity: Double = 100
    @State private var selectedUnit: IngredientUnit = .gram

    let onAdd: (RecipeIngredient) -> Void

    private let commonIngredients: [CommonIngredient] = CommonIngredient.all

    var filteredIngredients: [CommonIngredient] {
        if searchText.isEmpty {
            return commonIngredients
        }
        return commonIngredients.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let ingredient = selectedIngredient {
                    // Quantity editor
                    quantityEditor(ingredient)
                } else {
                    // Search and list
                    searchAndList
                }
            }
            .background(FuelColors.background)
            .navigationTitle(selectedIngredient == nil ? "Add Ingredient" : "Set Amount")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(selectedIngredient == nil ? "Cancel" : "Back") {
                        if selectedIngredient != nil {
                            selectedIngredient = nil
                        } else {
                            dismiss()
                        }
                    }
                }

                if selectedIngredient != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Add") {
                            addIngredient()
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
        }
    }

    // MARK: - Search and List

    private var searchAndList: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack(spacing: FuelSpacing.sm) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(FuelColors.textTertiary)

                TextField("Search ingredients...", text: $searchText)
                    .font(FuelTypography.body)
                    .foregroundStyle(FuelColors.textPrimary)

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(FuelColors.textTertiary)
                    }
                }
            }
            .padding(FuelSpacing.sm)
            .background(FuelColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
            .padding(.horizontal, FuelSpacing.screenHorizontal)
            .padding(.vertical, FuelSpacing.md)

            // Categories
            if searchText.isEmpty {
                categoriesSection
            }

            // Ingredient list
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(filteredIngredients, id: \.id) { ingredient in
                        ingredientRow(ingredient)

                        Divider()
                            .padding(.leading, FuelSpacing.screenHorizontal + 44 + FuelSpacing.md)
                    }
                }
            }
        }
    }

    private var categoriesSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: FuelSpacing.sm) {
                ForEach(IngredientCategory.allCases, id: \.self) { category in
                    VStack(spacing: FuelSpacing.xs) {
                        Image(systemName: category.icon)
                            .font(.system(size: 20))
                            .foregroundStyle(category.color)
                            .frame(width: 44, height: 44)
                            .background(category.color.opacity(0.15))
                            .clipShape(Circle())

                        Text(category.displayName)
                            .font(FuelTypography.caption)
                            .foregroundStyle(FuelColors.textSecondary)
                    }
                }
            }
            .padding(.horizontal, FuelSpacing.screenHorizontal)
            .padding(.bottom, FuelSpacing.md)
        }
    }

    private func ingredientRow(_ ingredient: CommonIngredient) -> some View {
        Button {
            selectedIngredient = ingredient
            FuelHaptics.shared.tap()
        } label: {
            HStack(spacing: FuelSpacing.md) {
                // Icon
                Image(systemName: ingredient.category.icon)
                    .font(.system(size: 18))
                    .foregroundStyle(ingredient.category.color)
                    .frame(width: 44, height: 44)
                    .background(ingredient.category.color.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusSm))

                // Info
                VStack(alignment: .leading, spacing: FuelSpacing.xxxs) {
                    Text(ingredient.name)
                        .font(FuelTypography.body)
                        .foregroundStyle(FuelColors.textPrimary)

                    Text("\(ingredient.caloriesPer100g) cal per 100g")
                        .font(FuelTypography.caption)
                        .foregroundStyle(FuelColors.textTertiary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(FuelColors.textTertiary)
            }
            .padding(.horizontal, FuelSpacing.screenHorizontal)
            .padding(.vertical, FuelSpacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Quantity Editor

    private func quantityEditor(_ ingredient: CommonIngredient) -> some View {
        ScrollView {
            VStack(spacing: FuelSpacing.xl) {
                // Selected ingredient info
                VStack(spacing: FuelSpacing.md) {
                    Image(systemName: ingredient.category.icon)
                        .font(.system(size: 32))
                        .foregroundStyle(ingredient.category.color)
                        .frame(width: 80, height: 80)
                        .background(ingredient.category.color.opacity(0.15))
                        .clipShape(Circle())

                    Text(ingredient.name)
                        .font(FuelTypography.title3)
                        .foregroundStyle(FuelColors.textPrimary)
                }
                .padding(.top, FuelSpacing.lg)

                // Quantity input
                VStack(spacing: FuelSpacing.md) {
                    Text("QUANTITY")
                        .font(FuelTypography.caption)
                        .foregroundStyle(FuelColors.textTertiary)

                    HStack(spacing: FuelSpacing.md) {
                        // Decrease button
                        Button {
                            if quantity > 10 {
                                quantity -= 10
                                FuelHaptics.shared.tap()
                            }
                        } label: {
                            Image(systemName: "minus")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(FuelColors.primary)
                                .frame(width: 44, height: 44)
                                .background(FuelColors.surface)
                                .clipShape(Circle())
                        }

                        // Quantity display
                        VStack(spacing: FuelSpacing.xxxs) {
                            TextField("", value: $quantity, format: .number)
                                .font(.system(size: 40, weight: .bold))
                                .foregroundStyle(FuelColors.textPrimary)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.center)
                                .frame(width: 120)

                            // Unit picker
                            Menu {
                                ForEach(IngredientUnit.allCases, id: \.self) { unit in
                                    Button(unit.displayName) {
                                        selectedUnit = unit
                                    }
                                }
                            } label: {
                                HStack(spacing: FuelSpacing.xxxs) {
                                    Text(selectedUnit.rawValue)
                                        .font(FuelTypography.body)
                                        .foregroundStyle(FuelColors.textSecondary)
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 10))
                                        .foregroundStyle(FuelColors.textTertiary)
                                }
                            }
                        }

                        // Increase button
                        Button {
                            quantity += 10
                            FuelHaptics.shared.tap()
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(FuelColors.primary)
                                .frame(width: 44, height: 44)
                                .background(FuelColors.surface)
                                .clipShape(Circle())
                        }
                    }

                    // Quick amounts
                    HStack(spacing: FuelSpacing.sm) {
                        ForEach([50, 100, 150, 200], id: \.self) { amount in
                            Button {
                                quantity = Double(amount)
                                FuelHaptics.shared.tap()
                            } label: {
                                Text("\(amount)g")
                                    .font(FuelTypography.captionMedium)
                                    .foregroundStyle(quantity == Double(amount) ? .white : FuelColors.textSecondary)
                                    .padding(.horizontal, FuelSpacing.md)
                                    .padding(.vertical, FuelSpacing.sm)
                                    .background(quantity == Double(amount) ? FuelColors.primary : FuelColors.surface)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }

                // Nutrition preview
                nutritionPreview(ingredient)
            }
            .padding(.horizontal, FuelSpacing.screenHorizontal)
        }
    }

    private func nutritionPreview(_ ingredient: CommonIngredient) -> some View {
        let multiplier = quantity / 100.0

        return VStack(spacing: FuelSpacing.md) {
            Text("NUTRITION")
                .font(FuelTypography.caption)
                .foregroundStyle(FuelColors.textTertiary)

            HStack(spacing: FuelSpacing.md) {
                nutritionBox(
                    "Calories",
                    "\(Int(Double(ingredient.caloriesPer100g) * multiplier))",
                    "cal",
                    FuelColors.primary
                )
                nutritionBox(
                    "Protein",
                    "\(Int(ingredient.proteinPer100g * multiplier))",
                    "g",
                    FuelColors.protein
                )
                nutritionBox(
                    "Carbs",
                    "\(Int(ingredient.carbsPer100g * multiplier))",
                    "g",
                    FuelColors.carbs
                )
                nutritionBox(
                    "Fat",
                    "\(Int(ingredient.fatPer100g * multiplier))",
                    "g",
                    FuelColors.fat
                )
            }
        }
        .padding(FuelSpacing.lg)
        .background(FuelColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusLg))
    }

    private func nutritionBox(_ label: String, _ value: String, _ unit: String, _ color: Color) -> some View {
        VStack(spacing: FuelSpacing.xxxs) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(FuelTypography.headline)
                    .foregroundStyle(FuelColors.textPrimary)
                Text(unit)
                    .font(FuelTypography.caption)
                    .foregroundStyle(FuelColors.textTertiary)
            }

            Text(label)
                .font(FuelTypography.caption)
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Actions

    private func addIngredient() {
        guard let ingredient = selectedIngredient else { return }

        let recipeIngredient = RecipeIngredient(
            name: ingredient.name,
            quantity: quantity,
            unit: selectedUnit,
            baseCalories: ingredient.caloriesPer100g,
            baseProtein: ingredient.proteinPer100g,
            baseCarbs: ingredient.carbsPer100g,
            baseFat: ingredient.fatPer100g
        )

        onAdd(recipeIngredient)
        dismiss()
    }
}

// MARK: - Common Ingredient

struct CommonIngredient: Identifiable {
    let id = UUID().uuidString
    let name: String
    let category: IngredientCategory
    let caloriesPer100g: Int
    let proteinPer100g: Double
    let carbsPer100g: Double
    let fatPer100g: Double

    static var all: [CommonIngredient] {
        [
            // Proteins
            CommonIngredient(name: "Chicken Breast", category: .protein, caloriesPer100g: 165, proteinPer100g: 31, carbsPer100g: 0, fatPer100g: 3.6),
            CommonIngredient(name: "Salmon", category: .protein, caloriesPer100g: 208, proteinPer100g: 20, carbsPer100g: 0, fatPer100g: 13),
            CommonIngredient(name: "Eggs", category: .protein, caloriesPer100g: 155, proteinPer100g: 13, carbsPer100g: 1.1, fatPer100g: 11),
            CommonIngredient(name: "Ground Beef (lean)", category: .protein, caloriesPer100g: 250, proteinPer100g: 26, carbsPer100g: 0, fatPer100g: 15),
            CommonIngredient(name: "Tofu", category: .protein, caloriesPer100g: 76, proteinPer100g: 8, carbsPer100g: 1.9, fatPer100g: 4.8),
            CommonIngredient(name: "Greek Yogurt", category: .dairy, caloriesPer100g: 97, proteinPer100g: 17, carbsPer100g: 3.6, fatPer100g: 0.7),

            // Vegetables
            CommonIngredient(name: "Broccoli", category: .vegetable, caloriesPer100g: 34, proteinPer100g: 2.8, carbsPer100g: 7, fatPer100g: 0.4),
            CommonIngredient(name: "Spinach", category: .vegetable, caloriesPer100g: 23, proteinPer100g: 2.9, carbsPer100g: 3.6, fatPer100g: 0.4),
            CommonIngredient(name: "Bell Pepper", category: .vegetable, caloriesPer100g: 31, proteinPer100g: 1, carbsPer100g: 6, fatPer100g: 0.3),
            CommonIngredient(name: "Carrot", category: .vegetable, caloriesPer100g: 41, proteinPer100g: 0.9, carbsPer100g: 10, fatPer100g: 0.2),
            CommonIngredient(name: "Tomato", category: .vegetable, caloriesPer100g: 18, proteinPer100g: 0.9, carbsPer100g: 3.9, fatPer100g: 0.2),

            // Fruits
            CommonIngredient(name: "Banana", category: .fruit, caloriesPer100g: 89, proteinPer100g: 1.1, carbsPer100g: 23, fatPer100g: 0.3),
            CommonIngredient(name: "Apple", category: .fruit, caloriesPer100g: 52, proteinPer100g: 0.3, carbsPer100g: 14, fatPer100g: 0.2),
            CommonIngredient(name: "Blueberries", category: .fruit, caloriesPer100g: 57, proteinPer100g: 0.7, carbsPer100g: 14, fatPer100g: 0.3),
            CommonIngredient(name: "Strawberries", category: .fruit, caloriesPer100g: 32, proteinPer100g: 0.7, carbsPer100g: 7.7, fatPer100g: 0.3),

            // Grains
            CommonIngredient(name: "Rice (cooked)", category: .grain, caloriesPer100g: 130, proteinPer100g: 2.7, carbsPer100g: 28, fatPer100g: 0.3),
            CommonIngredient(name: "Oats", category: .grain, caloriesPer100g: 389, proteinPer100g: 16.9, carbsPer100g: 66, fatPer100g: 6.9),
            CommonIngredient(name: "Quinoa (cooked)", category: .grain, caloriesPer100g: 120, proteinPer100g: 4.4, carbsPer100g: 21, fatPer100g: 1.9),
            CommonIngredient(name: "Pasta (cooked)", category: .grain, caloriesPer100g: 131, proteinPer100g: 5, carbsPer100g: 25, fatPer100g: 1.1),
            CommonIngredient(name: "Bread (whole wheat)", category: .grain, caloriesPer100g: 247, proteinPer100g: 13, carbsPer100g: 41, fatPer100g: 3.4),

            // Dairy
            CommonIngredient(name: "Milk (whole)", category: .dairy, caloriesPer100g: 61, proteinPer100g: 3.2, carbsPer100g: 4.8, fatPer100g: 3.3),
            CommonIngredient(name: "Cheese (cheddar)", category: .dairy, caloriesPer100g: 403, proteinPer100g: 25, carbsPer100g: 1.3, fatPer100g: 33),
            CommonIngredient(name: "Almond Milk", category: .dairy, caloriesPer100g: 15, proteinPer100g: 0.5, carbsPer100g: 0.3, fatPer100g: 1.2),

            // Fats & Oils
            CommonIngredient(name: "Olive Oil", category: .fat, caloriesPer100g: 884, proteinPer100g: 0, carbsPer100g: 0, fatPer100g: 100),
            CommonIngredient(name: "Butter", category: .fat, caloriesPer100g: 717, proteinPer100g: 0.9, carbsPer100g: 0.1, fatPer100g: 81),
            CommonIngredient(name: "Avocado", category: .fat, caloriesPer100g: 160, proteinPer100g: 2, carbsPer100g: 9, fatPer100g: 15),
            CommonIngredient(name: "Almonds", category: .fat, caloriesPer100g: 579, proteinPer100g: 21, carbsPer100g: 22, fatPer100g: 50),
            CommonIngredient(name: "Peanut Butter", category: .fat, caloriesPer100g: 588, proteinPer100g: 25, carbsPer100g: 20, fatPer100g: 50),

            // Other
            CommonIngredient(name: "Honey", category: .other, caloriesPer100g: 304, proteinPer100g: 0.3, carbsPer100g: 82, fatPer100g: 0),
            CommonIngredient(name: "Protein Powder", category: .other, caloriesPer100g: 400, proteinPer100g: 80, carbsPer100g: 10, fatPer100g: 5),
            CommonIngredient(name: "Chia Seeds", category: .other, caloriesPer100g: 486, proteinPer100g: 17, carbsPer100g: 42, fatPer100g: 31)
        ]
    }
}

// MARK: - Ingredient Category

enum IngredientCategory: String, CaseIterable {
    case protein
    case vegetable
    case fruit
    case grain
    case dairy
    case fat
    case other

    var displayName: String {
        switch self {
        case .protein: return "Protein"
        case .vegetable: return "Veggies"
        case .fruit: return "Fruit"
        case .grain: return "Grains"
        case .dairy: return "Dairy"
        case .fat: return "Fats"
        case .other: return "Other"
        }
    }

    var icon: String {
        switch self {
        case .protein: return "fish.fill"
        case .vegetable: return "leaf.fill"
        case .fruit: return "apple.logo"
        case .grain: return "wheat"
        case .dairy: return "drop.fill"
        case .fat: return "drop.circle.fill"
        case .other: return "square.grid.2x2.fill"
        }
    }

    var color: Color {
        switch self {
        case .protein: return FuelColors.protein
        case .vegetable: return FuelColors.success
        case .fruit: return .orange
        case .grain: return .brown
        case .dairy: return .cyan
        case .fat: return FuelColors.fat
        case .other: return FuelColors.textSecondary
        }
    }
}

// MARK: - Preview

#Preview {
    AddIngredientSheet { _ in }
}
