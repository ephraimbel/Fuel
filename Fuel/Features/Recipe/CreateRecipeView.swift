import SwiftUI
import PhotosUI

/// Create Recipe View
/// Form for creating or editing a recipe

struct CreateRecipeView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: CreateRecipeViewModel
    @State private var showingAddIngredient = false
    @State private var showingPhotoPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var newInstruction = ""

    let onSave: (Recipe) -> Void

    init(recipe: Recipe? = nil, onSave: @escaping (Recipe) -> Void) {
        self._viewModel = State(initialValue: CreateRecipeViewModel(recipe: recipe))
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: FuelSpacing.xl) {
                    // Image section
                    imageSection

                    // Basic info
                    basicInfoSection

                    // Category & servings
                    categoryServingsSection

                    // Time section
                    timeSection

                    // Ingredients section
                    ingredientsSection

                    // Instructions section
                    instructionsSection

                    // Nutrition preview
                    if !viewModel.ingredients.isEmpty {
                        nutritionPreview
                    }
                }
                .padding(.horizontal, FuelSpacing.screenHorizontal)
                .padding(.vertical, FuelSpacing.lg)
            }
            .background(FuelColors.background)
            .navigationTitle(viewModel.isEditing ? "Edit Recipe" : "New Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        let recipe = viewModel.createRecipe()
                        onSave(recipe)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(!viewModel.isValid)
                }
            }
            .sheet(isPresented: $showingAddIngredient) {
                AddIngredientSheet { ingredient in
                    viewModel.addIngredient(ingredient)
                }
            }
            .photosPicker(
                isPresented: $showingPhotoPicker,
                selection: $selectedPhotoItem,
                matching: .images
            )
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        viewModel.imageData = data
                    }
                }
            }
        }
    }

    // MARK: - Image Section

    private var imageSection: some View {
        Button {
            showingPhotoPicker = true
            FuelHaptics.shared.tap()
        } label: {
            ZStack {
                if let imageData = viewModel.imageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
                } else {
                    RoundedRectangle(cornerRadius: FuelSpacing.radiusMd)
                        .fill(FuelColors.surface)
                        .frame(height: 180)
                        .overlay {
                            VStack(spacing: FuelSpacing.sm) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 32))
                                    .foregroundStyle(FuelColors.textTertiary)

                                Text("Add Photo")
                                    .font(FuelTypography.subheadlineMedium)
                                    .foregroundStyle(FuelColors.textSecondary)
                            }
                        }
                }
            }
        }
    }

    // MARK: - Basic Info Section

    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: FuelSpacing.md) {
            sectionHeader("BASIC INFO")

            VStack(spacing: FuelSpacing.sm) {
                // Name
                VStack(alignment: .leading, spacing: FuelSpacing.xs) {
                    Text("Recipe Name")
                        .font(FuelTypography.caption)
                        .foregroundStyle(FuelColors.textSecondary)

                    TextField("e.g. Protein Smoothie Bowl", text: $viewModel.name)
                        .font(FuelTypography.body)
                        .padding(FuelSpacing.md)
                        .background(FuelColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusSm))
                }

                // Description
                VStack(alignment: .leading, spacing: FuelSpacing.xs) {
                    Text("Description (optional)")
                        .font(FuelTypography.caption)
                        .foregroundStyle(FuelColors.textSecondary)

                    TextField("A short description...", text: $viewModel.recipeDescription, axis: .vertical)
                        .font(FuelTypography.body)
                        .lineLimit(3...5)
                        .padding(FuelSpacing.md)
                        .background(FuelColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusSm))
                }
            }
        }
    }

    // MARK: - Category & Servings Section

    private var categoryServingsSection: some View {
        VStack(alignment: .leading, spacing: FuelSpacing.md) {
            sectionHeader("DETAILS")

            HStack(spacing: FuelSpacing.md) {
                // Category picker
                VStack(alignment: .leading, spacing: FuelSpacing.xs) {
                    Text("Category")
                        .font(FuelTypography.caption)
                        .foregroundStyle(FuelColors.textSecondary)

                    Menu {
                        ForEach(RecipeCategory.allCases, id: \.self) { category in
                            Button {
                                viewModel.category = category
                            } label: {
                                Label(category.displayName, systemImage: category.icon)
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: viewModel.category.icon)
                                .foregroundStyle(viewModel.category.color)
                            Text(viewModel.category.displayName)
                                .font(FuelTypography.body)
                                .foregroundStyle(FuelColors.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12))
                                .foregroundStyle(FuelColors.textTertiary)
                        }
                        .padding(FuelSpacing.md)
                        .background(FuelColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusSm))
                    }
                }
                .frame(maxWidth: .infinity)

                // Servings stepper
                VStack(alignment: .leading, spacing: FuelSpacing.xs) {
                    Text("Servings")
                        .font(FuelTypography.caption)
                        .foregroundStyle(FuelColors.textSecondary)

                    HStack {
                        Button {
                            if viewModel.servings > 1 {
                                viewModel.servings -= 1
                                FuelHaptics.shared.tap()
                            }
                        } label: {
                            Image(systemName: "minus")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(viewModel.servings > 1 ? FuelColors.primary : FuelColors.textTertiary)
                                .frame(width: 36, height: 36)
                                .background(FuelColors.surfaceSecondary)
                                .clipShape(Circle())
                        }
                        .disabled(viewModel.servings <= 1)

                        Text("\(viewModel.servings)")
                            .font(FuelTypography.headline)
                            .foregroundStyle(FuelColors.textPrimary)
                            .frame(width: 40)

                        Button {
                            viewModel.servings += 1
                            FuelHaptics.shared.tap()
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(FuelColors.primary)
                                .frame(width: 36, height: 36)
                                .background(FuelColors.surfaceSecondary)
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, FuelSpacing.sm)
                    .padding(.vertical, FuelSpacing.xs)
                    .background(FuelColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusSm))
                }
            }
        }
    }

    // MARK: - Time Section

    private var timeSection: some View {
        VStack(alignment: .leading, spacing: FuelSpacing.md) {
            sectionHeader("TIME (OPTIONAL)")

            HStack(spacing: FuelSpacing.md) {
                // Prep time
                timeInput(
                    label: "Prep",
                    value: Binding(
                        get: { viewModel.prepTime ?? 0 },
                        set: { viewModel.prepTime = $0 > 0 ? $0 : nil }
                    )
                )

                // Cook time
                timeInput(
                    label: "Cook",
                    value: Binding(
                        get: { viewModel.cookTime ?? 0 },
                        set: { viewModel.cookTime = $0 > 0 ? $0 : nil }
                    )
                )
            }
        }
    }

    private func timeInput(label: String, value: Binding<Int>) -> some View {
        VStack(alignment: .leading, spacing: FuelSpacing.xs) {
            Text("\(label) Time")
                .font(FuelTypography.caption)
                .foregroundStyle(FuelColors.textSecondary)

            HStack {
                TextField("0", value: value, format: .number)
                    .font(FuelTypography.body)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)

                Text("min")
                    .font(FuelTypography.caption)
                    .foregroundStyle(FuelColors.textTertiary)
            }
            .padding(FuelSpacing.md)
            .background(FuelColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusSm))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Ingredients Section

    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: FuelSpacing.md) {
            HStack {
                sectionHeader("INGREDIENTS")

                Spacer()

                Button {
                    showingAddIngredient = true
                    FuelHaptics.shared.tap()
                } label: {
                    HStack(spacing: FuelSpacing.xs) {
                        Image(systemName: "plus")
                        Text("Add")
                    }
                    .font(FuelTypography.captionMedium)
                    .foregroundStyle(FuelColors.primary)
                }
            }

            if viewModel.ingredients.isEmpty {
                // Empty state
                VStack(spacing: FuelSpacing.sm) {
                    Image(systemName: "leaf")
                        .font(.system(size: 24))
                        .foregroundStyle(FuelColors.textTertiary)

                    Text("No ingredients added")
                        .font(FuelTypography.caption)
                        .foregroundStyle(FuelColors.textTertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, FuelSpacing.lg)
                .background(FuelColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.ingredients.enumerated()), id: \.element.id) { index, ingredient in
                        IngredientRow(
                            ingredient: ingredient,
                            onDelete: {
                                viewModel.removeIngredient(at: index)
                            }
                        )

                        if index < viewModel.ingredients.count - 1 {
                            Divider()
                                .padding(.leading, FuelSpacing.md)
                        }
                    }
                }
                .background(FuelColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
            }
        }
    }

    // MARK: - Instructions Section

    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: FuelSpacing.md) {
            sectionHeader("INSTRUCTIONS (OPTIONAL)")

            // Add instruction input
            HStack(spacing: FuelSpacing.sm) {
                TextField("Add a step...", text: $newInstruction)
                    .font(FuelTypography.body)
                    .padding(FuelSpacing.md)
                    .background(FuelColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusSm))

                Button {
                    viewModel.addInstruction(newInstruction)
                    newInstruction = ""
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(FuelColors.primary)
                }
                .disabled(newInstruction.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            if !viewModel.instructions.isEmpty {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.instructions.enumerated()), id: \.offset) { index, instruction in
                        InstructionRow(
                            step: index + 1,
                            instruction: instruction,
                            onDelete: {
                                viewModel.removeInstruction(at: index)
                            }
                        )

                        if index < viewModel.instructions.count - 1 {
                            Divider()
                                .padding(.leading, FuelSpacing.md + 32 + FuelSpacing.md)
                        }
                    }
                }
                .background(FuelColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
            }
        }
    }

    // MARK: - Nutrition Preview

    private var nutritionPreview: some View {
        VStack(alignment: .leading, spacing: FuelSpacing.md) {
            sectionHeader("NUTRITION (PER SERVING)")

            HStack(spacing: FuelSpacing.md) {
                nutritionBox("Calories", "\(viewModel.caloriesPerServing)", "cal", FuelColors.primary)
                nutritionBox("Protein", "\(Int(viewModel.totalProtein / Double(viewModel.servings)))", "g", FuelColors.protein)
                nutritionBox("Carbs", "\(Int(viewModel.totalCarbs / Double(viewModel.servings)))", "g", FuelColors.carbs)
                nutritionBox("Fat", "\(Int(viewModel.totalFat / Double(viewModel.servings)))", "g", FuelColors.fat)
            }
        }
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
        .padding(FuelSpacing.md)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusSm))
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(FuelTypography.caption)
            .foregroundStyle(FuelColors.textTertiary)
    }
}

