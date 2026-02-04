import SwiftUI

/// Food Detail Sheet
/// Shows detailed nutrition info for a food item before adding to meal

struct FoodDetailSheet: View {
    let food: FoodSearchItem
    let mealType: MealType
    let onAdd: (FoodItem) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var numberOfServings: Double = 1.0
    @State private var showingNutritionFacts = false

    // MARK: - Computed Properties

    private var adjustedCalories: Int {
        Int(Double(food.calories) * numberOfServings)
    }

    private var adjustedProtein: Double {
        food.protein * numberOfServings
    }

    private var adjustedCarbs: Double {
        food.carbs * numberOfServings
    }

    private var adjustedFat: Double {
        food.fat * numberOfServings
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: FuelSpacing.lg) {
                    // Header with image and basic info
                    headerSection

                    Divider()
                        .background(FuelColors.border)

                    // Serving size selector
                    servingSizeSection

                    // Nutrition summary
                    nutritionSummary

                    // Macro breakdown
                    macroBreakdown

                    // Nutrition facts (expandable)
                    if showingNutritionFacts {
                        nutritionFactsSection
                    }

                    // Toggle nutrition facts
                    Button {
                        withAnimation(FuelAnimations.spring) {
                            showingNutritionFacts.toggle()
                        }
                        FuelHaptics.shared.tap()
                    } label: {
                        HStack(spacing: FuelSpacing.xs) {
                            Text(showingNutritionFacts ? "Hide Nutrition Facts" : "Show Nutrition Facts")
                                .font(FuelTypography.subheadlineMedium)

                            Image(systemName: showingNutritionFacts ? "chevron.up" : "chevron.down")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundStyle(FuelColors.primary)
                    }
                }
                .padding(FuelSpacing.screenHorizontal)
            }
            .background(FuelColors.background)
            .navigationTitle("Food Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        FuelHaptics.shared.tap()
                        dismiss()
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                addButton
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(spacing: FuelSpacing.md) {
            // Food image
            if let imageURL = food.imageURL,
               let url = URL(string: imageURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure, .empty:
                        imagePlaceholder
                    @unknown default:
                        imagePlaceholder
                    }
                }
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
            } else {
                imagePlaceholder
            }

            // Food info
            VStack(alignment: .leading, spacing: FuelSpacing.xxs) {
                Text(food.name)
                    .font(FuelTypography.headline)
                    .foregroundStyle(FuelColors.textPrimary)
                    .lineLimit(2)

                if let brand = food.brand {
                    Text(brand)
                        .font(FuelTypography.subheadline)
                        .foregroundStyle(FuelColors.textSecondary)
                }

                HStack(spacing: FuelSpacing.sm) {
                    // Source badge
                    HStack(spacing: FuelSpacing.xxxs) {
                        Image(systemName: food.source.icon)
                        Text(food.source.displayName)
                    }
                    .font(FuelTypography.caption)
                    .foregroundStyle(FuelColors.textTertiary)

                    // Meal type
                    HStack(spacing: FuelSpacing.xxxs) {
                        Image(systemName: mealType.icon)
                        Text(mealType.displayName)
                    }
                    .font(FuelTypography.caption)
                    .foregroundStyle(FuelColors.primary)
                }
            }

