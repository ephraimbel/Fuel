import SwiftUI

/// Fuel Design System - Navigation Components
/// Premium navigation bar and tab bar styling

// MARK: - Navigation Bar

public struct FuelNavigationBar<LeadingContent: View, TrailingContent: View>: View {
    let title: String
    let subtitle: String?
    let showBackButton: Bool
    let leadingContent: LeadingContent
    let trailingContent: TrailingContent
    let onBack: (() -> Void)?

    public init(
        title: String,
        subtitle: String? = nil,
        showBackButton: Bool = false,
        @ViewBuilder leadingContent: () -> LeadingContent = { EmptyView() },
        @ViewBuilder trailingContent: () -> TrailingContent = { EmptyView() },
        onBack: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.showBackButton = showBackButton
        self.leadingContent = leadingContent()
        self.trailingContent = trailingContent()
        self.onBack = onBack
    }

    public var body: some View {
        HStack(spacing: FuelSpacing.md) {
            // Leading content
            if showBackButton {
                Button {
                    FuelHaptics.shared.tap()
                    onBack?()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(FuelColors.textPrimary)
                        .frame(width: 44, height: 44)
                }
            } else {
                leadingContent
            }

            Spacer()

            // Title
            VStack(spacing: FuelSpacing.xxxs) {
                Text(title)
                    .font(FuelTypography.headline)
                    .foregroundStyle(FuelColors.textPrimary)

                if let subtitle {
                    Text(subtitle)
                        .font(FuelTypography.caption)
                        .foregroundStyle(FuelColors.textSecondary)
                }
            }

            Spacer()

            // Trailing content
            trailingContent
        }
        .padding(.horizontal, FuelSpacing.screenHorizontal)
        .padding(.vertical, FuelSpacing.sm)
        .background(FuelColors.background)
    }
}

// MARK: - Large Title Navigation Bar

public struct FuelLargeTitleBar<TrailingContent: View>: View {
    let title: String
    let subtitle: String?
    let trailingContent: TrailingContent

    public init(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder trailingContent: () -> TrailingContent = { EmptyView() }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.trailingContent = trailingContent()
    }

    public var body: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: FuelSpacing.xxxs) {
                if let subtitle {
                    Text(subtitle)
                        .font(FuelTypography.caption)
                        .foregroundStyle(FuelColors.textSecondary)
                        .textCase(.uppercase)
                        .tracking(1)
                }

                Text(title)
                    .font(FuelTypography.largeTitle)
                    .foregroundStyle(FuelColors.textPrimary)
            }

            Spacer()

            trailingContent
        }
        .padding(.horizontal, FuelSpacing.screenHorizontal)
        .padding(.top, FuelSpacing.md)
        .padding(.bottom, FuelSpacing.sm)
    }
}

// MARK: - Tab Bar

public struct FuelTabBar: View {
    @Binding var selectedTab: Int
    let tabs: [TabItem]

    public struct TabItem: Identifiable {
        public let id = UUID()
        let icon: String
        let selectedIcon: String
        let label: String

        public init(icon: String, selectedIcon: String? = nil, label: String) {
            self.icon = icon
            self.selectedIcon = selectedIcon ?? icon
            self.label = label
        }
    }

    public init(selectedTab: Binding<Int>, tabs: [TabItem]) {
        self._selectedTab = selectedTab
        self.tabs = tabs
    }

