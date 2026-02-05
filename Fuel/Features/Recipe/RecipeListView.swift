import SwiftUI

/// Recipe List View
/// Shows all user recipes with search and filtering

struct RecipeListView: View {
    @State private var viewModel = RecipeViewModel()
    @State private var showingCreateRecipe = false
    @State private var selectedRecipe: Recipe? = nil
    @State private var showRecipePaywall = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: FuelSpacing.sectionSpacing) {
                    // Search and filter section
                    VStack(spacing: FuelSpacing.md) {
                        searchBar
                        categoryFilter
                    }

                    // Favorites section
                    if !viewModel.favoriteRecipes.isEmpty && viewModel.selectedCategory == nil && viewModel.searchText.isEmpty {
                        favoritesSection
                    }

                    // All recipes
                    recipesSection
                }
                .padding(.horizontal, FuelSpacing.screenHorizontal)
                .padding(.bottom, FuelSpacing.screenBottom + 80) // Tab bar space
            }
            .scrollIndicators(.hidden)
            .background(FuelColors.background)
            .navigationTitle("Recipes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        // Check recipe limit before allowing creation
                        if FeatureGateService.shared.canSaveRecipe(currentCount: viewModel.recipes.count) {
                            showingCreateRecipe = true
                            FuelHaptics.shared.tap()
                        } else {
                            FuelHaptics.shared.error()
                            showRecipePaywall = true
                        }
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
            }
            .sheet(isPresented: $showingCreateRecipe) {
                CreateRecipeView { recipe in
                    let result = viewModel.addRecipe(recipe)
                    if result == .limitReached {
                        showRecipePaywall = true
                    }
                }
            }
            .fullScreenCover(isPresented: $showRecipePaywall) {
                PaywallView(context: .recipeLimit)
            }
            .sheet(item: $selectedRecipe) { recipe in
                RecipeDetailView(recipe: recipe) {
                    viewModel.toggleFavorite(recipe)
                } onDelete: {
                    viewModel.deleteRecipe(recipe)
                    selectedRecipe = nil
                }
            }
            .refreshable {
                viewModel.loadRecipes()
            }
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: FuelSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(FuelColors.textTertiary)

            TextField("Search recipes...", text: $viewModel.searchText)
                .font(FuelTypography.body)
                .foregroundStyle(FuelColors.textPrimary)

            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(FuelColors.textTertiary)
                }
            }
        }
        .padding(FuelSpacing.sm)
        .background(FuelColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
    }

    // MARK: - Category Filter

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: FuelSpacing.sm) {
                // All button
                categoryButton(nil, label: "All")

                ForEach(RecipeCategory.allCases, id: \.self) { category in
                    categoryButton(category, label: category.displayName)
                }
            }
        }
    }

    private func categoryButton(_ category: RecipeCategory?, label: String) -> some View {
        let isSelected = viewModel.selectedCategory == category

        return Button {
            viewModel.selectCategory(category)
        } label: {
            HStack(spacing: FuelSpacing.xs) {
                if let category = category {
                    Image(systemName: category.icon)
                        .font(.system(size: 12))
                }

                Text(label)
                    .font(FuelTypography.subheadlineMedium)
            }
            .foregroundStyle(isSelected ? .white : FuelColors.textSecondary)
            .padding(.horizontal, FuelSpacing.md)
            .padding(.vertical, FuelSpacing.sm)
            .background(isSelected ? FuelColors.primary : FuelColors.surface)
            .clipShape(Capsule())
        }
    }

    // MARK: - Section Header

    private func sectionHeader(title: String, icon: String, iconColor: Color = FuelColors.textTertiary) -> some View {
        HStack(spacing: FuelSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(iconColor)

            Text(title)
                .font(FuelTypography.caption)
                .fontWeight(.semibold)
                .foregroundStyle(FuelColors.textTertiary)
                .textCase(.uppercase)
                .tracking(0.5)

            Spacer()
        }
        .padding(.bottom, FuelSpacing.xs)
    }

    // MARK: - Favorites Section

    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader(title: "Favorites", icon: "heart.fill", iconColor: FuelColors.error)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: FuelSpacing.md) {
                    ForEach(viewModel.favoriteRecipes, id: \.id) { recipe in
                        FavoriteRecipeCard(recipe: recipe) {
                            selectedRecipe = recipe
                        }
                    }
                }
            }
        }
    }

    // MARK: - Recipes Section

    private var recipesSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                sectionHeader(
                    title: viewModel.selectedCategory?.displayName ?? "All Recipes",
                    icon: "book.fill"
                )

                Spacer()

                Text("\(viewModel.filteredRecipes.count) recipes")
                    .font(FuelTypography.caption)
                    .foregroundStyle(FuelColors.textTertiary)
            }

            if viewModel.filteredRecipes.isEmpty {
                emptyState
            } else {
                LazyVStack(spacing: FuelSpacing.cardSpacing) {
                    ForEach(viewModel.filteredRecipes, id: \.id) { recipe in
                        RecipeCard(recipe: recipe) {
                            selectedRecipe = recipe
                        }
                    }
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: FuelSpacing.lg) {
            Image(systemName: "book.closed")
                .font(.system(size: 48))
                .foregroundStyle(FuelColors.textTertiary)

            VStack(spacing: FuelSpacing.sm) {
                Text("No Recipes Yet")
                    .font(FuelTypography.headline)
                    .foregroundStyle(FuelColors.textPrimary)

                Text("Create your first recipe to track the nutrition of your favorite meals.")
                    .font(FuelTypography.body)
                    .foregroundStyle(FuelColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                showingCreateRecipe = true
                FuelHaptics.shared.tap()
            } label: {
                HStack(spacing: FuelSpacing.sm) {
                    Image(systemName: "plus")
                    Text("Create Recipe")
                }
                .font(FuelTypography.subheadlineMedium)
                .foregroundStyle(.white)
                .padding(.horizontal, FuelSpacing.lg)
                .padding(.vertical, FuelSpacing.md)
                .background(FuelColors.primary)
                .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, FuelSpacing.xxl)
    }
}

// MARK: - Recipe Card

struct RecipeCard: View {
    let recipe: Recipe
    let onTap: () -> Void

    var body: some View {
        Button {
            onTap()
            FuelHaptics.shared.tap()
        } label: {
            HStack(spacing: FuelSpacing.md) {
                // Image or placeholder
                recipeImage

                // Info
                VStack(alignment: .leading, spacing: FuelSpacing.xs) {
                    HStack {
                        Text(recipe.name)
                            .font(FuelTypography.subheadlineMedium)
                            .foregroundStyle(FuelColors.textPrimary)
                            .lineLimit(1)

                        if recipe.isFavorite {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(FuelColors.error)
                        }
                    }

                    HStack(spacing: FuelSpacing.sm) {
                        // Category badge
                        HStack(spacing: FuelSpacing.xxxs) {
                            Image(systemName: recipe.category.icon)
                                .font(.system(size: 10))
                            Text(recipe.category.displayName)
                                .font(FuelTypography.caption)
                        }
                        .foregroundStyle(recipe.category.color)

                        // Time
                        if let time = recipe.formattedTotalTime {
                            HStack(spacing: FuelSpacing.xxxs) {
                                Image(systemName: "clock")
                                    .font(.system(size: 10))
                                Text(time)
                                    .font(FuelTypography.caption)
                            }
                            .foregroundStyle(FuelColors.textTertiary)
                        }
                    }

                    // Nutrition summary
                    HStack(spacing: FuelSpacing.md) {
                        nutritionLabel("\(recipe.caloriesPerServing)", "cal")
                        nutritionLabel("\(Int(recipe.proteinPerServing))g", "P", FuelColors.protein)
                        nutritionLabel("\(Int(recipe.carbsPerServing))g", "C", FuelColors.carbs)
                        nutritionLabel("\(Int(recipe.fatPerServing))g", "F", FuelColors.fat)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(FuelColors.textTertiary)
            }
            .padding(FuelSpacing.md)
            .background(FuelColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusLg))
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }

    private var recipeImage: some View {
        Group {
            if let imageData = recipe.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: recipe.category.icon)
                    .font(.system(size: 24))
                    .foregroundStyle(recipe.category.color)
            }
        }
        .frame(width: 64, height: 64)
        .background(recipe.category.color.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusSm))
    }

    private func nutritionLabel(_ value: String, _ label: String, _ color: Color = FuelColors.textSecondary) -> some View {
        HStack(spacing: 2) {
            Text(value)
                .font(FuelTypography.captionMedium)
                .foregroundStyle(FuelColors.textPrimary)
            Text(label)
                .font(FuelTypography.caption)
                .foregroundStyle(color)
        }
    }
}

