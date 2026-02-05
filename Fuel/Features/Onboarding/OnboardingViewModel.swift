import SwiftUI
import SwiftData
import OSLog

/// Onboarding View Model
/// Manages state and navigation for the onboarding flow

private let logger = Logger(subsystem: "com.fuel.app", category: "Onboarding")

@Observable
final class OnboardingViewModel {
    // MARK: - Navigation

    var currentStep: OnboardingStep = .welcome
    var isComplete = false

    var totalSteps: Int {
        OnboardingStep.allCases.count
    }

    var showProgressBar: Bool {
        currentStep != .welcome && currentStep != .allSet && currentStep != .calculating
    }

    var canGoBack: Bool {
        currentStep.rawValue > 0 && currentStep != .calculating && currentStep != .allSet
    }

    // MARK: - User Data

    // Goal
    var selectedGoal: FitnessGoal = .maintain

    // Personal Info
    var selectedGender: Gender = .notSpecified
    var birthYear: Int = 1990
    var heightCm: Double = 170
    var heightFeet: Int = 5
    var heightInches: Int = 7
    var useMetricHeight: Bool = true

    // Weight
    var currentWeightKg: Double = 70
    var currentWeightLbs: Double = 154
    var targetWeightKg: Double = 70
    var targetWeightLbs: Double = 154
    var useMetricWeight: Bool = true

    // Activity
    var activityLevel: ActivityLevel = .moderate
    var workoutsPerWeek: Int = 3

    // Diet
    var dietPreference: DietPreference = .none

    // Preferences
    var notificationsEnabled: Bool = false
    var mealReminderTimes: [MealReminderTime] = []

    // Calculated
    var calculatedCalories: Int = 2000
    var calculatedProtein: Int = 150
    var calculatedCarbs: Int = 200
    var calculatedFat: Int = 67

    // MARK: - Computed Properties

    var age: Int {
        Calendar.current.component(.year, from: Date()) - birthYear
    }

    var heightForCalculation: Double {
        if useMetricHeight {
            return heightCm
        } else {
            return Double(heightFeet * 12 + heightInches) * 2.54
        }
    }

    var currentWeightForCalculation: Double {
        useMetricWeight ? currentWeightKg : currentWeightLbs / 2.20462
    }

    var targetWeightForCalculation: Double {
        useMetricWeight ? targetWeightKg : targetWeightLbs / 2.20462
    }

    var weightDifference: Double {
        currentWeightForCalculation - targetWeightForCalculation
    }

    var estimatedWeeks: Int {
        let weeklyChange = selectedGoal == .lose ? 0.5 : 0.25 // kg per week
        return max(1, Int(ceil(abs(weightDifference) / weeklyChange)))
    }

    // MARK: - Navigation Methods

    func nextStep() {
        guard let nextIndex = OnboardingStep(rawValue: currentStep.rawValue + 1) else {
            return
        }

        FuelHaptics.shared.tap()

        withAnimation(FuelAnimations.spring) {
            currentStep = nextIndex
        }

        // Trigger calculation when reaching that step
        if nextIndex == .calculating {
            calculatePlan()
        }
    }

    func previousStep() {
        guard canGoBack,
              let prevIndex = OnboardingStep(rawValue: currentStep.rawValue - 1) else {
            return
        }

        FuelHaptics.shared.tap()

        withAnimation(FuelAnimations.spring) {
            currentStep = prevIndex
        }
    }

    func goToStep(_ step: OnboardingStep) {
        FuelHaptics.shared.tap()

        withAnimation(FuelAnimations.spring) {
            currentStep = step
        }
    }

    func completeOnboarding() {
        FuelHaptics.shared.celebration()
        isComplete = true
    }

    // MARK: - Calculation

