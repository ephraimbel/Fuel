import SwiftUI

/// Root View
/// Handles app-level navigation between onboarding, auth, and main content

struct RootView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    @State private var isLoading = true

    var body: some View {
        ZStack {
            // Background
            FuelColors.background
                .ignoresSafeArea()

            // Content
            if isLoading {
                launchScreen
            } else if appState.showOnboarding {
                OnboardingContainerView()
                    .transition(.opacity)
            } else {
                MainTabView()
                    .transition(.opacity)
            }
        }
        .animation(FuelAnimations.spring, value: isLoading)
        .animation(FuelAnimations.spring, value: appState.showOnboarding)
        .task {
            await initializeApp()
        }
        .fullScreenCover(isPresented: Binding(
            get: { appState.showPaywall },
            set: { appState.showPaywall = $0 }
        )) {
            PaywallView(context: appState.paywallContext)
        }
        .fullScreenCover(isPresented: Binding(
            get: { appState.showCamera },
            set: { appState.showCamera = $0 }
        )) {
            FoodScannerView()
                .environment(appState)
        }
    }

    // MARK: - Launch Screen

    private var launchScreen: some View {
        VStack(spacing: FuelSpacing.lg) {
            // Logo
            Image(systemName: "flame.fill")
                .font(.system(size: 80, weight: .bold))
                .foregroundStyle(FuelColors.primaryGradient)

            Text("Fuel")
                .font(FuelTypography.largeTitle)
                .foregroundStyle(FuelColors.textPrimary)

            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: FuelColors.primary))
                .scaleEffect(1.2)
        }
    }

    // MARK: - Initialization

    private func initializeApp() async {
        // Check authentication state
        AuthService.shared.checkExistingCredentials()

        // Load subscription status
        await SubscriptionService.shared.loadProducts()

        // Load user data if authenticated
        if AuthService.shared.isAuthenticated {
            await loadUserData()
        }

        // Ensure minimum display time for launch screen (for smooth UX)
        // This is intentionally short - just enough to prevent jarring transitions
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

        // Complete loading
        await MainActor.run {
            withAnimation(FuelAnimations.spring) {
                isLoading = false
            }

            // Check if trial just ended (after loading completes)
            appState.checkTrialStatus()
        }
    }

    private func loadUserData() async {
        // Load user profile from SwiftData
        // The user data is already available through the modelContext
        // Additional async loading (like remote sync) would go here
    }
}

// MARK: - Placeholder Views

/// Onboarding Container - Uses the full onboarding flow
struct OnboardingContainerView: View {
    var body: some View {
        OnboardingView()
    }
}

/// Placeholder for camera capture
struct CameraCaptureView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button {
                    FuelHaptics.shared.tap()
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                .padding()
            }

            Spacer()

            Text("Camera View")
                .font(FuelTypography.title1)
                .foregroundStyle(.white)

            Text("Photo capture will be implemented here")
                .font(FuelTypography.body)
                .foregroundStyle(.white.opacity(0.7))

            Spacer()

            // Capture button
            Button {
                FuelHaptics.shared.capture()
                // Capture action
            } label: {
                Circle()
                    .stroke(.white, lineWidth: 4)
                    .frame(width: 72, height: 72)
                    .overlay(
                        Circle()
                            .fill(.white)
                            .frame(width: 60, height: 60)
                    )
            }
            .padding(.bottom, FuelSpacing.huge)
        }
        .background(Color.black)
    }
}

// Note: PaywallView is now in /Fuel/Features/Subscription/PaywallView.swift

#Preview {
    RootView()
        .environment(AppState())
}
