import SwiftUI

/// Fuel Design System - Macro Progress Bars
/// Premium animated progress bars for protein, carbs, and fat tracking

// MARK: - Macro Type

public enum MacroType: String, CaseIterable {
    case protein
    case carbs
    case fat

    var color: Color {
        switch self {
        case .protein: return FuelColors.protein
        case .carbs: return FuelColors.carbs
        case .fat: return FuelColors.fat
        }
    }

    var emoji: String {
        switch self {
        case .protein: return "🥩"
        case .carbs: return "🌾"
        case .fat: return "🥑"
        }
    }

    /// SF Symbol name (kept for fallback contexts)
    var icon: String {
        switch self {
        case .protein: return "fish.fill"
        case .carbs: return "leaf.fill"
        case .fat: return "drop.circle.fill"
        }
    }

    var label: String {
        rawValue.capitalized
    }

    var unit: String {
        "g"
    }
}

// MARK: - Macro Icon View

/// Renders the appropriate emoji icon for each macro
struct MacroIconView: View {
    let type: MacroType
    var size: CGFloat = 12

    var body: some View {
        Text(type.emoji)
            .font(.system(size: size))
    }
}

// MARK: - Single Macro Progress Bar

public struct MacroProgressBar: View {
    let type: MacroType
    let current: Double
    let target: Double
    let showLabel: Bool
    let animate: Bool
    let height: CGFloat

    @State private var animatedProgress: Double = 0
    @State private var hasAppeared = false

    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(current / target, 1.0)
    }

    private var isComplete: Bool {
        current >= target
    }

    public init(
        type: MacroType,
        current: Double,
        target: Double,
        showLabel: Bool = true,
        animate: Bool = true,
        height: CGFloat = FuelSpacing.progressBarHeight
    ) {
        self.type = type
        self.current = current
        self.target = target
        self.showLabel = showLabel
        self.animate = animate
        self.height = height
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: FuelSpacing.xs) {
            // Label row
            if showLabel {
                HStack {
                    // Icon and name
                    HStack(spacing: FuelSpacing.xxs) {
                        MacroIconView(type: type, size: 12)

                        Text(type.label)
                            .font(FuelTypography.subheadline)
                            .foregroundStyle(FuelColors.textPrimary)
                    }

                    Spacer()

                    // Values
                    HStack(spacing: FuelSpacing.xxxs) {
                        Text("\(Int(current))")
                            .font(FuelTypography.subheadlineMedium)
                            .foregroundStyle(FuelColors.textPrimary)

                        Text("/ \(Int(target))\(type.unit)")
                            .font(FuelTypography.caption)
                            .foregroundStyle(FuelColors.textTertiary)
                    }
                }
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: height / 2, style: .continuous)
                        .fill(FuelColors.surfaceSecondary)

                    // Progress fill
                    RoundedRectangle(cornerRadius: height / 2, style: .continuous)
                        .fill(type.color)
                        .frame(width: geometry.size.width * animatedProgress)

                    // Glow when complete
                    if isComplete {
                        RoundedRectangle(cornerRadius: height / 2, style: .continuous)
                            .fill(type.color.opacity(0.3))
                            .frame(width: geometry.size.width * animatedProgress)
                            .blur(radius: 4)
                    }
                }
            }
            .frame(height: height)
        }
        .onAppear {
            guard !hasAppeared else { return }
            hasAppeared = true

            if animate {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(FuelAnimations.spring) {
                        animatedProgress = progress
                    }
                }
            } else {
                animatedProgress = progress
            }
        }
        .onChange(of: current) { _, _ in
            withAnimation(FuelAnimations.spring) {
                animatedProgress = progress
            }
        }
    }
}

// MARK: - Macro Summary View

/// Shows all three macros in a compact layout
public struct MacroSummary: View {
    let protein: (current: Double, target: Double)
    let carbs: (current: Double, target: Double)
    let fat: (current: Double, target: Double)
    let layout: Layout
    let animate: Bool