            Spacer()
        }
    }

    private var imagePlaceholder: some View {
        RoundedRectangle(cornerRadius: FuelSpacing.radiusMd)
            .fill(FuelColors.surfaceSecondary)
            .frame(width: 80, height: 80)
            .overlay(
                Image(systemName: "fork.knife")
                    .font(.system(size: 28))
                    .foregroundStyle(FuelColors.textTertiary)
            )
    }

    // MARK: - Serving Size Section

    private var servingSizeSection: some View {
        VStack(alignment: .leading, spacing: FuelSpacing.sm) {
            Text("SERVING SIZE")
                .font(FuelTypography.caption)
                .foregroundStyle(FuelColors.textTertiary)

            HStack {
                VStack(alignment: .leading, spacing: FuelSpacing.xxxs) {
                    Text(food.servingSize)
                        .font(FuelTypography.subheadlineMedium)
                        .foregroundStyle(FuelColors.textPrimary)

                    Text("per serving")
                        .font(FuelTypography.caption)
                        .foregroundStyle(FuelColors.textTertiary)
                }

                Spacer()

                // Stepper
                HStack(spacing: FuelSpacing.sm) {
                    Button {
                        if numberOfServings > 0.25 {
                            numberOfServings -= 0.25
                            FuelHaptics.shared.select()
                        }
                    } label: {
                        Image(systemName: "minus")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(numberOfServings <= 0.25 ? FuelColors.textTertiary : FuelColors.primary)
                            .frame(width: 36, height: 36)
                            .background(FuelColors.surfaceSecondary)
                            .clipShape(Circle())
                    }
                    .disabled(numberOfServings <= 0.25)

                    Text(formatServings(numberOfServings))
                        .font(FuelTypography.headline)
                        .foregroundStyle(FuelColors.textPrimary)
                        .frame(minWidth: 50)

                    Button {
                        numberOfServings += 0.25
                        FuelHaptics.shared.select()
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(FuelColors.primary)
                            .frame(width: 36, height: 36)
                            .background(FuelColors.surfaceSecondary)
                            .clipShape(Circle())
                    }
                }
            }
            .padding(FuelSpacing.md)
            .background(FuelColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
        }
    }

    // MARK: - Nutrition Summary

    private var nutritionSummary: some View {
        VStack(spacing: FuelSpacing.md) {
            HStack {
                Text("Calories")
                    .font(FuelTypography.subheadline)
                    .foregroundStyle(FuelColors.textSecondary)

                Spacer()

                Text("\(adjustedCalories)")
                    .font(FuelTypography.title1)
                    .foregroundStyle(FuelColors.primary)
            }
        }
        .padding(FuelSpacing.md)
        .background(FuelColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
    }

    // MARK: - Macro Breakdown

    private var macroBreakdown: some View {
        HStack(spacing: FuelSpacing.md) {
            macroItem(
                label: "Protein",
                value: adjustedProtein,
                color: FuelColors.protein
            )

            macroItem(
                label: "Carbs",
                value: adjustedCarbs,
                color: FuelColors.carbs
            )

            macroItem(
                label: "Fat",
                value: adjustedFat,
                color: FuelColors.fat
            )
        }
    }

    private func macroItem(label: String, value: Double, color: Color) -> some View {
        VStack(spacing: FuelSpacing.sm) {
            // Circular indicator
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 6)
                    .frame(width: 60, height: 60)

                Circle()
                    .trim(from: 0, to: min(value / 50, 1))
                    .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))

                Text("\(Int(value))")
                    .font(FuelTypography.headline)
                    .foregroundStyle(FuelColors.textPrimary)
            }

            Text(label)
                .font(FuelTypography.caption)
                .foregroundStyle(FuelColors.textSecondary)

            Text("\(Int(value))g")
                .font(FuelTypography.subheadlineMedium)
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .padding(FuelSpacing.md)
        .background(FuelColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
    }

    // MARK: - Nutrition Facts

    private var nutritionFactsSection: some View {
        VStack(alignment: .leading, spacing: FuelSpacing.sm) {
            Text("NUTRITION FACTS")
                .font(FuelTypography.caption)
                .foregroundStyle(FuelColors.textTertiary)

            VStack(spacing: 0) {
                nutritionRow(label: "Calories", value: "\(adjustedCalories)", bold: true)
                Divider()
                nutritionRow(label: "Total Fat", value: "\(Int(adjustedFat))g")
                nutritionRow(label: "Total Carbohydrate", value: "\(Int(adjustedCarbs))g")
                nutritionRow(label: "  Sugars", value: "-", indent: true)
                nutritionRow(label: "  Fiber", value: "-", indent: true)
                nutritionRow(label: "Protein", value: "\(Int(adjustedProtein))g")
            }
            .padding(FuelSpacing.md)
            .background(FuelColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
        }
    }

    private func nutritionRow(label: String, value: String, bold: Bool = false, indent: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(bold ? FuelTypography.subheadlineMedium : FuelTypography.subheadline)
                .foregroundStyle(indent ? FuelColors.textTertiary : FuelColors.textPrimary)

            Spacer()

            Text(value)
                .font(bold ? FuelTypography.subheadlineMedium : FuelTypography.subheadline)
                .foregroundStyle(FuelColors.textPrimary)
        }
        .padding(.vertical, FuelSpacing.xs)
    }

    // MARK: - Add Button

    private var addButton: some View {
        VStack(spacing: 0) {
            Divider()
                .background(FuelColors.border)

            Button {
                let foodItem = food.toFoodItem(servings: numberOfServings)
                FuelHaptics.shared.success()
                onAdd(foodItem)
            } label: {
                HStack(spacing: FuelSpacing.sm) {
                    Image(systemName: "plus")

                    Text("Add to \(mealType.displayName)")

                    Text("· \(adjustedCalories) cal")
                        .foregroundStyle(.white.opacity(0.8))
                }
                .font(FuelTypography.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, FuelSpacing.md)
                .background(FuelColors.primary)
                .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
            }
            .padding(.horizontal, FuelSpacing.screenHorizontal)
            .padding(.vertical, FuelSpacing.md)
        }
        .background(FuelColors.background)
    }

    // MARK: - Helpers

    private func formatServings(_ value: Double) -> String {
        if value == Double(Int(value)) {
            return "\(Int(value))"
        }
        return String(format: "%.2f", value)
    }
}

// MARK: - Preview

#Preview {
    FoodDetailSheet(
        food: FoodSearchItem(
            id: "1",
            name: "Grilled Chicken Breast",
            brand: "Tyson",
            calories: 165,
            servingSize: "100g",
            protein: 31,
            carbs: 0,
            fat: 3.6,
            imageURL: nil,
            source: .database,
            barcode: nil
        ),
        mealType: .lunch,
        onAdd: { _ in }
    )
}
