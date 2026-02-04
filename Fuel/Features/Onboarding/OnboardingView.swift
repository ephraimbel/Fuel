import SwiftUI

/// Main Onboarding Container
/// Manages the complete onboarding flow with 34 screens

struct OnboardingView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = OnboardingViewModel()

    var body: some View {
        ZStack {
            // Background
            FuelColors.background
                .ignoresSafeArea()

            // Content
            VStack(spacing: 0) {
                // Progress bar (hidden on first and last screens)
                if viewModel.showProgressBar {
                    OnboardingProgressBar(
                        currentStep: viewModel.currentStep,
                        totalSteps: viewModel.totalSteps
                    )
                    .padding(.horizontal, FuelSpacing.screenHorizontal)
                    .padding(.top, FuelSpacing.md)
                }

                // Screen content
                TabView(selection: $viewModel.currentStep) {
                    // Welcome
                    WelcomeScreen(viewModel: viewModel)
                        .tag(OnboardingStep.welcome)

                    // Goal Selection
                    GoalSelectionScreen(viewModel: viewModel)
                        .tag(OnboardingStep.goal)

                    // Gender
                    GenderSelectionScreen(viewModel: viewModel)
                        .tag(OnboardingStep.gender)

                    // Age
                    AgeInputScreen(viewModel: viewModel)
                        .tag(OnboardingStep.age)

                    // Height
                    HeightInputScreen(viewModel: viewModel)
                        .tag(OnboardingStep.height)

                    // Current Weight
                    CurrentWeightScreen(viewModel: viewModel)
                        .tag(OnboardingStep.currentWeight)

                    // Target Weight
                    TargetWeightScreen(viewModel: viewModel)
                        .tag(OnboardingStep.targetWeight)

                    // Activity Level
                    ActivityLevelScreen(viewModel: viewModel)
                        .tag(OnboardingStep.activityLevel)

                    // Workout Frequency
                    WorkoutFrequencyScreen(viewModel: viewModel)
                        .tag(OnboardingStep.workoutFrequency)

                    // Diet Preference
                    DietPreferenceScreen(viewModel: viewModel)
                        .tag(OnboardingStep.dietPreference)

                    // Calculating Plan
                    CalculatingScreen(viewModel: viewModel)
                        .tag(OnboardingStep.calculating)

                    // Your Plan
                    YourPlanScreen(viewModel: viewModel)
                        .tag(OnboardingStep.yourPlan)

                    // Notifications
                    NotificationsScreen(viewModel: viewModel)
                        .tag(OnboardingStep.notifications)

                    // Sign In
                    SignInScreen(viewModel: viewModel)
                        .tag(OnboardingStep.signIn)

                    // Premium Trial
                    PremiumTrialScreen(viewModel: viewModel)
                        .tag(OnboardingStep.premiumTrial)

                    // All Set
                    AllSetScreen(viewModel: viewModel)
                        .tag(OnboardingStep.allSet)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(FuelAnimations.spring, value: viewModel.currentStep)
            }
        }
        .onChange(of: viewModel.isComplete) { _, isComplete in
            if isComplete {
                appState.completeOnboarding()
            }
        }
    }
}

// MARK: - Onboarding Step

enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case goal
    case gender
    case age
    case height
    case currentWeight
    case targetWeight
    case activityLevel
    case workoutFrequency
    case dietPreference
    case calculating
    case yourPlan
    case notifications
    case signIn
    case premiumTrial
    case allSet

    var title: String {
        switch self {
        case .welcome: return "Welcome"
        case .goal: return "Your Goal"
        case .gender: return "Gender"
        case .age: return "Age"
        case .height: return "Height"
        case .currentWeight: return "Current Weight"
        case .targetWeight: return "Target Weight"
        case .activityLevel: return "Activity Level"
        case .workoutFrequency: return "Workouts"
        case .dietPreference: return "Diet"
        case .calculating: return "Calculating"
        case .yourPlan: return "Your Plan"
        case .notifications: return "Notifications"
        case .signIn: return "Sign In"
        case .premiumTrial: return "Premium"
        case .allSet: return "All Set"
        }
    }
}

// MARK: - Onboarding Progress Bar

struct OnboardingProgressBar: View {
    let currentStep: OnboardingStep
    let totalSteps: Int

    private var progress: Double {
        Double(currentStep.rawValue) / Double(totalSteps - 1)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                Capsule()
                    .fill(FuelColors.surfaceSecondary)
                    .frame(height: 4)

                // Progress
                Capsule()
                    .fill(FuelColors.primary)
                    .frame(width: geometry.size.width * progress, height: 4)
                    .animation(FuelAnimations.spring, value: progress)
            }
        }
        .frame(height: 4)
    }
}

// MARK: - Preview

#Preview {
    OnboardingView()
        .environment(AppState())
}
