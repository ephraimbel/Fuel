import SwiftUI

/// Calculating Screen
/// Shows animated progress while calculating the user's personalized plan

struct CalculatingScreen: View {
    @Bindable var viewModel: OnboardingViewModel

    @State private var currentStep = 0
    @State private var progress: Double = 0

    private let steps = [
        "Analyzing your profile...",
        "Calculating metabolism...",
        "Setting macro targets...",
        "Personalizing your plan..."
    ]

    var body: some View {
        VStack(spacing: FuelSpacing.xxl) {
            Spacer()

            // Animated icon
            ZStack {
                // Rotating circles
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .stroke(FuelColors.primary.opacity(0.3 - Double(index) * 0.1), lineWidth: 3)
                        .frame(width: CGFloat(100 + index * 40), height: CGFloat(100 + index * 40))
                        .rotationEffect(.degrees(progress * 360 * (index % 2 == 0 ? 1 : -1)))
                }

                // Center icon
                Image(systemName: "sparkles")
                    .font(.system(size: 50, weight: .medium))
                    .foregroundStyle(FuelColors.primary)
                    .scaleEffect(1 + sin(progress * .pi * 4) * 0.1)
            }
            .animation(FuelAnimations.spring, value: progress)

            // Progress text
            VStack(spacing: FuelSpacing.md) {
                Text("Creating Your Plan")
                    .font(FuelTypography.title2)
                    .foregroundStyle(FuelColors.textPrimary)

                Text(steps[min(currentStep, steps.count - 1)])
                    .font(FuelTypography.body)
                    .foregroundStyle(FuelColors.textSecondary)
                    .contentTransition(.opacity)
                    .animation(FuelAnimations.spring, value: currentStep)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(FuelColors.surfaceSecondary)
                        .frame(height: 8)

                    Capsule()
                        .fill(FuelColors.primaryGradient)
                        .frame(width: geometry.size.width * progress, height: 8)
                }
            }
            .frame(height: 8)
            .padding(.horizontal, FuelSpacing.xxl)
            .animation(FuelAnimations.spring, value: progress)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, FuelSpacing.screenHorizontal)
        .onAppear {
            startAnimation()
        }
    }

    private func startAnimation() {
        // Animation timing matches calculatePlan() delay (0.8 seconds)
        let totalDuration = 0.8
        let stepDuration = totalDuration / Double(steps.count)

        // Progress animation
        withAnimation(.linear(duration: totalDuration)) {
            progress = 1.0
        }

        // Step text animation
        for i in 0..<steps.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(i)) {
                withAnimation {
                    currentStep = i
                }
                FuelHaptics.shared.tick()
            }
        }
    }
}

#Preview {
    CalculatingScreen(viewModel: OnboardingViewModel())
}
