import Foundation

/// Feature Gate Service
/// Centralized gating logic for free vs premium features

@Observable
public final class FeatureGateService {
    // MARK: - Singleton

    public static let shared = FeatureGateService()

    // MARK: - Constants

    /// Free tier limits
    public struct FreeTierLimits {
        public static let aiScansPerWeek = 3
        public static let historyDays = 7
        public static let maxRecipes = 3
    }

    // MARK: - UserDefaults Keys

    private enum Keys {
        static let weeklyScansUsed = "fuel.weeklyScansUsed"
        static let weeklyScansResetDate = "fuel.weeklyScansResetDate"
        static let hasUsedTrial = "fuel.hasUsedTrial"
        static let trialStartDate = "fuel.trialStartDate"
    }

    // MARK: - State

    public private(set) var weeklyScansUsed: Int = 0
    public private(set) var weeklyScansResetDate: Date?

    // MARK: - Computed Properties

    /// Returns true if user has premium access (subscription or active trial)
    public var isPremium: Bool {
        SubscriptionService.shared.isPremium || isInTrial
    }

    /// Returns true if user is currently in trial period
    public var isInTrial: Bool {
        guard let trialStart = trialStartDate else { return false }
        let trialEnd = Calendar.current.date(byAdding: .day, value: 3, to: trialStart) ?? trialStart
        return Date() < trialEnd
    }

    /// Returns the trial end date if in trial
    public var trialEndsAt: Date? {
        guard let trialStart = trialStartDate else { return nil }
        return Calendar.current.date(byAdding: .day, value: 3, to: trialStart)
    }

    /// Returns remaining trial days
    public var trialDaysRemaining: Int {
        guard let endDate = trialEndsAt else { return 0 }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: endDate).day ?? 0
        return max(0, days)
    }

    /// Returns true if trial just ended (within last session)
    public var trialJustEnded: Bool {
        guard let trialStart = trialStartDate, !isInTrial else { return false }
        // Trial ended and user hasn't subscribed
        return !SubscriptionService.shared.isPremium
    }

    /// Returns true if user has already used their trial
    public var hasUsedTrial: Bool {
        UserDefaults.standard.bool(forKey: Keys.hasUsedTrial)
    }

    /// Trial start date from UserDefaults
    private var trialStartDate: Date? {
        UserDefaults.standard.object(forKey: Keys.trialStartDate) as? Date
    }

    /// Remaining AI scans this week for free users
    public var remainingAIScans: Int {
        if isPremium { return .max }
        resetWeeklyScansIfNeeded()
        return max(0, FreeTierLimits.aiScansPerWeek - weeklyScansUsed)
    }

    // MARK: - Initialization

    private init() {
        loadScanData()
    }

    // MARK: - AI Scan Methods

    /// Check if user can perform an AI scan
    public func canUseAIScan() -> Bool {
        if isPremium { return true }
        resetWeeklyScansIfNeeded()
        return weeklyScansUsed < FreeTierLimits.aiScansPerWeek
    }

    /// Use an AI scan (call after successful scan)
    public func useAIScan() {
        guard !isPremium else { return }
        resetWeeklyScansIfNeeded()
        weeklyScansUsed += 1
        saveScanData()
    }

    // MARK: - History Access

    /// Check if user can access a specific date's history
    public func canAccessDate(_ date: Date) -> Bool {
        if isPremium { return true }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let targetDate = calendar.startOfDay(for: date)

        guard let daysDiff = calendar.dateComponents([.day], from: targetDate, to: today).day else {
            return false
        }

        return daysDiff < FreeTierLimits.historyDays
    }

    // MARK: - Recipe Limits

    /// Check if user can save a new recipe
    public func canSaveRecipe(currentCount: Int) -> Bool {
        if isPremium { return true }
        return currentCount < FreeTierLimits.maxRecipes
    }

    // MARK: - Analytics Access

    /// Check if user can access full analytics (month+)
    public func canAccessFullAnalytics() -> Bool {
        return isPremium
    }

    // MARK: - Ads

    /// Check if ads should be shown
    public func shouldShowAds() -> Bool {
        return !isPremium
    }

    // MARK: - Trial Management

    /// Start a 3-day free trial
    public func startTrial() {
        guard !hasUsedTrial else { return }

        UserDefaults.standard.set(Date(), forKey: Keys.trialStartDate)
        UserDefaults.standard.set(true, forKey: Keys.hasUsedTrial)
        FuelHaptics.shared.celebration()
    }

    // MARK: - Private Methods

    private func loadScanData() {
        weeklyScansUsed = UserDefaults.standard.integer(forKey: Keys.weeklyScansUsed)
        weeklyScansResetDate = UserDefaults.standard.object(forKey: Keys.weeklyScansResetDate) as? Date
        resetWeeklyScansIfNeeded()
    }

    private func saveScanData() {
        UserDefaults.standard.set(weeklyScansUsed, forKey: Keys.weeklyScansUsed)
        UserDefaults.standard.set(weeklyScansResetDate, forKey: Keys.weeklyScansResetDate)
    }

    private func resetWeeklyScansIfNeeded() {
        let calendar = Calendar.current
        let now = Date()

        // If no reset date set, initialize it
        guard let resetDate = weeklyScansResetDate else {
            weeklyScansResetDate = now
            weeklyScansUsed = 0
            saveScanData()
            return
        }

        // Check if a week has passed since last reset
        if let daysDiff = calendar.dateComponents([.day], from: resetDate, to: now).day,
           daysDiff >= 7 {
            weeklyScansResetDate = now
            weeklyScansUsed = 0
            saveScanData()
        }
    }

    // MARK: - Debug / Testing

    #if DEBUG
    /// Reset scan counter for testing
    public func debugResetScans() {
        weeklyScansUsed = 0
        weeklyScansResetDate = Date()
        saveScanData()
    }

    /// Use all scans for testing
    public func debugUseAllScans() {
        weeklyScansUsed = FreeTierLimits.aiScansPerWeek
        saveScanData()
    }

    /// Reset trial for testing
    public func debugResetTrial() {
        UserDefaults.standard.removeObject(forKey: Keys.trialStartDate)
        UserDefaults.standard.removeObject(forKey: Keys.hasUsedTrial)
    }
    #endif
}
