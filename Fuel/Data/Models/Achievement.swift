import Foundation
import SwiftData

/// Achievement model
/// Gamification system for user engagement

@Model
public final class Achievement {
    // MARK: - Identifiers

    @Attribute(.unique) public var id: UUID
    public var achievementType: AchievementType

    // MARK: - Status

    public var isUnlocked: Bool
    public var unlockedAt: Date?
    public var progress: Double // 0.0 to 1.0
    public var currentValue: Int
    public var targetValue: Int

    // MARK: - Relationships

    public var user: User?

    // MARK: - Metadata

    public var createdAt: Date
    public var updatedAt: Date

    // MARK: - Initialization

    public init(
        id: UUID = UUID(),
        achievementType: AchievementType
    ) {
        self.id = id
        self.achievementType = achievementType
        self.isUnlocked = false
        self.progress = 0
        self.currentValue = 0
        self.targetValue = achievementType.targetValue
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: - Computed Properties

    public var title: String {
        achievementType.title
    }

    public var achievementDescription: String {
        achievementType.achievementDescription
    }

    public var icon: String {
        achievementType.icon
    }

    public var tier: AchievementTier {
        achievementType.tier
    }

    public var progressText: String {
        "\(currentValue) / \(targetValue)"
    }

    // MARK: - Methods

    /// Update progress toward this achievement
    public func updateProgress(newValue: Int) {
        currentValue = newValue
        progress = min(Double(currentValue) / Double(targetValue), 1.0)
        updatedAt = Date()

        if progress >= 1.0 && !isUnlocked {
            unlock()
        }
    }

    /// Mark achievement as unlocked
    public func unlock() {
        guard !isUnlocked else { return }

        isUnlocked = true
        unlockedAt = Date()
        progress = 1.0
        currentValue = targetValue
        updatedAt = Date()

        // Haptic feedback will be triggered by the observer
    }
}

// MARK: - Achievement Type

public enum AchievementType: String, Codable, CaseIterable {
    // Streak Achievements
    case firstDay = "first_day"
    case streak3 = "streak_3"
    case streak7 = "streak_7"
    case streak14 = "streak_14"
    case streak30 = "streak_30"
    case streak60 = "streak_60"
    case streak100 = "streak_100"
    case streak365 = "streak_365"

    // Meal Logging
    case firstMeal = "first_meal"
    case meals10 = "meals_10"
    case meals50 = "meals_50"
    case meals100 = "meals_100"
    case meals500 = "meals_500"
    case meals1000 = "meals_1000"

    // Photo Scanning
    case firstScan = "first_scan"
    case scans25 = "scans_25"
    case scans100 = "scans_100"
    case scans500 = "scans_500"

    // Weight Progress
    case firstWeighIn = "first_weigh_in"
    case lost5 = "lost_5"
    case lost10 = "lost_10"
    case lost25 = "lost_25"
    case gained5 = "gained_5"
    case gained10 = "gained_10"

    // Consistency
    case perfectDay = "perfect_day"
    case perfectWeek = "perfect_week"
    case perfectMonth = "perfect_month"

    // Special
    case earlyBird = "early_bird"
    case nightOwl = "night_owl"
    case weekendWarrior = "weekend_warrior"
    case proteinPro = "protein_pro"
    case balanced = "balanced"

    public var title: String {
        switch self {
        case .firstDay: return "Getting Started"
        case .streak3: return "Three's Company"
        case .streak7: return "First Week"
        case .streak14: return "Two Week Warrior"
        case .streak30: return "Monthly Master"
        case .streak60: return "Two Month Champion"
        case .streak100: return "Century Club"
        case .streak365: return "Year of Dedication"

        case .firstMeal: return "First Bite"
        case .meals10: return "Getting Serious"
        case .meals50: return "Halfway Hero"
        case .meals100: return "Century Logger"
        case .meals500: return "Food Journalist"
        case .meals1000: return "Nutrition Master"

        case .firstScan: return "AI Explorer"
        case .scans25: return "Scanner Pro"
        case .scans100: return "Scan Master"
        case .scans500: return "AI Whisperer"

        case .firstWeighIn: return "Scale Friend"
        case .lost5: return "5kg Down"
        case .lost10: return "10kg Down"
        case .lost25: return "Transformation"
        case .gained5: return "5kg Gained"
        case .gained10: return "10kg Gained"

        case .perfectDay: return "Perfect Day"
        case .perfectWeek: return "Perfect Week"
        case .perfectMonth: return "Perfect Month"

        case .earlyBird: return "Early Bird"
        case .nightOwl: return "Night Owl"
        case .weekendWarrior: return "Weekend Warrior"
        case .proteinPro: return "Protein Pro"
        case .balanced: return "Balance Master"
        }
    }

