import Foundation
import SwiftUI

/// Analytics Manager
/// Handles analytics configuration, consent, and initialization

@Observable
public final class AnalyticsManager {
    public static let shared = AnalyticsManager()

    // MARK: - State

    var hasUserConsent: Bool {
        get { UserDefaults.standard.bool(forKey: "analytics_consent") }
        set {
            UserDefaults.standard.set(newValue, forKey: "analytics_consent")
            AnalyticsService.shared.setEnabled(newValue)
        }
    }

    var hasCrashReportingConsent: Bool {
        get { UserDefaults.standard.bool(forKey: "crash_reporting_consent") }
        set { UserDefaults.standard.set(newValue, forKey: "crash_reporting_consent") }
    }

    var hasPromptedForConsent: Bool {
        get { UserDefaults.standard.bool(forKey: "analytics_consent_prompted") }
        set { UserDefaults.standard.set(newValue, forKey: "analytics_consent_prompted") }
    }

    // MARK: - Initialization

    private init() {}

    // MARK: - Setup

    /// Initialize analytics on app launch
    public func initialize() {
        // Only enable if user has consented
        AnalyticsService.shared.setEnabled(hasUserConsent)

        // Track app launch
        if hasUserConsent {
            AnalyticsService.shared.trackAppLifecycle(.launched)
        }

        // Setup notification observers
        setupLifecycleObservers()
    }

    /// Configure with user ID after authentication
    public func configureForUser(userId: String, email: String?, name: String?) {
        guard hasUserConsent else { return }

        AnalyticsService.shared.identify(userId: userId)

        var properties: [UserProperty: Any] = [
            .userId: userId,
            .createdAt: ISO8601DateFormatter().string(from: Date())
        ]

        if let email = email {
            properties[.email] = email
        }
        if let name = name {
            properties[.name] = name
        }

        AnalyticsService.shared.setUserProperties(properties)
    }

    /// Reset on logout
    public func reset() {
        AnalyticsService.shared.reset()
    }

    // MARK: - Consent Management

    /// Grant analytics consent
    public func grantConsent() {
        hasUserConsent = true
        hasPromptedForConsent = true
        AnalyticsService.shared.track(.analyticsEnabled)
    }

    /// Revoke analytics consent
    public func revokeConsent() {
        hasUserConsent = false
        AnalyticsService.shared.reset()
    }

    // MARK: - Lifecycle Observers

    private func setupLifecycleObservers() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard self?.hasUserConsent == true else { return }
            AnalyticsService.shared.trackAppLifecycle(.backgrounded)
        }

        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard self?.hasUserConsent == true else { return }
            AnalyticsService.shared.trackAppLifecycle(.foregrounded)
        }
    }
}

// MARK: - Analytics Consent View

struct AnalyticsConsentView: View {
    @Environment(\.dismiss) private var dismiss
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: FuelSpacing.xl) {
            Spacer()

            // Icon
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 64))
                .foregroundStyle(FuelColors.primary)

            // Title
            VStack(spacing: FuelSpacing.sm) {
                Text("Help Us Improve")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(FuelColors.textPrimary)

                Text("Share anonymous usage data to help us make Fuel better for everyone.")
                    .font(FuelTypography.body)
                    .foregroundStyle(FuelColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            // What we collect
            VStack(alignment: .leading, spacing: FuelSpacing.md) {
                Text("What we collect:")
                    .font(FuelTypography.subheadlineMedium)
                    .foregroundStyle(FuelColors.textPrimary)

                consentItem(icon: "hand.tap", text: "Feature usage patterns")
                consentItem(icon: "exclamationmark.triangle", text: "Error reports")
                consentItem(icon: "speedometer", text: "Performance metrics")

                Text("We never collect personal health data, food logs, or weight information.")
                    .font(FuelTypography.caption)
                    .foregroundStyle(FuelColors.textTertiary)
                    .padding(.top, FuelSpacing.sm)
            }
            .padding(FuelSpacing.lg)
            .background(FuelColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))

            Spacer()

            // Buttons
            VStack(spacing: FuelSpacing.md) {
                Button {
                    AnalyticsManager.shared.grantConsent()
                    FuelHaptics.shared.success()
                    onComplete()
                } label: {
                    Text("Share Analytics")
                        .font(FuelTypography.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, FuelSpacing.md)
                        .background(FuelColors.primary)
                        .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
                }

                Button {
                    AnalyticsManager.shared.hasPromptedForConsent = true
                    FuelHaptics.shared.tap()
                    onComplete()
                } label: {
                    Text("No Thanks")
                        .font(FuelTypography.subheadlineMedium)
                        .foregroundStyle(FuelColors.textSecondary)
                }
            }
        }
        .padding(.horizontal, FuelSpacing.screenHorizontal)
        .padding(.bottom, FuelSpacing.xl)
        .background(FuelColors.background)
    }

    private func consentItem(icon: String, text: String) -> some View {
        HStack(spacing: FuelSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(FuelColors.primary)
                .frame(width: 24)

            Text(text)
                .font(FuelTypography.body)
                .foregroundStyle(FuelColors.textSecondary)
        }
    }
}

// MARK: - Analytics Integration Examples

/*
 INTEGRATION GUIDE
 =================

 1. Initialize on app launch (in FuelApp.swift):
    ```swift
    init() {
        AnalyticsManager.shared.initialize()
    }
    ```

 2. Track screen views (add to views):
    ```swift
    var body: some View {
        NavigationStack {
            // content
        }
        .trackScreen(.dashboard)
    }
    ```

 3. Track events in actions:
    ```swift
    Button("Log Food") {
        // ... log food logic
        AnalyticsService.shared.trackFoodLogged(
            name: food.name,
            calories: food.calories,
            mealType: .breakfast,
            source: .search
        )
    }
    ```

 4. Track onboarding:
    ```swift
    // In OnboardingViewModel
    func completeStep(_ step: Int) {
        AnalyticsService.shared.trackOnboardingStep(step, name: stepName)
    }

    func complete() {
        AnalyticsService.shared.trackOnboardingComplete(
            goalType: selectedGoal.rawValue,
            calorieGoal: calculatedCalories,
            startWeight: currentWeight,
            targetWeight: targetWeight
        )
    }
    ```

 5. Track errors:
    ```swift
    do {
        try await someOperation()
    } catch {
        AnalyticsService.shared.trackError(error, context: "food_scan")
    }
    ```

 6. User properties (after auth):
    ```swift
    AnalyticsManager.shared.configureForUser(
        userId: user.id,
        email: user.email,
        name: user.name
    )
    ```

 7. Subscription events:
    ```swift
    // On purchase
    AnalyticsService.shared.trackSubscriptionPurchased(
        plan: "premium_monthly",
        price: 9.99,
        currency: "USD"
    )

    // On trial start
    AnalyticsService.shared.trackTrialStarted(
        plan: "premium_yearly",
        trialDays: 7
    )
    ```

 MIXPANEL SETUP
 ==============

 1. Add Mixpanel SDK to Package.swift:
    ```swift
    .package(url: "https://github.com/mixpanel/mixpanel-swift", from: "4.0.0")
    ```

 2. Import in AnalyticsService.swift:
    ```swift
    import Mixpanel
    ```

 3. Uncomment Mixpanel calls in AnalyticsService.swift

 4. Replace "YOUR_MIXPANEL_TOKEN" with your actual token

 5. Enable automatic events in Mixpanel dashboard
*/

// MARK: - Preview

#Preview {
    AnalyticsConsentView {}
}
