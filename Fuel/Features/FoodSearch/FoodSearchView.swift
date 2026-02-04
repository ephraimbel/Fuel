import SwiftUI

/// Food Search View
/// Main interface for searching and selecting foods to add to meals

struct FoodSearchView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel = FoodSearchViewModel()
    @State private var selectedFood: FoodSearchItem?
    @State private var showingFoodDetail = false
    @State private var showingScanner = false

    let mealType: MealType
    let onFoodAdded: (FoodItem) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                FuelColors.background
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search bar
                    searchBar

                    // Content
                    if viewModel.isSearching && !viewModel.hasSearched {
                        loadingView
                    } else if viewModel.hasSearched {
                        searchResultsView
                    } else {
                        recentAndSuggestionsView
                    }
                }
            }
            .navigationTitle("Add Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        FuelHaptics.shared.tap()
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        FuelHaptics.shared.tap()
                        showingScanner = true
                    } label: {
                        Image(systemName: "barcode.viewfinder")
                    }
                }
            }
            .sheet(isPresented: $showingFoodDetail) {
                if let food = selectedFood {
                    FoodDetailSheet(
                        food: food,
                        mealType: mealType,
                        onAdd: { foodItem in
                            viewModel.saveRecentFood(food)
                            onFoodAdded(foodItem)
                            showingFoodDetail = false
                            dismiss()
                        }
                    )
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                }
            }
            .fullScreenCover(isPresented: $showingScanner) {
                BarcodeScannerView()
            }
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: FuelSpacing.sm) {
            HStack(spacing: FuelSpacing.sm) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(FuelColors.textTertiary)

                TextField("Search foods...", text: $viewModel.searchText)
                    .font(FuelTypography.body)
                    .foregroundStyle(FuelColors.textPrimary)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .submitLabel(.search)
                    .onSubmit {
                        viewModel.search()
                    }
                    .onChange(of: viewModel.searchText) { _, _ in
                        viewModel.search()
                    }

                if !viewModel.searchText.isEmpty {
                    Button {
                        viewModel.reset()
                        FuelHaptics.shared.tap()
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
        .padding(.horizontal, FuelSpacing.screenHorizontal)
        .padding(.vertical, FuelSpacing.sm)
        .background(FuelColors.background)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: FuelSpacing.lg) {
            Spacer()

            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: FuelColors.primary))
                .scaleEffect(1.2)

            Text("Searching foods...")
                .font(FuelTypography.subheadline)
                .foregroundStyle(FuelColors.textSecondary)

            Spacer()
        }
    }

    // MARK: - Search Results

    private var searchResultsView: some View {
        Group {
            if viewModel.searchResults.isEmpty {
                emptyResultsView
            } else {
                resultsList
            }
        }
    }

    private var emptyResultsView: some View {
        VStack(spacing: FuelSpacing.lg) {
            Spacer()

            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundStyle(FuelColors.textTertiary)

            VStack(spacing: FuelSpacing.sm) {
                Text("No Results")
                    .font(FuelTypography.headline)
                    .foregroundStyle(FuelColors.textPrimary)

                Text("Try a different search term or scan a barcode")
                    .font(FuelTypography.body)
                    .foregroundStyle(FuelColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            // Quick add button
            Button {
                // TODO: Show quick add
                FuelHaptics.shared.tap()
            } label: {
                HStack(spacing: FuelSpacing.sm) {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Custom Food")
                }
                .font(FuelTypography.subheadlineMedium)
                .foregroundStyle(FuelColors.primary)
            }

            Spacer()
        }
        .padding(.horizontal, FuelSpacing.xl)
    }

    private var resultsList: some View {
        ScrollView {
            LazyVStack(spacing: FuelSpacing.sm) {
                // Results count
                HStack {
                    Text("\(viewModel.searchResults.count) results")
                        .font(FuelTypography.caption)
                        .foregroundStyle(FuelColors.textTertiary)

                    Spacer()
                }
                .padding(.horizontal, FuelSpacing.screenHorizontal)
                .padding(.top, FuelSpacing.sm)

                // Results
                ForEach(viewModel.searchResults) { food in
                    FoodSearchResultRow(food: food) {
                        selectedFood = food
                        showingFoodDetail = true
                        FuelHaptics.shared.tap()
                    }
                    .padding(.horizontal, FuelSpacing.screenHorizontal)
                }

                // Load more indicator
                if viewModel.hasMoreResults {
                    if viewModel.isLoadingMore {
                        ProgressView()
                            .padding()
                    } else {
                        Color.clear
                            .frame(height: 1)
                            .onAppear {
                                viewModel.loadMoreResults()
                            }
                    }
                }
            }
            .padding(.bottom, FuelSpacing.xl)
        }
    }

    // MARK: - Recent and Suggestions

    private var recentAndSuggestionsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: FuelSpacing.xl) {
                // Quick actions
                quickActionsSection

                // Recent searches
                if !viewModel.recentSearches.isEmpty {
                    recentSearchesSection
                }

                // Recent foods
                if !viewModel.recentFoods.isEmpty {
                    recentFoodsSection
                }

                // Empty state
                if viewModel.recentSearches.isEmpty && viewModel.recentFoods.isEmpty {
                    emptyStateView
                }
            }
            .padding(.vertical, FuelSpacing.lg)
        }
    }

    // MARK: - Quick Actions

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: FuelSpacing.md) {
            Text("QUICK ADD")
                .font(FuelTypography.caption)
                .foregroundStyle(FuelColors.textTertiary)
                .padding(.horizontal, FuelSpacing.screenHorizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: FuelSpacing.sm) {
                    quickActionButton(
                        title: "Scan Barcode",
                        icon: "barcode.viewfinder",
                        color: FuelColors.primary
                    ) {
                        showingScanner = true
                    }

                    quickActionButton(
                        title: "Scan Food",
                        icon: "camera.fill",
                        color: FuelColors.secondary
                    ) {
                        // TODO: Show camera
                    }

                    quickActionButton(
                        title: "Quick Calories",
                        icon: "bolt.fill",
                        color: FuelColors.gold
                    ) {
                        // TODO: Show quick add
                    }

                    quickActionButton(
                        title: "Create Food",
                        icon: "plus",
                        color: FuelColors.textSecondary
                    ) {
                        // TODO: Show create food
                    }
                }
                .padding(.horizontal, FuelSpacing.screenHorizontal)
            }
        }
    }

    private func quickActionButton(
        title: String,
        icon: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            FuelHaptics.shared.tap()
            action()
        } label: {
            VStack(spacing: FuelSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundStyle(color)
                    .frame(width: 50, height: 50)
                    .background(color.opacity(0.15))
                    .clipShape(Circle())

                Text(title)
                    .font(FuelTypography.caption)
                    .foregroundStyle(FuelColors.textSecondary)
            }
            .frame(width: 80)
        }
    }

    // MARK: - Recent Searches

    private var recentSearchesSection: some View {
        VStack(alignment: .leading, spacing: FuelSpacing.md) {
            HStack {
                Text("RECENT SEARCHES")
                    .font(FuelTypography.caption)
                    .foregroundStyle(FuelColors.textTertiary)

                Spacer()

                Button {
                    viewModel.clearRecentSearches()
                    FuelHaptics.shared.tap()
                } label: {
                    Text("Clear")
                        .font(FuelTypography.caption)
                        .foregroundStyle(FuelColors.primary)
                }
            }
            .padding(.horizontal, FuelSpacing.screenHorizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: FuelSpacing.sm) {
                    ForEach(viewModel.recentSearches, id: \.self) { query in
                        Button {
                            viewModel.selectRecentSearch(query)
                            FuelHaptics.shared.tap()
                        } label: {
                            HStack(spacing: FuelSpacing.xs) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.system(size: 12))

                                Text(query)
                                    .font(FuelTypography.subheadline)
                            }
                            .foregroundStyle(FuelColors.textSecondary)
                            .padding(.horizontal, FuelSpacing.md)
                            .padding(.vertical, FuelSpacing.sm)
                            .background(FuelColors.surface)
                            .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal, FuelSpacing.screenHorizontal)
            }
        }
    }

    // MARK: - Recent Foods

    private var recentFoodsSection: some View {
        VStack(alignment: .leading, spacing: FuelSpacing.md) {
            HStack {
                Text("RECENT FOODS")
                    .font(FuelTypography.caption)
                    .foregroundStyle(FuelColors.textTertiary)

                Spacer()

                Button {
                    viewModel.clearRecentFoods()
                    FuelHaptics.shared.tap()
                } label: {
                    Text("Clear")
                        .font(FuelTypography.caption)
                        .foregroundStyle(FuelColors.primary)
                }
            }
            .padding(.horizontal, FuelSpacing.screenHorizontal)

            VStack(spacing: FuelSpacing.sm) {
                ForEach(viewModel.recentFoods.prefix(5)) { food in
                    FoodSearchResultRow(food: food) {
                        selectedFood = food
                        showingFoodDetail = true
                        FuelHaptics.shared.tap()
                    }
                    .padding(.horizontal, FuelSpacing.screenHorizontal)
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: FuelSpacing.lg) {
            Image(systemName: "fork.knife")
                .font(.system(size: 50))
                .foregroundStyle(FuelColors.textTertiary)

            VStack(spacing: FuelSpacing.sm) {
                Text("Search for Foods")
                    .font(FuelTypography.headline)
                    .foregroundStyle(FuelColors.textPrimary)

                Text("Find foods by name, brand, or scan a barcode")
                    .font(FuelTypography.body)
                    .foregroundStyle(FuelColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, FuelSpacing.xl)
        .padding(.top, FuelSpacing.xxl)
    }
}

// MARK: - Preview

#Preview {
    FoodSearchView(mealType: .lunch) { _ in }
}