    public enum Layout {
        case vertical   // Stacked bars
        case horizontal // Side by side circles
        case compact    // Minimal inline
    }

    public init(
        protein: (current: Double, target: Double),
        carbs: (current: Double, target: Double),
        fat: (current: Double, target: Double),
        layout: Layout = .vertical,
        animate: Bool = true
    ) {
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.layout = layout
        self.animate = animate
    }

    public var body: some View {
        switch layout {
        case .vertical:
            verticalLayout
        case .horizontal:
            horizontalLayout
        case .compact:
            compactLayout
        }
    }

    // MARK: - Layouts

    private var verticalLayout: some View {
        VStack(spacing: FuelSpacing.md) {
            MacroProgressBar(type: .protein, current: protein.current, target: protein.target, animate: animate)
            MacroProgressBar(type: .carbs, current: carbs.current, target: carbs.target, animate: animate)
            MacroProgressBar(type: .fat, current: fat.current, target: fat.target, animate: animate)
        }
    }

    private var horizontalLayout: some View {
        HStack(spacing: FuelSpacing.xl) {
            MacroCircle(type: .protein, current: protein.current, target: protein.target, animate: animate)
            MacroCircle(type: .carbs, current: carbs.current, target: carbs.target, animate: animate)
            MacroCircle(type: .fat, current: fat.current, target: fat.target, animate: animate)
        }
    }

    private var compactLayout: some View {
        HStack(spacing: FuelSpacing.md) {
            compactMacro(type: .protein, current: protein.current, target: protein.target)
            compactMacro(type: .carbs, current: carbs.current, target: carbs.target)
            compactMacro(type: .fat, current: fat.current, target: fat.target)
        }
    }

    private func compactMacro(type: MacroType, current: Double, target: Double) -> some View {
        HStack(spacing: FuelSpacing.xxs) {
            Circle()
                .fill(type.color)
                .frame(width: 8, height: 8)

            Text("\(Int(current))g")
                .font(FuelTypography.caption)
                .foregroundStyle(FuelColors.textSecondary)
        }
    }
}

// MARK: - Macro Circle

/// Circular progress indicator for a single macro
public struct MacroCircle: View {
    let type: MacroType
    let current: Double
    let target: Double
    let size: CGFloat
    let animate: Bool

    @State private var animatedProgress: Double = 0
    @State private var hasAppeared = false

    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(current / target, 1.0)
    }

    public init(
        type: MacroType,
        current: Double,
        target: Double,
        size: CGFloat = 64,
        animate: Bool = true
    ) {
        self.type = type
        self.current = current
        self.target = target
        self.size = size
        self.animate = animate
    }

    public var body: some View {
        VStack(spacing: FuelSpacing.xs) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(type.color.opacity(0.2), lineWidth: 6)

                // Progress ring
                Circle()
                    .trim(from: 0, to: animatedProgress)
                    .stroke(
                        type.color,
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                // Icon
                MacroIconView(type: type, size: size * 0.3)
            }
            .frame(width: size, height: size)

            // Label
            VStack(spacing: 0) {
                Text("\(Int(current))")
                    .font(FuelTypography.subheadlineMedium)
                    .foregroundStyle(FuelColors.textPrimary)

                Text(type.label)
                    .font(FuelTypography.caption)
                    .foregroundStyle(FuelColors.textTertiary)
            }
        }
        .onAppear {
            guard !hasAppeared else { return }
            hasAppeared = true

            if animate {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(FuelAnimations.spring) {
                        animatedProgress = progress
                    }
                }
            } else {
                animatedProgress = progress
            }
        }
        .onChange(of: current) { _, _ in
            withAnimation(FuelAnimations.spring) {
                animatedProgress = progress
            }
        }
    }
}

// MARK: - Macro Breakdown Card

