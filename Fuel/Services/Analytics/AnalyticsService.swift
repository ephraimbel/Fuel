import Foundation
import SwiftUI

/// Analytics Service
/// Centralized analytics tracking using Mixpanel

// MARK: - Analytics Service

@Observable
public final class AnalyticsService {
    public static let shared = AnalyticsService()

    private var isEnabled = true
    private var userId: String?
    private var sessionStartTime: Date?
    private var screenViewStack: [String] = []

    // MARK: - Configuration

    private let mixpanelToken = "YOUR_MIXPANEL_TOKEN" // Replace with actual token

    private init() {
        startSession()
    }

    // MARK: - Setup

    /// Initialize analytics with optional user ID
    public func configure(userId: String? = nil) {
        self.userId = userId

        // Initialize Mixpanel SDK
        // Mixpanel.initialize(token: mixpanelToken, trackAutomaticEvents: true)

        if let userId = userId {
            identify(userId: userId)
        }

        track(.appLaunched)
    }

    /// Enable or disable analytics tracking
    public func setEnabled(_ enabled: Bool) {
        isEnabled = enabled

        if enabled {
            track(.analyticsEnabled)
        }
    }

    // MARK: - User Identification

    /// Identify user for tracking
    public func identify(userId: String) {
        guard isEnabled else { return }

        self.userId = userId
        // Mixpanel.mainInstance().identify(distinctId: userId)

        log("Identified user: \(userId)")
    }

    /// Reset user identity (on logout)
    public func reset() {
        guard isEnabled else { return }

        userId = nil
        // Mixpanel.mainInstance().reset()

        log("Reset user identity")
    }

    // MARK: - User Properties

    /// Set user properties
    public func setUserProperties(_ properties: [UserProperty: Any]) {
        guard isEnabled else { return }

        var mixpanelProperties: [String: Any] = [:]
        for (key, value) in properties {
            mixpanelProperties[key.rawValue] = value
        }

        // Mixpanel.mainInstance().people.set(properties: mixpanelProperties)

        log("Set user properties: \(mixpanelProperties)")
    }

    /// Set a single user property
    public func setUserProperty(_ property: UserProperty, value: Any) {
        setUserProperties([property: value])
    }

    /// Increment a numeric user property
    public func incrementUserProperty(_ property: UserProperty, by amount: Double = 1) {
        guard isEnabled else { return }

        // Mixpanel.mainInstance().people.increment(property: property.rawValue, by: amount)

        log("Incremented \(property.rawValue) by \(amount)")
    }

    // MARK: - Event Tracking

    /// Track an analytics event
    public func track(_ event: AnalyticsEvent, properties: [String: Any]? = nil) {
        guard isEnabled else { return }

        var eventProperties = properties ?? [:]

        // Add default properties
        eventProperties["session_duration"] = sessionDuration
        eventProperties["screen"] = currentScreen

        // Mixpanel.mainInstance().track(event: event.name, properties: eventProperties)

        log("Track: \(event.name) - \(eventProperties)")
    }

    /// Track event with typed properties
    public func track(_ event: AnalyticsEvent, with eventProperties: EventProperties) {
        track(event, properties: eventProperties.toDictionary())
    }

    // MARK: - Screen Tracking

    /// Track screen view
    public func trackScreen(_ screen: AnalyticsScreen) {
        guard isEnabled else { return }

        screenViewStack.append(screen.rawValue)

        track(.screenViewed, properties: [
            "screen_name": screen.rawValue,
            "previous_screen": previousScreen ?? "none"
        ])
    }

    /// Track screen exit
    public func trackScreenExit(_ screen: AnalyticsScreen) {
        guard isEnabled else { return }

        if let index = screenViewStack.lastIndex(of: screen.rawValue) {
            screenViewStack.remove(at: index)
        }
    }

    private var currentScreen: String? {
        screenViewStack.last
    }

    private var previousScreen: String? {
        guard screenViewStack.count >= 2 else { return nil }
        return screenViewStack[screenViewStack.count - 2]
    }

    // MARK: - Session Management

    private func startSession() {
        sessionStartTime = Date()
    }

    private var sessionDuration: TimeInterval {
        guard let start = sessionStartTime else { return 0 }
        return Date().timeIntervalSince(start)
    }

    // MARK: - Timed Events

    private var timedEvents: [String: Date] = [:]

    /// Start timing an event
    public func startTimedEvent(_ event: AnalyticsEvent) {
        timedEvents[event.name] = Date()
    }

    /// End timed event and track with duration
    public func endTimedEvent(_ event: AnalyticsEvent, properties: [String: Any]? = nil) {
        guard let startTime = timedEvents[event.name] else {
            track(event, properties: properties)
            return
        }

        let duration = Date().timeIntervalSince(startTime)
        var eventProperties = properties ?? [:]
        eventProperties["duration_seconds"] = duration

        track(event, properties: eventProperties)
        timedEvents.removeValue(forKey: event.name)
    }