    public var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(tabs.enumerated()), id: \.element.id) { index, tab in
                tabButton(tab: tab, index: index)
            }
        }
        .padding(.horizontal, FuelSpacing.sm)
        .padding(.top, FuelSpacing.sm)
        .padding(.bottom, FuelSpacing.safeAreaBottom)
        .background(
            FuelColors.surface
                .shadow(color: .black.opacity(0.08), radius: 8, y: -4)
        )
    }

    private func tabButton(tab: TabItem, index: Int) -> some View {
        let isSelected = selectedTab == index

        return Button {
            guard !isSelected else { return }
            FuelHaptics.shared.select()
            withAnimation(FuelAnimations.spring) {
                selectedTab = index
            }
        } label: {
            VStack(spacing: FuelSpacing.xxs) {
                Image(systemName: isSelected ? tab.selectedIcon : tab.icon)
                    .font(.system(size: 22, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? FuelColors.primary : FuelColors.textTertiary)
                    .frame(height: 24)

                Text(tab.label)
                    .font(FuelTypography.caption)
                    .foregroundStyle(isSelected ? FuelColors.primary : FuelColors.textTertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, FuelSpacing.xxs)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Floating Action Button

public struct FuelFAB: View {
    let icon: String
    let action: () -> Void

    @State private var isPressed = false

    public init(icon: String = "plus", action: @escaping () -> Void) {
        self.icon = icon
        self.action = action
    }

    public var body: some View {
        Button {
            FuelHaptics.shared.impact()
            action()
        } label: {
            ZStack {
                Circle()
                    .fill(FuelColors.primaryGradient)
                    .frame(width: 56, height: 56)
                    .shadow(color: FuelColors.primary.opacity(0.4), radius: 12, y: 6)

                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(PressableButtonStyle(scale: 0.92))
    }
}

// MARK: - Segmented Control

public struct FuelSegmentedControl: View {
    let options: [String]
    @Binding var selectedIndex: Int

    public init(options: [String], selectedIndex: Binding<Int>) {
        self.options = options
        self._selectedIndex = selectedIndex
    }

    public var body: some View {
        HStack(spacing: FuelSpacing.xxs) {
            ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                segmentButton(option: option, index: index)
            }
        }
        .padding(FuelSpacing.xxs)
        .background(FuelColors.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd, style: .continuous))
    }

    private func segmentButton(option: String, index: Int) -> some View {
        let isSelected = selectedIndex == index

        return Button {
            guard !isSelected else { return }
            FuelHaptics.shared.select()
            withAnimation(FuelAnimations.spring) {
                selectedIndex = index
            }
        } label: {
            Text(option)
                .font(FuelTypography.subheadlineMedium)
                .foregroundStyle(isSelected ? FuelColors.textPrimary : FuelColors.textSecondary)
                .padding(.horizontal, FuelSpacing.md)
                .padding(.vertical, FuelSpacing.sm)
                .frame(maxWidth: .infinity)
                .background(
                    isSelected
                        ? FuelColors.surface
                        : Color.clear
                )
                .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusSm, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Page Indicator

public struct FuelPageIndicator: View {
    let totalPages: Int
    let currentPage: Int

    public init(totalPages: Int, currentPage: Int) {
        self.totalPages = totalPages
        self.currentPage = currentPage
    }

    public var body: some View {
        HStack(spacing: FuelSpacing.xs) {
            ForEach(0..<totalPages, id: \.self) { index in
                Capsule()
                    .fill(index == currentPage ? FuelColors.primary : FuelColors.surfaceSecondary)
                    .frame(width: index == currentPage ? 24 : 8, height: 8)
                    .animation(FuelAnimations.spring, value: currentPage)
            }
        }
    }
}

// MARK: - Preview

#Preview("Navigation") {
    VStack(spacing: 24) {
        // Standard nav bar
        FuelNavigationBar(
            title: "Today",
            subtitle: "February 4, 2026",
            showBackButton: false
        ) {
            EmptyView()
        } trailingContent: {
            FuelIconButton(icon: "gearshape") {}
        }

        Divider()

        // Large title
        FuelLargeTitleBar(title: "Good morning!", subtitle: "Today") {
            FuelIconButton(icon: "bell") {}
        }

        Divider()

        // Segmented control
        FuelSegmentedControl(
            options: ["Day", "Week", "Month"],
            selectedIndex: .constant(0)
        )
        .padding()

        // Page indicator
        FuelPageIndicator(totalPages: 5, currentPage: 2)

        Spacer()

        // Tab bar
        FuelTabBar(selectedTab: .constant(0), tabs: [
            .init(icon: "house", selectedIcon: "house.fill", label: "Home"),
            .init(icon: "magnifyingglass", label: "Search"),
            .init(icon: "plus.circle", selectedIcon: "plus.circle.fill", label: "Add"),
            .init(icon: "chart.bar", selectedIcon: "chart.bar.fill", label: "Progress"),
            .init(icon: "person", selectedIcon: "person.fill", label: "Profile")
        ])
    }
    .background(FuelColors.background)
}