/// Full card showing macro breakdown with percentages
public struct MacroBreakdownCard: View {
    let protein: (current: Double, target: Double)
    let carbs: (current: Double, target: Double)
    let fat: (current: Double, target: Double)

    private var totalCalories: Double {
        (protein.current * 4) + (carbs.current * 4) + (fat.current * 9)
    }

    private var proteinPercent: Double {
        guard totalCalories > 0 else { return 0 }
        return (protein.current * 4) / totalCalories * 100
    }

    private var carbsPercent: Double {
        guard totalCalories > 0 else { return 0 }
        return (carbs.current * 4) / totalCalories * 100
    }

    private var fatPercent: Double {
        guard totalCalories > 0 else { return 0 }
        return (fat.current * 9) / totalCalories * 100
    }

    public init(
        protein: (current: Double, target: Double),
        carbs: (current: Double, target: Double),
        fat: (current: Double, target: Double)
    ) {
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
    }

    public var body: some View {
        FuelCard {
            VStack(spacing: FuelSpacing.md) {
                // Header
                HStack {
                    Text("Macro Breakdown")
                        .font(FuelTypography.headline)
                        .foregroundStyle(FuelColors.textPrimary)

                    Spacer()

                    Text("\(Int(totalCalories)) cal")
                        .font(FuelTypography.subheadline)
                        .foregroundStyle(FuelColors.textSecondary)
                }

                // Stacked bar
                GeometryReader { geometry in
                    HStack(spacing: 2) {
                        // Protein segment
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(FuelColors.protein)
                            .frame(width: max(geometry.size.width * proteinPercent / 100, 4))

                        // Carbs segment
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(FuelColors.carbs)
                            .frame(width: max(geometry.size.width * carbsPercent / 100, 4))

                        // Fat segment
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(FuelColors.fat)
                            .frame(width: max(geometry.size.width * fatPercent / 100, 4))
                    }
                }
                .frame(height: 12)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

                // Legend
                HStack(spacing: FuelSpacing.lg) {
                    macroLegendItem(type: .protein, value: protein.current, percent: proteinPercent)
                    macroLegendItem(type: .carbs, value: carbs.current, percent: carbsPercent)
                    macroLegendItem(type: .fat, value: fat.current, percent: fatPercent)
                }
            }
        }
    }

    private func macroLegendItem(type: MacroType, value: Double, percent: Double) -> some View {
        VStack(alignment: .leading, spacing: FuelSpacing.xxxs) {
            HStack(spacing: FuelSpacing.xxs) {
                Circle()
                    .fill(type.color)
                    .frame(width: 8, height: 8)

                Text(type.label)
                    .font(FuelTypography.caption)
                    .foregroundStyle(FuelColors.textSecondary)
            }

            Text("\(Int(value))g (\(Int(percent))%)")
                .font(FuelTypography.subheadlineMedium)
                .foregroundStyle(FuelColors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Preview

#Preview("Macro Progress") {
    ScrollView {
        VStack(spacing: 24) {
            // Individual bars
            VStack(spacing: 16) {
                MacroProgressBar(type: .protein, current: 85, target: 150)
                MacroProgressBar(type: .carbs, current: 200, target: 250)
                MacroProgressBar(type: .fat, current: 55, target: 65)
            }
            .padding()
            .background(FuelColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            // Circles layout
            MacroSummary(
                protein: (85, 150),
                carbs: (200, 250),
                fat: (55, 65),
                layout: .horizontal
            )
            .padding()
            .background(FuelColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            // Compact layout
            MacroSummary(
                protein: (85, 150),
                carbs: (200, 250),
                fat: (55, 65),
                layout: .compact
            )
            .padding()
            .background(FuelColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            // Breakdown card
            MacroBreakdownCard(
                protein: (85, 150),
                carbs: (200, 250),
                fat: (55, 65)
            )
        }
        .padding()
    }
    .background(FuelColors.background)
}
