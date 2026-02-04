import SwiftUI

/// Fuel Design System - Spacing & Layout
/// Consistent spacing based on 4px grid system
public struct FuelSpacing {

    // MARK: - Base Spacing Scale (4px grid)

    /// 2pt - Hairline spacing
    public static let xxxs: CGFloat = 2

    /// 4pt - Minimal spacing
    public static let xxs: CGFloat = 4

    /// 8pt - Tight spacing between related elements
    public static let xs: CGFloat = 8

    /// 12pt - Default spacing between related elements
    public static let sm: CGFloat = 12

    /// 16pt - Standard spacing
    public static let md: CGFloat = 16

    /// 20pt - Comfortable spacing
    public static let lg: CGFloat = 20

    /// 24pt - Generous spacing between sections
    public static let xl: CGFloat = 24

    /// 32pt - Large section breaks
    public static let xxl: CGFloat = 32

    /// 40pt - Major section breaks
    public static let xxxl: CGFloat = 40

    /// 48pt - Hero spacing
    public static let huge: CGFloat = 48

    /// 64pt - Maximum spacing
    public static let massive: CGFloat = 64

    // MARK: - Screen Layout

    /// Horizontal padding for screen content - 20pt
    public static let screenHorizontal: CGFloat = 20

    /// Top padding below navigation - 16pt
    public static let screenTop: CGFloat = 16

    /// Bottom padding above tab bar - 24pt
    public static let screenBottom: CGFloat = 24

    /// Safe area bottom additional padding
    public static let safeAreaBottom: CGFloat = 34

    // MARK: - Component Spacing

    /// Internal card padding - 20pt
    public static let cardPadding: CGFloat = 20

    /// Spacing between cards - 16pt
    public static let cardSpacing: CGFloat = 16

    /// List item vertical spacing - 12pt
    public static let listItemSpacing: CGFloat = 12

    /// Section vertical spacing - 32pt
    public static let sectionSpacing: CGFloat = 32

    /// Button internal horizontal padding - 24pt
    public static let buttonPaddingH: CGFloat = 24

    /// Button internal vertical padding - 16pt
    public static let buttonPaddingV: CGFloat = 16

    // MARK: - Corner Radius

    /// 6pt - Small elements (badges, chips)
    public static let radiusXs: CGFloat = 6

    /// 8pt - Small cards, inputs
    public static let radiusSm: CGFloat = 8

    /// 12pt - Medium elements, buttons
    public static let radiusMd: CGFloat = 12

    /// 16pt - Standard cards
    public static let radiusLg: CGFloat = 16

    /// 20pt - Large cards
    public static let radiusXl: CGFloat = 20

    /// 24pt - Bottom sheets, modals
    public static let radiusXxl: CGFloat = 24

    /// 9999pt - Fully rounded (pills, circles)
    public static let radiusFull: CGFloat = 9999

    // MARK: - Icon Sizes

    /// 16pt - Small inline icons
    public static let iconSm: CGFloat = 16

    /// 20pt - Standard icons
    public static let iconMd: CGFloat = 20

    /// 24pt - Large icons
    public static let iconLg: CGFloat = 24

    /// 28pt - Extra large icons
    public static let iconXl: CGFloat = 28

    /// 32pt - Hero icons
    public static let iconXxl: CGFloat = 32

    /// 48pt - Feature icons
    public static let iconHuge: CGFloat = 48

    // MARK: - Touch Targets

    /// Minimum touch target - 44pt (Apple HIG)
    public static let minTouchTarget: CGFloat = 44

    /// Standard button height - 52pt
    public static let buttonHeight: CGFloat = 52

    /// Large button height - 56pt
    public static let buttonHeightLarge: CGFloat = 56

    /// Small button height - 40pt
    public static let buttonHeightSmall: CGFloat = 40

    // MARK: - Progress Elements

    /// Calorie ring line width - 16pt
    public static let ringLineWidth: CGFloat = 16

    /// Macro bar height - 8pt
    public static let progressBarHeight: CGFloat = 8

    /// Thin progress bar - 4pt
    public static let progressBarThin: CGFloat = 4
}

// MARK: - Edge Insets Helpers

extension EdgeInsets {
    /// Standard screen padding
    public static let screenPadding = EdgeInsets(
        top: FuelSpacing.screenTop,
        leading: FuelSpacing.screenHorizontal,
        bottom: FuelSpacing.screenBottom,
        trailing: FuelSpacing.screenHorizontal
    )

    /// Card internal padding
    public static let cardPadding = EdgeInsets(
        top: FuelSpacing.cardPadding,
        leading: FuelSpacing.cardPadding,
        bottom: FuelSpacing.cardPadding,
        trailing: FuelSpacing.cardPadding
    )

    /// Horizontal only padding
    public static func horizontal(_ value: CGFloat) -> EdgeInsets {
        EdgeInsets(top: 0, leading: value, bottom: 0, trailing: value)
    }

    /// Vertical only padding
    public static func vertical(_ value: CGFloat) -> EdgeInsets {
        EdgeInsets(top: value, leading: 0, bottom: value, trailing: 0)
    }
}

// MARK: - View Extensions for Spacing

extension View {
    /// Apply standard screen horizontal padding
    public func screenPadding() -> some View {
        padding(.horizontal, FuelSpacing.screenHorizontal)
    }

    /// Apply card internal padding
    public func cardPadding() -> some View {
        padding(FuelSpacing.cardPadding)
    }
}