    public var achievementDescription: String {
        switch self {
        case .firstDay: return "Log your first day of meals"
        case .streak3: return "Maintain a 3-day logging streak"
        case .streak7: return "Log meals for 7 consecutive days"
        case .streak14: return "Log meals for 14 consecutive days"
        case .streak30: return "Log meals for 30 consecutive days"
        case .streak60: return "Log meals for 60 consecutive days"
        case .streak100: return "Log meals for 100 consecutive days"
        case .streak365: return "Log meals for an entire year"

        case .firstMeal: return "Log your first meal"
        case .meals10: return "Log 10 meals"
        case .meals50: return "Log 50 meals"
        case .meals100: return "Log 100 meals"
        case .meals500: return "Log 500 meals"
        case .meals1000: return "Log 1,000 meals"

        case .firstScan: return "Scan your first meal with AI"
        case .scans25: return "Scan 25 meals with AI"
        case .scans100: return "Scan 100 meals with AI"
        case .scans500: return "Scan 500 meals with AI"

        case .firstWeighIn: return "Log your first weight"
        case .lost5: return "Lose 5 kilograms"
        case .lost10: return "Lose 10 kilograms"
        case .lost25: return "Lose 25 kilograms"
        case .gained5: return "Gain 5 kilograms"
        case .gained10: return "Gain 10 kilograms"

        case .perfectDay: return "Hit all macro targets in a day"
        case .perfectWeek: return "Hit calorie target 7 days straight"
        case .perfectMonth: return "Hit calorie target 30 days straight"

        case .earlyBird: return "Log breakfast before 7 AM"
        case .nightOwl: return "Log a meal after 10 PM"
        case .weekendWarrior: return "Log all meals on a weekend"
        case .proteinPro: return "Hit protein target 10 days in a row"
        case .balanced: return "Stay within 100 cal of target for a week"
        }
    }

    public var icon: String {
        switch self {
        case .firstDay, .streak3, .streak7, .streak14, .streak30,
             .streak60, .streak100, .streak365:
            return "flame.fill"

        case .firstMeal, .meals10, .meals50, .meals100,
             .meals500, .meals1000:
            return "fork.knife"

        case .firstScan, .scans25, .scans100, .scans500:
            return "camera.viewfinder"

        case .firstWeighIn, .lost5, .lost10, .lost25,
             .gained5, .gained10:
            return "scalemass.fill"

        case .perfectDay, .perfectWeek, .perfectMonth:
            return "checkmark.seal.fill"

        case .earlyBird:
            return "sunrise.fill"
        case .nightOwl:
            return "moon.stars.fill"
        case .weekendWarrior:
            return "calendar"
        case .proteinPro:
            return "bolt.fill"
        case .balanced:
            return "equal.circle.fill"
        }
    }

    public var tier: AchievementTier {
        switch self {
        case .firstDay, .firstMeal, .firstScan, .firstWeighIn:
            return .bronze
        case .streak3, .streak7, .meals10, .scans25, .perfectDay,
             .earlyBird, .nightOwl:
            return .bronze
        case .streak14, .streak30, .meals50, .meals100, .scans100,
             .lost5, .gained5, .perfectWeek, .weekendWarrior:
            return .silver
        case .streak60, .streak100, .meals500, .scans500, .lost10,
             .gained10, .perfectMonth, .proteinPro, .balanced:
            return .gold
        case .streak365, .meals1000, .lost25:
            return .platinum
        }
    }

    public var targetValue: Int {
        switch self {
        case .firstDay, .firstMeal, .firstScan, .firstWeighIn: return 1
        case .streak3: return 3
        case .streak7, .perfectWeek: return 7
        case .streak14: return 14
        case .streak30, .perfectMonth: return 30
        case .streak60: return 60
        case .streak100: return 100
        case .streak365: return 365
        case .meals10, .proteinPro: return 10
        case .meals50: return 50
        case .meals100, .scans100: return 100
        case .meals500, .scans500: return 500
        case .meals1000: return 1000
        case .scans25: return 25
        case .lost5, .gained5: return 5
        case .lost10, .gained10: return 10
        case .lost25: return 25
        case .perfectDay, .earlyBird, .nightOwl, .weekendWarrior, .balanced: return 1
        }
    }
}

// MARK: - Achievement Tier

public enum AchievementTier: String, Codable, CaseIterable, Comparable {
    case bronze
    case silver
    case gold
    case platinum

    public var displayName: String {
        rawValue.capitalized
    }

    public var color: String {
        switch self {
        case .bronze: return "bronze"
        case .silver: return "silver"
        case .gold: return "gold"
        case .platinum: return "platinum"
        }
    }

    public static func < (lhs: AchievementTier, rhs: AchievementTier) -> Bool {
        let order: [AchievementTier] = [.bronze, .silver, .gold, .platinum]
        return (order.firstIndex(of: lhs) ?? 0) < (order.firstIndex(of: rhs) ?? 0)
    }
}

// MARK: - Achievement Manager Helper

/// Helper for checking and unlocking achievements
public struct AchievementChecker {

    /// Get achievements that should be checked based on action
    public static func achievementsToCheck(for action: AchievementAction) -> [AchievementType] {
        switch action {
        case .mealLogged:
            return [.firstMeal, .meals10, .meals50, .meals100, .meals500, .meals1000]
        case .photoScanned:
            return [.firstScan, .scans25, .scans100, .scans500]
        case .weightLogged:
            return [.firstWeighIn]
        case .streakUpdated:
            return [.firstDay, .streak3, .streak7, .streak14, .streak30, .streak60, .streak100, .streak365]
        case .macrosHit:
            return [.perfectDay, .proteinPro, .balanced]
        }
    }

    public enum AchievementAction {
        case mealLogged
        case photoScanned
        case weightLogged
        case streakUpdated
        case macrosHit
    }
}
