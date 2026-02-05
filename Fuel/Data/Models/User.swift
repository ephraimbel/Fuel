import Foundation
import SwiftData

/// User profile and settings model
/// Stores all user-specific data including goals, preferences, and stats

@Model
public final class User {
    // MARK: - Identifiers

    @Attribute(.unique) public var id: UUID
    public var appleUserID: String?
    public var email: String?

    // MARK: - Profile

    public var name: String
    public var avatarURL: String?
    public var createdAt: Date
    public var lastActiveAt: Date

    // MARK: - Physical Stats

    public var birthDate: Date?
    public var gender: Gender
    public var heightCm: Double
    public var currentWeightKg: Double
    public var targetWeightKg: Double
    public var activityLevel: ActivityLevel
    public var fitnessGoal: FitnessGoal

    // MARK: - Calculated Goals

    public var dailyCalorieTarget: Int
    public var dailyProteinTarget: Int
    public var dailyCarbsTarget: Int
    public var dailyFatTarget: Int

    // MARK: - Preferences

    public var preferredUnits: Units
    public var hapticsEnabled: Bool
    public var notificationsEnabled: Bool
    public var mealReminderTimes: [Date]
    public var weeklyWeighInDay: Int // 0 = Sunday, 1 = Monday, etc.
    public var weeklyWeighInTime: Date?

    // MARK: - Subscription

    public var subscriptionTier: SubscriptionTier
    public var subscriptionExpiresAt: Date?
    public var trialEndsAt: Date?

    // MARK: - Scan Tracking

    public var weeklyAIScansUsed: Int
    public var weeklyScansResetDate: Date?

    // MARK: - Stats

    public var totalMealsLogged: Int
    public var currentStreak: Int
    public var longestStreak: Int
    public var streakLastUpdatedAt: Date?

    // MARK: - Relationships

    @Relationship(deleteRule: .cascade, inverse: \Meal.user)
    public var meals: [Meal]?

    @Relationship(deleteRule: .cascade, inverse: \WeightEntry.user)
    public var weightEntries: [WeightEntry]?

    @Relationship(deleteRule: .cascade, inverse: \Achievement.user)
    public var achievements: [Achievement]?

    // MARK: - Initialization

    public init(
        id: UUID = UUID(),
        name: String = "",
        gender: Gender = .notSpecified,
        heightCm: Double = 170,
        currentWeightKg: Double = 70,
        targetWeightKg: Double = 70,
        activityLevel: ActivityLevel = .moderate,
        fitnessGoal: FitnessGoal = .maintain
    ) {
        self.id = id
        self.name = name
        self.createdAt = Date()
        self.lastActiveAt = Date()

        self.gender = gender
        self.heightCm = heightCm
        self.currentWeightKg = currentWeightKg
        self.targetWeightKg = targetWeightKg
        self.activityLevel = activityLevel
        self.fitnessGoal = fitnessGoal

        // Calculate initial targets
        self.dailyCalorieTarget = 2000
        self.dailyProteinTarget = 150
        self.dailyCarbsTarget = 250
        self.dailyFatTarget = 65

        // Defaults
        self.preferredUnits = .metric
        self.hapticsEnabled = true
        self.notificationsEnabled = true
        self.mealReminderTimes = []
        self.weeklyWeighInDay = 1 // Monday

        self.subscriptionTier = .free
        self.weeklyAIScansUsed = 0
        self.weeklyScansResetDate = nil
        self.totalMealsLogged = 0
        self.currentStreak = 0
        self.longestStreak = 0
    }

    // MARK: - Computed Properties

    public var age: Int? {
        guard let birthDate else { return nil }
        return Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year
    }

    public var bmi: Double {
        guard heightCm > 0 else { return 0 }
        let heightM = heightCm / 100
        return currentWeightKg / (heightM * heightM)
    }

    public var isPremium: Bool {
        subscriptionTier == .premium
    }

    public var isInTrial: Bool {
        guard let trialEndsAt else { return false }
        return Date() < trialEndsAt
    }

