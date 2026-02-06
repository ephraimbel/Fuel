import SwiftUI

/// Daily Progress Card
/// Premium card showing calorie ring and macro progress with gradients and animations

struct DailyProgressCard: View {
    let totalCalories: Int
    let calorieGoal: Int
    let remainingCalories: Int
    let calorieProgress: Double
    let proteinProgress: Double
    let carbsProgress: Double
    let fatProgress: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let proteinGoal: Double
    let carbsGoal: Double
    let fatGoal: Double
    let isOverGoal: Bool

    @State private var animatedProgress: Double = 0
    @State private var animatedProtein: Double = 0
    @State private var animatedCarbs: Double = 0
    @State private var animatedFat: Double = 0
    @State private var showCalories = false

    var body: some View {
        VStack(spacing: FuelSpacing.lg) {
            // Calorie ring section
            HStack(spacing: FuelSpacing.xl) {
                calorieRing
                calorieStats
            }

            // Macro progress bars
            macroProgressSection
        }
        .padding(FuelSpacing.xl)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: FuelSpacing.radiusXl)
                    .fill(FuelColors.heroCardGradient)

                // Subtle accent glow in corner
                Circle()
                    .fill(FuelColors.primary.opacity(0.04))
                    .frame(width: 200, height: 200)
                    .blur(radius: 60)
                    .offset(x: 80, y: -60)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusXl))
        .overlay(
            RoundedRectangle(cornerRadius: FuelSpacing.radiusXl)
                .stroke(FuelColors.border.opacity(0.5), lineWidth: 0.5)
        )
        .heroShadow()
        .onAppear {
            animateProgress()
        }
        .onChange(of: calorieProgress) { _, _ in
            animateProgress()
        }
    }

    // MARK: - Premium Calorie Ring

    private var calorieRing: some View {
        ZStack {
            // Background ring (empty part)
            Circle()
                .stroke(FuelColors.surfaceSecondary.opacity(0.8), lineWidth: 14)
                .frame(width: 140, height: 140)

            // Glow behind filled portion
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    ringColor.opacity(0.35),
                    style: StrokeStyle(lineWidth: 22, lineCap: .round)
                )
                .frame(width: 140, height: 140)
                .rotationEffect(.degrees(-90))
                .blur(radius: 10)

            // Progress ring with gradient
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    ringGradient,
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .frame(width: 140, height: 140)
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.8, dampingFraction: 0.7), value: animatedProgress)

            // Center content
            VStack(spacing: FuelSpacing.xxxs) {
                if showCalories {
                    Text("\(totalCalories)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(isOverGoal ? FuelColors.error : FuelColors.textPrimary)
                        .contentTransition(.numericText())

                    Text("eaten")
                        .font(FuelTypography.caption)
                        .foregroundStyle(FuelColors.textTertiary)
                } else {
                    ProgressView()
                        .tint(FuelColors.primary)
                }
            }
        }
    }

    // Solid color for glow
    private var ringColor: Color {
        if isOverGoal {
            return FuelColors.error
        } else if animatedProgress >= 1.0 {
            return FuelColors.success
        } else {
            return FuelColors.primary
        }
    }

    // Ring gradient based on state
    private var ringGradient: LinearGradient {
        if isOverGoal {
            return LinearGradient(
                colors: [FuelColors.error, FuelColors.error.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if animatedProgress >= 1.0 {
            return LinearGradient(
                colors: [FuelColors.success, FuelColors.success.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [FuelColors.primary, FuelColors.primary.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    // MARK: - Calorie Stats

    private var calorieStats: some View {
        VStack(alignment: .leading, spacing: FuelSpacing.md) {
            VStack(alignment: .leading, spacing: FuelSpacing.xxxs) {
                HStack(spacing: FuelSpacing.xs) {
                    Circle()
                        .fill(isOverGoal ? FuelColors.error : FuelColors.primary)
                        .frame(width: 8, height: 8)

                    Text(isOverGoal ? "Over by" : "Remaining")
                        .font(FuelTypography.caption)
                        .foregroundStyle(FuelColors.textSecondary)
                }

                Text("\(isOverGoal ? totalCalories - calorieGoal : remainingCalories)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(isOverGoal ? FuelColors.error : FuelColors.textPrimary)
                + Text(" cal")
                    .font(FuelTypography.subheadline)
                    .foregroundStyle(FuelColors.textSecondary)
            }

            Divider()

            VStack(alignment: .leading, spacing: FuelSpacing.xxxs) {
                Text("Daily Goal")
                    .font(FuelTypography.caption)
                    .foregroundStyle(FuelColors.textTertiary)

                Text("\(calorieGoal) cal")
                    .font(FuelTypography.subheadlineMedium)
                    .foregroundStyle(FuelColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Premium Macro Progress Section

    private var macroProgressSection: some View {
        HStack(spacing: FuelSpacing.sm) {
            PremiumMacroBar(
                name: "Protein",
                current: protein,
                goal: proteinGoal,
                animatedProgress: animatedProtein,
                color: FuelColors.protein
            )

            PremiumMacroBar(
                name: "Carbs",
                current: carbs,
                goal: carbsGoal,
                animatedProgress: animatedCarbs,
                color: FuelColors.carbs
            )

            PremiumMacroBar(
                name: "Fat",
                current: fat,
                goal: fatGoal,
                animatedProgress: animatedFat,
                color: FuelColors.fat
            )
        }
        .padding(FuelSpacing.md)
        .background(FuelColors.surfaceSecondary.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
    }

    // MARK: - Animation

    private func animateProgress() {
        // Stagger animations for premium feel
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
            animatedProgress = min(calorieProgress, 1.0)
        }

        // Animate macros with stagger
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                animatedProtein = min(proteinProgress, 1.0)
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                animatedCarbs = min(carbsProgress, 1.0)
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                animatedFat = min(fatProgress, 1.0)
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 0.4)) {
                showCalories = true
            }
        }

        // Haptic on calorie goal completion
        if calorieProgress >= 1.0 && !isOverGoal {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                FuelHaptics.shared.success()
            }
        }
    }
}

// MARK: - Premium Macro Bar Component

struct PremiumMacroBar: View {
    let name: String
    let current: Double
    let goal: Double
    let animatedProgress: Double
    let color: Color

    @State private var showCompletion = false
    @State private var pulseScale: CGFloat = 1.0

    private var isComplete: Bool {
        current >= goal
    }

    var body: some View {
        VStack(spacing: FuelSpacing.sm) {
            // Progress bar with gradient
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color.opacity(0.15))
                        .frame(height: 8)

                    // Gradient progress fill
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * animatedProgress, height: 8)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: animatedProgress)

                    // Glow on completion
                    if isComplete {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(color.opacity(0.3))
                            .frame(width: geometry.size.width * animatedProgress, height: 8)
                            .blur(radius: 4)
                            .scaleEffect(y: pulseScale)
                    }
                }
            }
            .frame(height: 8)

            // Label with completion state
            VStack(spacing: FuelSpacing.xxxs) {
                HStack(spacing: 2) {
                    Text("\(Int(current))g")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(FuelColors.textPrimary)

                    // Checkmark on completion
                    if isComplete && showCompletion {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(color)
                            .transition(.scale.combined(with: .opacity))
                    }
                }

                Text(name)
                    .font(FuelTypography.caption)
                    .foregroundStyle(FuelColors.textTertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .onChange(of: animatedProgress) { _, newValue in
            if newValue >= 1.0 && isComplete {
                // Trigger completion animation
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    showCompletion = true
                }

                // Pulse animation
                withAnimation(.easeInOut(duration: 0.3).repeatCount(2, autoreverses: true)) {
                    pulseScale = 1.3
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    withAnimation(.easeOut(duration: 0.2)) {
                        pulseScale = 1.0
                    }
                }

                // Haptic feedback
                FuelHaptics.shared.success()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            // Under goal
            DailyProgressCard(
                totalCalories: 1420,
                calorieGoal: 2000,
                remainingCalories: 580,
                calorieProgress: 0.71,
                proteinProgress: 0.6,
                carbsProgress: 0.45,
                fatProgress: 0.8,
                protein: 90,
                carbs: 90,
                fat: 52,
                proteinGoal: 150,
                carbsGoal: 200,
                fatGoal: 65,
                isOverGoal: false
            )

            // At goal with completions
            DailyProgressCard(
                totalCalories: 2000,
                calorieGoal: 2000,
                remainingCalories: 0,
                calorieProgress: 1.0,
                proteinProgress: 1.0,
                carbsProgress: 1.0,
                fatProgress: 1.0,
                protein: 150,
                carbs: 200,
                fat: 65,
                proteinGoal: 150,
                carbsGoal: 200,
                fatGoal: 65,
                isOverGoal: false
            )

            // Over goal
            DailyProgressCard(
                totalCalories: 2300,
                calorieGoal: 2000,
                remainingCalories: 0,
                calorieProgress: 1.15,
                proteinProgress: 0.9,
                carbsProgress: 1.1,
                fatProgress: 1.2,
                protein: 135,
                carbs: 220,
                fat: 78,
                proteinGoal: 150,
                carbsGoal: 200,
                fatGoal: 65,
                isOverGoal: true
            )
        }
        .padding()
    }
    .background(FuelColors.background)
}
