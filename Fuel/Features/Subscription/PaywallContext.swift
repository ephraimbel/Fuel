import Foundation

/// Paywall Context
/// Defines the different triggers and contexts for showing the paywall

public enum PaywallContext: String, CaseIterable {
    /// User hit the AI scan limit (3/week for free)
    case scanLimit

    /// User tried to access history older than 7 days
    case historyLimit

    /// User tried to save more than 3 recipes
    case recipeLimit

    /// User tried to access month+ analytics
    case analyticsLimit

    /// User's trial period just ended
    case trialEnded

    /// Shown during onboarding
    case onboarding

    /// Generic upgrade prompt
    case general

    // MARK: - Display Properties

    /// Headline shown on paywall
    public var headline: String {
        switch self {
        case .scanLimit:
            return "Unlock Unlimited AI Scans"
        case .historyLimit:
            return "See Your Complete Journey"
        case .recipeLimit:
            return "Save Unlimited Recipes"
        case .analyticsLimit:
            return "Advanced Analytics"
        case .trialEnded:
            return "Your Trial Has Ended"
        case .onboarding:
            return "Start Your Journey"
        case .general:
            return "Upgrade to Fuel+"
        }
    }

    /// Subheadline shown on paywall
    public var subheadline: String {
        switch self {
        case .scanLimit:
            return "You've used all 3 free scans this week"
        case .historyLimit:
            return "Free plan includes 7 days of history"
        case .recipeLimit:
            return "You've reached the 3 recipe limit"
        case .analyticsLimit:
            return "Track your progress over months & years"
        case .trialEnded:
            return "Keep unlimited scans & all Fuel+ features"
        case .onboarding:
            return "3-day free trial, cancel anytime"
        case .general:
            return "Unlock all premium features"
        }
    }

    /// Primary CTA button text
    public var primaryCTA: String {
        switch self {
        case .scanLimit:
            return "Try Fuel+ Free"
        case .historyLimit:
            return "Upgrade to Fuel+"
        case .recipeLimit:
            return "Get Fuel+"
        case .analyticsLimit:
            return "Unlock with Fuel+"
        case .trialEnded:
            return "Continue with Fuel+"
        case .onboarding:
            return "Try Fuel+ Free"
        case .general:
            return "Start Free Trial"
        }
    }

    /// Icon name for the context
    public var iconName: String {
        switch self {
        case .scanLimit:
            return "camera.viewfinder"
        case .historyLimit:
            return "calendar"
        case .recipeLimit:
            return "book.closed"
        case .analyticsLimit:
            return "chart.xyaxis.line"
        case .trialEnded:
            return "clock.badge.exclamationmark"
        case .onboarding, .general:
            return "flame.fill"
        }
    }

    /// Whether to show trial option
    public var showTrialOption: Bool {
        switch self {
        case .trialEnded:
            return false
        default:
            return !FeatureGateService.shared.hasUsedTrial
        }
    }

    /// Analytics event name for tracking
    public var analyticsEventName: String {
        "paywall_viewed_\(rawValue)"
    }
}

// MARK: - Paywall Feature

/// Features to display on the paywall
public struct PaywallFeature: Identifiable {
    public let id = UUID()
    public let icon: String
    public let title: String

    public static let allFeatures: [PaywallFeature] = [
        PaywallFeature(icon: "camera.viewfinder", title: "Unlimited AI food scans"),
        PaywallFeature(icon: "calendar", title: "Full history access"),
        PaywallFeature(icon: "book.closed", title: "Unlimited saved recipes"),
        PaywallFeature(icon: "chart.xyaxis.line", title: "Advanced analytics & charts"),
        PaywallFeature(icon: "nosign", title: "Ad-free experience")
    ]
}
