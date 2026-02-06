import SwiftUI
import SwiftData
import OSLog

/// Fuel - AI-Powered Calorie Tracker
/// Main application entry point

private let logger = Logger(subsystem: "com.fuel.app", category: "App")

@main
struct FuelApp: App {
    // MARK: - State

    @State private var appState = AppState()
    @State private var initializationError: Error?

    // MARK: - Model Container

    let modelContainer: ModelContainer?

    init() {
        let schema = Schema([
            User.self,
            Meal.self,
            FoodItem.self,
            WeightEntry.self,
            Achievement.self
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )

        // Try primary storage first, then fallback to in-memory
        if let container = try? ModelContainer(for: schema, configurations: [modelConfiguration]) {
            self.modelContainer = container
            logger.info("ModelContainer initialized successfully")
        } else {
            logger.error("Failed to create ModelContainer with persistent storage")
            // Try fallback with in-memory storage
            let fallbackConfig = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: true
            )
            if let fallbackContainer = try? ModelContainer(for: schema, configurations: [fallbackConfig]) {
                self.modelContainer = fallbackContainer
                logger.warning("Using in-memory fallback storage")
            } else {
                logger.critical("Failed to create any ModelContainer")
                self.modelContainer = nil
            }
        }
    }

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            if let container = modelContainer {
                RootView()
                    .environment(appState)
                    .withToasts()
                    .modelContainer(container)
                    .onAppear {
                        #if DEBUG
                        if CommandLine.arguments.contains("--load-demo-data") {
                            UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                            appState.showOnboarding = false
                            MockDataService.shared.generateMockData(in: container.mainContext)
                            logger.info("Demo data loaded via launch argument")
                        }
                        #endif
                    }
            } else {
                DatabaseErrorView {
                    // Attempt recovery by resetting the app
                    resetAppData()
                }
            }
        }
    }

    // MARK: - Recovery

    private func resetAppData() {
        // Clear UserDefaults
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }

        // Log the reset attempt
        logger.info("App data reset attempted")

        // The user would need to restart the app
    }
}

// MARK: - Database Error View

struct DatabaseErrorView: View {
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.orange)

            Text("Unable to Start")
                .font(.title.bold())

            Text("There was a problem initializing the app's database. This may be due to a storage issue or corrupted data.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            VStack(spacing: 12) {
                Button {
                    onRetry()
                } label: {
                    Text("Reset App Data")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.red)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Text("This will clear all local data. You may need to restart the app.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 32)
        }
        .padding()
    }
}

// MARK: - App State

@Observable
final class AppState {
    // MARK: - Navigation

    var selectedTab: Tab = .home
    var showOnboarding = false
    var showPaywall = false
    var paywallContext: PaywallContext = .general
    var showCamera = false
    var showAddMealSheet = false

    // MARK: - User

    var isAuthenticated: Bool {
        AuthService.shared.isAuthenticated
    }

    var isPremium: Bool {
        SubscriptionService.shared.isPremium
    }

    // MARK: - Daily Summary

    var dailyCaloriesConsumed: Int = 0
    var dailyCalorieTarget: Int = 2000
    var dailyProtein: Double = 0
    var dailyCarbs: Double = 0
    var dailyFat: Double = 0

    // MARK: - Initialization

    init() {
        checkOnboardingStatus()
    }

    // MARK: - Methods

    func checkOnboardingStatus() {
        showOnboarding = !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }

    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        showOnboarding = false
        FuelHaptics.shared.celebration()
    }

    func resetOnboarding() {
        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
        showOnboarding = true
    }

    /// Check if trial just ended and show paywall
    func checkTrialStatus() {
        if FeatureGateService.shared.trialJustEnded {
            paywallContext = .trialEnded
            showPaywall = true
        }
    }

    /// Show paywall with specific context
    func showPaywall(context: PaywallContext) {
        paywallContext = context
        showPaywall = true
    }
}

// MARK: - Tabs

enum Tab: String, CaseIterable {
    case home
    case history
    case progress
    case profile

    var title: String {
        switch self {
        case .home: return "Home"
        case .history: return "Meals"
        case .progress: return "Progress"
        case .profile: return "Profile"
        }
    }

    var icon: String {
        switch self {
        case .home: return "house"
        case .history: return "fork.knife"
        case .progress: return "chart.line.uptrend.xyaxis"
        case .profile: return "person"
        }
    }

    var selectedIcon: String {
        switch self {
        case .home: return "house.fill"
        case .history: return "fork.knife"
        case .progress: return "chart.line.uptrend.xyaxis"
        case .profile: return "person.fill"
        }
    }
}
