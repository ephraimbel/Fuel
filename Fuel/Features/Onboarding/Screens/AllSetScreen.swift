import SwiftUI

/// All Set Screen
/// Final celebration screen before entering the main app

struct AllSetScreen: View {
    @Bindable var viewModel: OnboardingViewModel

    @State private var showCheckmark = false
    @State private var showContent = false
    @State private var showConfetti = false

    var body: some View {
        ZStack {
            // Confetti overlay
            ConfettiView(isActive: showConfetti, intensity: .high)

            VStack(spacing: FuelSpacing.xl) {
                Spacer()

                // Success animation
                ZStack {
                    // Pulse circles
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .stroke(FuelColors.success.opacity(0.3 - Double(index) * 0.1), lineWidth: 2)
                            .frame(width: CGFloat(100 + index * 50), height: CGFloat(100 + index * 50))
                            .scaleEffect(showCheckmark ? 1 : 0.5)
                            .opacity(showCheckmark ? 1 : 0)
                    }

                    // Checkmark circle
                    Circle()
                        .fill(FuelColors.success)
                        .frame(width: 100, height: 100)
                        .scaleEffect(showCheckmark ? 1 : 0)

                    Image(systemName: "checkmark")
                        .font(.system(size: 50, weight: .bold))
                        .foregroundStyle(.white)
                        .scaleEffect(showCheckmark ? 1 : 0)
                }
                .animation(FuelAnimations.springCelebration, value: showCheckmark)

                // Text content
                VStack(spacing: FuelSpacing.md) {
                    Text("You're All Set!")
                        .font(FuelTypography.largeTitle)
                        .foregroundStyle(FuelColors.textPrimary)

                    Text("Your personalized plan is ready. Let's start your journey to better health!")
                        .font(FuelTypography.body)
                        .foregroundStyle(FuelColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, FuelSpacing.xl)
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 30)
                .animation(FuelAnimations.spring.delay(0.3), value: showContent)

                // Stats summary
                VStack(spacing: FuelSpacing.md) {
                    HStack(spacing: FuelSpacing.lg) {
                        statItem(value: "\(viewModel.calculatedCalories)", label: "Daily Calories")
                        statItem(value: "\(viewModel.calculatedProtein)g", label: "Protein")
                    }

                    if viewModel.selectedGoal != .maintain {
                        HStack(spacing: FuelSpacing.xs) {
                            Image(systemName: "calendar")
                                .font(.system(size: 14))

                            Text("Goal: ~\(viewModel.estimatedWeeks) weeks")
                                .font(FuelTypography.subheadline)
                        }
                        .foregroundStyle(FuelColors.textSecondary)
                    }
                }
                .padding(FuelSpacing.lg)
                .background(FuelColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusLg, style: .continuous))
                .padding(.horizontal, FuelSpacing.screenHorizontal)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 30)
                .animation(FuelAnimations.spring.delay(0.5), value: showContent)

                Spacer()

                // Start button
                VStack(spacing: FuelSpacing.md) {
                    FuelButton("Start Tracking", icon: "arrow.right", iconPosition: .trailing) {
                        viewModel.saveOnboardingData()
                        viewModel.completeOnboarding()
                    }

                    Text("You can always adjust your goals in Settings")
                        .font(FuelTypography.caption)
                        .foregroundStyle(FuelColors.textTertiary)
                }
                .padding(.horizontal, FuelSpacing.screenHorizontal)
                .opacity(showContent ? 1 : 0)
                .animation(FuelAnimations.spring.delay(0.7), value: showContent)

                Spacer()
                    .frame(height: FuelSpacing.xl)
            }
        }
        .onAppear {
            animateIn()
        }
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: FuelSpacing.xs) {
            Text(value)
                .font(FuelTypography.title1)
                .foregroundStyle(FuelColors.primary)

            Text(label)
                .font(FuelTypography.caption)
                .foregroundStyle(FuelColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func animateIn() {
        // Trigger celebration haptic
        FuelHaptics.shared.celebration()

        // Animate elements in sequence
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            showCheckmark = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            showContent = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            showConfetti = true
        }
    }
}

#Preview {
    AllSetScreen(viewModel: OnboardingViewModel())
}
