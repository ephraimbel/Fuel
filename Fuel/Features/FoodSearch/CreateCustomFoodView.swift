import SwiftUI

/// Create Custom Food View
/// Allows users to manually enter a custom food item

struct CreateCustomFoodView: View {
    @Environment(\.dismiss) private var dismiss

    let mealType: MealType
    let onSave: (FoodItem) -> Void

    @State private var name = ""
    @State private var brand = ""
    @State private var servingSize = "100"
    @State private var servingUnit = "g"
    @State private var calories = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fat = ""
    @State private var fiber = ""
    @State private var sugar = ""

    @State private var showingServingUnitPicker = false
    @FocusState private var focusedField: Field?

    private enum Field {
        case name, brand, servingSize, calories, protein, carbs, fat, fiber, sugar
    }

    private let servingUnits = ["g", "ml", "oz", "cup", "tbsp", "tsp", "piece", "slice", "serving"]

    private var isValid: Bool {
        !name.isEmpty && !calories.isEmpty && (Int(calories) ?? 0) > 0
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: FuelSpacing.lg) {
                    // Basic info section
                    basicInfoSection

                    // Serving section
                    servingSection

                    // Calories section
                    caloriesSection

                    // Macros section
                    macrosSection

                    // Optional section
                    optionalSection
                }
                .padding(FuelSpacing.screenHorizontal)
                .padding(.bottom, FuelSpacing.xxl)
            }
            .background(FuelColors.background)
            .navigationTitle("Create Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        FuelHaptics.shared.tap()
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveFood()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isValid)
                }

                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Next") {
                        focusNextField()
                    }
                    Button("Done") {
                        focusedField = nil
                    }
                }
            }
            .sheet(isPresented: $showingServingUnitPicker) {
                servingUnitPicker
            }
        }
    }

    // MARK: - Basic Info Section

    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: FuelSpacing.sm) {
            Text("BASIC INFO")
                .font(FuelTypography.caption)
                .foregroundStyle(FuelColors.textTertiary)

            VStack(spacing: FuelSpacing.sm) {
                // Name field
                VStack(alignment: .leading, spacing: FuelSpacing.xxs) {
                    Text("Name")
                        .font(FuelTypography.caption)
                        .foregroundStyle(FuelColors.textSecondary)

                    TextField("e.g., Grilled Chicken", text: $name)
                        .font(FuelTypography.body)
                        .focused($focusedField, equals: .name)
                        .textInputAutocapitalization(.words)
                        .padding(FuelSpacing.sm)
                        .background(FuelColors.surfaceSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusSm))
                }

                // Brand field (optional)
                VStack(alignment: .leading, spacing: FuelSpacing.xxs) {
                    HStack {
                        Text("Brand")
                            .font(FuelTypography.caption)
                            .foregroundStyle(FuelColors.textSecondary)

                        Text("(optional)")
                            .font(FuelTypography.caption)
                            .foregroundStyle(FuelColors.textTertiary)
                    }

                    TextField("e.g., Tyson", text: $brand)
                        .font(FuelTypography.body)
                        .focused($focusedField, equals: .brand)
                        .textInputAutocapitalization(.words)
                        .padding(FuelSpacing.sm)
                        .background(FuelColors.surfaceSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusSm))
                }
            }
            .padding(FuelSpacing.md)
            .background(FuelColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
        }
    }

    // MARK: - Serving Section

    private var servingSection: some View {
        VStack(alignment: .leading, spacing: FuelSpacing.sm) {
            Text("SERVING SIZE")
                .font(FuelTypography.caption)
                .foregroundStyle(FuelColors.textTertiary)

            HStack(spacing: FuelSpacing.sm) {
                // Serving size
                VStack(alignment: .leading, spacing: FuelSpacing.xxs) {
                    Text("Amount")
                        .font(FuelTypography.caption)
                        .foregroundStyle(FuelColors.textSecondary)

                    TextField("100", text: $servingSize)
                        .font(FuelTypography.body)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .servingSize)
                        .padding(FuelSpacing.sm)
                        .background(FuelColors.surfaceSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusSm))
                }

                // Serving unit
                VStack(alignment: .leading, spacing: FuelSpacing.xxs) {
                    Text("Unit")
                        .font(FuelTypography.caption)
                        .foregroundStyle(FuelColors.textSecondary)

                    Button {
                        showingServingUnitPicker = true
                        FuelHaptics.shared.tap()
                    } label: {
                        HStack {
                            Text(servingUnit)
                                .font(FuelTypography.body)
                                .foregroundStyle(FuelColors.textPrimary)

                            Spacer()

                            Image(systemName: "chevron.down")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(FuelColors.textTertiary)
                        }
                        .padding(FuelSpacing.sm)
                        .background(FuelColors.surfaceSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusSm))
                    }
                }
            }
            .padding(FuelSpacing.md)
            .background(FuelColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
        }
    }

    // MARK: - Calories Section

    private var caloriesSection: some View {
        VStack(alignment: .leading, spacing: FuelSpacing.sm) {
            Text("CALORIES")
                .font(FuelTypography.caption)
                .foregroundStyle(FuelColors.textTertiary)

            HStack {
                TextField("0", text: $calories)
                    .font(.system(size: 32, weight: .bold))
                    .keyboardType(.numberPad)
                    .focused($focusedField, equals: .calories)
                    .foregroundStyle(FuelColors.primary)

                Spacer()

                Text("calories")
                    .font(FuelTypography.headline)
                    .foregroundStyle(FuelColors.textSecondary)
            }
            .padding(FuelSpacing.md)
            .background(FuelColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
        }
    }

    // MARK: - Macros Section

    private var macrosSection: some View {
        VStack(alignment: .leading, spacing: FuelSpacing.sm) {
            Text("MACROS")
                .font(FuelTypography.caption)
                .foregroundStyle(FuelColors.textTertiary)

            HStack(spacing: FuelSpacing.sm) {
                macroField(title: "Protein", value: $protein, color: FuelColors.protein, field: .protein)
                macroField(title: "Carbs", value: $carbs, color: FuelColors.carbs, field: .carbs)
                macroField(title: "Fat", value: $fat, color: FuelColors.fat, field: .fat)
            }
        }
    }

    private func macroField(title: String, value: Binding<String>, color: Color, field: Field) -> some View {
        VStack(spacing: FuelSpacing.xs) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(title)
                .font(FuelTypography.caption)
                .foregroundStyle(FuelColors.textSecondary)

            HStack(spacing: 2) {
                TextField("0", text: value)
                    .font(FuelTypography.headline)
                    .keyboardType(.decimalPad)
                    .focused($focusedField, equals: field)
                    .multilineTextAlignment(.center)

                Text("g")
                    .font(FuelTypography.caption)
                    .foregroundStyle(FuelColors.textTertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(FuelSpacing.md)
        .background(FuelColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
    }

    // MARK: - Optional Section

    private var optionalSection: some View {
        VStack(alignment: .leading, spacing: FuelSpacing.sm) {
            Text("OPTIONAL")
                .font(FuelTypography.caption)
                .foregroundStyle(FuelColors.textTertiary)

            HStack(spacing: FuelSpacing.sm) {
                optionalField(title: "Fiber", value: $fiber, field: .fiber)
                optionalField(title: "Sugar", value: $sugar, field: .sugar)
            }
        }
    }

    private func optionalField(title: String, value: Binding<String>, field: Field) -> some View {
        VStack(alignment: .leading, spacing: FuelSpacing.xxs) {
            Text(title)
                .font(FuelTypography.caption)
                .foregroundStyle(FuelColors.textSecondary)

            HStack(spacing: 2) {
                TextField("0", text: value)
                    .font(FuelTypography.body)
                    .keyboardType(.decimalPad)
                    .focused($focusedField, equals: field)

                Text("g")
                    .font(FuelTypography.caption)
                    .foregroundStyle(FuelColors.textTertiary)
            }
            .padding(FuelSpacing.sm)
            .background(FuelColors.surfaceSecondary)
            .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusSm))
        }
        .frame(maxWidth: .infinity)
        .padding(FuelSpacing.md)
        .background(FuelColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
    }

    // MARK: - Serving Unit Picker

    private var servingUnitPicker: some View {
        NavigationStack {
            List(servingUnits, id: \.self) { unit in
                Button {
                    servingUnit = unit
                    showingServingUnitPicker = false
                    FuelHaptics.shared.select()
                } label: {
                    HStack {
                        Text(unit)
                            .foregroundStyle(FuelColors.textPrimary)

                        Spacer()

                        if servingUnit == unit {
                            Image(systemName: "checkmark")
                                .foregroundStyle(FuelColors.primary)
                        }
                    }
                }
            }
            .navigationTitle("Select Unit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        showingServingUnitPicker = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Actions

    private func saveFood() {
        guard isValid else { return }

        let foodItem = FoodItem(
            name: name,
            servingSize: Double(servingSize) ?? 100,
            servingUnit: servingUnit,
            numberOfServings: 1,
            calories: Int(calories) ?? 0,
            protein: Double(protein) ?? 0,
            carbs: Double(carbs) ?? 0,
            fat: Double(fat) ?? 0,
            source: .manual
        )

        if !brand.isEmpty {
            foodItem.brandName = brand
        }

        if let fiberValue = Double(fiber), fiberValue > 0 {
            foodItem.fiberPerServing = fiberValue
        }

        if let sugarValue = Double(sugar), sugarValue > 0 {
            foodItem.sugarPerServing = sugarValue
        }

        foodItem.isCustom = true

        FuelHaptics.shared.success()
        onSave(foodItem)
        dismiss()
    }

    private func focusNextField() {
        switch focusedField {
        case .name:
            focusedField = .brand
        case .brand:
            focusedField = .servingSize
        case .servingSize:
            focusedField = .calories
        case .calories:
            focusedField = .protein
        case .protein:
            focusedField = .carbs
        case .carbs:
            focusedField = .fat
        case .fat:
            focusedField = .fiber
        case .fiber:
            focusedField = .sugar
        case .sugar:
            focusedField = nil
        case nil:
            focusedField = .name
        }
    }
}

// MARK: - Preview

#Preview {
    CreateCustomFoodView(mealType: .lunch) { _ in }
}
