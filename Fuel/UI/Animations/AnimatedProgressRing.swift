import SwiftUI

/// Animated Progress Ring
/// Circular progress indicator that animates from 0 to target value

struct AnimatedProgressRing: View {
    let progress: Double // 0.0 to 1.0
    let lineWidth: CGFloat
    let gradient: LinearGradient?
    let color: Color
    let backgroundColor: Color
    let duration: Double
    let showPercentage: Bool
    let percentageFont: Font
    let onAnimationComplete: (() -> Void)?

    @State private var animatedProgress: Double = 0
    @State private var hasAnimated = false

    init(
        progress: Double,
        lineWidth: CGFloat = 8,
        gradient: LinearGradient? = nil,
        color: Color = FuelColors.primary,
        backgroundColor: Color? = nil,
        duration: Double = 1.0,
        showPercentage: Bool = true,
        percentageFont: Font = .system(size: 14, weight: .semibold, design: .rounded),
        onAnimationComplete: (() -> Void)? = nil
    ) {
        self.progress = min(max(progress, 0), 1)
        self.lineWidth = lineWidth
        self.gradient = gradient
        self.color = color
        self.backgroundColor = backgroundColor ?? color.opacity(0.15)
        self.duration = duration
        self.showPercentage = showPercentage
        self.percentageFont = percentageFont
        self.onAnimationComplete = onAnimationComplete
    }

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(backgroundColor, lineWidth: lineWidth)

            // Progress ring
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    gradient ?? LinearGradient(colors: [color], startPoint: .top, endPoint: .bottom),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: color.opacity(0.3), radius: animatedProgress > 0 ? 4 : 0, x: 0, y: 2)

            // Percentage text
            if showPercentage {
                AnimatedPercentage(
                    value: animatedProgress,
                    duration: duration,
                    font: percentageFont,
                    color: FuelColors.textPrimary
                )
            }
        }
        .onAppear {
            guard !hasAnimated else { return }
            hasAnimated = true
            animateProgress()
        }
        .onChange(of: progress) { _, newValue in
            animateProgress(to: newValue)
        }
    }

    private func animateProgress(to target: Double? = nil) {
        let targetValue = target ?? progress

        withAnimation(.easeOut(duration: duration)) {
            animatedProgress = targetValue
        }

        // Haptic feedback when animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            if animatedProgress > 0 {
                FuelHaptics.shared.tap()
            }
            onAnimationComplete?()
        }
    }
}

/// Animated Macro Ring
/// Specialized progress ring for macro nutrients

struct AnimatedMacroRing: View {
    let name: String
    let value: Double
    let goal: Double
    let color: Color
    let delay: Double

    @State private var isVisible = false

    private var progress: Double {
        goal > 0 ? min(value / goal, 1.0) : 0
    }

    var body: some View {
        VStack(spacing: FuelSpacing.sm) {
            AnimatedProgressRing(
                progress: isVisible ? progress : 0,
                lineWidth: 6,
                color: color,
                duration: 1.0,
                showPercentage: true,
                percentageFont: .system(size: 13, weight: .semibold, design: .rounded)
            )
            .frame(width: 56, height: 56)

            VStack(spacing: 2) {
                if isVisible {
                    AnimatedInteger(
                        value: Int(value),
                        suffix: "g",
                        duration: 0.8,
                        font: FuelTypography.subheadlineMedium,
                        color: FuelColors.textPrimary
                    )
                } else {
                    Text("0g")
                        .font(FuelTypography.subheadlineMedium)
                        .foregroundStyle(FuelColors.textPrimary)
                }

                Text(name)
                    .font(FuelTypography.caption)
                    .foregroundStyle(FuelColors.textTertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, FuelSpacing.md)
        .padding(.horizontal, FuelSpacing.sm)
        .background(FuelColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation {
                    isVisible = true
                }
            }
        }
    }
}

/// Mini Calorie Ring for Weekly Overview
/// Smaller ring with day indicator

struct MiniCalorieRing: View {
    let day: String
    let calories: Int
    let goal: Int
    let isToday: Bool
    let delay: Double

    @State private var isVisible = false

    private var progress: Double {
        goal > 0 ? min(Double(calories) / Double(goal), 1.0) : 0
    }

    private var isOverGoal: Bool {
        calories > goal
    }

    private var ringColor: Color {
        if calories == 0 {
            return FuelColors.textTertiary
        } else if isOverGoal {
            return FuelColors.error
        } else {
            return FuelColors.primary
        }
    }

    var body: some View {
        VStack(spacing: FuelSpacing.xs) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(ringColor.opacity(0.15), lineWidth: 4)

                // Progress ring
                Circle()
                    .trim(from: 0, to: isVisible ? progress : 0)
                    .stroke(ringColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.8).delay(delay), value: isVisible)

                // Checkmark or calories
                if calories > 0 && !isOverGoal {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(FuelColors.primary)
                        .scaleEffect(isVisible ? 1 : 0)
                        .animation(.spring(response: 0.4, dampingFraction: 0.6).delay(delay + 0.3), value: isVisible)
                }
            }
            .frame(width: 32, height: 32)

            Text(day)
                .font(.system(size: 10, weight: isToday ? .bold : .regular))
                .foregroundStyle(isToday ? FuelColors.primary : FuelColors.textSecondary)
        }
        .onAppear {
            isVisible = true
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 40) {
        AnimatedProgressRing(
            progress: 0.75,
            lineWidth: 10,
            color: FuelColors.primary
        )
        .frame(width: 100, height: 100)

        HStack {
            AnimatedMacroRing(name: "Protein", value: 120, goal: 150, color: FuelColors.protein, delay: 0)
            AnimatedMacroRing(name: "Carbs", value: 180, goal: 200, color: FuelColors.carbs, delay: 0.1)
            AnimatedMacroRing(name: "Fat", value: 55, goal: 65, color: FuelColors.fat, delay: 0.2)
        }
        .padding()

        HStack(spacing: FuelSpacing.md) {
            MiniCalorieRing(day: "Mon", calories: 1800, goal: 2000, isToday: false, delay: 0)
            MiniCalorieRing(day: "Tue", calories: 2100, goal: 2000, isToday: false, delay: 0.1)
            MiniCalorieRing(day: "Wed", calories: 1950, goal: 2000, isToday: true, delay: 0.2)
        }
    }
    .padding()
    .background(FuelColors.background)
}