    public var weightToLose: Double {
        max(0, currentWeightKg - targetWeightKg)
    }

    public var weightToGain: Double {
        max(0, targetWeightKg - currentWeightKg)
    }

    /// Remaining AI scans this week
    public var remainingAIScans: Int {
        if isPremium || isInTrial { return .max }
        resetWeeklyScansIfNeeded()
        return max(0, subscriptionTier.aiScansPerWeek - weeklyAIScansUsed)
    }

    /// Whether user can perform an AI scan
    public var canUseAIScan: Bool {
        if isPremium || isInTrial { return true }
        resetWeeklyScansIfNeeded()
        return weeklyAIScansUsed < subscriptionTier.aiScansPerWeek
    }

    // MARK: - Methods

    /// Calculate TDEE using Mifflin-St Jeor equation
    public func calculateTDEE() -> Int {
        guard let age, age > 0, age < 150 else { return 2000 }

        // Validate inputs for realistic ranges
        let validWeight = max(30, min(currentWeightKg, 500))  // 30-500 kg
        let validHeight = max(100, min(heightCm, 300))        // 100-300 cm

        // BMR calculation
        var bmr: Double
        switch gender {
        case .male:
            bmr = (10 * validWeight) + (6.25 * validHeight) - (5 * Double(age)) + 5
        case .female:
            bmr = (10 * validWeight) + (6.25 * validHeight) - (5 * Double(age)) - 161
        case .notSpecified:
            bmr = (10 * validWeight) + (6.25 * validHeight) - (5 * Double(age)) - 78
        }

        // Apply activity multiplier
        let tdee = bmr * activityLevel.multiplier

        // Clamp to reasonable range (800-8000 calories)
        return max(800, min(Int(tdee), 8000))
    }

    /// Calculate daily calorie target based on goal
    public func calculateCalorieTarget() -> Int {
        let tdee = calculateTDEE()

        switch fitnessGoal {
        case .lose:
            return tdee - 500 // ~0.5kg/week loss
        case .maintain:
            return tdee
        case .gain:
            return tdee + 300 // Lean bulk
        }
    }

    /// Calculate macro targets based on goal and preferences
    public func calculateMacroTargets() -> (protein: Int, carbs: Int, fat: Int) {
        let calories = Double(dailyCalorieTarget)

        // Protein: 1.6-2.2g per kg for most goals
        let proteinPerKg: Double
        switch fitnessGoal {
        case .lose:
            proteinPerKg = 2.0 // Higher protein for muscle preservation
        case .maintain:
            proteinPerKg = 1.8
        case .gain:
            proteinPerKg = 2.2 // Maximum for muscle building
        }

        let proteinGrams = Int(currentWeightKg * proteinPerKg)
        let proteinCalories = Double(proteinGrams) * 4

        // Fat: 25-30% of calories
        let fatCalories = calories * 0.28
        let fatGrams = Int(fatCalories / 9)

        // Carbs: Remainder
        let carbCalories = calories - proteinCalories - fatCalories
        let carbGrams = Int(carbCalories / 4)

        return (proteinGrams, carbGrams, fatGrams)
    }

    /// Use an AI scan (decrements counter for free users)
    public func useAIScan() {
        guard !isPremium && !isInTrial else { return }
        resetWeeklyScansIfNeeded()
        weeklyAIScansUsed += 1
    }

    /// Reset weekly scan counter if a week has passed
    private func resetWeeklyScansIfNeeded() {
        let calendar = Calendar.current
        let now = Date()

        guard let resetDate = weeklyScansResetDate else {
            weeklyScansResetDate = now
            weeklyAIScansUsed = 0
            return
        }

        if let daysDiff = calendar.dateComponents([.day], from: resetDate, to: now).day,
           daysDiff >= 7 {
            weeklyScansResetDate = now
            weeklyAIScansUsed = 0
        }
    }

