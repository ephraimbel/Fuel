import SwiftUI

/// Today Meal Card - Premium Design
/// Horizontal card with photo on left, meal info on right
/// Matches Cal AI's "Recently logged" design

struct TodayMealCard: View {
    let meal: Meal
    let onTap: () -> Void

    var body: some View {
        Button {
            onTap()
        } label: {
            HStack(spacing: FuelSpacing.md) {
                // Meal photo (left side)
                mealPhotoView
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))

                // Meal info (right side)
                VStack(alignment: .leading, spacing: FuelSpacing.xs) {
                    // Top row: Meal name + time badge
                    HStack(alignment: .top) {
                        Text(mealName)
                            .font(FuelTypography.subheadlineMedium)
                            .foregroundStyle(FuelColors.textPrimary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)

                        Spacer(minLength: 8)

                        // Time badge
                        Text(meal.displayTime)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(FuelColors.textTertiary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(FuelColors.surfaceSecondary)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }

                    Spacer(minLength: 4)

                    // Calories with fire icon
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(FuelColors.primary)

                        Text("\(meal.totalCalories) calories")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(FuelColors.textPrimary)
                    }

                    // Macro row
                    HStack(spacing: FuelSpacing.md) {
                        macroItem(macro: .protein, value: Int(meal.totalProtein))
                        macroItem(macro: .carbs, value: Int(meal.totalCarbs))
                        macroItem(macro: .fat, value: Int(meal.totalFat))
                    }
                }
                .padding(.vertical, FuelSpacing.xs)
            }
            .padding(FuelSpacing.sm)
            .background(FuelColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusLg))
            .overlay(
                RoundedRectangle(cornerRadius: FuelSpacing.radiusLg)
                    .stroke(FuelColors.border.opacity(0.3), lineWidth: 0.5)
            )
            .cardShadow()
        }
        .buttonStyle(MealCardButtonStyle())
    }

    // MARK: - Meal Name

    private var mealName: String {
        if let items = meal.foodItems, !items.isEmpty {
            let names = items.prefix(3).map { $0.name }
            let joined = names.joined(separator: ", ")
            if items.count > 3 {
                return "\(joined)..."
            }
            return joined
        }
        return meal.mealType.displayName
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
                    image.resizable().aspectRatio(contentMode: .fill)
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
                    image.resizable().aspectRatio(contentMode: .fill)
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
            // Subtle gradient background based on meal type
            LinearGradient(
                colors: mealGradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Image(systemName: meal.mealType.icon)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(.white.opacity(0.6))
        }
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
            return [FuelColors.primary.opacity(0.8), FuelColors.primary.opacity(0.5)]
        }
    }

    // MARK: - Macro Item

    private func macroItem(macro: MacroType, value: Int) -> some View {
        HStack(spacing: 4) {
            MacroIconView(type: macro, size: 11)

            Text("\(value)g")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(FuelColors.textSecondary)
        }
    }
}

// MARK: - Button Style

struct MealCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Empty Meals Card

struct EmptyMealsCard: View {
    let onAddMeal: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "fork.knife")
                .font(.system(size: 32, weight: .thin))
                .foregroundStyle(FuelColors.textTertiary.opacity(0.4))

            VStack(spacing: 4) {
                Text("No meals logged")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(FuelColors.textSecondary)

                Text("Tap \(Image(systemName: "plus")) to get started")
                    .font(.system(size: 14))
                    .foregroundStyle(FuelColors.textTertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 48)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: FuelSpacing.md) {
        TodayMealCard(
            meal: Meal(mealType: .breakfast, loggedAt: Date()),
            onTap: {}
        )

        TodayMealCard(
            meal: Meal(mealType: .lunch, loggedAt: Date()),
            onTap: {}
        )

        EmptyMealsCard(onAddMeal: {})
    }
    .padding()
    .background(FuelColors.background)
}