    // MARK: - Logging

    private func log(_ message: String) {
        #if DEBUG
        print("[Analytics] \(message)")
        #endif
    }
}

// MARK: - Analytics Events

public enum AnalyticsEvent {
    // App Lifecycle
    case appLaunched
    case appBackgrounded
    case appForegrounded
    case analyticsEnabled

    // Onboarding
    case onboardingStarted
    case onboardingStepCompleted(step: String)
    case onboardingCompleted
    case onboardingSkipped

    // Authentication
    case signInStarted
    case signInCompleted(method: String)
    case signInFailed(error: String)
    case signOutCompleted

    // Food Logging
    case foodSearched(query: String)
    case foodSelected(source: String)
    case foodLogged(mealType: String, source: String)
    case foodDeleted(mealType: String)
    case mealCompleted(mealType: String)

    // Scanning
    case cameraScanStarted
    case cameraScanCompleted(foodCount: Int)
    case cameraScanFailed(error: String)
    case barcodeScanStarted
    case barcodeScanCompleted(found: Bool)
    case barcodeScanFailed(error: String)

    // Recipes
    case recipeCreated(category: String)
    case recipeEdited
    case recipeDeleted
    case recipeViewed
    case recipeFavorited
    case recipeUnfavorited
    case recipeAddedToMeal

    // Progress
    case progressViewed(timeRange: String)
    case weightLogged(change: Double)
    case achievementEarned(achievement: String)
    case achievementViewed

    // Settings
    case settingsViewed
    case settingChanged(setting: String, value: String)
    case goalsUpdated
    case notificationsToggled(enabled: Bool)

    // Subscription
    case paywallViewed(source: String)
    case subscriptionStarted(plan: String)
    case subscriptionCancelled
    case subscriptionRestored
    case trialStarted(plan: String)

    // Engagement
    case streakMilestone(days: Int)
    case screenViewed
    case featureUsed(feature: String)
    case shareCompleted(type: String)
    case feedbackSubmitted

    // Errors
    case errorOccurred(type: String, message: String)

    var name: String {
        switch self {
        case .appLaunched: return "App Launched"
        case .appBackgrounded: return "App Backgrounded"
        case .appForegrounded: return "App Foregrounded"
        case .analyticsEnabled: return "Analytics Enabled"

        case .onboardingStarted: return "Onboarding Started"
        case .onboardingStepCompleted: return "Onboarding Step Completed"
        case .onboardingCompleted: return "Onboarding Completed"
        case .onboardingSkipped: return "Onboarding Skipped"

        case .signInStarted: return "Sign In Started"
        case .signInCompleted: return "Sign In Completed"
        case .signInFailed: return "Sign In Failed"
        case .signOutCompleted: return "Sign Out Completed"

        case .foodSearched: return "Food Searched"
        case .foodSelected: return "Food Selected"
        case .foodLogged: return "Food Logged"
        case .foodDeleted: return "Food Deleted"
        case .mealCompleted: return "Meal Completed"

        case .cameraScanStarted: return "Camera Scan Started"
        case .cameraScanCompleted: return "Camera Scan Completed"
        case .cameraScanFailed: return "Camera Scan Failed"
        case .barcodeScanStarted: return "Barcode Scan Started"
        case .barcodeScanCompleted: return "Barcode Scan Completed"
        case .barcodeScanFailed: return "Barcode Scan Failed"

        case .recipeCreated: return "Recipe Created"
        case .recipeEdited: return "Recipe Edited"
        case .recipeDeleted: return "Recipe Deleted"
        case .recipeViewed: return "Recipe Viewed"
        case .recipeFavorited: return "Recipe Favorited"
        case .recipeUnfavorited: return "Recipe Unfavorited"
        case .recipeAddedToMeal: return "Recipe Added to Meal"

        case .progressViewed: return "Progress Viewed"
        case .weightLogged: return "Weight Logged"
        case .achievementEarned: return "Achievement Earned"
        case .achievementViewed: return "Achievement Viewed"

        case .settingsViewed: return "Settings Viewed"
        case .settingChanged: return "Setting Changed"
        case .goalsUpdated: return "Goals Updated"
        case .notificationsToggled: return "Notifications Toggled"

        case .paywallViewed: return "Paywall Viewed"
        case .subscriptionStarted: return "Subscription Started"
        case .subscriptionCancelled: return "Subscription Cancelled"
        case .subscriptionRestored: return "Subscription Restored"
        case .trialStarted: return "Trial Started"

        case .streakMilestone: return "Streak Milestone"
        case .screenViewed: return "Screen Viewed"
        case .featureUsed: return "Feature Used"
        case .shareCompleted: return "Share Completed"
        case .feedbackSubmitted: return "Feedback Submitted"

        case .errorOccurred: return "Error Occurred"
        }
    }

