import SwiftUI

/// Fuel Design System - Primary Button Component
/// Premium button with multiple styles, sizes, and states
public struct FuelButton: View {

    // MARK: - Button Style

    public enum Style {
        /// Solid primary color - Main CTAs
        case primary
        /// Outline with border - Secondary actions
        case secondary
        /// Subtle background - Tertiary actions
        case tertiary
        /// Red destructive - Delete, cancel subscription
        case destructive
        /// Ghost with no background - Text-like buttons
        case ghost
    }

    // MARK: - Button Size

    public enum Size {
        /// 40pt height - Compact buttons
        case small
        /// 48pt height - Standard buttons
        case medium
        /// 56pt height - Main CTAs
        case large

        var height: CGFloat {
            switch self {
            case .small: return 40
            case .medium: return 48
            case .large: return 56
            }
        }

        var cornerRadius: CGFloat {
            switch self {
            case .small: return 10
            case .medium: return 12
            case .large: return 14
            }
        }

        var font: Font {
            switch self {
            case .small: return FuelTypography.subheadlineMedium
            case .medium: return FuelTypography.headline
            case .large: return FuelTypography.headline
            }
        }

        var iconSize: CGFloat {
            switch self {
            case .small: return 14
            case .medium: return 16
            case .large: return 18
            }
        }
    }

    // MARK: - Properties

    private let title: String
    private let icon: String?
    private let iconPosition: IconPosition
    private let style: Style
    private let size: Size
    private let isFullWidth: Bool
    private let isLoading: Bool
    private let isDisabled: Bool
    private let action: () -> Void

    public enum IconPosition {
        case leading
        case trailing
    }

    // MARK: - Initialization

    public init(
        _ title: String,
        icon: String? = nil,
        iconPosition: IconPosition = .leading,
        style: Style = .primary,
        size: Size = .large,
        isFullWidth: Bool = true,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.iconPosition = iconPosition
        self.style = style
        self.size = size
        self.isFullWidth = isFullWidth
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }

    // MARK: - Body

    public var body: some View {
        Button {
            guard !isLoading && !isDisabled else { return }
            FuelHaptics.shared.tap()
            action()
        } label: {
            HStack(spacing: FuelSpacing.xs) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: textColor))
                        .scaleEffect(0.8)
                } else {
                    if iconPosition == .leading, let icon {
                        Image(systemName: icon)
                            .font(.system(size: size.iconSize, weight: .semibold))
                    }

                    Text(title)
                        .font(size.font)

                    if iconPosition == .trailing, let icon {
                        Image(systemName: icon)
                            .font(.system(size: size.iconSize, weight: .semibold))
                    }
                }
            }
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .frame(height: size.height)
            .padding(.horizontal, isFullWidth ? 0 : FuelSpacing.buttonPaddingH)
            .foregroundStyle(textColor)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: size.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: size.cornerRadius, style: .continuous)
                    .stroke(borderColor, lineWidth: style == .secondary ? 1.5 : 0)
            )
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(isDisabled || isLoading)
        .opacity(isDisabled ? 0.5 : 1.0)
        .animation(FuelAnimations.springQuick, value: isLoading)
        .animation(FuelAnimations.springQuick, value: isDisabled)
    }

    // MARK: - Computed Colors

    private var backgroundColor: Color {
        switch style {
        case .primary:
            return FuelColors.primary
        case .secondary:
            return .clear
        case .tertiary:
            return FuelColors.surfaceSecondary
        case .destructive:
            return FuelColors.error
        case .ghost:
            return .clear
        }
    }

    private var textColor: Color {
        switch style {
        case .primary:
            return .white
        case .secondary:
            return FuelColors.textPrimary
        case .tertiary:
            return FuelColors.textPrimary
        case .destructive:
            return .white
        case .ghost:
            return FuelColors.primary
        }
    }

    private var borderColor: Color {
        switch style {
        case .secondary:
            return FuelColors.border
        default:
            return .clear
        }
    }
}

// MARK: - Convenience Initializers

extension FuelButton {
    /// Primary full-width button
    public static func primary(
        _ title: String,
        icon: String? = nil,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) -> FuelButton {
        FuelButton(
            title,
            icon: icon,
            style: .primary,
            size: .large,
            isLoading: isLoading,
            action: action
        )
    }

    /// Secondary outline button
    public static func secondary(
        _ title: String,
        icon: String? = nil,
        action: @escaping () -> Void
    ) -> FuelButton {
        FuelButton(
            title,
            icon: icon,
            style: .secondary,
            size: .large,
            action: action
        )
    }

    /// Small tertiary button
    public static func small(
        _ title: String,
        icon: String? = nil,
        action: @escaping () -> Void
    ) -> FuelButton {
        FuelButton(
            title,
            icon: icon,
            style: .tertiary,
            size: .small,
            isFullWidth: false,
            action: action
        )
    }
}

// MARK: - Icon Button

/// Circular icon-only button
public struct FuelIconButton: View {
    private let icon: String
    private let size: CGFloat
    private let style: FuelButton.Style
    private let action: () -> Void

    public init(
        icon: String,
        size: CGFloat = 44,
        style: FuelButton.Style = .tertiary,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.size = size
        self.style = style
        self.action = action
    }

    public var body: some View {
        Button {
            FuelHaptics.shared.tap()
            action()
        } label: {
            Image(systemName: icon)
                .font(.system(size: size * 0.45, weight: .semibold))
                .foregroundStyle(foregroundColor)
                .frame(width: size, height: size)
                .background(backgroundColor)
                .clipShape(Circle())
        }
        .buttonStyle(PressableButtonStyle())
    }

    private var backgroundColor: Color {
        switch style {
        case .primary: return FuelColors.primary
        case .tertiary: return FuelColors.surfaceSecondary
        default: return .clear
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary: return .white
        default: return FuelColors.textPrimary
        }
    }
}

// MARK: - Preview

#Preview("Buttons") {
    VStack(spacing: 16) {
        FuelButton("Get Started", icon: "arrow.right", iconPosition: .trailing) {}

        FuelButton("Secondary Action", style: .secondary) {}

        FuelButton("Tertiary", style: .tertiary, size: .medium) {}

        FuelButton("Delete Account", style: .destructive) {}

        FuelButton("Loading...", isLoading: true) {}

        FuelButton("Disabled", isDisabled: true) {}

        HStack(spacing: 12) {
            FuelIconButton(icon: "camera.fill", style: .primary) {}
            FuelIconButton(icon: "xmark") {}
            FuelIconButton(icon: "bolt.fill") {}
        }
    }
    .padding()
}