    func calculatePlan() {
        Task { @MainActor in
            // Brief delay for animation timing (allows calculating screen to show)
            try? await Task.sleep(nanoseconds: 800_000_000) // 0.8 seconds

            // Calculate TDEE using Mifflin-St Jeor
            let weightKg = currentWeightForCalculation
            let heightCm = heightForCalculation
            let ageYears = Double(age)

            var bmr: Double
            switch selectedGender {
            case .male:
                bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * ageYears) + 5
            case .female:
                bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * ageYears) - 161
            case .notSpecified:
                bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * ageYears) - 78
            }

            // Apply activity multiplier
            let tdee = bmr * activityLevel.multiplier

            // Adjust for goal
            switch selectedGoal {
            case .lose:
                calculatedCalories = Int(tdee - 500)
            case .maintain:
                calculatedCalories = Int(tdee)
            case .gain:
                calculatedCalories = Int(tdee + 300)
            }

            // Calculate macros
            let proteinPerKg: Double = selectedGoal == .gain ? 2.2 : 2.0
            calculatedProtein = Int(weightKg * proteinPerKg)

            let proteinCalories = Double(calculatedProtein) * 4
            let fatCalories = Double(calculatedCalories) * 0.28
            calculatedFat = Int(fatCalories / 9)

            let carbCalories = Double(calculatedCalories) - proteinCalories - fatCalories
            calculatedCarbs = Int(carbCalories / 4)

            FuelHaptics.shared.success()

            // Move to plan screen
            withAnimation(FuelAnimations.spring) {
                currentStep = .yourPlan
            }
        }
    }

    // MARK: - Data Persistence

    /// Save onboarding data to SwiftData User model
    func saveOnboardingData(to context: ModelContext) {
        // Check if user already exists
        let descriptor = FetchDescriptor<User>()
        let existingUsers = (try? context.fetch(descriptor)) ?? []

        let user: User
        if let existingUser = existingUsers.first {
            // Update existing user
            user = existingUser
            logger.info("Updating existing user with onboarding data")
        } else {
            // Create new user
            user = User()
            context.insert(user)
            logger.info("Creating new user with onboarding data")
        }

        // Set personal info
        user.gender = selectedGender
        user.heightCm = heightForCalculation
        user.currentWeightKg = currentWeightForCalculation
        user.targetWeightKg = targetWeightForCalculation
        user.activityLevel = activityLevel
        user.fitnessGoal = selectedGoal

        // Set birth date from birth year
        var components = DateComponents()
        components.year = birthYear
        components.month = 1
        components.day = 1
        if let birthDate = Calendar.current.date(from: components) {
            user.birthDate = birthDate
        }

        // Set calculated goals
        user.dailyCalorieTarget = calculatedCalories
        user.dailyProteinTarget = calculatedProtein
        user.dailyCarbsTarget = calculatedCarbs
        user.dailyFatTarget = calculatedFat

        // Set preferences
        user.preferredUnits = useMetricWeight ? .metric : .imperial
        user.notificationsEnabled = notificationsEnabled

        // Set meal reminder times
        user.mealReminderTimes = mealReminderTimes.filter { $0.isEnabled }.map { $0.time }

        // Update timestamps
        user.lastActiveAt = Date()

        // Save context
        do {
            try context.save()
            logger.info("Successfully saved onboarding data to SwiftData")
        } catch {
            logger.error("Failed to save onboarding data: \(error.localizedDescription)")
        }

        // Also save minimal data to UserDefaults as backup/quick access
        UserDefaults.standard.set(calculatedCalories, forKey: "user.dailyCalorieTarget")
        UserDefaults.standard.set(calculatedProtein, forKey: "user.dailyProteinTarget")
        UserDefaults.standard.set(calculatedCarbs, forKey: "user.dailyCarbsTarget")
        UserDefaults.standard.set(calculatedFat, forKey: "user.dailyFatTarget")
    }

    /// Legacy method - deprecated, use saveOnboardingData(to:) instead
    @available(*, deprecated, message: "Use saveOnboardingData(to:) with ModelContext instead")
    func saveOnboardingData() {
        logger.warning("saveOnboardingData() called without ModelContext - data will not persist to SwiftData")
        // Only save to UserDefaults as fallback
        UserDefaults.standard.set(calculatedCalories, forKey: "user.dailyCalorieTarget")
    }
}

// MARK: - Diet Preference

enum DietPreference: String, CaseIterable {
    case none = "none"
    case vegetarian = "vegetarian"
    case vegan = "vegan"
    case pescatarian = "pescatarian"
    case keto = "keto"
    case paleo = "paleo"
    case glutenFree = "gluten_free"
    case dairyFree = "dairy_free"

    var displayName: String {
        switch self {
        case .none: return "No Preference"
        case .vegetarian: return "Vegetarian"
        case .vegan: return "Vegan"
        case .pescatarian: return "Pescatarian"
        case .keto: return "Keto"
        case .paleo: return "Paleo"
        case .glutenFree: return "Gluten Free"
        case .dairyFree: return "Dairy Free"
        }
    }

    var icon: String {
        switch self {
        case .none: return "fork.knife"
        case .vegetarian: return "leaf"
        case .vegan: return "leaf.fill"
        case .pescatarian: return "fish"
        case .keto: return "flame"
        case .paleo: return "hare"
        case .glutenFree: return "xmark.circle"
        case .dairyFree: return "drop.triangle"
        }
    }
}

// MARK: - Meal Reminder Time

struct MealReminderTime: Identifiable, Hashable {
    let id = UUID()
    let mealType: MealType
    var time: Date
    var isEnabled: Bool

    static let defaults: [MealReminderTime] = [
        MealReminderTime(mealType: .breakfast, time: Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? Date(), isEnabled: true),
        MealReminderTime(mealType: .lunch, time: Calendar.current.date(from: DateComponents(hour: 12, minute: 30)) ?? Date(), isEnabled: true),
        MealReminderTime(mealType: .dinner, time: Calendar.current.date(from: DateComponents(hour: 18, minute: 30)) ?? Date(), isEnabled: true)
    ]
}
