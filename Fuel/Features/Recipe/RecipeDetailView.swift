import SwiftUI

/// Recipe Detail View
/// Shows full recipe details with nutrition info

struct RecipeDetailView: View {
    let recipe: Recipe
    let onToggleFavorite: () -> Void
    let onDelete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showingDeleteConfirmation = false
    @State private var showingEditRecipe = false
    @State private var servingsMultiplier = 1

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: FuelSpacing.xl) {
                    // Header image
                    headerImage

                    VStack(spacing: FuelSpacing.xl) {
                        // Title and category
                        titleSection

                        // Quick stats
                        quickStatsSection

                        // Nutrition per serving
                        nutritionSection

                        // Ingredients
                        ingredientsSection

                        // Instructions
                        if !recipe.instructions.isEmpty {
                            instructionsSection
                        }

                        // Add to meal button
                        addToMealButton
                    }
                    .padding(.horizontal, FuelSpacing.screenHorizontal)
                }
                .padding(.bottom, FuelSpacing.xxl)
            }
            .background(FuelColors.background)
            .ignoresSafeArea(edges: .top)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(FuelColors.textPrimary)
                            .frame(width: 32, height: 32)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: FuelSpacing.sm) {
                        // Favorite button
                        Button {
                            onToggleFavorite()
                        } label: {
                            Image(systemName: recipe.isFavorite ? "heart.fill" : "heart")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(recipe.isFavorite ? FuelColors.error : FuelColors.textPrimary)
                                .frame(width: 32, height: 32)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }

                        // More options
                        Menu {
                            Button {
                                showingEditRecipe = true
                            } label: {
                                Label("Edit Recipe", systemImage: "pencil")
                            }

                            Button(role: .destructive) {
                                showingDeleteConfirmation = true
                            } label: {
                                Label("Delete Recipe", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(FuelColors.textPrimary)
                                .frame(width: 32, height: 32)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                    }
                }
            }
            .confirmationDialog(
                "Delete Recipe",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    onDelete()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete this recipe? This action cannot be undone.")
            }
            .sheet(isPresented: $showingEditRecipe) {
                CreateRecipeView(recipe: recipe) { _ in
                    // Recipe updated
                }
            }
        }
    }

    // MARK: - Header Image

    private var headerImage: some View {
        ZStack(alignment: .bottom) {
            if let imageData = recipe.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 280)
                    .clipped()
            } else {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [recipe.category.color.opacity(0.3), recipe.category.color.opacity(0.1)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 280)
                    .overlay {
                        Image(systemName: recipe.category.icon)
                            .font(.system(size: 64))
                            .foregroundStyle(recipe.category.color.opacity(0.5))
                    }
            }

            // Gradient overlay
            LinearGradient(
                colors: [.clear, FuelColors.background],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 100)
        }
    }

    // MARK: - Title Section

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: FuelSpacing.sm) {
            // Category badge
            HStack(spacing: FuelSpacing.xs) {
                Image(systemName: recipe.category.icon)
                    .font(.system(size: 12))
                Text(recipe.category.displayName)
                    .font(FuelTypography.captionMedium)
            }
            .foregroundStyle(recipe.category.color)
            .padding(.horizontal, FuelSpacing.sm)
            .padding(.vertical, FuelSpacing.xs)
            .background(recipe.category.color.opacity(0.15))
            .clipShape(Capsule())

            // Title
            Text(recipe.name)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(FuelColors.textPrimary)

            // Description
            if !recipe.recipeDescription.isEmpty {
                Text(recipe.recipeDescription)
                    .font(FuelTypography.body)
                    .foregroundStyle(FuelColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Quick Stats Section

    private var quickStatsSection: some View {
        HStack(spacing: FuelSpacing.md) {
            // Servings
            quickStatCard(
                icon: "person.2.fill",
                value: "\(recipe.servings)",
                label: recipe.servings == 1 ? "Serving" : "Servings",
                color: FuelColors.primary
            )

            // Prep time
            if let prep = recipe.prepTime {
                quickStatCard(
                    icon: "clock",
                    value: "\(prep)",
                    label: "Prep (min)",
                    color: .blue
                )
            }

            // Cook time
            if let cook = recipe.cookTime {
                quickStatCard(
                    icon: "flame.fill",
                    value: "\(cook)",
                    label: "Cook (min)",
                    color: .orange
                )
            }

            // Total time
            if let total = recipe.formattedTotalTime {
                quickStatCard(
                    icon: "timer",
                    value: total,
                    label: "Total",
                    color: .purple
                )
            }
        }
    }

    private func quickStatCard(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: FuelSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(color)

            Text(value)
                .font(FuelTypography.headline)
                .foregroundStyle(FuelColors.textPrimary)

            Text(label)
                .font(FuelTypography.caption)
                .foregroundStyle(FuelColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(FuelSpacing.md)
        .background(FuelColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
    }

    // MARK: - Nutrition Section

    private var nutritionSection: some View {
        VStack(alignment: .leading, spacing: FuelSpacing.md) {
            HStack {
                Text("NUTRITION PER SERVING")
                    .font(FuelTypography.caption)
                    .foregroundStyle(FuelColors.textTertiary)

                Spacer()

                // Servings adjuster
                HStack(spacing: FuelSpacing.sm) {
                    Button {
                        if servingsMultiplier > 1 {
                            servingsMultiplier -= 1
                            FuelHaptics.shared.tap()
                        }
                    } label: {
                        Image(systemName: "minus")
                            .font(.system(size: 10, weight: .semibold))
                            .frame(width: 24, height: 24)
                            .background(FuelColors.surfaceSecondary)
                            .clipShape(Circle())
                    }

                    Text("\(servingsMultiplier)x")
                        .font(FuelTypography.captionMedium)
                        .foregroundStyle(FuelColors.textSecondary)

                    Button {
                        servingsMultiplier += 1
                        FuelHaptics.shared.tap()
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 10, weight: .semibold))
                            .frame(width: 24, height: 24)
                            .background(FuelColors.surfaceSecondary)
                            .clipShape(Circle())
                    }
                }
            }

            HStack(spacing: FuelSpacing.sm) {
                nutritionCard(
                    "Calories",
                    "\(recipe.caloriesPerServing * servingsMultiplier)",
                    "cal",
                    FuelColors.primary
                )
                nutritionCard(
                    "Protein",
                    "\(Int(recipe.proteinPerServing * Double(servingsMultiplier)))",
                    "g",
                    FuelColors.protein
                )
                nutritionCard(
                    "Carbs",
                    "\(Int(recipe.carbsPerServing * Double(servingsMultiplier)))",
                    "g",
                    FuelColors.carbs
                )
                nutritionCard(
                    "Fat",
                    "\(Int(recipe.fatPerServing * Double(servingsMultiplier)))",
                    "g",
                    FuelColors.fat
                )
            }
        }
    }

    private func nutritionCard(_ label: String, _ value: String, _ unit: String, _ color: Color) -> some View {
        VStack(spacing: FuelSpacing.xs) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(FuelTypography.title3)
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
        .padding(FuelSpacing.md)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusSm))
    }

    // MARK: - Ingredients Section

    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: FuelSpacing.md) {
            HStack {
                Text("INGREDIENTS")
                    .font(FuelTypography.caption)
                    .foregroundStyle(FuelColors.textTertiary)

                Spacer()

                Text("\(recipe.ingredients.count) items")
                    .font(FuelTypography.caption)
                    .foregroundStyle(FuelColors.textTertiary)
            }

            VStack(spacing: 0) {
                ForEach(recipe.ingredients, id: \.id) { ingredient in
                    HStack(spacing: FuelSpacing.md) {
                        Circle()
                            .fill(FuelColors.primary)
                            .frame(width: 6, height: 6)

                        Text(ingredient.name)
                            .font(FuelTypography.body)
                            .foregroundStyle(FuelColors.textPrimary)

                        Spacer()

                        Text("\(Int(ingredient.quantity * Double(servingsMultiplier))) \(ingredient.unit.rawValue)")
                            .font(FuelTypography.body)
                            .foregroundStyle(FuelColors.textSecondary)
                    }
                    .padding(FuelSpacing.md)

                    if ingredient.id != recipe.ingredients.last?.id {
                        Divider()
                            .padding(.leading, FuelSpacing.md + 6 + FuelSpacing.md)
                    }
                }
            }
            .background(FuelColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
        }
    }

    // MARK: - Instructions Section

    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: FuelSpacing.md) {
            Text("INSTRUCTIONS")
                .font(FuelTypography.caption)
                .foregroundStyle(FuelColors.textTertiary)

            VStack(spacing: 0) {
                ForEach(Array(recipe.instructions.enumerated()), id: \.offset) { index, instruction in
                    HStack(alignment: .top, spacing: FuelSpacing.md) {
                        // Step number
                        Text("\(index + 1)")
                            .font(FuelTypography.subheadlineMedium)
                            .foregroundStyle(.white)
                            .frame(width: 28, height: 28)
                            .background(FuelColors.primary)
                            .clipShape(Circle())

                        Text(instruction)
                            .font(FuelTypography.body)
                            .foregroundStyle(FuelColors.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(FuelSpacing.md)

                    if index < recipe.instructions.count - 1 {
                        Divider()
                            .padding(.leading, FuelSpacing.md + 28 + FuelSpacing.md)
                    }
                }
            }
            .background(FuelColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
        }
    }

    // MARK: - Add to Meal Button

    private var addToMealButton: some View {
        Button {
            FuelHaptics.shared.success()
            dismiss()
            // TODO: Add to meal
        } label: {
            HStack(spacing: FuelSpacing.sm) {
                Image(systemName: "plus.circle.fill")
                Text("Add to Meal")
            }
            .font(FuelTypography.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, FuelSpacing.md)
            .background(FuelColors.primary)
            .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
        }
    }
}

// MARK: - Preview

#Preview {
    RecipeDetailView(
        recipe: Recipe(
            name: "Protein Smoothie Bowl",
            recipeDescription: "A delicious and filling breakfast smoothie bowl",
            ingredients: [
                RecipeIngredient(
                    name: "Greek Yogurt",
                    quantity: 150,
                    unit: .gram,
                    baseCalories: 97,
                    baseProtein: 17,
                    baseCarbs: 3.6,
                    baseFat: 0.7
                ),
                RecipeIngredient(
                    name: "Banana",
                    quantity: 100,
                    unit: .gram,
                    baseCalories: 89,
                    baseProtein: 1.1,
                    baseCarbs: 23,
                    baseFat: 0.3
                )
            ],
            servings: 1,
            prepTime: 5,
            instructions: [
                "Add yogurt to a bowl",
                "Slice banana and add on top",
                "Drizzle with honey"
            ],
            category: .breakfast,
            isFavorite: true
        ),
        onToggleFavorite: {},
        onDelete: {}
    )
}
