import SwiftUI

/// Appearance Settings View
/// Configure app theme and display options

struct AppearanceSettingsView: View {
    @State private var colorScheme: AppColorScheme = .system
    @State private var accentColor: AppAccentColor = .green
    @State private var showCaloriesInTab = true
    @State private var compactMealView = false

    var body: some View {
        ScrollView {
            VStack(spacing: FuelSpacing.xl) {
                // Theme section
                themeSection

                // Accent color section
                accentColorSection

                // Display options
                displayOptionsSection
            }
            .padding(.horizontal, FuelSpacing.screenHorizontal)
            .padding(.vertical, FuelSpacing.lg)
        }
        .background(FuelColors.background)
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Theme Section

    private var themeSection: some View {
        VStack(alignment: .leading, spacing: FuelSpacing.sm) {
            Text("THEME")
                .font(FuelTypography.caption)
                .foregroundStyle(FuelColors.textTertiary)

            VStack(spacing: 0) {
                ForEach(AppColorScheme.allCases, id: \.self) { scheme in
                    themeRow(scheme)

                    if scheme != AppColorScheme.allCases.last {
                        Divider()
                            .padding(.leading, FuelSpacing.md + 32 + FuelSpacing.md)
                    }
                }
            }
            .background(FuelColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
        }
    }

    private func themeRow(_ scheme: AppColorScheme) -> some View {
        Button {
            colorScheme = scheme
            FuelHaptics.shared.select()
        } label: {
            HStack(spacing: FuelSpacing.md) {
                // Icon
                Image(systemName: scheme.icon)
                    .font(.system(size: 18))
                    .foregroundStyle(scheme.iconColor)
                    .frame(width: 32)

                // Text
                VStack(alignment: .leading, spacing: FuelSpacing.xxxs) {
                    Text(scheme.displayName)
                        .font(FuelTypography.subheadlineMedium)
                        .foregroundStyle(FuelColors.textPrimary)

                    Text(scheme.description)
                        .font(FuelTypography.caption)
                        .foregroundStyle(FuelColors.textTertiary)
                }

                Spacer()

                // Checkmark
                if colorScheme == scheme {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(FuelColors.primary)
                }
            }
            .padding(FuelSpacing.md)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Accent Color Section

    private var accentColorSection: some View {
        VStack(alignment: .leading, spacing: FuelSpacing.sm) {
            Text("ACCENT COLOR")
                .font(FuelTypography.caption)
                .foregroundStyle(FuelColors.textTertiary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: FuelSpacing.md) {
                    ForEach(AppAccentColor.allCases, id: \.self) { color in
                        accentColorButton(color)
                    }
                }
                .padding(.horizontal, FuelSpacing.md)
                .padding(.vertical, FuelSpacing.sm)
            }
            .background(FuelColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
        }
    }

    private func accentColorButton(_ color: AppAccentColor) -> some View {
        Button {
            accentColor = color
            FuelHaptics.shared.select()
        } label: {
            VStack(spacing: FuelSpacing.sm) {
                Circle()
                    .fill(color.color)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle()
                            .stroke(accentColor == color ? Color.white : Color.clear, lineWidth: 3)
                    )
                    .overlay(
                        Circle()
                            .stroke(accentColor == color ? color.color : Color.clear, lineWidth: 2)
                            .padding(2)
                    )

                Text(color.displayName)
                    .font(FuelTypography.caption)
                    .foregroundStyle(FuelColors.textSecondary)
            }
        }
    }

    // MARK: - Display Options Section

    private var displayOptionsSection: some View {
        VStack(alignment: .leading, spacing: FuelSpacing.sm) {
            Text("DISPLAY")
                .font(FuelTypography.caption)
                .foregroundStyle(FuelColors.textTertiary)

            VStack(spacing: 0) {
                // Show calories in tab
                HStack(spacing: FuelSpacing.md) {
                    Image(systemName: "number.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.blue)
                        .frame(width: 32)

                    VStack(alignment: .leading, spacing: FuelSpacing.xxxs) {
                        Text("Calories in Tab Bar")
                            .font(FuelTypography.subheadlineMedium)
                            .foregroundStyle(FuelColors.textPrimary)

                        Text("Show remaining calories")
                            .font(FuelTypography.caption)
                            .foregroundStyle(FuelColors.textTertiary)
                    }

                    Spacer()

                    Toggle("", isOn: $showCaloriesInTab)
                        .labelsHidden()
                        .tint(FuelColors.primary)
                        .onChange(of: showCaloriesInTab) { _, _ in
                            FuelHaptics.shared.tap()
                        }
                }
                .padding(FuelSpacing.md)

                Divider()
                    .padding(.leading, FuelSpacing.md + 32 + FuelSpacing.md)

                // Compact meal view
                HStack(spacing: FuelSpacing.md) {
                    Image(systemName: "rectangle.compress.vertical")
                        .font(.system(size: 18))
                        .foregroundStyle(.purple)
                        .frame(width: 32)

                    VStack(alignment: .leading, spacing: FuelSpacing.xxxs) {
                        Text("Compact Meal View")
                            .font(FuelTypography.subheadlineMedium)
                            .foregroundStyle(FuelColors.textPrimary)

                        Text("Show meals in condensed format")
                            .font(FuelTypography.caption)
                            .foregroundStyle(FuelColors.textTertiary)
                    }

                    Spacer()

                    Toggle("", isOn: $compactMealView)
                        .labelsHidden()
                        .tint(FuelColors.primary)
                        .onChange(of: compactMealView) { _, _ in
                            FuelHaptics.shared.tap()
                        }
                }
                .padding(FuelSpacing.md)
            }
            .background(FuelColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
        }
    }
}

// MARK: - App Color Scheme

enum AppColorScheme: String, CaseIterable {
    case system
    case light
    case dark

    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var description: String {
        switch self {
        case .system: return "Follow device settings"
        case .light: return "Always use light mode"
        case .dark: return "Always use dark mode"
        }
    }

    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }

    var iconColor: Color {
        switch self {
        case .system: return .gray
        case .light: return .orange
        case .dark: return .indigo
        }
    }
}

// MARK: - App Accent Color

enum AppAccentColor: String, CaseIterable {
    case green
    case blue
    case purple
    case orange
    case red
    case pink

    var displayName: String {
        rawValue.capitalized
    }

    var color: Color {
        switch self {
        case .green: return Color(red: 0.6, green: 0.9, blue: 0.4)
        case .blue: return .blue
        case .purple: return .purple
        case .orange: return .orange
        case .red: return .red
        case .pink: return .pink
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AppearanceSettingsView()
    }
}
