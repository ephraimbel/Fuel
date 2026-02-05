import SwiftUI

/// Fuel Design System - Calorie Ring
/// Premium animated circular progress indicator for daily calorie tracking
/// Hero element on the main dashboard

public struct CalorieRing: View {
    // MARK: - Properties

    let consumed: Int
    let target: Int
    let animate: Bool
    let showLabel: Bool
    let size: CGFloat

    @State private var animatedProgress: Double = 0
    @State private var hasAppeared = false

    // MARK: - Computed Properties

    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(Double(consumed) / Double(target), 1.5) // Allow overflow to 150%
    }

    private var remaining: Int {
        max(target - consumed, 0)
    }

    private var isOverTarget: Bool {
        consumed > target
    }

    private var overAmount: Int {
        max(consumed - target, 0)
    }

    private var ringColor: Color {
        if isOverTarget {
            return FuelColors.error
        } else if progress > 0.9 {
            return FuelColors.success
        } else {
            return FuelColors.primary
        }
    }

    // MARK: - Initialization

    public init(
        consumed: Int,
        target: Int,
        animate: Bool = true,
        showLabel: Bool = true,
        size: CGFloat = 240
    ) {
        self.consumed = consumed
        self.target = target
        self.animate = animate
        self.showLabel = showLabel
        self.size = size
    }

    // MARK: - Body

    public var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(
                    FuelColors.surfaceSecondary,
                    style: StrokeStyle(
                        lineWidth: FuelSpacing.ringLineWidth,
                        lineCap: .round
                    )
                )

            // Progress ring
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    ringGradient,
                    style: StrokeStyle(
                        lineWidth: FuelSpacing.ringLineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(animate ? FuelAnimations.springSlow : .none, value: animatedProgress)

            // Glow effect when near/at goal
            if progress > 0.9 && !isOverTarget {
                Circle()
                    .trim(from: 0, to: animatedProgress)
                    .stroke(
                        ringColor.opacity(0.3),
                        style: StrokeStyle(
                            lineWidth: FuelSpacing.ringLineWidth + 8,
                            lineCap: .round
                        )
                    )
                    .rotationEffect(.degrees(-90))
                    .blur(radius: 8)
            }

            // Center content
            if showLabel {
                centerLabel
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            guard !hasAppeared else { return }
            hasAppeared = true

            if animate {
                // Delay for visual effect
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(FuelAnimations.springSlow) {
                        animatedProgress = min(progress, 1.0)
                    }

                    // Haptic feedback at milestones
                    provideMilestoneHaptics()
                }
            } else {
                animatedProgress = min(progress, 1.0)
            }
        }
        .onChange(of: consumed) { _, _ in
            withAnimation(FuelAnimations.spring) {
                animatedProgress = min(progress, 1.0)
            }
        }
    }

    // MARK: - Subviews

    private var centerLabel: some View {
        VStack(spacing: FuelSpacing.xxs) {
            // Main number with animation
            if animate && hasAppeared {
                NumberRevealAnimation(targetValue: consumed, duration: 1.2) {
                    if progress >= 1.0 && !isOverTarget {
                        FuelHaptics.shared.celebration()
                    }
                }
                .font(FuelTypography.hero)
                .foregroundStyle(FuelColors.textPrimary)
            } else {
                Text("\(consumed)")
                    .font(FuelTypography.hero)
                    .foregroundStyle(FuelColors.textPrimary)
            }

            // Status text
            statusText
        }
    }

    @ViewBuilder
    private var statusText: some View {
        if isOverTarget {
            HStack(spacing: FuelSpacing.xxs) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 12))
                Text("\(overAmount) over")
            }
            .font(FuelTypography.subheadline)
            .foregroundStyle(FuelColors.error)
        } else if remaining == 0 {
            HStack(spacing: FuelSpacing.xxs) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 12))
                Text("Goal reached!")
            }
            .font(FuelTypography.subheadline)
            .foregroundStyle(FuelColors.success)
        } else {
            Text("\(remaining) remaining")
                .font(FuelTypography.subheadline)
                .foregroundStyle(FuelColors.textSecondary)
        }
    }

    // MARK: - Gradient

    private var ringGradient: AngularGradient {
        if isOverTarget {
            return AngularGradient(
                colors: [FuelColors.error.opacity(0.8), FuelColors.error],
                center: .center,
                startAngle: .degrees(0),
                endAngle: .degrees(360 * animatedProgress)
            )
        } else {
            return AngularGradient(
                colors: [FuelColors.primary.opacity(0.8), FuelColors.primary, FuelColors.primaryDark],
                center: .center,
                startAngle: .degrees(0),
                endAngle: .degrees(360 * animatedProgress)
            )
        }
    }

    // MARK: - Haptics

    private func provideMilestoneHaptics() {
        // Haptic at 25%, 50%, 75%, 100%
        let milestones = [0.25, 0.5, 0.75, 1.0]

        for (index, milestone) in milestones.enumerated() {
            if progress >= milestone {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.3) {
                    FuelHaptics.shared.milestone()
                }
            }
        }
    }
}

