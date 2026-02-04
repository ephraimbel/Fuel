import SwiftUI

/// Welcome Screen - First screen of onboarding
/// Introduces the app with animated logo and tagline

struct WelcomeScreen: View {
    @Bindable var viewModel: OnboardingViewModel

    @State private var showLogo = false
    @State private var showTitle = false
    @State private var showSubtitle = false
    @State private var showButton = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Logo
            ZStack {
                // Glow effect
                Circle()
                    .fill(FuelColors.primary.opacity(0.2))
                    .frame(width: 180, height: 180)
                    .blur(radius: 40)
                    .scaleEffect(showLogo ? 1 : 0.5)

                // Logo icon
                Image(systemName: "flame.fill")
                    .font(.system(size: 100, weight: .bold))
                    .foregroundStyle(FuelColors.primaryGradient)
                    .scaleEffect(showLogo ? 1 : 0.3)
                    .opacity(showLogo ? 1 : 0)
            }
            .animation(FuelAnimations.springCelebration, value: showLogo)

            Spacer()
                .frame(height: FuelSpacing.xxl)

            // Title
            Text("Fuel")
                .font(FuelTypography.hero)
                .foregroundStyle(FuelColors.textPrimary)
                .opacity(showTitle ? 1 : 0)
                .offset(y: showTitle ? 0 : 20)
                .animation(FuelAnimations.spring.delay(0.2), value: showTitle)

            Spacer()
                .frame(height: FuelSpacing.sm)

            // Subtitle
            Text("AI-Powered Calorie Tracking")
                .font(FuelTypography.title3)
                .foregroundStyle(FuelColors.textSecondary)
                .opacity(showSubtitle ? 1 : 0)
                .offset(y: showSubtitle ? 0 : 20)
                .animation(FuelAnimations.spring.delay(0.4), value: showSubtitle)

            Spacer()

            // Features preview
            VStack(spacing: FuelSpacing.md) {
                featureRow(icon: "camera.viewfinder", text: "Snap a photo to log meals instantly")
                featureRow(icon: "chart.bar.fill", text: "Track calories and macros effortlessly")
                featureRow(icon: "flame.fill", text: "Build healthy eating habits")
            }
            .opacity(showSubtitle ? 1 : 0)
            .offset(y: showSubtitle ? 0 : 20)
            .animation(FuelAnimations.spring.delay(0.6), value: showSubtitle)
            .padding(.horizontal, FuelSpacing.screenHorizontal)

            Spacer()

            // Get Started Button
            VStack(spacing: FuelSpacing.md) {
                FuelButton("Get Started") {
                    viewModel.nextStep()
                }

                Text("Takes less than 2 minutes")
                    .font(FuelTypography.caption)
                    .foregroundStyle(FuelColors.textTertiary)
            }
            .opacity(showButton ? 1 : 0)
            .offset(y: showButton ? 0 : 20)
            .animation(FuelAnimations.spring.delay(0.8), value: showButton)
            .padding(.horizontal, FuelSpacing.screenHorizontal)
            .padding(.bottom, FuelSpacing.xxl)
        }
        .onAppear {
            animateIn()
        }
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: FuelSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(FuelColors.primary)
                .frame(width: 32)

            Text(text)
                .font(FuelTypography.body)
                .foregroundStyle(FuelColors.textSecondary)

            Spacer()
        }
    }

    private func animateIn() {
        showLogo = true
        showTitle = true
        showSubtitle = true
        showButton = true

        // Haptic on logo appear
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            FuelHaptics.shared.impact()
        }
    }
}

#Preview {
    WelcomeScreen(viewModel: OnboardingViewModel())
}
