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
    @State private var showingMealHistory = false
    @State private var showingNutritionDetail = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: FuelSpacing.sectionSpacing) {
                    // Date navigation
                    dateNavigationBar

                    // Daily progress card (tappable)
                    Button {
                        FuelHaptics.shared.tap()
                        showingNutritionDetail = true
                    } label: {
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
                    }
                    .buttonStyle(ScaleButtonStyle())

                    // Meals section
                    mealsSection
                }
                .padding(.horizontal, FuelSpacing.screenHorizontal)
                .padding(.bottom, FuelSpacing.screenBottom + 80) // Tab bar space
            }
            .scrollIndicators(.hidden)
            .background(FuelColors.backgroundGradient)
            .refreshable {
                viewModel.refresh()
            }
            .onAppear {
                viewModel.setup(with: modelContext)
            }
            .onReceive(NotificationCenter.default.publisher(for: .demoDataLoaded)) { _ in
                viewModel.refresh()
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
        .sheet(item: $selectedMeal) { meal in
            MealDetailView(meal: meal) {
                viewModel.deleteMeal(meal)
                selectedMeal = nil
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .onDisappear {
                viewModel.refresh()
            }
        }
        .fullScreenCover(isPresented: $viewModel.showHistoryPaywall) {
            PaywallView(context: .historyLimit)
        }
        .sheet(isPresented: $showingNutritionDetail) {
            DailyNutritionDetailView(
                date: viewModel.selectedDate,
                calories: viewModel.totalCalories,
                calorieGoal: viewModel.calorieGoal,
                protein: viewModel.totalProtein,
                proteinGoal: viewModel.proteinGoal,
                carbs: viewModel.totalCarbs,
                carbsGoal: viewModel.carbsGoal,
                fat: viewModel.totalFat,
                fatGoal: viewModel.fatGoal,
                fiber: viewModel.totalFiber,
                sugar: viewModel.totalSugar,
                sodium: viewModel.totalSodium,
                saturatedFat: viewModel.totalSaturatedFat,
                cholesterol: viewModel.totalCholesterol,
                mealsLogged: viewModel.todaysMeals.count
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
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
                    .frame(width: 38, height: 38)
                    .background(FuelColors.surface)
                    .clipShape(Circle())
                    .subtleShadow()
            }

            Spacer()

            // Date display
            Button {
                showingDatePicker = true
                FuelHaptics.shared.tap()
            } label: {
                HStack(spacing: FuelSpacing.xs) {
                    Text(viewModel.formattedDate)
                        .font(.system(size: 17, weight: .semibold))
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
                    .frame(width: 38, height: 38)
                    .background(FuelColors.surface)
                    .clipShape(Circle())
                    .subtleShadow()
            }
            .disabled(viewModel.isToday)
        }
        .padding(.top, FuelSpacing.sm)
    }

    // MARK: - Meals Section (Premium Design)

    private var mealsSection: some View {
        VStack(alignment: .leading, spacing: FuelSpacing.sm) {
            // Section header
            HStack {
                Text("Today's Meals")
                    .font(FuelTypography.headline)
                    .foregroundStyle(FuelColors.textPrimary)

                Spacer()

                if !viewModel.todaysMeals.isEmpty {
                    Button {
                        FuelHaptics.shared.tap()
                        showingMealHistory = true
                    } label: {
                        Text("See all")
                            .font(FuelTypography.subheadlineMedium)
                            .foregroundStyle(FuelColors.primary)
                    }
                }
            }

            let meals = viewModel.todaysMeals

            if meals.isEmpty {
                EmptyMealsCard {
                    appState.showAddMealSheet = true
                }
            } else {
                // Vertical list of meal cards (like Cal AI)
                VStack(spacing: FuelSpacing.sm) {
                    ForEach(meals.prefix(5)) { meal in
                        TodayMealCard(meal: meal) {
                            FuelHaptics.shared.tap()
                            selectedMeal = meal
                        }
                    }

                    // Show more button if there are more meals
                    if meals.count > 5 {
                        Button {
                            FuelHaptics.shared.tap()
                            showingMealHistory = true
                        } label: {
                            HStack(spacing: FuelSpacing.xs) {
                                Text("View \(meals.count - 5) more")
                                    .font(FuelTypography.subheadlineMedium)
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundStyle(FuelColors.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, FuelSpacing.md)
                            .background(FuelColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
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
