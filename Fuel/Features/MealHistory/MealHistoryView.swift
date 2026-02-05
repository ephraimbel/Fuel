import SwiftUI
import SwiftData

/// Meal History View
/// Shows all logged meals grouped by date with photos

struct MealHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = MealHistoryViewModel()
    @State private var selectedMeal: Meal?
    @State private var showingMealDetail = false

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
            .padding(.bottom, FuelSpacing.screenBottom)
        }
        .scrollIndicators(.hidden)
        .background(FuelColors.background)
        .navigationTitle("Meal History")
        .navigationBarTitleDisplayMode(.large)
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
        .background(FuelColors.background)
    }

    // MARK: - Meal Grid

    private func mealGrid(for date: Date) -> some View {
        let meals = viewModel.meals(for: date)

        return LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: FuelSpacing.sm),
                GridItem(.flexible(), spacing: FuelSpacing.sm)
            ],
            spacing: FuelSpacing.sm
        ) {
            ForEach(meals) { meal in
                MealHistoryCard(meal: meal) {
                    selectedMeal = meal
                    showingMealDetail = true
                    FuelHaptics.shared.tap()
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

// MARK: - Meal History Card

struct MealHistoryCard: View {
    let meal: Meal
    let onTap: () -> Void

    var body: some View {
        Button {
            onTap()
        } label: {
            ZStack(alignment: .bottomLeading) {
                // Photo
                mealPhotoView
                    .frame(height: 140)
                    .frame(maxWidth: .infinity)

                // Gradient overlay
                LinearGradient(
                    colors: [.clear, .black.opacity(0.65)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Content
                VStack(alignment: .leading, spacing: FuelSpacing.xxxs) {
                    Spacer()

                    // Meal type badge
                    HStack(spacing: FuelSpacing.xxs) {
                        Image(systemName: meal.mealType.icon)
                            .font(.system(size: 9, weight: .semibold))
                        Text(meal.mealType.displayName)
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundStyle(.white.opacity(0.85))

                    // Calories
                    Text("\(meal.totalCalories) cal")
                        .font(FuelTypography.subheadlineMedium)
                        .foregroundStyle(.white)

                    // Time
                    Text(meal.displayTime)
                        .font(FuelTypography.caption2)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .padding(FuelSpacing.sm)
            }
            .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
        }
        .buttonStyle(MealCardButtonStyle())
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
                case .failure, .empty:
                    placeholderView
                @unknown default:
                    placeholderView
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
                case .failure, .empty:
                    placeholderView
                @unknown default:
                    placeholderView
                }
            }
        } else {
            placeholderView
        }
    }

    private var placeholderView: some View {
        ZStack {
            mealTypeGradient

            Image(systemName: meal.mealType.icon)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(.white.opacity(0.4))
        }
    }

    private var mealTypeGradient: some View {
        LinearGradient(
            colors: mealGradientColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var mealGradientColors: [Color] {
        switch meal.mealType {
        case .breakfast:
            return [Color.orange.opacity(0.7), Color.yellow.opacity(0.5)]
        case .lunch:
            return [Color.green.opacity(0.6), Color.teal.opacity(0.4)]
        case .dinner:
            return [Color.purple.opacity(0.6), Color.indigo.opacity(0.4)]
        case .snack:
            return [FuelColors.primary.opacity(0.7), FuelColors.primaryDark.opacity(0.5)]
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        MealHistoryView()
    }
}
