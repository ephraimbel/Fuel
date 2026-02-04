import SwiftUI

/// Quick Add View
/// Quick entry for calories and optional macros without full food details

struct QuickAddView: View {
    @Environment(\.dismiss) private var dismiss

    let mealType: MealType
    let onAdd: (FoodItem) -> Void

    @State private var calories = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fat = ""
    @State private var description = ""
    @State private var showMacros = false

    @FocusState private var focusedField: Field?

    private enum Field {
        case calories, protein, carbs, fat, description
    }

    private var isValid: Bool {
        (Int(calories) ?? 0) > 0
    }

    private var enteredCalories: Int {
        Int(calories) ?? 0
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: FuelSpacing.lg) {
                // Header
                VStack(spacing: FuelSpacing.sm) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(FuelColors.gold)

                    Text("Quick Add")
                        .font(FuelTypography.title2)
                        .foregroundStyle(FuelColors.textPrimary)

                    Text("Add calories to \(mealType.displayName)")
                        .font(FuelTypography.body)
                        .foregroundStyle(FuelColors.textSecondary)
                }
                .padding(.top, FuelSpacing.lg)

                // Calories input
                caloriesInput

                // Macros toggle
                macrosToggle

                // Macros input
                if showMacros {
                    macrosInput
                }

                // Description
                descriptionInput

                Spacer()

                // Presets
                presetsSection

                // Add button
                addButton
            }
            .padding(FuelSpacing.screenHorizontal)
            .background(FuelColors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        FuelHaptics.shared.tap()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }

                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        focusedField = nil
                    }
                }
            }
        }
    }

    // MARK: - Calories Input

    private var caloriesInput: some View {
        VStack(spacing: FuelSpacing.sm) {
            HStack(alignment: .firstTextBaseline, spacing: FuelSpacing.xs) {
                TextField("0", text: $calories)
                    .font(.system(size: 64, weight: .bold))
                    .keyboardType(.numberPad)
                    .focused($focusedField, equals: .calories)
                    .foregroundStyle(FuelColors.primary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 200)

                Text("cal")
                    .font(FuelTypography.title2)
                    .foregroundStyle(FuelColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, FuelSpacing.lg)
    }

    // MARK: - Macros Toggle

    private var macrosToggle: some View {
        Button {
            withAnimation(FuelAnimations.spring) {
                showMacros.toggle()
            }
            FuelHaptics.shared.tap()
        } label: {
            HStack {
                Text("Add macros")
                    .font(FuelTypography.subheadline)
                    .foregroundStyle(FuelColors.textSecondary)

                Spacer()

                Image(systemName: showMacros ? "chevron.up" : "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(FuelColors.textTertiary)
            }
            .padding(FuelSpacing.md)
            .background(FuelColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
        }
    }

    // MARK: - Macros Input

    private var macrosInput: some View {
        HStack(spacing: FuelSpacing.sm) {
            macroField(title: "Protein", value: $protein, color: FuelColors.protein, field: .protein)
            macroField(title: "Carbs", value: $carbs, color: FuelColors.carbs, field: .carbs)
            macroField(title: "Fat", value: $fat, color: FuelColors.fat, field: .fat)
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

    // MARK: - Description Input

    private var descriptionInput: some View {
        VStack(alignment: .leading, spacing: FuelSpacing.xxs) {
            Text("Note (optional)")
                .font(FuelTypography.caption)
                .foregroundStyle(FuelColors.textTertiary)

            TextField("e.g., Office snack", text: $description)
                .font(FuelTypography.body)
                .focused($focusedField, equals: .description)
                .padding(FuelSpacing.sm)
                .background(FuelColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusSm))
        }
    }

    // MARK: - Presets Section

    private var presetsSection: some View {
        VStack(alignment: .leading, spacing: FuelSpacing.sm) {
            Text("Quick presets")
                .font(FuelTypography.caption)
                .foregroundStyle(FuelColors.textTertiary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: FuelSpacing.sm) {
                    presetButton(value: 100)
                    presetButton(value: 200)
                    presetButton(value: 300)
                    presetButton(value: 500)
                }
            }
        }
    }

    private func presetButton(value: Int) -> some View {
        Button {
            calories = "\(value)"
            FuelHaptics.shared.tap()
        } label: {
            Text("\(value) cal")
                .font(FuelTypography.subheadlineMedium)
                .foregroundStyle(enteredCalories == value ? .white : FuelColors.textSecondary)
                .padding(.horizontal, FuelSpacing.md)
                .padding(.vertical, FuelSpacing.sm)
                .background(enteredCalories == value ? FuelColors.primary : FuelColors.surface)
                .clipShape(Capsule())
        }
    }

    // MARK: - Add Button

    private var addButton: some View {
        Button {
            addFood()
        } label: {
            HStack(spacing: FuelSpacing.sm) {
                Image(systemName: "plus")
                Text("Add \(enteredCalories) Calories")
            }
            .font(FuelTypography.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, FuelSpacing.md)
            .background(isValid ? FuelColors.primary : FuelColors.primary.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
        }
        .disabled(!isValid)
        .padding(.bottom, FuelSpacing.md)
    }

    // MARK: - Actions

    private func addFood() {
        guard isValid else { return }

        let name = description.isEmpty ? "Quick Add (\(enteredCalories) cal)" : description

        let foodItem = FoodItem(
            name: name,
            servingSize: 1,
            servingUnit: "serving",
            numberOfServings: 1,
            calories: enteredCalories,
            protein: Double(protein) ?? 0,
            carbs: Double(carbs) ?? 0,
            fat: Double(fat) ?? 0,
            source: .quickAdd
        )

        FuelHaptics.shared.success()
        onAdd(foodItem)
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    QuickAddView(mealType: .snack) { _ in }
}
