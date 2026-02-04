import SwiftUI

/// Fuel Design System - Card Components
/// Premium card containers with consistent styling

// MARK: - Base Card

/// Standard card container with shadow and rounded corners
public struct FuelCard<Content: View>: View {
    private let content: Content
    private let padding: CGFloat
    private let cornerRadius: CGFloat

    public init(
        padding: CGFloat = FuelSpacing.cardPadding,
        cornerRadius: CGFloat = FuelSpacing.radiusLg,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    public var body: some View {
        content
            .padding(padding)
            .background(FuelColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Selection Card

/// Selectable card for onboarding and settings
/// Features selected state with checkmark and color highlight
public struct SelectionCard: View {
    let title: String
    let subtitle: String?
    let icon: String?
    let isSelected: Bool
    let action: () -> Void

    public init(
        title: String,
        subtitle: String? = nil,
        icon: String? = nil,
        isSelected: Bool,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.isSelected = isSelected
        self.action = action
    }

    public var body: some View {
        Button {
            FuelHaptics.shared.select()
            action()
        } label: {
            HStack(spacing: FuelSpacing.md) {
                // Icon
                if let icon {
                    ZStack {
                        RoundedRectangle(cornerRadius: FuelSpacing.radiusMd, style: .continuous)
                            .fill(isSelected ? FuelColors.primaryLight : FuelColors.surfaceSecondary)
                            .frame(width: 48, height: 48)

                        Image(systemName: icon)
                            .font(.system(size: 22, weight: .medium))
                            .foregroundStyle(isSelected ? FuelColors.primary : FuelColors.textSecondary)
                    }
                }

                // Text
                VStack(alignment: .leading, spacing: FuelSpacing.xxs) {
                    Text(title)
                        .font(FuelTypography.headline)
                        .foregroundStyle(FuelColors.textPrimary)

                    if let subtitle {
                        Text(subtitle)
                            .font(FuelTypography.subheadline)
                            .foregroundStyle(FuelColors.textSecondary)
                            .lineLimit(2)
                    }
                }

                Spacer()

                // Checkmark
                ZStack {
                    Circle()
                        .stroke(isSelected ? FuelColors.primary : FuelColors.border, lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(FuelColors.primary)
                            .frame(width: 24, height: 24)

                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .padding(FuelSpacing.md)
            .background(isSelected ? FuelColors.primaryLight : FuelColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusLg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: FuelSpacing.radiusLg, style: .continuous)
                    .stroke(isSelected ? FuelColors.primary : FuelColors.border, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PressableButtonStyle(scale: 0.98))
        .animation(FuelAnimations.spring, value: isSelected)
    }
}

// MARK: - Meal Card

/// Card for displaying logged meals
public struct MealCard: View {
    let mealType: String
    let mealIcon: String
    let calories: Int
    let items: [String]
    let time: Date
    let imageURL: String?
    let onTap: () -> Void
    let onAdd: () -> Void

    public init(
        mealType: String,
        mealIcon: String,
        calories: Int,
        items: [String],
        time: Date,
        imageURL: String? = nil,
        onTap: @escaping () -> Void,
        onAdd: @escaping () -> Void
    ) {
        self.mealType = mealType
        self.mealIcon = mealIcon
        self.calories = calories
        self.items = items
        self.time = time
        self.imageURL = imageURL
        self.onTap = onTap
        self.onAdd = onAdd
    }

    public var body: some View {
        FuelCard {
            VStack(alignment: .leading, spacing: FuelSpacing.sm) {
                // Header
                HStack {
                    Image(systemName: mealIcon)
                        .font(.system(size: 16))
                        .foregroundStyle(FuelColors.primary)

                    Text(mealType)
                        .font(FuelTypography.headline)
                        .foregroundStyle(FuelColors.textPrimary)

                    Spacer()

                    if calories > 0 {
                        Text("\(calories) cal")
                            .font(FuelTypography.subheadline)
                            .foregroundStyle(FuelColors.textSecondary)
                    }

                    Button {
                        FuelHaptics.shared.tap()
                        onAdd()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(FuelColors.primary)
                    }
                }

                // Content
                if items.isEmpty {
                    Text("Tap + to add \(mealType.lowercased())")
                        .font(FuelTypography.subheadline)
                        .foregroundStyle(FuelColors.textTertiary)
                        .padding(.vertical, FuelSpacing.sm)
                } else {
                    Button {
                        FuelHaptics.shared.tap()
                        onTap()
                    } label: {
                        HStack(spacing: FuelSpacing.sm) {
                            // Thumbnail
                            if let imageURL {
                                AsyncImage(url: URL(string: imageURL)) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                } placeholder: {
                                    Rectangle()
                                        .fill(FuelColors.surfaceSecondary)
                                }
                                .frame(width: 48, height: 48)
                                .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusSm, style: .continuous))
                            }

                            // Items
                            VStack(alignment: .leading, spacing: FuelSpacing.xxs) {
                                Text(items.joined(separator: ", "))
                                    .font(FuelTypography.subheadline)
                                    .foregroundStyle(FuelColors.textPrimary)
                                    .lineLimit(1)

                                Text(time, style: .time)
                                    .font(FuelTypography.caption)
                                    .foregroundStyle(FuelColors.textTertiary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(FuelColors.textTertiary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Achievement Card

/// Card for displaying achievements and milestones
public struct AchievementCard: View {
    let title: String
    let description: String
    let icon: String
    let isUnlocked: Bool
    let progress: Double?
    let unlockedDate: Date?

    public init(
        title: String,
        description: String,
        icon: String,
        isUnlocked: Bool,
        progress: Double? = nil,
        unlockedDate: Date? = nil
    ) {
        self.title = title
        self.description = description
        self.icon = icon
        self.isUnlocked = isUnlocked
        self.progress = progress
        self.unlockedDate = unlockedDate
    }

    public var body: some View {
        HStack(spacing: FuelSpacing.md) {
            // Badge
            ZStack {
                Circle()
                    .fill(isUnlocked ? FuelColors.goldGradient : LinearGradient(colors: [FuelColors.surfaceSecondary], startPoint: .top, endPoint: .bottom))
                    .frame(width: 56, height: 56)

                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(isUnlocked ? .white : FuelColors.textTertiary)
            }
            .shadow(color: isUnlocked ? FuelColors.gold.opacity(0.3) : .clear, radius: 8, y: 4)

            // Content
            VStack(alignment: .leading, spacing: FuelSpacing.xxs) {
                Text(title)
                    .font(FuelTypography.headline)
                    .foregroundStyle(isUnlocked ? FuelColors.textPrimary : FuelColors.textTertiary)

                Text(description)
                    .font(FuelTypography.caption)
                    .foregroundStyle(FuelColors.textSecondary)

                // Progress or date
                if let progress, !isUnlocked {
                    ProgressView(value: progress)
                        .tint(FuelColors.primary)
                        .frame(height: 4)
                } else if let date = unlockedDate, isUnlocked {
                    Text("Unlocked \(date, style: .date)")
                        .font(FuelTypography.caption)
                        .foregroundStyle(FuelColors.success)
                }
            }

            Spacer()

            if isUnlocked {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(FuelColors.success)
            }
        }
        .padding(FuelSpacing.md)
        .background(FuelColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusLg, style: .continuous))
        .opacity(isUnlocked ? 1.0 : 0.7)
    }
}

// MARK: - Preview

#Preview("Cards") {
    ScrollView {
        VStack(spacing: 16) {
            FuelCard {
                Text("Basic Card")
                    .font(FuelTypography.body)
            }

            SelectionCard(
                title: "Lose Weight",
                subtitle: "Shed pounds and feel great",
                icon: "scalemass",
                isSelected: true
            ) {}

            SelectionCard(
                title: "Build Muscle",
                subtitle: "Gain strength and size",
                icon: "figure.strengthtraining.traditional",
                isSelected: false
            ) {}

            MealCard(
                mealType: "Breakfast",
                mealIcon: "sun.rise",
                calories: 450,
                items: ["Oatmeal", "Banana", "Coffee"],
                time: Date(),
                onTap: {},
                onAdd: {}
            )

            AchievementCard(
                title: "First Week",
                description: "Log meals for 7 consecutive days",
                icon: "flame.fill",
                isUnlocked: true,
                unlockedDate: Date()
            )

            AchievementCard(
                title: "Century Club",
                description: "Log 100 meals",
                icon: "trophy.fill",
                isUnlocked: false,
                progress: 0.45
            )
        }
        .padding()
    }
}