// MARK: - Compact Calorie Ring

/// Smaller version of CalorieRing for lists and cards
public struct CompactCalorieRing: View {
    let consumed: Int
    let target: Int
    let size: CGFloat

    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(Double(consumed) / Double(target), 1.0)
    }

    private var isOverTarget: Bool {
        consumed > target
    }

    public init(consumed: Int, target: Int, size: CGFloat = 48) {
        self.consumed = consumed
        self.target = target
        self.size = size
    }

    public var body: some View {
        ZStack {
            Circle()
                .stroke(FuelColors.surfaceSecondary, lineWidth: 4)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    isOverTarget ? FuelColors.error : FuelColors.primary,
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            Text("\(Int(progress * 100))%")
                .font(FuelTypography.caption)
                .foregroundStyle(FuelColors.textSecondary)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Weekly Ring Summary

/// Shows 7 mini rings for weekly overview
public struct WeeklyCalorieRings: View {
    let dailyData: [(consumed: Int, target: Int)]
    let dayLabels: [String]

    public init(dailyData: [(consumed: Int, target: Int)], dayLabels: [String] = ["M", "T", "W", "T", "F", "S", "S"]) {
        self.dailyData = dailyData
        self.dayLabels = dayLabels
    }

    public var body: some View {
        HStack(spacing: FuelSpacing.sm) {
            ForEach(0..<min(dailyData.count, 7), id: \.self) { index in
                VStack(spacing: FuelSpacing.xxs) {
                    CompactCalorieRing(
                        consumed: dailyData[index].consumed,
                        target: dailyData[index].target,
                        size: 36
                    )

                    Text(dayLabels[index])
                        .font(FuelTypography.caption)
                        .foregroundStyle(FuelColors.textTertiary)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Calorie Rings") {
    VStack(spacing: 32) {
        // Main ring - under target
        CalorieRing(consumed: 1450, target: 2000)

        // Main ring - at target
        CalorieRing(consumed: 2000, target: 2000, size: 180)

        // Main ring - over target
        CalorieRing(consumed: 2300, target: 2000, size: 180)

        // Compact rings
        HStack(spacing: 16) {
            CompactCalorieRing(consumed: 500, target: 2000)
            CompactCalorieRing(consumed: 1500, target: 2000)
            CompactCalorieRing(consumed: 2000, target: 2000)
            CompactCalorieRing(consumed: 2500, target: 2000)
        }

        // Weekly overview
        WeeklyCalorieRings(dailyData: [
            (1800, 2000), (2100, 2000), (1950, 2000), (2000, 2000),
            (1700, 2000), (2200, 2000), (1500, 2000)
        ])
    }
    .padding()
}
