import SwiftUI
import SwiftData

/// Previous Meals View
/// Lets users quickly re-log meals they've eaten before

// MARK: - View Model

@Observable
final class PreviousMealsViewModel {
    var recentMeals: [Meal] = []
    var frequentMeals: [Meal] = []
    var isLoading = true
    var selectedMeal: Meal?
    var showMealTypePicker = false

    func loadMeals(in context: ModelContext) {
        isLoading = true
        recentMeals = MealService.shared.getRecentMeals(in: context)
        frequentMeals = MealService.shared.getFrequentMeals(in: context)
        isLoading = false
    }

    func selectMeal(_ meal: Meal) {
        selectedMeal = meal
        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            showMealTypePicker = true
        }
        FuelHaptics.shared.select()
    }

    func cancelSelection() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            showMealTypePicker = false
        }
        selectedMeal = nil
    }

    func logMeal(to mealType: MealType, in context: ModelContext) {
        guard let meal = selectedMeal else { return }
        MealService.shared.logMealAgain(meal, to: mealType, in: context)
        FuelHaptics.shared.success()
    }
}

// MARK: - Previous Meals View

struct PreviousMealsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = PreviousMealsViewModel()

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Group {
                    if viewModel.isLoading {
                        loadingView
                    } else if viewModel.recentMeals.isEmpty && viewModel.frequentMeals.isEmpty {
                        emptyState
                    } else {
                        mealsList
                    }
                }

                // Bottom meal type picker overlay
                if viewModel.showMealTypePicker {
                    mealTypePickerOverlay
                }
            }
            .background(FuelColors.background)
            .navigationTitle("Previous Meals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(FuelColors.textSecondary)
                }
            }
        }
        .onAppear {
            viewModel.loadMeals(in: modelContext)
        }
    }

    // MARK: - Meals List

    private var mealsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Frequently Eaten Section
                if !viewModel.frequentMeals.isEmpty {
                    sectionHeader(title: "Frequently Eaten", icon: "arrow.triangle.2.circlepath")

                    ForEach(viewModel.frequentMeals) { meal in
                        PreviousMealRow(
                            meal: meal,
                            isSelected: viewModel.selectedMeal?.id == meal.id
                        ) {
                            viewModel.selectMeal(meal)
                        }
                    }

                    Spacer().frame(height: FuelSpacing.lg)
                }

                // Recent Meals Section
                if !viewModel.recentMeals.isEmpty {
                    sectionHeader(title: "Recent Meals", icon: "clock")

                    ForEach(viewModel.recentMeals) { meal in
                        PreviousMealRow(
                            meal: meal,
                            isSelected: viewModel.selectedMeal?.id == meal.id
                        ) {
                            viewModel.selectMeal(meal)
                        }
                    }
                }
            }
            .padding(.bottom, viewModel.showMealTypePicker ? 200 : FuelSpacing.screenBottom)
        }
        .scrollIndicators(.hidden)
    }

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
        .padding(.horizontal, FuelSpacing.screenHorizontal)
        .padding(.vertical, FuelSpacing.sm)
    }

    // MARK: - Meal Type Picker Overlay

    private var mealTypePickerOverlay: some View {
        VStack(spacing: 0) {
            // Dimming tap area
            Color.black.opacity(0.001)
                .onTapGesture {
                    viewModel.cancelSelection()
                }

            VStack(spacing: FuelSpacing.md) {
                // Drag handle
                Capsule()
                    .fill(Color(.systemGray4))
                    .frame(width: 36, height: 5)
                    .padding(.top, FuelSpacing.sm)

                // Title
                Text("Add to...")
                    .font(FuelTypography.subheadlineMedium)
                    .foregroundStyle(FuelColors.textSecondary)

                // Meal type buttons
                HStack(spacing: FuelSpacing.sm) {
                    ForEach(MealType.allCases, id: \.self) { mealType in
                        mealTypeButton(mealType)
                    }
                }
                .padding(.horizontal, FuelSpacing.screenHorizontal)
                .padding(.bottom, FuelSpacing.lg)
            }
            .background(
                RoundedRectangle(cornerRadius: FuelSpacing.radiusXxl)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.15), radius: 20, y: -5)
                    .ignoresSafeArea(edges: .bottom)
            )
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private func mealTypeButton(_ mealType: MealType) -> some View {
        Button {
            viewModel.logMeal(to: mealType, in: modelContext)
            dismiss()
        } label: {
            VStack(spacing: FuelSpacing.xs) {
                Image(systemName: mealType.icon)
                    .font(.system(size: 22))
                    .foregroundStyle(FuelColors.primary)
                    .frame(width: 52, height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(FuelColors.primary.opacity(0.1))
                    )

                Text(mealType.displayName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(FuelColors.textPrimary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: FuelSpacing.md) {
            ProgressView()
            Text("Loading meals...")
                .font(FuelTypography.caption)
                .foregroundStyle(FuelColors.textTertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: FuelSpacing.md) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 48))
                .foregroundStyle(FuelColors.textTertiary)

            Text("No Previous Meals")
                .font(FuelTypography.headline)
                .foregroundStyle(FuelColors.textPrimary)

            Text("Meals you log will appear here\nso you can quickly add them again.")
                .font(FuelTypography.subheadline)
                .foregroundStyle(FuelColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, FuelSpacing.screenHorizontal)
    }
}

// MARK: - Previous Meal Row

struct PreviousMealRow: View {
    let meal: Meal
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button {
            onTap()
        } label: {
            HStack(spacing: FuelSpacing.md) {
                // Thumbnail
                mealThumbnail
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusSm))

                // Info
                VStack(alignment: .leading, spacing: FuelSpacing.xxxs) {
                    // Food names
                    Text(foodNames)
                        .font(FuelTypography.subheadlineMedium)
                        .foregroundStyle(FuelColors.textPrimary)
                        .lineLimit(1)

                    // Item count + relative date
                    HStack(spacing: FuelSpacing.xs) {
                        Text("\(meal.foodItemCount) item\(meal.foodItemCount == 1 ? "" : "s")")
                            .foregroundStyle(FuelColors.textTertiary)

                        Text("·")
                            .foregroundStyle(FuelColors.textTertiary)

                        Text(relativeDate)
                            .foregroundStyle(FuelColors.textTertiary)
                    }
                    .font(FuelTypography.caption)
                }

                Spacer()

                // Calories
                Text("\(meal.totalCalories) cal")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(isSelected ? FuelColors.primary : FuelColors.textPrimary)
            }
            .padding(.horizontal, FuelSpacing.screenHorizontal)
            .padding(.vertical, FuelSpacing.sm)
            .background(isSelected ? FuelColors.primary.opacity(0.08) : .clear)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private var foodNames: String {
        meal.foodItemNames.joined(separator: ", ")
    }

    private var relativeDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: meal.loggedAt, relativeTo: Date())
    }

    @ViewBuilder
    private var mealThumbnail: some View {
        if let thumbnailData = meal.photoThumbnailData,
           let uiImage = UIImage(data: thumbnailData) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            // Gradient placeholder with meal type icon
            LinearGradient(
                colors: [FuelColors.primary.opacity(0.15), FuelColors.primary.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .overlay {
                Image(systemName: meal.mealType.icon)
                    .font(.system(size: 20))
                    .foregroundStyle(FuelColors.primary.opacity(0.5))
            }
        }
    }
}

// MARK: - Preview

#Preview {
    PreviousMealsView()
}
