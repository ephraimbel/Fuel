import SwiftUI

/// Fuel Design System - Toast Notifications
/// Lightweight feedback messages with auto-dismiss

// MARK: - Toast Type

public enum ToastType {
    case success
    case error
    case warning
    case info

    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .success: return FuelColors.success
        case .error: return FuelColors.error
        case .warning: return FuelColors.warning
        case .info: return FuelColors.primary
        }
    }

    var haptic: () -> Void {
        switch self {
        case .success: return { FuelHaptics.shared.success() }
        case .error: return { FuelHaptics.shared.error() }
        case .warning: return { FuelHaptics.shared.warning() }
        case .info: return { FuelHaptics.shared.tap() }
        }
    }
}

// MARK: - Toast View

public struct FuelToast: View {
    let message: String
    let type: ToastType
    let action: (() -> Void)?
    let actionLabel: String?

    @State private var isVisible = false

    public init(
        message: String,
        type: ToastType = .info,
        action: (() -> Void)? = nil,
        actionLabel: String? = nil
    ) {
        self.message = message
        self.type = type
        self.action = action
        self.actionLabel = actionLabel
    }

    public var body: some View {
        HStack(spacing: FuelSpacing.sm) {
            // Icon
            Image(systemName: type.icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(type.color)

            // Message
            Text(message)
                .font(FuelTypography.subheadline)
                .foregroundStyle(FuelColors.textPrimary)
                .lineLimit(2)

            Spacer()

            // Action button
            if let action, let actionLabel {
                Button {
                    FuelHaptics.shared.tap()
                    action()
                } label: {
                    Text(actionLabel)
                        .font(FuelTypography.subheadlineMedium)
                        .foregroundStyle(type.color)
                }
            }
        }
        .padding(.horizontal, FuelSpacing.md)
        .padding(.vertical, FuelSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: FuelSpacing.radiusMd, style: .continuous)
                .fill(FuelColors.surface)
                .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: FuelSpacing.radiusMd, style: .continuous)
                .stroke(type.color.opacity(0.2), lineWidth: 1)
        )
        .scaleEffect(isVisible ? 1 : 0.9)
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            type.haptic()
            withAnimation(FuelAnimations.springBouncy) {
                isVisible = true
            }
        }
    }
}

// MARK: - Toast Manager

@Observable
public final class ToastManager {
    public static let shared = ToastManager()

    public private(set) var currentToast: ToastItem?
    private var dismissTask: Task<Void, Never>?

    public struct ToastItem: Identifiable {
        public let id = UUID()
        let message: String
        let type: ToastType
        let duration: TimeInterval
        let action: (() -> Void)?
        let actionLabel: String?
    }

    private init() {}

    public func show(
        _ message: String,
        type: ToastType = .info,
        duration: TimeInterval = 3.0,
        action: (() -> Void)? = nil,
        actionLabel: String? = nil
    ) {
        dismissTask?.cancel()

        currentToast = ToastItem(
            message: message,
            type: type,
            duration: duration,
            action: action,
            actionLabel: actionLabel
        )

        dismissTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            if !Task.isCancelled {
                dismiss()
            }
        }
    }

    public func dismiss() {
        withAnimation(FuelAnimations.springQuick) {
            currentToast = nil
        }
    }

    // Convenience methods
    public func success(_ message: String) {
        show(message, type: .success)
    }

    public func error(_ message: String) {
        show(message, type: .error, duration: 4.0)
    }

    public func warning(_ message: String) {
        show(message, type: .warning)
    }

    public func info(_ message: String) {
        show(message, type: .info)
    }

    public func mealLogged(calories: Int) {
        show("Logged \(calories) calories", type: .success)
    }

    public func achievementUnlocked(_ name: String) {
        show("Achievement unlocked: \(name)", type: .success, duration: 4.0)
        FuelHaptics.shared.celebration()
    }
}

// MARK: - Toast Container View

/// Place this at the root of your app to display toasts
public struct ToastContainer<Content: View>: View {
    @Bindable private var toastManager = ToastManager.shared
    let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        ZStack(alignment: .top) {
            content

            // Toast overlay
            if let toast = toastManager.currentToast {
                FuelToast(
                    message: toast.message,
                    type: toast.type,
                    action: toast.action,
                    actionLabel: toast.actionLabel
                )
                .padding(.horizontal, FuelSpacing.screenHorizontal)
                .padding(.top, FuelSpacing.xl)
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(1000)
                .onTapGesture {
                    toastManager.dismiss()
                }
            }
        }
        .animation(FuelAnimations.spring, value: toastManager.currentToast?.id)
    }
}

// MARK: - View Extension

extension View {
    /// Adds toast support to a view hierarchy
    public func withToasts() -> some View {
        ToastContainer { self }
    }
}

// MARK: - Preview

#Preview("Toasts") {
    VStack(spacing: 20) {
        FuelToast(message: "Meal logged successfully!", type: .success)
        FuelToast(message: "Unable to connect to server", type: .error)
        FuelToast(message: "Approaching daily limit", type: .warning)
        FuelToast(message: "Syncing your data...", type: .info)

        FuelToast(
            message: "Connection lost",
            type: .error,
            action: { print("Retry") },
            actionLabel: "Retry"
        )
    }
    .padding()
}
