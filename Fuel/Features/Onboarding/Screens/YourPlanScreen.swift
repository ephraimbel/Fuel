import SwiftUI

/// Your Plan Screen
/// Shows the calculated personalized plan with calories and macros

struct YourPlanScreen: View {
    @Bindable var viewModel: OnboardingViewModel

    @State private var showCalories = false
    @State private var showMacros = false
    @State private var showTimeline = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: FuelSpacing.xl) {
                // Header
                VStack(spacing: FuelSpacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(FuelColors.success)
                        .scaleEffect(showCalories ? 1 : 0.5)
                        .opacity(showCalories ? 1 : 0)

                    Text("Your Personalized Plan")
                        .font(FuelTypography.title1)
                        .foregroundStyle(FuelColors.textPrimary)

                    Text("Based on your goals and activity level")
                        .font(FuelTypography.body)
                        .foregroundStyle(FuelColors.textSecondary)
                }
                .padding(.top, FuelSpacing.xl)
                .animation(FuelAnimations.springBouncy, value: showCalories)

                // Calorie target
                calorieCard
                    .opacity(showCalories ? 1 : 0)
                    .offset(y: showCalories ? 0 : 30)
                    .animation(FuelAnimations.spring.delay(0.2), value: showCalories)

                // Macro breakdown
                macroCard
                    .opacity(showMacros ? 1 : 0)
                    .offset(y: showMacros ? 0 : 30)
                    .animation(FuelAnimations.spring.delay(0.1), value: showMacros)

                // Timeline (for weight goals)
                if viewModel.selectedGoal != .maintain {
                    timelineCard
                        .opacity(showTimeline ? 1 : 0)
                        .offset(y: showTimeline ? 0 : 30)
                        .animation(FuelAnimations.spring.delay(0.1), value: showTimeline)
                }

                Spacer()
                    .frame(height: FuelSpacing.huge)
            }
            .padding(.horizontal, FuelSpacing.screenHorizontal)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: FuelSpacing.sm) {
                FuelButton("Looks Great!") {
                    viewModel.nextStep()
                }

                Button {
                    FuelHaptics.shared.tap()
                    viewModel.goToStep(.goal)
                } label: {
                    Text("Adjust my goals")
                        .font(FuelTypography.subheadline)
                        .foregroundStyle(FuelColors.primary)
                }
            }
            .padding(.horizontal, FuelSpacing.screenHorizontal)
            .padding(.vertical, FuelSpacing.lg)
            .background(FuelColors.background)
        }
        .onAppear {
            animateIn()
        }
    }

    // MARK: - Calorie Card

    private var calorieCard: some View {
        FuelCard {
            VStack(spacing: FuelSpacing.md) {
                Text("Daily Calorie Target")
                    .font(FuelTypography.subheadline)
                    .foregroundStyle(FuelColors.textSecondary)

                HStack(alignment: .firstTextBaseline, spacing: FuelSpacing.xs) {
                    Text("\(viewModel.calculatedCalories)")
                        .font(FuelTypography.hero)
                        .foregroundStyle(FuelColors.primary)

                    Text("calories")
                        .font(FuelTypography.title3)
                        .foregroundStyle(FuelColors.textSecondary)
                }

                // Goal indicator
                HStack(spacing: FuelSpacing.xs) {
                    Image(systemName: viewModel.selectedGoal.icon)
                        .font(.system(size: 14))

                    Text(viewModel.selectedGoal == .lose ? "Caloric deficit for weight loss" :
                         viewModel.selectedGoal == .gain ? "Caloric surplus for muscle gain" :
                         "Maintenance calories")
                        .font(FuelTypography.caption)
                }
                .foregroundStyle(FuelColors.textSecondary)
            }
        }
    }

    // MARK: - Macro Card

    private var macroCard: some View {
        FuelCard {
            VStack(spacing: FuelSpacing.md) {
                Text("Daily Macro Targets")
                    .font(FuelTypography.subheadline)
                    .foregroundStyle(FuelColors.textSecondary)

                HStack(spacing: FuelSpacing.lg) {
                    macroItem(
                        label: "Protein",
                        value: viewModel.calculatedProtein,
                        color: FuelColors.protein
                    )

                    macroItem(
                        label: "Carbs",
                        value: viewModel.calculatedCarbs,
                        color: FuelColors.carbs
                    )

                    macroItem(
                        label: "Fat",
                        value: viewModel.calculatedFat,
                        color: FuelColors.fat
                    )
                }
            }
        }
    }

    private func macroItem(label: String, value: Int, color: Color) -> some View {
        VStack(spacing: FuelSpacing.xs) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)

            Text("\(value)g")
                .font(FuelTypography.title2)
                .foregroundStyle(FuelColors.textPrimary)

            Text(label)
                .font(FuelTypography.caption)
                .foregroundStyle(FuelColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Timeline Card

    private var timelineCard: some View {
        FuelCard {
            VStack(spacing: FuelSpacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: FuelSpacing.xxxs) {
                        Text("Projected Timeline")
                            .font(FuelTypography.headline)
                            .foregroundStyle(FuelColors.textPrimary)

                        Text("At a healthy pace")
                            .font(FuelTypography.caption)
                            .foregroundStyle(FuelColors.textSecondary)
                    }

                    Spacer()

                    Text("~\(viewModel.estimatedWeeks) weeks")
                        .font(FuelTypography.title3)
                        .foregroundStyle(FuelColors.primary)
                }

                // Progress visualization
                HStack(alignment: .center, spacing: FuelSpacing.sm) {
                    // Start weight
                    VStack(spacing: FuelSpacing.xxxs) {
                        Text("Now")
                            .font(FuelTypography.caption)
                            .foregroundStyle(FuelColors.textTertiary)

                        Text("\(String(format: "%.1f", viewModel.currentWeightForCalculation)) kg")
                            .font(FuelTypography.subheadlineMedium)
                            .foregroundStyle(FuelColors.textPrimary)
                    }

                    // Arrow
                    Image(systemName: "arrow.right")
                        .font(.system(size: 16))
                        .foregroundStyle(FuelColors.primary)
                        .frame(maxWidth: .infinity)

                    // Goal weight
                    VStack(spacing: FuelSpacing.xxxs) {
                        Text("Goal")
                            .font(FuelTypography.caption)
                            .foregroundStyle(FuelColors.textTertiary)

                        Text("\(String(format: "%.1f", viewModel.targetWeightForCalculation)) kg")
                            .font(FuelTypography.subheadlineMedium)
                            .foregroundStyle(FuelColors.success)
                    }
                }
            }
        }
    }

    // MARK: - Animation

    private func animateIn() {
        FuelHaptics.shared.success()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            showCalories = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showMacros = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showTimeline = true
        }
    }
}

#Preview {
    YourPlanScreen(viewModel: OnboardingViewModel())
}