    var properties: [String: Any] {
        switch self {
        case .onboardingStepCompleted(let step):
            return ["step": step]
        case .signInCompleted(let method):
            return ["method": method]
        case .signInFailed(let error):
            return ["error": error]
        case .foodSearched(let query):
            return ["query": query]
        case .foodSelected(let source):
            return ["source": source]
        case .foodLogged(let mealType, let source):
            return ["meal_type": mealType, "source": source]
        case .foodDeleted(let mealType):
            return ["meal_type": mealType]
        case .mealCompleted(let mealType):
            return ["meal_type": mealType]
        case .cameraScanCompleted(let foodCount):
            return ["food_count": foodCount]
        case .cameraScanFailed(let error):
            return ["error": error]
        case .barcodeScanCompleted(let found):
            return ["product_found": found]
        case .barcodeScanFailed(let error):
            return ["error": error]
        case .recipeCreated(let category):
            return ["category": category]
        case .progressViewed(let timeRange):
            return ["time_range": timeRange]
        case .weightLogged(let change):
            return ["weight_change": change]
        case .achievementEarned(let achievement):
            return ["achievement": achievement]
        case .settingChanged(let setting, let value):
            return ["setting": setting, "value": value]
        case .notificationsToggled(let enabled):
            return ["enabled": enabled]
        case .paywallViewed(let source):
            return ["source": source]
        case .subscriptionStarted(let plan):
            return ["plan": plan]
        case .trialStarted(let plan):
            return ["plan": plan]
        case .streakMilestone(let days):
            return ["days": days]
        case .featureUsed(let feature):
            return ["feature": feature]
        case .shareCompleted(let type):
            return ["type": type]
        case .errorOccurred(let type, let message):
            return ["error_type": type, "message": message]
        default:
            return [:]
        }
    }
}

// MARK: - User Properties

public enum UserProperty: String {
    // Profile
    case userId = "user_id"
    case email = "email"
    case name = "name"
    case createdAt = "created_at"

    // Demographics
    case age = "age"
    case gender = "gender"
    case country = "country"

    // Goals
    case goalType = "goal_type"
    case calorieGoal = "calorie_goal"
    case startingWeight = "starting_weight"
    case targetWeight = "target_weight"
    case activityLevel = "activity_level"

    // Subscription
    case subscriptionStatus = "subscription_status"
    case subscriptionPlan = "subscription_plan"
    case trialEndDate = "trial_end_date"

    // Engagement
    case totalMealsLogged = "total_meals_logged"
    case totalDaysLogged = "total_days_logged"
    case currentStreak = "current_streak"
    case longestStreak = "longest_streak"
    case achievementsEarned = "achievements_earned"
    case recipesCreated = "recipes_created"

    // App
    case appVersion = "app_version"
    case iosVersion = "ios_version"
    case deviceModel = "device_model"
    case lastActiveAt = "last_active_at"
    case pushEnabled = "push_enabled"
}

// MARK: - Analytics Screens

public enum AnalyticsScreen: String {
    case onboarding = "Onboarding"
    case dashboard = "Dashboard"
    case foodSearch = "Food Search"
    case foodDetail = "Food Detail"
    case cameraScanner = "Camera Scanner"
    case barcodeScanner = "Barcode Scanner"
    case recipes = "Recipes"
    case recipeDetail = "Recipe Detail"
    case createRecipe = "Create Recipe"
    case progress = "Progress"
    case achievements = "Achievements"
    case settings = "Settings"
    case profile = "Profile"
    case subscription = "Subscription"
    case paywall = "Paywall"
}

// MARK: - Event Properties

public struct EventProperties {
    private var properties: [String: Any] = [:]

    public init() {}

    public mutating func set(_ key: String, value: Any) {
        properties[key] = value
    }

    public func toDictionary() -> [String: Any] {
        properties
    }

    // Convenience builders
    public static func foodLogged(
        mealType: String,
        source: String,
        calories: Int,
        foodName: String
    ) -> EventProperties {
        var props = EventProperties()
        props.set("meal_type", value: mealType)
        props.set("source", value: source)
        props.set("calories", value: calories)
        props.set("food_name", value: foodName)
        return props
    }

    public static func scanCompleted(
        type: String,
        success: Bool,
        itemCount: Int,
        duration: TimeInterval
    ) -> EventProperties {
        var props = EventProperties()
        props.set("scan_type", value: type)
        props.set("success", value: success)
        props.set("item_count", value: itemCount)
        props.set("duration_seconds", value: duration)
        return props
    }
}
