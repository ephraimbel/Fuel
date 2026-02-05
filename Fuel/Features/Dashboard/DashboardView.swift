import SwiftUI
import SwiftData

/// Dashboard View
/// Main home screen showing daily progress, meals, and stats

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @State private var viewModel = DashboardViewModel()
    @State private var showingQuickAdd = false
    @State private var selectedMealType: MealType = .breakfast
    @State private var showingDatePicker = false
    @State private var selectedMeal: Meal?
    @State private var showingMealDetail = false
    @State private var showingMealHistory = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: FuelSpacing.sectionSpacing) {
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

                    // Meals section
                    mealsSection
                }
                .padding(.horizontal, FuelSpacing.screenHorizontal)
                .padding(.bottom, FuelSpacing.screenBottom + 80) // Tab bar space
            }
            .scrollIndicators(.hidden)
            .background(FuelColors.background)
            .refreshable {
                viewModel.refresh()
            }
            .onAppear {
                viewModel.setup(with: modelContext)
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    streakBadge
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        FuelHaptics.shared.tap()
                        showingMealHistory = true
                    } label: {
                        Image(systemName: "calendar")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
            }
            .navigationDestination(isPresented: $showingMealHistory) {
                MealHistoryView()
            }
        }
        .sheet(isPresented: $showingQuickAdd) {
            QuickAddView(mealType: selectedMealType) { foodItem in
                viewModel.addFoodItem(foodItem, to: selectedMealType)
                FuelHaptics.shared.success()
            }
            .presentationDetents([.medium, .large])
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
        .sheet(isPresented: $showingMealDetail) {
            if let meal = selectedMeal {
                MealDetailView(meal: meal) {
                    viewModel.deleteMeal(meal)
                    showingMealDetail = false
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
        .fullScreenCover(isPresented: $viewModel.showHistoryPaywall) {
            PaywallView(context: .historyLimit)
        }
    }

    // MARK: - Streak Badge

    @ViewBuilder
    private var streakBadge: some View {
        let streak = viewModel.currentStreak > 0 ? viewModel.currentStreak : 7
        HStack(spacing: 4) {
            Image(systemName: "flame.fill")
            Text("\(streak)")
        }
        .font(.system(size: 12, weight: .semibold, design: .rounded))
        .foregroundStyle(FuelColors.primary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(FuelColors.primary.opacity(0.1))
        .clipShape(Capsule())
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
        .padding(.bottom, FuelSpacing.xs)
    }

    // MARK: - Meals Section (New Visual Design)

    private var mealsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader(title: "Today's Meals", icon: "fork.knife")

            let meals = viewModel.todaysMeals

            if meals.isEmpty {
                EmptyMealsCard {
                    appState.showAddMealSheet = true
                }
            } else {
                // 2-column grid of meal cards
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: FuelSpacing.sm),
                        GridItem(.flexible(), spacing: FuelSpacing.sm)
                    ],
                    spacing: FuelSpacing.sm
                ) {
                    ForEach(meals) { meal in
                        TodayMealCard(meal: meal) {
                            selectedMeal = meal
                            showingMealDetail = true
                        }
                    }
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
