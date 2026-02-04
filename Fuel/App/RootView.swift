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
            PaywallView()
        }
        .fullScreenCover(isPresented: Binding(
            get: { appState.showCamera },
            set: { appState.showCamera = $0 }
        )) {
            CameraCaptureView()
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
        // Simulate initial load
        try? await Task.sleep(nanoseconds: 1_500_000_000)

        // Check authentication state
        AuthService.shared.checkExistingCredentials()

        // Load subscription status
        await SubscriptionService.shared.loadProducts()

        // Load user data if authenticated
        if AuthService.shared.isAuthenticated {
            await loadUserData()
        }

        // Complete loading
        await MainActor.run {
            withAnimation(FuelAnimations.spring) {
                isLoading = false
            }
        }
    }

    private func loadUserData() async {
        // In production, fetch user data from SwiftData
        // This is a placeholder
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

/// Placeholder for paywall
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedProduct: SubscriptionService.ProductID = .yearlyPremium

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: FuelSpacing.xl) {
                    // Header
                    VStack(spacing: FuelSpacing.md) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(FuelColors.gold)

                        Text("Upgrade to Premium")
                            .font(FuelTypography.title1)
                            .foregroundStyle(FuelColors.textPrimary)

                        Text("Unlock unlimited AI scans and premium features")
                            .font(FuelTypography.body)
                            .foregroundStyle(FuelColors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, FuelSpacing.xl)

                    // Features
                    VStack(alignment: .leading, spacing: FuelSpacing.md) {
                        featureRow(icon: "camera.viewfinder", text: "Unlimited AI food scans")
                        featureRow(icon: "chart.xyaxis.line", text: "Advanced analytics")
                        featureRow(icon: "icloud", text: "Cloud sync across devices")
                        featureRow(icon: "bell.badge", text: "Smart reminders")
                        featureRow(icon: "rectangle.stack", text: "Custom recipes")
                    }
                    .padding(.horizontal, FuelSpacing.screenHorizontal)

                    // Pricing options
                    VStack(spacing: FuelSpacing.sm) {
                        pricingOption(
                            title: "Yearly",
                            price: "$49.99/year",
                            detail: "$4.17/month",
                            isSelected: selectedProduct == .yearlyPremium,
                            badge: "Best Value"
                        ) {
                            selectedProduct = .yearlyPremium
                        }

                        pricingOption(
                            title: "Monthly",
                            price: "$9.99/month",
                            detail: nil,
                            isSelected: selectedProduct == .monthlyPremium
                        ) {
                            selectedProduct = .monthlyPremium
                        }

                        pricingOption(
                            title: "Lifetime",
                            price: "$149.99",
                            detail: "One-time purchase",
                            isSelected: selectedProduct == .lifetime
                        ) {
                            selectedProduct = .lifetime
                        }
                    }
                    .padding(.horizontal, FuelSpacing.screenHorizontal)

                    // Purchase button
                    FuelButton("Continue") {
                        Task {
                            // Purchase flow
                            FuelHaptics.shared.impact()
                        }
                    }
                    .padding(.horizontal, FuelSpacing.screenHorizontal)

                    // Restore
                    Button {
                        FuelHaptics.shared.tap()
                        Task {
                            try? await SubscriptionService.shared.restorePurchases()
                        }
                    } label: {
                        Text("Restore Purchases")
                            .font(FuelTypography.subheadline)
                            .foregroundStyle(FuelColors.textSecondary)
                    }

                    // Terms
                    Text("Cancel anytime. Terms apply.")
                        .font(FuelTypography.caption)
                        .foregroundStyle(FuelColors.textTertiary)
                        .padding(.bottom, FuelSpacing.xl)
                }
            }
            .background(FuelColors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        FuelHaptics.shared.tap()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(FuelColors.textSecondary)
                    }
                }
            }
        }
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: FuelSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(FuelColors.primary)
                .frame(width: 28)

            Text(text)
                .font(FuelTypography.body)
                .foregroundStyle(FuelColors.textPrimary)
        }
    }

    private func pricingOption(
        title: String,
        price: String,
        detail: String?,
        isSelected: Bool,
        badge: String? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            FuelHaptics.shared.select()
            action()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: FuelSpacing.xxxs) {
                    HStack {
                        Text(title)
                            .font(FuelTypography.headline)
                            .foregroundStyle(FuelColors.textPrimary)

                        if let badge {
                            Text(badge)
                                .font(FuelTypography.caption)
                                .foregroundStyle(.white)
                                .padding(.horizontal, FuelSpacing.xs)
                                .padding(.vertical, FuelSpacing.xxxs)
                                .background(FuelColors.success)
                                .clipShape(Capsule())
                        }
                    }

                    if let detail {
                        Text(detail)
                            .font(FuelTypography.caption)
                            .foregroundStyle(FuelColors.textSecondary)
                    }
                }

                Spacer()

                Text(price)
                    .font(FuelTypography.headline)
                    .foregroundStyle(FuelColors.textPrimary)

                Circle()
                    .stroke(isSelected ? FuelColors.primary : FuelColors.border, lineWidth: 2)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Circle()
                            .fill(isSelected ? FuelColors.primary : .clear)
                            .frame(width: 16, height: 16)
                    )
            }
            .padding(FuelSpacing.md)
            .background(isSelected ? FuelColors.primaryLight : FuelColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
            .overlay(
                RoundedRectangle(cornerRadius: FuelSpacing.radiusMd)
                    .stroke(isSelected ? FuelColors.primary : FuelColors.border, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    RootView()
        .environment(AppState())
}
