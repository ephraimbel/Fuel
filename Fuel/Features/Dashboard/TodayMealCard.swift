import SwiftUI

/// Today Meal Card
/// Visual meal card with photo, calories, and macros for the Today's Meals section

struct TodayMealCard: View {
    let meal: Meal
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button {
            FuelHaptics.shared.tap()
            onTap()
        } label: {
            ZStack(alignment: .bottomLeading) {
                // Photo background
                mealPhotoView
                    .frame(height: 160)
                    .frame(maxWidth: .infinity)

                // Gradient overlay
                LinearGradient(
                    colors: [.clear, .black.opacity(0.7)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Content overlay
                VStack(alignment: .leading, spacing: FuelSpacing.xxs) {
                    Spacer()

                    // Meal type and time
                    HStack(spacing: FuelSpacing.xxs) {
                        Image(systemName: meal.mealType.icon)
                            .font(.system(size: 10, weight: .semibold))

                        Text(meal.displayTime)
                            .font(FuelTypography.caption)
                    }
                    .foregroundStyle(.white.opacity(0.8))

                    // Calories
                    Text("\(meal.totalCalories)")
                        .font(FuelTypography.title2)
                        .foregroundStyle(.white)
                    + Text(" cal")
                        .font(FuelTypography.subheadline)
                        .foregroundStyle(.white.opacity(0.8))

                    // Macros
                    HStack(spacing: FuelSpacing.sm) {
                        macroLabel(value: meal.totalProtein, letter: "P", color: FuelColors.protein)
                        macroLabel(value: meal.totalCarbs, letter: "C", color: FuelColors.carbs)
                        macroLabel(value: meal.totalFat, letter: "F", color: FuelColors.fat)
                    }
                }
                .padding(FuelSpacing.sm)
            }
            .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusLg))
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(MealCardButtonStyle())
    }

    // MARK: - Photo View

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

            VStack(spacing: FuelSpacing.xs) {
                Image(systemName: meal.mealType.icon)
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.5))

                if let items = meal.foodItems, !items.isEmpty {
                    Text(items.first?.name ?? "")
                        .font(FuelTypography.caption)
                        .foregroundStyle(.white.opacity(0.6))
                        .lineLimit(1)
                }
            }
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
            return [Color.orange.opacity(0.8), Color.yellow.opacity(0.6)]
        case .lunch:
            return [Color.green.opacity(0.7), Color.teal.opacity(0.5)]
        case .dinner:
            return [Color.purple.opacity(0.7), Color.indigo.opacity(0.5)]
        case .snack:
            return [FuelColors.primary.opacity(0.8), FuelColors.primaryDark.opacity(0.6)]
        }
    }

    // MARK: - Macro Label

    private func macroLabel(value: Double, letter: String, color: Color) -> some View {
        HStack(spacing: 2) {
            Text("\(Int(value))")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
            Text(letter)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(color)
        }
    }
}

// MARK: - Button Style

struct MealCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(FuelAnimations.springQuick, value: configuration.isPressed)
    }
}

// MARK: - Empty State Card

struct EmptyMealsCard: View {
    let onAddMeal: () -> Void

    var body: some View {
        VStack(spacing: FuelSpacing.md) {
            // Icon
            Circle()
                .fill(FuelColors.primary.opacity(0.1))
                .frame(width: 64, height: 64)
                .overlay {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(FuelColors.primary)
                }

            // Text
            VStack(spacing: FuelSpacing.xs) {
                Text("No meals logged yet")
                    .font(FuelTypography.headline)
                    .foregroundStyle(FuelColors.textPrimary)

                Text("Take a photo of your food to get started")
                    .font(FuelTypography.subheadline)
                    .foregroundStyle(FuelColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            // Add button
            Button {
                FuelHaptics.shared.tap()
                onAddMeal()
            } label: {
                HStack(spacing: FuelSpacing.xs) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Add First Meal")
                        .font(FuelTypography.headline)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, FuelSpacing.lg)
                .padding(.vertical, FuelSpacing.sm)
                .background(FuelColors.primary)
                .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, FuelSpacing.xxl)
        .padding(.horizontal, FuelSpacing.lg)
        .background(FuelColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusLg))
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: FuelSpacing.md) {
        TodayMealCard(
            meal: Meal(mealType: .breakfast, loggedAt: Date()),
            onTap: {}
        )

        EmptyMealsCard(onAddMeal: {})
    }
    .padding()
    .background(FuelColors.background)
}
