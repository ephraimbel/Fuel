import SwiftUI

/// Scanned Product Sheet
/// Displays product details after barcode scan with option to add to meal

struct ScannedProductSheet: View {
    let product: ScannedProduct
    let onAdd: (Double, MealType) -> Void
    let onScanAgain: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var numberOfServings: Double = 1.0
    @State private var selectedMealType: MealType = Self.defaultMealType
    @State private var showingNutritionDetails = false

    /// Returns the default meal type based on current time of day
    private static var defaultMealType: MealType {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<11: return .breakfast
        case 11..<15: return .lunch
        case 15..<21: return .dinner
        default: return .snack
        }
    }

    private var adjustedCalories: Int {
        Int(Double(product.calories) * numberOfServings)
    }

    private var adjustedProtein: Double {
        product.protein * numberOfServings
    }

    private var adjustedCarbs: Double {
        product.carbs * numberOfServings
    }

    private var adjustedFat: Double {
        product.fat * numberOfServings
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: FuelSpacing.lg) {
                    // Product header
                    productHeader

                    Divider()
                        .background(FuelColors.border)

                    // Serving size selector
                    servingSizeSection

                    // Meal type selector
                    mealTypeSection

                    // Nutrition summary
                    nutritionSummary

                    // Detailed nutrition
                    if showingNutritionDetails {
                        detailedNutrition
                    }

                    // Toggle details button
                    Button {
                        withAnimation(FuelAnimations.spring) {
                            showingNutritionDetails.toggle()
                        }
                        FuelHaptics.shared.tap()
                    } label: {
                        HStack(spacing: FuelSpacing.xs) {
                            Text(showingNutritionDetails ? "Hide Details" : "Show All Nutrition")
                                .font(FuelTypography.subheadlineMedium)

                            Image(systemName: showingNutritionDetails ? "chevron.up" : "chevron.down")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundStyle(FuelColors.primary)
                    }
                }
                .padding(FuelSpacing.screenHorizontal)
            }
            .background(FuelColors.background)
            .navigationTitle("Product Found")
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
                bottomActions
            }
        }
    }

    // MARK: - Product Header

    private var productHeader: some View {
        HStack(spacing: FuelSpacing.md) {
            // Product image
            if let imageURL = product.imageURL,
               let url = URL(string: imageURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        imagePlaceholder
                    case .empty:
                        ProgressView()
                    @unknown default:
                        imagePlaceholder
                    }
                }
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
            } else {
                imagePlaceholder
            }

            // Product info
            VStack(alignment: .leading, spacing: FuelSpacing.xxs) {
                Text(product.name)
                    .font(FuelTypography.headline)
                    .foregroundStyle(FuelColors.textPrimary)
                    .lineLimit(2)

                if let brand = product.brand {
                    Text(brand)
                        .font(FuelTypography.subheadline)
                        .foregroundStyle(FuelColors.textSecondary)
                }

                HStack(spacing: FuelSpacing.sm) {
                    // Barcode
                    Label(product.barcode, systemImage: "barcode")
                        .font(FuelTypography.caption)
                        .foregroundStyle(FuelColors.textTertiary)

                    // Nutrition grade if available
                    if let grade = product.nutritionGrade?.uppercased() {
                        NutritionGradeBadge(grade: grade)
                    }
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
                Image(systemName: "photo")
                    .font(.system(size: 24))
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
                // Serving info
                VStack(alignment: .leading, spacing: FuelSpacing.xxxs) {
                    Text(product.formattedServingSize)
                        .font(FuelTypography.subheadlineMedium)
                        .foregroundStyle(FuelColors.textPrimary)

                    if let quantity = product.quantity {
                        Text("Package: \(quantity)")
                            .font(FuelTypography.caption)
                            .foregroundStyle(FuelColors.textTertiary)
                    }
                }

                Spacer()

                // Stepper
                HStack(spacing: FuelSpacing.sm) {
                    Button {
                        if numberOfServings > 0.5 {
                            numberOfServings -= 0.5
                            FuelHaptics.shared.select()
                        }
                    } label: {
                        Image(systemName: "minus")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(numberOfServings <= 0.5 ? FuelColors.textTertiary : FuelColors.primary)
                            .frame(width: 36, height: 36)
                            .background(FuelColors.surfaceSecondary)
                            .clipShape(Circle())
                    }
                    .disabled(numberOfServings <= 0.5)

                    Text(formatServings(numberOfServings))
                        .font(FuelTypography.headline)
                        .foregroundStyle(FuelColors.textPrimary)
                        .frame(minWidth: 50)

                    Button {
                        numberOfServings += 0.5
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

    // MARK: - Meal Type Section

    private var mealTypeSection: some View {
        VStack(alignment: .leading, spacing: FuelSpacing.sm) {
            Text("ADD TO")
                .font(FuelTypography.caption)
                .foregroundStyle(FuelColors.textTertiary)

            HStack(spacing: FuelSpacing.sm) {
                ForEach(MealType.allCases, id: \.self) { mealType in
                    Button {
                        selectedMealType = mealType
                        FuelHaptics.shared.select()
                    } label: {
                        HStack(spacing: FuelSpacing.xs) {
                            Image(systemName: mealType.icon)
                                .font(.system(size: 14))
                            Text(mealType.displayName)
                                .font(FuelTypography.caption)
                        }
                        .padding(.horizontal, FuelSpacing.sm)
                        .padding(.vertical, FuelSpacing.xs)
                        .background(selectedMealType == mealType ? FuelColors.primary : FuelColors.surfaceSecondary)
                        .foregroundStyle(selectedMealType == mealType ? .white : FuelColors.textPrimary)
                        .clipShape(Capsule())
                    }
                }
            }
        }
    }

    // MARK: - Nutrition Summary

    private var nutritionSummary: some View {
        VStack(spacing: FuelSpacing.md) {
            // Calories
            HStack {
                Text("Calories")
                    .font(FuelTypography.subheadline)
                    .foregroundStyle(FuelColors.textSecondary)

                Spacer()

                Text("\(adjustedCalories)")
                    .font(FuelTypography.title2)
                    .foregroundStyle(FuelColors.primary)
            }

            // Macros
            HStack(spacing: FuelSpacing.lg) {
                macroItem(label: "Protein", value: adjustedProtein, color: FuelColors.protein)
                macroItem(label: "Carbs", value: adjustedCarbs, color: FuelColors.carbs)
                macroItem(label: "Fat", value: adjustedFat, color: FuelColors.fat)
            }
        }
        .padding(FuelSpacing.md)
        .background(FuelColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
    }

    private func macroItem(label: String, value: Double, color: Color) -> some View {
        VStack(spacing: FuelSpacing.xxs) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text("\(Int(value))g")
                .font(FuelTypography.headline)
                .foregroundStyle(FuelColors.textPrimary)

            Text(label)
                .font(FuelTypography.caption)
                .foregroundStyle(FuelColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Detailed Nutrition

    private var detailedNutrition: some View {
        VStack(spacing: FuelSpacing.sm) {
            nutritionRow(label: "Fiber", value: product.fiber * numberOfServings, unit: "g")
            nutritionRow(label: "Sugar", value: product.sugar * numberOfServings, unit: "g")
            nutritionRow(label: "Sodium", value: product.sodium * numberOfServings, unit: "mg")
        }
        .padding(FuelSpacing.md)
        .background(FuelColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
    }

    private func nutritionRow(label: String, value: Double, unit: String) -> some View {
        HStack {
            Text(label)
                .font(FuelTypography.subheadline)
                .foregroundStyle(FuelColors.textSecondary)

            Spacer()

            Text("\(Int(value))\(unit)")
                .font(FuelTypography.subheadlineMedium)
                .foregroundStyle(FuelColors.textPrimary)
        }
    }

    // MARK: - Bottom Actions

    private var bottomActions: some View {
        VStack(spacing: FuelSpacing.md) {
            Divider()
                .background(FuelColors.border)

            HStack(spacing: FuelSpacing.md) {
                // Scan again button
                Button {
                    FuelHaptics.shared.tap()
                    onScanAgain()
                } label: {
                    Text("Scan Again")
                        .font(FuelTypography.headline)
                        .foregroundStyle(FuelColors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, FuelSpacing.md)
                        .background(FuelColors.surfaceSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
                }

                // Add button
                Button {
                    FuelHaptics.shared.success()
                    onAdd(numberOfServings, selectedMealType)
                } label: {
                    HStack(spacing: FuelSpacing.xs) {
                        Image(systemName: "plus")
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
            .padding(.horizontal, FuelSpacing.screenHorizontal)
            .padding(.bottom, FuelSpacing.md)
        }
        .background(FuelColors.background)
    }

    // MARK: - Helpers

    private func formatServings(_ value: Double) -> String {
        if value == Double(Int(value)) {
            return "\(Int(value))"
        }
        return String(format: "%.1f", value)
    }
}

// MARK: - Nutrition Grade Badge

struct NutritionGradeBadge: View {
    let grade: String

    private var gradeColor: Color {
        switch grade {
        case "A": return Color.green
        case "B": return Color(red: 0.5, green: 0.8, blue: 0.2)
        case "C": return Color.yellow
        case "D": return Color.orange
        case "E": return Color.red
        default: return Color.gray
        }
    }

    var body: some View {
        Text(grade)
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 22, height: 22)
            .background(gradeColor)
            .clipShape(Circle())
    }
}

// MARK: - Preview

#Preview {
    ScannedProductSheet(
        product: ScannedProduct(
            barcode: "0012345678905",
            name: "Organic Greek Yogurt",
            brand: "Chobani",
            imageURL: nil,
            servingSize: 170,
            servingUnit: "g",
            servingSizeDescription: "1 container (170g)",
            calories: 120,
            protein: 15,
            carbs: 8,
            fat: 3,
            fiber: 0,
            sugar: 6,
            sodium: 65,
            nutritionGrade: "A",
            category: "Dairy",
            quantity: "4 x 170g"
        ),
        onAdd: { _, _ in },
        onScanAgain: {}
    )
}