// MARK: - Ingredient Row

struct IngredientRow: View {
    let ingredient: RecipeIngredient
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: FuelSpacing.md) {
            VStack(alignment: .leading, spacing: FuelSpacing.xxxs) {
                Text(ingredient.name)
                    .font(FuelTypography.body)
                    .foregroundStyle(FuelColors.textPrimary)

                Text("\(Int(ingredient.quantity)) \(ingredient.unit.rawValue)")
                    .font(FuelTypography.caption)
                    .foregroundStyle(FuelColors.textTertiary)
            }

            Spacer()

            Text("\(ingredient.calories) cal")
                .font(FuelTypography.captionMedium)
                .foregroundStyle(FuelColors.textSecondary)

            Button {
                onDelete()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(FuelColors.textTertiary)
            }
        }
        .padding(FuelSpacing.md)
    }
}

// MARK: - Instruction Row

struct InstructionRow: View {
    let step: Int
    let instruction: String
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: FuelSpacing.md) {
            // Step number
            Text("\(step)")
                .font(FuelTypography.subheadlineMedium)
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(FuelColors.primary)
                .clipShape(Circle())

            Text(instruction)
                .font(FuelTypography.body)
                .foregroundStyle(FuelColors.textPrimary)

            Spacer()

            Button {
                onDelete()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(FuelColors.textTertiary)
            }
        }
        .padding(FuelSpacing.md)
    }
}

// MARK: - Preview

#Preview {
    CreateRecipeView { _ in }
}
