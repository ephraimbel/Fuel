import SwiftUI
import SwiftData

/// Meal History View
/// Shows all logged meals grouped by date with photos

struct MealHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = MealHistoryViewModel()
    @State private var selectedMeal: Meal?

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                ForEach(viewModel.sortedDates, id: \.self) { date in
                    Section {
                        mealGrid(for: date)
                    } header: {
                        dateHeader(for: date)
                    }
                }

                // Load more trigger
                if viewModel.hasMoreData {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, FuelSpacing.lg)
                        .onAppear {
                            viewModel.loadMoreData()
                        }
                }
            }
            .padding(.horizontal, FuelSpacing.screenHorizontal)
            .padding(.bottom, FuelSpacing.screenBottom + 80)
        }
        .scrollIndicators(.hidden)
        .background(FuelColors.backgroundGradient)
        .navigationTitle("Meals")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            viewModel.refresh()
        }
        .onAppear {
            viewModel.setup(with: modelContext)
        }
        .overlay {
            if viewModel.sortedDates.isEmpty && !viewModel.isLoading {
                emptyStateView
            }
        }
        .sheet(item: $selectedMeal) { meal in
            MealDetailView(meal: meal) {
                viewModel.deleteMeal(meal)
                selectedMeal = nil
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Date Header

    private func dateHeader(for date: Date) -> some View {
        HStack {
            Text(viewModel.formattedDate(date))
                .font(FuelTypography.headline)
                .foregroundStyle(FuelColors.textPrimary)

            Spacer()

            // Total calories for the day
            Text("\(viewModel.totalCalories(for: date)) cal")
                .font(FuelTypography.subheadline)
                .foregroundStyle(FuelColors.textSecondary)
        }
        .padding(.vertical, FuelSpacing.sm)
        .padding(.horizontal, FuelSpacing.xxs)
        .background(FuelColors.backgroundGradient)
    }

    // MARK: - Meal List

    private func mealGrid(for date: Date) -> some View {
        let meals = viewModel.meals(for: date)

        return VStack(spacing: FuelSpacing.sm) {
            ForEach(meals) { meal in
                TodayMealCard(meal: meal) {
                    FuelHaptics.shared.tap()
                    selectedMeal = meal
                }
            }
        }
        .padding(.bottom, FuelSpacing.lg)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: FuelSpacing.lg) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundStyle(FuelColors.textTertiary)

            VStack(spacing: FuelSpacing.xs) {
                Text("No meals yet")
                    .font(FuelTypography.title3)
                    .foregroundStyle(FuelColors.textPrimary)

                Text("Start tracking your meals to see your history here")
                    .font(FuelTypography.subheadline)
                    .foregroundStyle(FuelColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, FuelSpacing.xxl)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        MealHistoryView()
    }
}
