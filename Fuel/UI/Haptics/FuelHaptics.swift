import UIKit
import SwiftUI

/// Fuel Design System - Haptic Feedback
/// Premium tactile feedback for all interactions
///
/// Usage Guide:
/// - `.tap()` - Button presses, toggles
/// - `.select()` - Picker changes, selection
/// - `.success()` - Meal logged, goal achieved
/// - `.error()` - Failed actions, validation errors
/// - `.warning()` - Approaching limit, caution
/// - `.heavy()` - Photo capture, destructive actions
/// - `.tick()` - Slider movement, progress updates
/// - `.celebration()` - Milestones, achievements, streaks
public final class FuelHaptics {

    // MARK: - Singleton

    public static let shared = FuelHaptics()

    // MARK: - Generators

    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private let rigidImpact = UIImpactFeedbackGenerator(style: .rigid)
    private let softImpact = UIImpactFeedbackGenerator(style: .soft)
    private let selection = UISelectionFeedbackGenerator()
    private let notification = UINotificationFeedbackGenerator()

    // MARK: - State

    private var isEnabled: Bool = true

    // MARK: - Initialization

    private init() {
        prepareGenerators()
    }

    /// Pre-warm haptic engines for lower latency
    private func prepareGenerators() {
        lightImpact.prepare()
        mediumImpact.prepare()
        heavyImpact.prepare()
        selection.prepare()
        notification.prepare()
    }

    // MARK: - Configuration

    /// Enable or disable haptics globally
    public func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
    }

    // MARK: - Basic Interactions

    /// Light tap - Buttons, toggles, minor actions
    /// Use for: Standard button presses, toggle switches, tab selection
    public func tap() {
        guard isEnabled else { return }
        lightImpact.impactOccurred()
    }

    /// Medium impact - Significant UI actions
    /// Use for: Opening sheets, confirming selections, FAB press
    public func impact() {
        guard isEnabled else { return }
        mediumImpact.impactOccurred()
    }

    /// Heavy impact - Major actions, captures
    /// Use for: Photo capture, delete confirmation, major state changes
    public func heavy() {
        guard isEnabled else { return }
        heavyImpact.impactOccurred()
    }

    /// Selection changed - Pickers, steppers
    /// Use for: Picker wheels, stepper +/-, carousel swipes
    public func select() {
        guard isEnabled else { return }
        selection.selectionChanged()
    }

    // MARK: - Feedback States

    /// Success notification - Positive outcomes
    /// Use for: Meal logged, weight recorded, goal achieved, streak maintained
    public func success() {
        guard isEnabled else { return }
        notification.notificationOccurred(.success)
    }

    /// Error notification - Negative outcomes
    /// Use for: Failed actions, validation errors, scan failures
    public func error() {
        guard isEnabled else { return }
        notification.notificationOccurred(.error)
    }

    /// Warning notification - Caution states
    /// Use for: Approaching calorie limit, streak at risk
    public func warning() {
        guard isEnabled else { return }
        notification.notificationOccurred(.warning)
    }

    // MARK: - Specialized Feedback

    /// Soft tick - Continuous feedback
    /// Use for: Slider dragging, progress updates, scroll snapping
    public func tick() {
        guard isEnabled else { return }
        softImpact.impactOccurred(intensity: 0.5)
    }

    /// Strong tick - Progress milestones
    /// Use for: Every 10% progress, number animations
    public func milestone() {
        guard isEnabled else { return }
        softImpact.impactOccurred(intensity: 0.8)
    }

    /// Camera capture - Rigid, decisive
    /// Use for: Photo shutter, scan complete
    public func capture() {
        guard isEnabled else { return }
        rigidImpact.impactOccurred(intensity: 1.0)
    }

    /// Celebration sequence - Achievement unlocked
    /// Use for: New milestone, streak achievement, goal reached
    public func celebration() {
        guard isEnabled else { return }

        // Multi-stage haptic for celebration feel
        notification.notificationOccurred(.success)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.mediumImpact.impactOccurred(intensity: 0.8)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.lightImpact.impactOccurred(intensity: 0.5)
        }
    }

    /// Double tap feedback
    /// Use for: Quick add, favorite toggle
    public func doubleTap() {
        guard isEnabled else { return }
        lightImpact.impactOccurred(intensity: 0.6)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.lightImpact.impactOccurred(intensity: 0.8)
        }
    }

    /// Streak fire feedback - Energetic pattern
    /// Use for: Streak count display, fire animation
    public func streak() {
        guard isEnabled else { return }

        for i in 0..<3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.08) { [weak self] in
                self?.softImpact.impactOccurred(intensity: 0.4 + Double(i) * 0.2)
            }
        }
    }

    // MARK: - Number Animation Feedback

    /// Feedback for counting animations (calories, macros)
    /// Call this periodically during count-up animations
    public func countTick(progress: Double) {
        guard isEnabled else { return }

        // Haptic at 25%, 50%, 75%, 100%
        let milestones = [0.25, 0.5, 0.75, 1.0]
        for milestone in milestones {
            if abs(progress - milestone) < 0.02 {
                softImpact.impactOccurred(intensity: 0.3 + progress * 0.4)
                break
            }
        }
    }
}

// MARK: - SwiftUI View Modifier

/// Haptic feedback modifier for buttons and taps
public struct HapticFeedback: ViewModifier {
    let style: HapticStyle

    public enum HapticStyle {
        case tap
        case impact
        case heavy
        case select
        case success
        case error
    }

    public func body(content: Content) -> some View {
        content.simultaneousGesture(
            TapGesture().onEnded { _ in
                switch style {
                case .tap: FuelHaptics.shared.tap()
                case .impact: FuelHaptics.shared.impact()
                case .heavy: FuelHaptics.shared.heavy()
                case .select: FuelHaptics.shared.select()
                case .success: FuelHaptics.shared.success()
                case .error: FuelHaptics.shared.error()
                }
            }
        )
    }
}

extension View {
    /// Add haptic feedback on tap
    public func hapticFeedback(_ style: HapticFeedback.HapticStyle = .tap) -> some View {
        modifier(HapticFeedback(style: style))
    }
}