    /// Update streak based on logged meals
    public func updateStreak(hasLoggedToday: Bool) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let lastUpdate = streakLastUpdatedAt {
            let lastUpdateDay = calendar.startOfDay(for: lastUpdate)
            let daysDiff = calendar.dateComponents([.day], from: lastUpdateDay, to: today).day ?? 0

            if daysDiff == 0 {
                // Already updated today
                return
            } else if daysDiff == 1 && hasLoggedToday {
                // Consecutive day
                currentStreak += 1
                longestStreak = max(longestStreak, currentStreak)
            } else if daysDiff > 1 {
                // Streak broken
                currentStreak = hasLoggedToday ? 1 : 0
            }
        } else if hasLoggedToday {
            currentStreak = 1
        }

        streakLastUpdatedAt = Date()
    }
}

// MARK: - Enums

public enum Gender: String, Codable, CaseIterable {
    case male = "male"
    case female = "female"
    case notSpecified = "not_specified"

    public var displayName: String {
        switch self {
        case .male: return "Male"
        case .female: return "Female"
        case .notSpecified: return "Prefer not to say"
        }
    }
}

public enum ActivityLevel: String, Codable, CaseIterable {
    case sedentary = "sedentary"
    case light = "light"
    case moderate = "moderate"
    case active = "active"
    case veryActive = "very_active"

    public var displayName: String {
        switch self {
        case .sedentary: return "Sedentary"
        case .light: return "Lightly Active"
        case .moderate: return "Moderately Active"
        case .active: return "Active"
        case .veryActive: return "Very Active"
        }
    }

    public var description: String {
        switch self {
        case .sedentary: return "Little or no exercise, desk job"
        case .light: return "Light exercise 1-3 days/week"
        case .moderate: return "Moderate exercise 3-5 days/week"
        case .active: return "Hard exercise 6-7 days/week"
        case .veryActive: return "Athlete or physical job"
        }
    }

    public var multiplier: Double {
        switch self {
        case .sedentary: return 1.2
        case .light: return 1.375
        case .moderate: return 1.55
        case .active: return 1.725
        case .veryActive: return 1.9
        }
    }

    public var icon: String {
        switch self {
        case .sedentary: return "figure.stand"
        case .light: return "figure.walk"
        case .moderate: return "figure.run"
        case .active: return "figure.highintensity.intervaltraining"
        case .veryActive: return "flame.fill"
        }
    }
}

public enum FitnessGoal: String, Codable, CaseIterable {
    case lose = "lose"
    case maintain = "maintain"
    case gain = "gain"

    public var displayName: String {
        switch self {
        case .lose: return "Lose Weight"
        case .maintain: return "Maintain Weight"
        case .gain: return "Build Muscle"
        }
    }

    public var description: String {
        switch self {
        case .lose: return "Lose fat while preserving muscle"
        case .maintain: return "Stay at your current weight"
        case .gain: return "Build muscle with lean gains"
        }
    }

    public var icon: String {
        switch self {
        case .lose: return "arrow.down.circle"
        case .maintain: return "equal.circle"
        case .gain: return "arrow.up.circle"
        }
    }
}

public enum Units: String, Codable, CaseIterable {
    case metric = "metric"
    case imperial = "imperial"

    public var weightUnit: String {
        switch self {
        case .metric: return "kg"
        case .imperial: return "lbs"
        }
    }

    public var heightUnit: String {
        switch self {
        case .metric: return "cm"
        case .imperial: return "ft/in"
        }
    }
}

public enum SubscriptionTier: String, Codable, CaseIterable {
    case free = "free"
    case premium = "premium"

    public var displayName: String {
        switch self {
        case .free: return "Free"
        case .premium: return "Fuel+"
        }
    }

    public var aiScansPerWeek: Int {
        switch self {
        case .free: return 3
        case .premium: return .max
        }
    }

    /// Maximum recipes for this tier
    public var maxRecipes: Int {
        switch self {
        case .free: return 3
        case .premium: return .max
        }
    }

    /// Maximum history days for this tier
    public var historyDays: Int {
        switch self {
        case .free: return 7
        case .premium: return .max
        }
    }
}
