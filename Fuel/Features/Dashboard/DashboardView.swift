import SwiftUI

/// Dashboard View
/// Main home screen showing daily progress, meals, and stats

struct DashboardView: View {
    @State private var viewModel = DashboardViewModel()
    @State private var showingFoodSearch = false
    @State private var selectedMealType: MealType = .breakfast
    @State private var showingDatePicker = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: FuelSpacing.lg) {
                    // Date navigation
                    dateNavigationBar

                    // Daily progress card
                    DailyProgressCard(
                        totalCalories: viewModel.totalCalories,
                        calorieGoal: viewModel.calorieGoal,
                        remainingCalories: viewModel.remainingCalories,
                        calorieProgress: viewModel.calorieProgress,
                        proteinProgress: viewModel.proteinProgress,
                        carbsProgress: viewModel.carbsProgress,
                        fatProgress: viewModel.fatProgress,
                        protein: viewModel.totalProtein,
                        carbs: viewModel.totalCarbs,
                        fat: viewModel.totalFat,
                        proteinGoal: viewModel.proteinGoal,
                        carbsGoal: viewModel.carbsGoal,
                        fatGoal: viewModel.fatGoal,
                        isOverGoal: viewModel.isOverGoal
                    )

                    // Streak card (only show if streak > 0)
                    if viewModel.currentStreak > 0 {
                        StreakCard(
                            currentStreak: viewModel.currentStreak,
                            longestStreak: viewModel.longestStreak
                        )
                    }

                    // Meals section
                    mealsSection
                }
                .padding(.horizontal, FuelSpacing.screenHorizontal)
                .padding(.bottom, FuelSpacing.xxl + 80) // Extra space for FAB
            }
            .background(FuelColors.background)
            .refreshable {
                viewModel.refresh()
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        FuelHaptics.shared.tap()
                        // Show calendar/history
                    } label: {
                        Image(systemName: "calendar")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
            }
        }
        .sheet(isPresented: $showingFoodSearch) {
            FoodSearchView(mealType: selectedMealType) { foodItem in
                // TODO: Add food item to meal
                FuelHaptics.shared.success()
            }
        }
        .sheet(isPresented: $showingDatePicker) {
            DatePickerSheet(
                selectedDate: viewModel.selectedDate,
                onSelect: { date in
                    viewModel.loadData(for: date)
                    showingDatePicker = false
                }
            )
            .presentationDetents([.medium])
        }
    }

    // MARK: - Date Navigation

    private var dateNavigationBar: some View {
        HStack {
            // Previous day
            Button {
                viewModel.goToPreviousDay()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(FuelColors.textSecondary)
                    .frame(width: 36, height: 36)
                    .background(FuelColors.surface)
                    .clipShape(Circle())
            }

            Spacer()

            // Date display
            Button {
                showingDatePicker = true
                FuelHaptics.shared.tap()
            } label: {
                HStack(spacing: FuelSpacing.xs) {
                    Text(viewModel.formattedDate)
                        .font(FuelTypography.headline)
                        .foregroundStyle(FuelColors.textPrimary)

                    if !viewModel.isToday {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(FuelColors.textTertiary)
                    }
                }
            }

            Spacer()

            // Next day (disabled if today)
            Button {
                viewModel.goToNextDay()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(viewModel.isToday ? FuelColors.textTertiary : FuelColors.textSecondary)
                    .frame(width: 36, height: 36)
                    .background(FuelColors.surface)
                    .clipShape(Circle())
            }
            .disabled(viewModel.isToday)
        }
        .padding(.top, FuelSpacing.sm)
    }

    // MARK: - Meals Section

    private var mealsSection: some View {
        VStack(alignment: .leading, spacing: FuelSpacing.md) {
            Text("MEALS")
                .font(FuelTypography.caption)
                .foregroundStyle(FuelColors.textTertiary)
                .padding(.leading, FuelSpacing.sm)

            VStack(spacing: FuelSpacing.sm) {
                ForEach(MealType.allCases, id: \.self) { mealType in
                    MealCard(
                        mealType: mealType,
                        items: viewModel.meals[mealType] ?? [],
                        totalCalories: viewModel.getMealCalories(for: mealType),
                        onAddFood: {
                            selectedMealType = mealType
                            showingFoodSearch = true
                            FuelHaptics.shared.tap()
                        },
                        onDeleteItem: { item in
                            viewModel.deleteFoodItem(item, from: mealType)
                        }
                    )
                }
            }
        }
    }
}

// MARK: - Date Picker Sheet

struct DatePickerSheet: View {
    let selectedDate: Date
    let onSelect: (Date) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var pickedDate: Date

    init(selectedDate: Date, onSelect: @escaping (Date) -> Void) {
        self.selectedDate = selectedDate
        self.onSelect = onSelect
        self._pickedDate = State(initialValue: selectedDate)
    }

    var body: some View {
        NavigationStack {
            VStack {
                DatePicker(
                    "Select Date",
                    selection: $pickedDate,
                    in: ...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .tint(FuelColors.primary)
                .padding()

                Spacer()
            }
            .background(FuelColors.background)
            .navigationTitle("Select Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        onSelect(pickedDate)
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    DashboardView()
}
