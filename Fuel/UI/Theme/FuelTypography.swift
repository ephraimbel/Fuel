import SwiftUI

/// Fuel Design System - Typography
/// Premium typography scale using SF Pro with careful hierarchy
public struct FuelTypography {

    // MARK: - Display (Hero Numbers)
    // Used for large calorie counts and key metrics

    /// 64pt Bold Rounded - Largest display number
    public static let heroLarge = Font.system(size: 64, weight: .bold, design: .rounded)

    /// 56pt Bold Rounded - Primary hero metric (calories remaining)
    public static let hero = Font.system(size: 56, weight: .bold, design: .rounded)

    /// 48pt Bold Rounded - Secondary hero metric
    public static let heroSmall = Font.system(size: 48, weight: .bold, design: .rounded)

    /// 40pt Bold Rounded - Tertiary hero metric
    public static let heroMini = Font.system(size: 40, weight: .bold, design: .rounded)

    // MARK: - Titles
    // Used for screen titles and section headers

    /// 34pt Bold - Screen titles, major headings
    public static let largeTitle = Font.system(size: 34, weight: .bold)

    /// 28pt Bold - Primary section headers
    public static let title1 = Font.system(size: 28, weight: .bold)

    /// 22pt Bold - Secondary section headers
    public static let title2 = Font.system(size: 22, weight: .bold)

    /// 20pt Semibold - Card titles, subsection headers
    public static let title3 = Font.system(size: 20, weight: .semibold)

    // MARK: - Body Text
    // Used for content and interactive elements

    /// 17pt Semibold - Emphasized body text, button labels
    public static let headline = Font.system(size: 17, weight: .semibold)

    /// 17pt Regular - Primary body text
    public static let body = Font.system(size: 17, weight: .regular)

    /// 17pt Medium - Medium emphasis body text
    public static let bodyMedium = Font.system(size: 17, weight: .medium)

    /// 16pt Regular - Secondary body text
    public static let callout = Font.system(size: 16, weight: .regular)

    /// 15pt Regular - Supporting text, descriptions
    public static let subheadline = Font.system(size: 15, weight: .regular)

    /// 15pt Medium - Medium emphasis supporting text
    public static let subheadlineMedium = Font.system(size: 15, weight: .medium)

    // MARK: - Small Text
    // Used for metadata, captions, and labels

    /// 13pt Regular - Footnotes, timestamps
    public static let footnote = Font.system(size: 13, weight: .regular)

    /// 13pt Medium - Emphasized footnotes
    public static let footnoteMedium = Font.system(size: 13, weight: .medium)

    /// 12pt Regular - Captions, badges
    public static let caption = Font.system(size: 12, weight: .regular)

    /// 12pt Medium - Emphasized captions
    public static let captionMedium = Font.system(size: 12, weight: .medium)

    /// 11pt Regular - Smallest text, fine print
    public static let caption2 = Font.system(size: 11, weight: .regular)

    // MARK: - Special Styles

    /// Monospaced for numbers that need alignment
    public static let monoNumber = Font.system(size: 17, weight: .medium, design: .monospaced)

    /// Rounded for friendly numeric displays
    public static let roundedNumber = Font.system(size: 24, weight: .bold, design: .rounded)
}

// MARK: - Text Style Modifier

/// Consistent text styling modifier
public struct FuelTextStyle: ViewModifier {
    let font: Font
    let color: Color
    let lineSpacing: CGFloat

    public init(font: Font, color: Color = FuelColors.textPrimary, lineSpacing: CGFloat = 0) {
        self.font = font
        self.color = color
        self.lineSpacing = lineSpacing
    }

    public func body(content: Content) -> some View {
        content
            .font(font)
            .foregroundStyle(color)
            .lineSpacing(lineSpacing)
    }
}

// MARK: - View Extension

extension View {
    /// Apply Fuel text styling
    public func fuelText(
        _ font: Font,
        color: Color = FuelColors.textPrimary,
        lineSpacing: CGFloat = 0
    ) -> some View {
        modifier(FuelTextStyle(font: font, color: color, lineSpacing: lineSpacing))
    }

    /// Primary title style
    public func titleStyle() -> some View {
        fuelText(FuelTypography.title1, color: FuelColors.textPrimary)
    }

    /// Body text style
    public func bodyStyle() -> some View {
        fuelText(FuelTypography.body, color: FuelColors.textPrimary)
    }

    /// Secondary text style
    public func secondaryStyle() -> some View {
        fuelText(FuelTypography.subheadline, color: FuelColors.textSecondary)
    }

    /// Caption style
    public func captionStyle() -> some View {
        fuelText(FuelTypography.caption, color: FuelColors.textTertiary)
    }
}
