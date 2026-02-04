import SwiftUI

// MARK: - View Modifier for Screen Tracking

struct AnalyticsScreenModifier: ViewModifier {
    let screen: AnalyticsScreen

    func body(content: Content) -> some View {
        content
            .onAppear {
                AnalyticsService.shared.trackScreen(screen)
            }
            .onDisappear {
                AnalyticsService.shared.trackScreenExit(screen)
            }
    }
}

extension View {
    /// Track screen views automatically
    func trackScreen(_ screen: AnalyticsScreen) -> some View {
        modifier(AnalyticsScreenModifier(screen: screen))
    }

    /// Track a custom event on appear
    func trackOnAppear(_ event: AnalyticsEvent) -> some View {
        onAppear {
            AnalyticsService.shared.track(event)
        }
    }

    /// Track a custom event on tap
    func trackOnTap(_ event: AnalyticsEvent) -> some View {
        simultaneousGesture(
            TapGesture().onEnded {
                AnalyticsService.shared.track(event)
            }
        )
    }
}

// MARK: - Analytics Convenience Extensions

extension AnalyticsService {
    // MARK: - Onboarding

    func trackOnboardingStep(_ step: Int, name: String) {
        track(.onboardingStepCompleted(step: "\(step)_\(name)"))
    }

    func trackOnboardingComplete(
        goalType: String,
        calorieGoal: Int,
        startWeight: Double,
        targetWeight: Double
    ) {
        track(.onboardingCompleted, properties: [
            "goal_type": goalType,
            "calorie_goal": calorieGoal,
            "start_weight": startWeight,
            "target_weight": targetWeight
        ])

        setUserProperties([
            .goalType: goalType,
            .calorieGoal: calorieGoal,
            .startingWeight: startWeight,
            .targetWeight: targetWeight
        ])
    }

    // MARK: - Food Logging

    func trackFoodLogged(
        name: String,
        calories: Int,
        mealType: MealType,
        source: FoodSource
    ) {
        track(.foodLogged(mealType: mealType.rawValue, source: source.rawValue), properties: [
            "food_name": name,
            "calories": calories
        ])

        incrementUserProperty(.totalMealsLogged)
    }

    func trackFoodSearch(_ query: String, resultCount: Int) {
        track(.foodSearched(query: query), properties: [
            "result_count": resultCount,
            "query_length": query.count
        ])
    }

    // MARK: - Scanning

    func trackCameraScan(success: Bool, foodItems: [String], duration: TimeInterval) {
        if success {
            track(.cameraScanCompleted(foodCount: foodItems.count), properties: [
                "foods": foodItems.joined(separator: ", "),
                "duration_seconds": duration
            ])
        } else {
            track(.cameraScanFailed(error: "no_foods_detected"))
        }
    }

    func trackBarcodeScan(success: Bool, barcode: String, productName: String?) {
        track(.barcodeScanCompleted(found: success), properties: [
            "barcode": barcode,
            "product_name": productName ?? "unknown"
        ])
    }

    // MARK: - Recipes

    func trackRecipeCreated(_ recipe: Recipe) {
        track(.recipeCreated(category: recipe.category.rawValue), properties: [
            "ingredient_count": recipe.ingredients.count,
            "has_instructions": !recipe.instructions.isEmpty,
            "has_image": recipe.imageData != nil,
            "calories_per_serving": recipe.caloriesPerServing
        ])

        incrementUserProperty(.recipesCreated)
    }

    // MARK: - Progress

    func trackWeightLogged(currentWeight: Double, previousWeight: Double?, goalWeight: Double) {
        let change = previousWeight.map { currentWeight - $0 } ?? 0
        let toGoal = currentWeight - goalWeight

        track(.weightLogged(change: change), properties: [
            "current_weight": currentWeight,
            "to_goal": toGoal,
            "direction": change < 0 ? "loss" : (change > 0 ? "gain" : "maintain")
        ])
    }

    func trackAchievementEarned(_ achievementId: String, title: String) {
        track(.achievementEarned(achievement: achievementId), properties: [
            "title": title
        ])

        incrementUserProperty(.achievementsEarned)
    }