// MARK: - Favorite Recipe Card

struct FavoriteRecipeCard: View {
    let recipe: Recipe
    let onTap: () -> Void

    var body: some View {
        Button {
            onTap()
            FuelHaptics.shared.tap()
        } label: {
            VStack(alignment: .leading, spacing: FuelSpacing.sm) {
                // Image
                ZStack(alignment: .topTrailing) {
                    if let imageData = recipe.imageData, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Image(systemName: recipe.category.icon)
                            .font(.system(size: 32))
                            .foregroundStyle(recipe.category.color)
                    }

                    // Heart badge
                    Image(systemName: "heart.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.white)
                        .padding(FuelSpacing.xs)
                        .background(FuelColors.error)
                        .clipShape(Circle())
                        .padding(FuelSpacing.xs)
                }
                .frame(width: 120, height: 80)
                .background(recipe.category.color.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusSm))

                // Info
                VStack(alignment: .leading, spacing: FuelSpacing.xxxs) {
                    Text(recipe.name)
                        .font(FuelTypography.captionMedium)
                        .foregroundStyle(FuelColors.textPrimary)
                        .lineLimit(1)

                    Text("\(recipe.caloriesPerServing) cal")
                        .font(FuelTypography.caption)
                        .foregroundStyle(FuelColors.textTertiary)
                }
            }
            .frame(width: 120)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    RecipeListView()
}
