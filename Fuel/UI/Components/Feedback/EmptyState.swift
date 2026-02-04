import SwiftUI

/// Fuel Design System - Empty State Views
/// Friendly illustrations and messages when content is empty

public struct EmptyState: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?

    @State private var isAnimating = false

    public init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        VStack(spacing: FuelSpacing.lg) {
            // Icon with animation
            ZStack {
                Circle()
                    .fill(FuelColors.primaryLight)
                    .frame(width: 100, height: 100)
                    .scaleEffect(isAnimating ? 1.05 : 1.0)

                Image(systemName: icon)
                    .font(.system(size: 44, weight: .medium))
                    .foregroundStyle(FuelColors.primary)
            }
            .animation(FuelAnimations.pulseGentle, value: isAnimating)
            .onAppear {
                isAnimating = true
            }

            // Text
            VStack(spacing: FuelSpacing.xs) {
                Text(title)
                    .font(FuelTypography.title2)
                    .foregroundStyle(FuelColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(FuelTypography.body)
                    .foregroundStyle(FuelColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            .padding(.horizontal, FuelSpacing.xl)

            // Action button
            if let actionTitle, let action {
                FuelButton(actionTitle, icon: "plus", style: .primary, size: .medium, isFullWidth: false) {
                    action()
                }
                .padding(.top, FuelSpacing.sm)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(FuelSpacing.xxl)
    }
}

// MARK: - Preset Empty States

extension EmptyState {
    /// No meals logged today
    public static func noMeals(action: @escaping () -> Void) -> EmptyState {
        EmptyState(
            icon: "fork.knife",
            title: "No Meals Yet",
            message: "Start tracking your nutrition by adding your first meal of the day.",
            actionTitle: "Add Meal",
            action: action
        )
    }

    /// No search results
    public static func noSearchResults(query: String) -> EmptyState {
        EmptyState(
            icon: "magnifyingglass",
            title: "No Results",
            message: "We couldn't find any foods matching \"\(query)\". Try a different search term.",
            actionTitle: nil,
            action: nil
        )
    }

    /// No history
    public static func noHistory() -> EmptyState {
        EmptyState(
            icon: "calendar",
            title: "No History",
            message: "Your meal history will appear here once you start logging.",
            actionTitle: nil,
            action: nil
        )
    }

    /// No achievements
    public static func noAchievements() -> EmptyState {
        EmptyState(
            icon: "trophy",
            title: "No Achievements Yet",
            message: "Keep logging your meals to unlock achievements and milestones.",
            actionTitle: nil,
            action: nil
        )
    }

    /// No recipes
    public static func noRecipes(action: @escaping () -> Void) -> EmptyState {
        EmptyState(
            icon: "book.closed",
            title: "No Recipes",
            message: "Save your favorite meals as recipes for quick logging later.",
            actionTitle: "Create Recipe",
            action: action
        )
    }

    /// Offline state
    public static func offline(action: @escaping () -> Void) -> EmptyState {
        EmptyState(
            icon: "wifi.slash",
            title: "You're Offline",
            message: "Some features require an internet connection. Please check your connection and try again.",
            actionTitle: "Retry",
            action: action
        )
    }

    /// Camera access needed
    public static func cameraAccessNeeded(action: @escaping () -> Void) -> EmptyState {
        EmptyState(
            icon: "camera.fill",
            title: "Camera Access Required",
            message: "Fuel needs camera access to analyze your meals. Please enable it in Settings.",
            actionTitle: "Open Settings",
            action: action
        )
    }

    /// Generic error
    public static func error(action: @escaping () -> Void) -> EmptyState {
        EmptyState(
            icon: "exclamationmark.triangle",
            title: "Something Went Wrong",
            message: "We encountered an unexpected error. Please try again.",
            actionTitle: "Try Again",
            action: action
        )
    }
}

// MARK: - Preview

#Preview("Empty States") {
    ScrollView {
        VStack(spacing: 40) {
            EmptyState.noMeals { }
                .frame(height: 300)

            Divider()

            EmptyState.noSearchResults(query: "pizza")
                .frame(height: 300)

            Divider()

            EmptyState.noAchievements()
                .frame(height: 300)
        }
    }
}
