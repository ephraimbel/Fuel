import SwiftUI

/// Meal Card
/// Displays a meal type with its food items

struct MealCard: View {
    let mealType: MealType
    let items: [FoodItem]
    let totalCalories: Int
    let onAddFood: () -> Void
    let onDeleteItem: (FoodItem) -> Void

    @State private var isExpanded = true

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(FuelAnimations.spring) {
                        isExpanded.toggle()
                    }
                    FuelHaptics.shared.tap()
                }

            // Content
            if isExpanded {
                VStack(spacing: 0) {
                    if items.isEmpty {
                        emptyStateView
                    } else {
                        itemsList
                    }

                    // Add food button
                    addFoodButton
                }
            }
        }
        .background(FuelColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(spacing: FuelSpacing.md) {
            // Meal icon
            Image(systemName: mealType.icon)
                .font(.system(size: 18))
                .foregroundStyle(mealType.color)
                .frame(width: 36, height: 36)
                .background(mealType.color.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusSm))

            // Meal name and item count
            VStack(alignment: .leading, spacing: FuelSpacing.xxxs) {
                Text(mealType.displayName)
                    .font(FuelTypography.subheadlineMedium)
                    .foregroundStyle(FuelColors.textPrimary)

                Text(itemCountText)
                    .font(FuelTypography.caption)
                    .foregroundStyle(FuelColors.textTertiary)
            }

            Spacer()

            // Calories
            if totalCalories > 0 {
                Text("\(totalCalories)")
                    .font(FuelTypography.headline)
                    .foregroundStyle(FuelColors.textPrimary)
                + Text(" cal")
                    .font(FuelTypography.caption)
                    .foregroundStyle(FuelColors.textTertiary)
            }

            // Expand/collapse chevron
            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(FuelColors.textTertiary)
        }
        .padding(FuelSpacing.md)
    }

    private var itemCountText: String {
        if items.isEmpty {
            return "No items logged"
        } else if items.count == 1 {
            return "1 item"
        } else {
            return "\(items.count) items"
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: FuelSpacing.sm) {
            Image(systemName: "fork.knife")
                .font(.system(size: 24))
                .foregroundStyle(FuelColors.textTertiary)

            Text("No foods logged yet")
                .font(FuelTypography.caption)
                .foregroundStyle(FuelColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, FuelSpacing.lg)
    }

    // MARK: - Items List

    private var itemsList: some View {
        VStack(spacing: 0) {
            Divider()
                .padding(.leading, FuelSpacing.md + 36 + FuelSpacing.md)

            ForEach(items) { item in
                MealItemRow(
                    item: item,
                    onDelete: {
                        onDeleteItem(item)
                    }
                )

                if item.id != items.last?.id {
                    Divider()
                        .padding(.leading, FuelSpacing.md + 36 + FuelSpacing.md)
                }
            }
        }
    }

    // MARK: - Add Food Button

    private var addFoodButton: some View {
        Button {
            onAddFood()
        } label: {
            HStack(spacing: FuelSpacing.sm) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 16))

                Text("Add Food")
                    .font(FuelTypography.subheadlineMedium)
            }
            .foregroundStyle(FuelColors.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, FuelSpacing.md)
            .background(FuelColors.primary.opacity(0.08))
        }
    }
}

// MARK: - Meal Item Row

struct MealItemRow: View {
    let item: FoodItem
    let onDelete: () -> Void

    @State private var offset: CGFloat = 0
    @State private var showingDelete = false

    var body: some View {
        ZStack(alignment: .trailing) {
            // Delete background
            HStack {
                Spacer()
                Button {
                    onDelete()
                } label: {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.white)
                        .frame(width: 60, height: 60)
                        .background(FuelColors.error)
                }
            }

            // Main content
            HStack(spacing: FuelSpacing.md) {
                // Food icon based on source
                Circle()
                    .fill(FuelColors.surfaceSecondary)
                    .frame(width: 36, height: 36)
                    .overlay {
                        Image(systemName: item.source.icon)
                            .font(.system(size: 14))
                            .foregroundStyle(FuelColors.textTertiary)
                    }

                // Food details
                VStack(alignment: .leading, spacing: FuelSpacing.xxxs) {
                    Text(item.name)
                        .font(FuelTypography.body)
                        .foregroundStyle(FuelColors.textPrimary)
                        .lineLimit(1)

                    Text(item.fullDisplayServing)
                        .font(FuelTypography.caption)
                        .foregroundStyle(FuelColors.textTertiary)
                }

                Spacer()

                // Calories and macros
                VStack(alignment: .trailing, spacing: FuelSpacing.xxxs) {
                    Text("\(item.calories) cal")
                        .font(FuelTypography.subheadlineMedium)
                        .foregroundStyle(FuelColors.textPrimary)

                    HStack(spacing: FuelSpacing.xs) {
                        macroLabel(value: item.protein, color: FuelColors.protein, letter: "P")
                        macroLabel(value: item.carbs, color: FuelColors.carbs, letter: "C")
                        macroLabel(value: item.fat, color: FuelColors.fat, letter: "F")
                    }
                }
            }
            .padding(.horizontal, FuelSpacing.md)
            .padding(.vertical, FuelSpacing.sm)
            .background(FuelColors.surface)
            .offset(x: offset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if value.translation.width < 0 {
                            offset = max(value.translation.width, -80)
                        }
                    }
                    .onEnded { value in
                        withAnimation(FuelAnimations.spring) {
                            if value.translation.width < -40 {
                                offset = -60
                                showingDelete = true
                            } else {
                                offset = 0
                                showingDelete = false
                            }
                        }
                    }
            )
            .onTapGesture {
                if showingDelete {
                    withAnimation(FuelAnimations.spring) {
                        offset = 0
                        showingDelete = false
                    }
                }
            }
        }
        .clipped()
    }

    private func macroLabel(value: Double, color: Color, letter: String) -> some View {
        Text("\(Int(value))\(letter)")
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(color)
    }
}

// MARK: - MealType Extensions

extension MealType {
    var color: Color {
        switch self {
        case .breakfast:
            return .orange
        case .lunch:
            return .yellow
        case .dinner:
            return .purple
        case .snack:
            return FuelColors.primary
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: FuelSpacing.md) {
        MealCard(
            mealType: .breakfast,
            items: [],
            totalCalories: 0,
            onAddFood: {},
            onDeleteItem: { _ in }
        )

        MealCard(
            mealType: .dinner,
            items: [],
            totalCalories: 0,
            onAddFood: {},
            onDeleteItem: { _ in }
        )
    }
    .padding()
    .background(FuelColors.background)
}
