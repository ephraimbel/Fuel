import SwiftUI

/// Food Search Result Row
/// Displays a single food item in search results

struct FoodSearchResultRow: View {
    let food: FoodSearchItem
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: FuelSpacing.md) {
                // Food image or placeholder
                foodImage

                // Food info
                VStack(alignment: .leading, spacing: FuelSpacing.xxxs) {
                    Text(food.name)
                        .font(FuelTypography.subheadlineMedium)
                        .foregroundStyle(FuelColors.textPrimary)
                        .lineLimit(1)

                    if let brand = food.brand, !brand.isEmpty {
                        Text(brand)
                            .font(FuelTypography.caption)
                            .foregroundStyle(FuelColors.textSecondary)
                            .lineLimit(1)
                    }

                    HStack(spacing: FuelSpacing.sm) {
                        Text(food.servingSize)
                            .font(FuelTypography.caption)
                            .foregroundStyle(FuelColors.textTertiary)

                        // Source badge
                        sourceBadge
                    }
                }

                Spacer()

                // Calories
                VStack(alignment: .trailing, spacing: FuelSpacing.xxxs) {
                    Text("\(food.calories)")
                        .font(FuelTypography.headline)
                        .foregroundStyle(FuelColors.primary)

                    Text("cal")
                        .font(FuelTypography.caption)
                        .foregroundStyle(FuelColors.textTertiary)
                }

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(FuelColors.textTertiary)
            }
            .padding(FuelSpacing.md)
            .background(FuelColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Food Image

    private var foodImage: some View {
        Group {
            if let imageURL = food.imageURL,
               let url = URL(string: imageURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        imagePlaceholder
                    case .empty:
                        ProgressView()
                            .frame(width: 50, height: 50)
                    @unknown default:
                        imagePlaceholder
                    }
                }
                .frame(width: 50, height: 50)
                .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusSm))
            } else {
                imagePlaceholder
            }
        }
    }

    private var imagePlaceholder: some View {
        RoundedRectangle(cornerRadius: FuelSpacing.radiusSm)
            .fill(FuelColors.surfaceSecondary)
            .frame(width: 50, height: 50)
            .overlay(
                Image(systemName: "fork.knife")
                    .font(.system(size: 18))
                    .foregroundStyle(FuelColors.textTertiary)
            )
    }

    // MARK: - Source Badge

    private var sourceBadge: some View {
        HStack(spacing: FuelSpacing.xxxs) {
            Image(systemName: food.source.icon)
                .font(.system(size: 10))

            Text(food.source.displayName)
                .font(.system(size: 10, weight: .medium))
        }
        .foregroundStyle(badgeColor)
        .padding(.horizontal, FuelSpacing.xs)
        .padding(.vertical, 2)
        .background(badgeColor.opacity(0.15))
        .clipShape(Capsule())
    }

    private var badgeColor: Color {
        switch food.source {
        case .database:
            return FuelColors.primary
        case .barcode:
            return FuelColors.success
        case .aiScan:
            return FuelColors.secondary
        case .manual:
            return FuelColors.textSecondary
        default:
            return FuelColors.textTertiary
        }
    }
}

// MARK: - Compact Food Row

struct CompactFoodRow: View {
    let food: FoodSearchItem
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: FuelSpacing.md) {
                VStack(alignment: .leading, spacing: FuelSpacing.xxxs) {
                    Text(food.name)
                        .font(FuelTypography.subheadline)
                        .foregroundStyle(FuelColors.textPrimary)
                        .lineLimit(1)

                    Text(food.servingSize)
                        .font(FuelTypography.caption)
                        .foregroundStyle(FuelColors.textTertiary)
                }

                Spacer()

                Text("\(food.calories) cal")
                    .font(FuelTypography.subheadlineMedium)
                    .foregroundStyle(FuelColors.primary)

                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(FuelColors.primary)
            }
            .padding(.vertical, FuelSpacing.sm)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: FuelSpacing.md) {
        FoodSearchResultRow(
            food: FoodSearchItem(
                id: "1",
                name: "Chicken Breast",
                brand: "Tyson",
                calories: 165,
                servingSize: "100g",
                protein: 31,
                carbs: 0,
                fat: 3.6,
                imageURL: nil,
                source: .database,
                barcode: nil
            ),
            onTap: {}
        )

        FoodSearchResultRow(
            food: FoodSearchItem(
                id: "2",
                name: "Greek Yogurt Plain",
                brand: "Chobani",
                calories: 100,
                servingSize: "170g",
                protein: 17,
                carbs: 6,
                fat: 0,
                imageURL: nil,
                source: .barcode,
                barcode: "123456789"
            ),
            onTap: {}
        )
    }
    .padding()
    .background(FuelColors.background)
}