    // MARK: - Streaks

    func trackStreakUpdate(current: Int, longest: Int) {
        setUserProperties([
            .currentStreak: current,
            .longestStreak: longest
        ])

        // Track milestones
        let milestones = [7, 14, 30, 60, 90, 180, 365]
        if milestones.contains(current) {
            track(.streakMilestone(days: current))
        }
    }

    // MARK: - Subscription

    func trackPaywallViewed(source: String, features: [String]) {
        track(.paywallViewed(source: source), properties: [
            "features_shown": features.joined(separator: ", ")
        ])
    }

    func trackSubscriptionPurchased(plan: String, price: Double, currency: String) {
        track(.subscriptionStarted(plan: plan), properties: [
            "price": price,
            "currency": currency
        ])

        setUserProperties([
            .subscriptionStatus: "active",
            .subscriptionPlan: plan
        ])
    }

    func trackTrialStarted(plan: String, trialDays: Int) {
        track(.trialStarted(plan: plan), properties: [
            "trial_days": trialDays
        ])

        setUserProperty(.subscriptionStatus, value: "trial")
    }

    // MARK: - Settings

    func trackSettingChanged(_ setting: String, from oldValue: Any, to newValue: Any) {
        track(.settingChanged(setting: setting, value: String(describing: newValue)), properties: [
            "old_value": String(describing: oldValue)
        ])
    }

    // MARK: - Errors

    func trackError(_ error: Error, context: String) {
        track(.errorOccurred(type: context, message: error.localizedDescription), properties: [
            "error_domain": (error as NSError).domain,
            "error_code": (error as NSError).code
        ])
    }

    // MARK: - App Lifecycle

    func trackAppLifecycle(_ state: AppLifecycleState) {
        switch state {
        case .launched:
            track(.appLaunched, properties: [
                "app_version": Bundle.main.appVersion,
                "ios_version": UIDevice.current.systemVersion,
                "device_model": UIDevice.current.model
            ])

            setUserProperties([
                .appVersion: Bundle.main.appVersion,
                .iosVersion: UIDevice.current.systemVersion,
                .deviceModel: UIDevice.current.model,
                .lastActiveAt: ISO8601DateFormatter().string(from: Date())
            ])

        case .backgrounded:
            track(.appBackgrounded)

        case .foregrounded:
            track(.appForegrounded)
            setUserProperty(.lastActiveAt, value: ISO8601DateFormatter().string(from: Date()))
        }
    }
}

// MARK: - App Lifecycle State

enum AppLifecycleState {
    case launched
    case backgrounded
    case foregrounded
}

// MARK: - Bundle Extension

extension Bundle {
    var appVersion: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
    }

    var buildNumber: String {
        infoDictionary?["CFBundleVersion"] as? String ?? "unknown"
    }
}

// MARK: - Analytics Debug View

#if DEBUG
struct AnalyticsDebugView: View {
    @State private var events: [(String, Date)] = []

    var body: some View {
        NavigationStack {
            List {
                Section("Recent Events") {
                    if events.isEmpty {
                        Text("No events tracked yet")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(events, id: \.1) { event, date in
                            VStack(alignment: .leading) {
                                Text(event)
                                    .font(.headline)
                                Text(date.formatted())
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Section("Test Events") {
                    Button("Track Screen View") {
                        AnalyticsService.shared.trackScreen(.dashboard)
                    }

                    Button("Track Food Logged") {
                        AnalyticsService.shared.track(
                            .foodLogged(mealType: "breakfast", source: "search")
                        )
                    }

                    Button("Track Achievement") {
                        AnalyticsService.shared.track(
                            .achievementEarned(achievement: "streak_7")
                        )
                    }
                }

                Section("User Properties") {
                    Button("Set Test Properties") {
                        AnalyticsService.shared.setUserProperties([
                            .calorieGoal: 2000,
                            .goalType: "lose_weight",
                            .currentStreak: 7
                        ])
                    }
                }
            }
            .navigationTitle("Analytics Debug")
        }
    }
}

#Preview {
    AnalyticsDebugView()
}
#endif
