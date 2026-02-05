import SwiftUI
import SwiftData

/// Meal Detail View
/// Full-screen sheet showing complete meal information with photo, nutrition, and food items

struct MealDetailView: View {
    let meal: Meal
    let onDelete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var showingDeleteConfirmation = false
    @State private var showingLogAgainSheet = false
    @State private var selectedMealType: MealType?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Hero photo section
                    heroPhotoSection

                    VStack(spacing: FuelSpacing.sectionSpacing) {
                        // Meal info header
                        mealInfoHeader

                        // Nutrition section
                        nutritionSection

                        // Food items list
                        foodItemsSection

                        // Log again button
                        logAgainButton

                        // Delete button
                        deleteButton
                    }
                    .padding(.horizontal, FuelSpacing.screenHorizontal)
                    .padding(.bottom, FuelSpacing.screenBottom)
                }
            }
            .scrollIndicators(.hidden)
            .background(FuelColors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(FuelColors.textSecondary)
                            .frame(width: 32, height: 32)
                            .background(FuelColors.surface)
                            .clipShape(Circle())
                    }
                }
            }
        }
        .confirmationDialog(
            "Delete Meal",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                onDelete()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this meal? This action cannot be undone.")
        }
        .sheet(isPresented: $showingLogAgainSheet) {
            LogAgainSheet(
                meal: meal,
                onLog: { mealType in
                    logMealAgain(to: mealType)
                }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Hero Photo Section

    @ViewBuilder
    private var heroPhotoSection: some View {
        ZStack(alignment: .bottomLeading) {
            // Photo
            mealPhotoView
                .frame(height: 280)
                .clipped()

            // Gradient overlay
            LinearGradient(
                colors: [.clear, .black.opacity(0.6)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 120)
            .frame(maxHeight: .infinity, alignment: .bottom)

            // Meal type badge
            HStack(spacing: FuelSpacing.xs) {
                Image(systemName: meal.mealType.icon)
                    .font(.system(size: 14, weight: .semibold))
                Text(meal.mealType.displayName)
                    .font(FuelTypography.subheadlineMedium)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, FuelSpacing.sm)
            .padding(.vertical, FuelSpacing.xs)
            .background(.ultraThinMaterial.opacity(0.8))
            .clipShape(Capsule())
            .padding(FuelSpacing.md)
        }
    }

    @ViewBuilder
    private var mealPhotoView: some View {
        if let thumbnailData = meal.photoThumbnailData,
           let uiImage = UIImage(data: thumbnailData) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else if let localPath = meal.photoLocalPath {
            AsyncImage(url: URL(fileURLWithPath: localPath)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    placeholderPhoto
                case .empty:
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(FuelColors.surfaceSecondary)
                @unknown default:
                    placeholderPhoto
                }
            }
        } else if let urlString = meal.photoURL,
                  let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    placeholderPhoto
                case .empty:
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(FuelColors.surfaceSecondary)
                @unknown default:
                    placeholderPhoto
                }
            }
        } else {
            placeholderPhoto
        }
    }

    private var placeholderPhoto: some View {
        ZStack {
            FuelColors.surfaceSecondary

            VStack(spacing: FuelSpacing.sm) {
                Image(systemName: "fork.knife.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(FuelColors.textTertiary)

                Text("No photo")
                    .font(FuelTypography.caption)
                    .foregroundStyle(FuelColors.textTertiary)
            }
        }
    }

    // MARK: - Meal Info Header

    private var mealInfoHeader: some View {
        VStack(alignment: .leading, spacing: FuelSpacing.xs) {
            // Time logged
            HStack(spacing: FuelSpacing.xs) {
                Image(systemName: "clock")
                    .font(.system(size: 12))
                Text(meal.displayDate)
                Text("at")
                Text(meal.displayTime)
            }
            .font(FuelTypography.caption)
            .foregroundStyle(FuelColors.textSecondary)

            // Food summary
            if let items = meal.foodItems, !items.isEmpty {
                Text(items.map { $0.name }.joined(separator: ", "))
                    .font(FuelTypography.body)
                    .foregroundStyle(FuelColors.textPrimary)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, FuelSpacing.lg)
    }

    // MARK: - Nutrition Section

    private var nutritionSection: some View {
        VStack(alignment: .leading, spacing: FuelSpacing.md) {
            sectionHeader(title: "Nutrition", icon: "flame.fill")

            VStack(spacing: FuelSpacing.md) {
                // Calories - Large prominent display
                HStack {
                    VStack(alignment: .leading, spacing: FuelSpacing.xxxs) {
                        Text("Calories")
                            .font(FuelTypography.caption)
                            .foregroundStyle(FuelColors.textSecondary)

                        Text("\(meal.totalCalories)")
                            .font(FuelTypography.heroSmall)
                            .foregroundStyle(FuelColors.textPrimary)
                    }

                    Spacer()

                    // Calorie icon
                    Circle()
                        .fill(FuelColors.primary.opacity(0.1))
                        .frame(width: 56, height: 56)
                        .overlay {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(FuelColors.primary)
                        }
                }
                .padding(FuelSpacing.cardPadding)
                .background(FuelColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusLg))

                // Macros grid
                HStack(spacing: FuelSpacing.sm) {
                    macroCard(
                        label: "Protein",
                        value: meal.totalProtein,
                        unit: "g",
                        color: FuelColors.protein
                    )

                    macroCard(
                        label: "Carbs",
                        value: meal.totalCarbs,
                        unit: "g",
                        color: FuelColors.carbs
                    )

                    macroCard(
                        label: "Fat",
                        value: meal.totalFat,
                        unit: "g",
                        color: FuelColors.fat
                    )
                }

                // Additional nutrients (if available)
                if hasAdditionalNutrients {
                    HStack(spacing: FuelSpacing.sm) {
                        if let fiber = meal.totalFiber {
                            microNutrientPill(label: "Fiber", value: fiber, unit: "g")
                        }
                        if let sugar = meal.totalSugar {
                            microNutrientPill(label: "Sugar", value: sugar, unit: "g")
                        }
                        if let sodium = meal.totalSodium {
                            microNutrientPill(label: "Sodium", value: sodium, unit: "mg")
                        }
                        Spacer()
                    }
                }
            }
        }
    }

    private var hasAdditionalNutrients: Bool {
        meal.totalFiber != nil || meal.totalSugar != nil || meal.totalSodium != nil
    }

    private func macroCard(label: String, value: Double, unit: String, color: Color) -> some View {
        VStack(spacing: FuelSpacing.xs) {
            Circle()
                .fill(color.opacity(0.15))
                .frame(width: 40, height: 40)
                .overlay {
                    Text("\(Int(value))")
                        .font(FuelTypography.headline)
                        .foregroundStyle(color)
                }

            Text(label)
                .font(FuelTypography.caption)
                .foregroundStyle(FuelColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, FuelSpacing.md)
        .background(FuelColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
    }

    private func microNutrientPill(label: String, value: Double, unit: String) -> some View {
        HStack(spacing: FuelSpacing.xxs) {
            Text(label)
                .foregroundStyle(FuelColors.textSecondary)
            Text("\(Int(value))\(unit)")
                .foregroundStyle(FuelColors.textPrimary)
        }
        .font(FuelTypography.caption)
        .padding(.horizontal, FuelSpacing.sm)
        .padding(.vertical, FuelSpacing.xs)
        .background(FuelColors.surface)
        .clipShape(Capsule())
    }

    // MARK: - Food Items Section

    private var foodItemsSection: some View {
        VStack(alignment: .leading, spacing: FuelSpacing.md) {
            sectionHeader(title: "Food Items", icon: "list.bullet")

            if let items = meal.foodItems, !items.isEmpty {
                VStack(spacing: 0) {
                    ForEach(items) { item in
                        foodItemRow(item)

                        if item.id != items.last?.id {
                            Divider()
                                .padding(.leading, FuelSpacing.md + 44 + FuelSpacing.md)
                        }
                    }
                }
                .background(FuelColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
            } else {
                emptyFoodItemsView
            }
        }
    }

    private func foodItemRow(_ item: FoodItem) -> some View {
        HStack(spacing: FuelSpacing.md) {
            // Food icon
            Circle()
                .fill(FuelColors.surfaceSecondary)
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: item.source.icon)
                        .font(.system(size: 16))
                        .foregroundStyle(FuelColors.textTertiary)
                }

            // Food details
            VStack(alignment: .leading, spacing: FuelSpacing.xxxs) {
                Text(item.name)
                    .font(FuelTypography.body)
                    .foregroundStyle(FuelColors.textPrimary)
                    .lineLimit(1)

                Text(item.fullDisplayServing)
                    .font(FuelTypography.caption)
                    .foregroundStyle(FuelColors.textTertiary)
            }

            Spacer()

            // Nutrition
            VStack(alignment: .trailing, spacing: FuelSpacing.xxxs) {
                Text("\(item.calories) cal")
                    .font(FuelTypography.subheadlineMedium)
                    .foregroundStyle(FuelColors.textPrimary)

                HStack(spacing: FuelSpacing.xs) {
                    Text("\(Int(item.protein))P")
                        .foregroundStyle(FuelColors.protein)
                    Text("\(Int(item.carbs))C")
                        .foregroundStyle(FuelColors.carbs)
                    Text("\(Int(item.fat))F")
                        .foregroundStyle(FuelColors.fat)
                }
                .font(.system(size: 10, weight: .medium))
            }
        }
        .padding(FuelSpacing.md)
    }

    private var emptyFoodItemsView: some View {
        VStack(spacing: FuelSpacing.sm) {
            Image(systemName: "tray")
                .font(.system(size: 32))
                .foregroundStyle(FuelColors.textTertiary)

            Text("No food items")
                .font(FuelTypography.body)
                .foregroundStyle(FuelColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, FuelSpacing.xxl)
        .background(FuelColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
    }

    // MARK: - Log Again Button

    private var logAgainButton: some View {
        Button {
            FuelHaptics.shared.tap()
            showingLogAgainSheet = true
        } label: {
            HStack(spacing: FuelSpacing.sm) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
                Text("Log Again Today")
                    .font(FuelTypography.headline)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, FuelSpacing.buttonPaddingV)
            .background(FuelColors.primary)
            .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
        }
    }

    // MARK: - Log Meal Again

    private func logMealAgain(to mealType: MealType) {
        guard let foodItems = meal.foodItems, !foodItems.isEmpty else { return }

        // Create copies of all food items and add to today's meal
        for item in foodItems {
            let newFoodItem = FoodItem(
                name: item.name,
                servingSize: item.servingSize,
                servingUnit: item.servingUnit,
                numberOfServings: item.numberOfServings,
                calories: item.caloriesPerServing,
                protein: item.proteinPerServing,
                carbs: item.carbsPerServing,
                fat: item.fatPerServing,
                source: item.source
            )

            // Copy additional nutrition data
            newFoodItem.fiberPerServing = item.fiberPerServing
            newFoodItem.sugarPerServing = item.sugarPerServing
            newFoodItem.sodiumPerServing = item.sodiumPerServing
            newFoodItem.brandName = item.brandName
            newFoodItem.barcode = item.barcode

            MealService.shared.addFoodItem(newFoodItem, to: mealType, date: Date(), in: modelContext)
        }

        FuelHaptics.shared.success()
        dismiss()
    }

    // MARK: - Delete Button

    private var deleteButton: some View {
        Button {
            FuelHaptics.shared.warning()
            showingDeleteConfirmation = true
        } label: {
            HStack(spacing: FuelSpacing.sm) {
                Image(systemName: "trash")
                    .font(.system(size: 16, weight: .semibold))
                Text("Delete Meal")
                    .font(FuelTypography.headline)
            }
            .foregroundStyle(FuelColors.error)
            .frame(maxWidth: .infinity)
            .padding(.vertical, FuelSpacing.buttonPaddingV)
            .background(FuelColors.error.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
        }
        .padding(.top, FuelSpacing.lg)
    }

    // MARK: - Section Header

    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: FuelSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(FuelColors.textTertiary)

            Text(title)
                .font(FuelTypography.caption)
                .fontWeight(.semibold)
                .foregroundStyle(FuelColors.textTertiary)
                .textCase(.uppercase)
                .tracking(0.5)

            Spacer()
        }
    }
}

// MARK: - Log Again Sheet

struct LogAgainSheet: View {
    let meal: Meal
    let onLog: (MealType) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedMealType: MealType

    init(meal: Meal, onLog: @escaping (MealType) -> Void) {
        self.meal = meal
        self.onLog = onLog
        // Default to same meal type or time-based
        self._selectedMealType = State(initialValue: Self.defaultMealType(from: meal))
    }

    private static func defaultMealType(from meal: Meal) -> MealType {
        // Use the original meal type by default
        return meal.mealType
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: FuelSpacing.lg) {
                // Header info
                VStack(spacing: FuelSpacing.sm) {
                    Image(systemName: "arrow.clockwise.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(FuelColors.primary)

                    Text("Log This Meal Again")
                        .font(FuelTypography.title3)
                        .foregroundStyle(FuelColors.textPrimary)

                    Text("\(meal.foodItems?.count ?? 0) items • \(meal.totalCalories) cal")
                        .font(FuelTypography.subheadline)
                        .foregroundStyle(FuelColors.textSecondary)
                }
                .padding(.top, FuelSpacing.lg)

                // Meal type selector
                VStack(alignment: .leading, spacing: FuelSpacing.sm) {
                    Text("ADD TO")
                        .font(FuelTypography.caption)
                        .foregroundStyle(FuelColors.textTertiary)
                        .padding(.horizontal, FuelSpacing.screenHorizontal)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: FuelSpacing.sm) {
                            ForEach(MealType.allCases, id: \.self) { mealType in
                                mealTypeButton(mealType)
                            }
                        }
                        .padding(.horizontal, FuelSpacing.screenHorizontal)
                    }
                }

                Spacer()

                // Confirm button
                VStack(spacing: FuelSpacing.md) {
                    FuelButton("Add to \(selectedMealType.displayName)", style: .primary) {
                        onLog(selectedMealType)
                    }

                    Button("Cancel") {
                        dismiss()
                    }
                    .font(FuelTypography.body)
                    .foregroundStyle(FuelColors.textSecondary)
                }
                .padding(.horizontal, FuelSpacing.screenHorizontal)
                .padding(.bottom, FuelSpacing.lg)
            }
            .background(FuelColors.background)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func mealTypeButton(_ mealType: MealType) -> some View {
        Button {
            selectedMealType = mealType
            FuelHaptics.shared.select()
        } label: {
            VStack(spacing: FuelSpacing.sm) {
                ZStack {
                    Circle()
                        .fill(selectedMealType == mealType ? FuelColors.primary : FuelColors.surfaceSecondary)
                        .frame(width: 56, height: 56)

                    Image(systemName: mealType.icon)
                        .font(.system(size: 22))
                        .foregroundStyle(selectedMealType == mealType ? .white : FuelColors.textSecondary)
                }

                Text(mealType.displayName)
                    .font(FuelTypography.caption)
                    .foregroundStyle(selectedMealType == mealType ? FuelColors.primary : FuelColors.textSecondary)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    MealDetailView(
        meal: Meal(mealType: .lunch, loggedAt: Date()),
        onDelete: {}
    )
}
