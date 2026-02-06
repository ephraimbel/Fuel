import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Color Extension for Hex

extension Color {
    /// Initialize a Color from a hex string
    /// - Parameter hex: Hex color string (6 or 8 characters, with or without #)
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: // RGB
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    /// Create an adaptive color that changes between light and dark mode
    /// - Parameters:
    ///   - light: Color to use in light mode
    ///   - dark: Color to use in dark mode
    init(light: Color, dark: Color) {
        #if canImport(UIKit)
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
        #else
        self = light // Fallback for non-UIKit platforms
        #endif
    }
}

// MARK: - Fuel Design System - Color Palette

/// Premium color system with full dark mode support
public struct FuelColors {

    // MARK: - Brand Colors

    /// Primary brand red - Used for CTAs, active states, progress indicators
    /// #E54D4D - Coral Red
    public static let primary = Color(hex: "E54D4D")

    /// Light variant for selected states and subtle highlights
    /// #FEE2E2 - Light pink/red
    public static let primaryLight = Color(hex: "FEE2E2")

    /// Dark variant for pressed states
    /// #DC2626 - Darker red
    public static let primaryDark = Color(hex: "DC2626")

    // MARK: - Background Colors (Adaptive)

    /// Main screen background
    /// Light: #FAFAFA | Dark: #000000
    public static var background: Color {
        Color(light: Color(hex: "FAFAFA"), dark: Color(hex: "000000"))
    }

    /// Card and elevated surface background
    /// Light: #FFFFFF | Dark: #1C1C1E
    public static var surface: Color {
        Color(light: Color(hex: "FFFFFF"), dark: Color(hex: "1C1C1E"))
    }

    /// Secondary surface for inputs and subtle containers
    /// Light: #F3F4F6 | Dark: #2C2C2E
    public static var surfaceSecondary: Color {
        Color(light: Color(hex: "F3F4F6"), dark: Color(hex: "2C2C2E"))
    }

    /// Elevated surface with more prominence
    /// Light: #FFFFFF | Dark: #2C2C2E
    public static var surfaceElevated: Color {
        Color(light: Color(hex: "FFFFFF"), dark: Color(hex: "2C2C2E"))
    }

    // MARK: - Text Colors (Adaptive)

    /// Primary text - Headlines, important content
    /// Light: #1A1A1A | Dark: #FFFFFF
    public static var textPrimary: Color {
        Color(light: Color(hex: "1A1A1A"), dark: Color(hex: "FFFFFF"))
    }

    /// Secondary text - Supporting content, labels
    /// Light: #6B7280 | Dark: #A1A1A6
    public static var textSecondary: Color {
        Color(light: Color(hex: "6B7280"), dark: Color(hex: "A1A1A6"))
    }

    /// Tertiary text - Placeholders, timestamps
    /// Light: #9CA3AF | Dark: #636366
    public static var textTertiary: Color {
        Color(light: Color(hex: "9CA3AF"), dark: Color(hex: "636366"))
    }

    // MARK: - Macro Colors (Consistent across modes)

    /// Protein - Purple
    public static let protein = Color(hex: "8B5CF6")

    /// Carbohydrates - Amber
    public static let carbs = Color(hex: "F59E0B")

    /// Fat - Pink
    public static let fat = Color(hex: "EC4899")

    /// Fiber - Emerald
    public static let fiber = Color(hex: "10B981")

    // MARK: - Semantic Colors

    /// Success states, positive feedback, goals achieved
    public static let success = Color(hex: "10B981")

    /// Warning states, approaching limits
    public static let warning = Color(hex: "F59E0B")

    /// Error states, over target, destructive actions
    public static let error = Color(hex: "EF4444")

    /// Informational highlights
    public static let info = Color(hex: "3B82F6")

    // MARK: - Border Colors (Adaptive)

    /// Standard border
    /// Light: #E5E7EB | Dark: #3A3A3C
    public static var border: Color {
        Color(light: Color(hex: "E5E7EB"), dark: Color(hex: "3A3A3C"))
    }

    /// Light border for subtle separation
    /// Light: #F3F4F6 | Dark: #2C2C2E
    public static var borderLight: Color {
        Color(light: Color(hex: "F3F4F6"), dark: Color(hex: "2C2C2E"))
    }

    // MARK: - Special Colors

    /// Streak flame color
    public static let streak = Color(hex: "FF6B35")

    /// Gold for achievements
    public static let gold = Color(hex: "FFD700")

    /// Silver for secondary achievements
    public static let silver = Color(hex: "C0C0C0")

    /// Bronze for tertiary achievements
    public static let bronze = Color(hex: "CD7F32")

    /// Platinum for top achievements
    public static let platinum = Color(hex: "E5E4E2")
}

// MARK: - Gradient Presets

extension FuelColors {
    /// Primary gradient for hero elements
    public static let primaryGradient = LinearGradient(
        colors: [primary, primaryDark],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Success gradient for achievements
    public static let successGradient = LinearGradient(
        colors: [success, Color(hex: "059669")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Gold gradient for premium achievements
    public static let goldGradient = LinearGradient(
        colors: [gold, Color(hex: "FFA500")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Streak gradient
    public static let streakGradient = LinearGradient(
        colors: [streak, Color(hex: "FF8C42")],
        startPoint: .bottom,
        endPoint: .top
    )

    // MARK: - Premium Card Gradients

    /// Hero card gradient - warm subtle tint
    public static var heroCardGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(light: Color(hex: "FFFFFF"), dark: Color(hex: "1C1C1E")),
                Color(light: Color(hex: "FFF8F6"), dark: Color(hex: "1E1A1A"))
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Screen background gradient for depth
    public static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(light: Color(hex: "F8F5F3"), dark: Color(hex: "000000")),
                Color(light: Color(hex: "FAFAFA"), dark: Color(hex: "050505")),
                Color(light: Color(hex: "F5F3F1"), dark: Color(hex: "000000"))
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - Premium Shadow System

extension View {
    /// Standard card shadow - visible, layered for depth
    func cardShadow() -> some View {
        self
            .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
            .shadow(color: .black.opacity(0.03), radius: 2, x: 0, y: 1)
    }

    /// Hero card shadow - stronger, with color tint
    func heroShadow(color: Color = FuelColors.primary) -> some View {
        self
            .shadow(color: .black.opacity(0.08), radius: 20, x: 0, y: 8)
            .shadow(color: color.opacity(0.12), radius: 16, x: 0, y: 6)
            .shadow(color: .black.opacity(0.03), radius: 2, x: 0, y: 1)
    }

    /// Subtle card shadow for secondary elements
    func subtleShadow() -> some View {
        self
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
            .shadow(color: .black.opacity(0.02), radius: 1, x: 0, y: 1)
    }
}
