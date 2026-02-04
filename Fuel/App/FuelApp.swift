import SwiftUI
import SwiftData

/// Fuel - AI-Powered Calorie Tracker
/// Main application entry point

@main
struct FuelApp: App {
    // MARK: - State

    @State private var appState = AppState()

    // MARK: - Model Container

    var modelContainer: ModelContainer = {
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

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .withToasts()
        }
        .modelContainer(modelContainer)
    }
}

// MARK: - App State

@Observable
final class AppState {
    // MARK: - Navigation

    var selectedTab: Tab = .home
    var showOnboarding = false
    var showPaywall = false
    var showCamera = false

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
}

// MARK: - Tabs

enum Tab: String, CaseIterable {
    case home
    case search
    case add
    case progress
    case profile

    var title: String {
        switch self {
        case .home: return "Home"
        case .search: return "Search"
        case .add: return "Add"
        case .progress: return "Progress"
        case .profile: return "Profile"
        }
    }

    var icon: String {
        switch self {
        case .home: return "house"
        case .search: return "magnifyingglass"
        case .add: return "plus.circle"
        case .progress: return "chart.bar"
        case .profile: return "person"
        }
    }

    var selectedIcon: String {
        switch self {
        case .home: return "house.fill"
        case .search: return "magnifyingglass"
        case .add: return "plus.circle.fill"
        case .progress: return "chart.bar.fill"
        case .profile: return "person.fill"
        }
    }
}
