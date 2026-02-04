import SwiftUI

/// Fuel Design System - Sheet Presentations
/// Premium bottom sheets and modal presentations

// MARK: - Bottom Sheet

public struct FuelBottomSheet<Content: View>: View {
    @Binding var isPresented: Bool
    let title: String?
    let showHandle: Bool
    let detents: Set<PresentationDetent>
    let content: Content

    @State private var currentDetent: PresentationDetent = .medium

    public init(
        isPresented: Binding<Bool>,
        title: String? = nil,
        showHandle: Bool = true,
        detents: Set<PresentationDetent> = [.medium, .large],
        @ViewBuilder content: () -> Content
    ) {
        self._isPresented = isPresented
        self.title = title
        self.showHandle = showHandle
        self.detents = detents
        self.content = content()
    }

    public var body: some View {
        Color.clear
            .sheet(isPresented: $isPresented) {
                sheetContent
                    .presentationDetents(detents, selection: $currentDetent)
                    .presentationDragIndicator(showHandle ? .visible : .hidden)
                    .presentationCornerRadius(FuelSpacing.radiusXxl)
                    .presentationBackground(FuelColors.surface)
            }
    }

    private var sheetContent: some View {
        VStack(spacing: 0) {
            // Header
            if let title {
                HStack {
                    Text(title)
                        .font(FuelTypography.headline)
                        .foregroundStyle(FuelColors.textPrimary)

                    Spacer()

                    Button {
                        FuelHaptics.shared.tap()
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(FuelColors.textSecondary)
                            .frame(width: 28, height: 28)
                            .background(FuelColors.surfaceSecondary)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, FuelSpacing.screenHorizontal)
                .padding(.top, FuelSpacing.md)
                .padding(.bottom, FuelSpacing.sm)
            }

            // Content
            content
        }
    }
}

// MARK: - Action Sheet

public struct FuelActionSheet: View {
    @Binding var isPresented: Bool
    let title: String?
    let message: String?
    let actions: [ActionItem]

    public struct ActionItem: Identifiable {
        public let id = UUID()
        let title: String
        let icon: String?
        let style: Style
        let action: () -> Void

        public enum Style {
            case `default`
            case destructive
            case cancel
        }

        public init(
            title: String,
            icon: String? = nil,
            style: Style = .default,
            action: @escaping () -> Void
        ) {
            self.title = title
            self.icon = icon
            self.style = style
            self.action = action
        }
    }

    public init(
        isPresented: Binding<Bool>,
        title: String? = nil,
        message: String? = nil,
        actions: [ActionItem]
    ) {
        self._isPresented = isPresented
        self.title = title
        self.message = message
        self.actions = actions
    }

    public var body: some View {
        Color.clear
            .sheet(isPresented: $isPresented) {
                VStack(spacing: FuelSpacing.md) {
                    // Handle
                    Capsule()
                        .fill(FuelColors.border)
                        .frame(width: 36, height: 4)
                        .padding(.top, FuelSpacing.sm)

                    // Header
                    if title != nil || message != nil {
                        VStack(spacing: FuelSpacing.xs) {
                            if let title {
                                Text(title)
                                    .font(FuelTypography.headline)
                                    .foregroundStyle(FuelColors.textPrimary)
                            }

                            if let message {
                                Text(message)
                                    .font(FuelTypography.subheadline)
                                    .foregroundStyle(FuelColors.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.horizontal, FuelSpacing.xl)
                    }

                    // Actions
                    VStack(spacing: FuelSpacing.xs) {
                        ForEach(actions.filter { $0.style != .cancel }) { action in
                            actionButton(action)
                        }
                    }
                    .padding(.horizontal, FuelSpacing.screenHorizontal)

                    // Cancel button
                    if let cancelAction = actions.first(where: { $0.style == .cancel }) {
                        Divider()
                            .padding(.horizontal, FuelSpacing.screenHorizontal)

                        Button {
                            FuelHaptics.shared.tap()
                            isPresented = false
                            cancelAction.action()
                        } label: {
                            Text(cancelAction.title)
                                .font(FuelTypography.headline)
                                .foregroundStyle(FuelColors.textSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, FuelSpacing.md)
                        }
                    }
                }
                .padding(.bottom, FuelSpacing.safeAreaBottom)
                .presentationDetents([.height(estimatedHeight)])
                .presentationCornerRadius(FuelSpacing.radiusXxl)
                .presentationBackground(FuelColors.surface)
            }
    }

    private var estimatedHeight: CGFloat {
        var height: CGFloat = 100 // Base height for handle and padding
        if title != nil { height += 30 }
        if message != nil { height += 40 }
        height += CGFloat(actions.filter { $0.style != .cancel }.count) * 52
        if actions.contains(where: { $0.style == .cancel }) { height += 60 }
        return height
    }

    private func actionButton(_ action: ActionItem) -> some View {
        Button {
            FuelHaptics.shared.tap()
            isPresented = false
            action.action()
        } label: {
            HStack(spacing: FuelSpacing.sm) {
                if let icon = action.icon {
                    Image(systemName: icon)
                        .font(.system(size: 18))
                }

                Text(action.title)
                    .font(FuelTypography.body)
            }
            .foregroundStyle(action.style == .destructive ? FuelColors.error : FuelColors.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, FuelSpacing.md)
            .background(FuelColors.surfaceSecondary)
            .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd, style: .continuous))
        }
    }
}

// MARK: - Confirmation Dialog

public struct FuelConfirmationDialog: View {
    @Binding var isPresented: Bool
    let title: String
    let message: String
    let confirmTitle: String
    let confirmStyle: ConfirmStyle
    let onConfirm: () -> Void

    public enum ConfirmStyle {
        case destructive
        case normal
    }

    public init(
        isPresented: Binding<Bool>,
        title: String,
        message: String,
        confirmTitle: String = "Confirm",
        confirmStyle: ConfirmStyle = .normal,
        onConfirm: @escaping () -> Void
    ) {
        self._isPresented = isPresented
        self.title = title
        self.message = message
        self.confirmTitle = confirmTitle
        self.confirmStyle = confirmStyle
        self.onConfirm = onConfirm
    }

    public var body: some View {
        Color.clear
            .alert(title, isPresented: $isPresented) {
                Button(confirmTitle, role: confirmStyle == .destructive ? .destructive : nil) {
                    FuelHaptics.shared.tap()
                    onConfirm()
                }
                Button("Cancel", role: .cancel) {
                    FuelHaptics.shared.tap()
                }
            } message: {
                Text(message)
            }
    }
}

// MARK: - Full Screen Cover

public struct FuelFullScreenCover<Content: View>: View {
    @Binding var isPresented: Bool
    let showCloseButton: Bool
    let content: Content

    public init(
        isPresented: Binding<Bool>,
        showCloseButton: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self._isPresented = isPresented
        self.showCloseButton = showCloseButton
        self.content = content()
    }

    public var body: some View {
        Color.clear
            .fullScreenCover(isPresented: $isPresented) {
                ZStack(alignment: .topTrailing) {
                    content

                    if showCloseButton {
                        Button {
                            FuelHaptics.shared.tap()
                            isPresented = false
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(FuelColors.textSecondary)
                                .frame(width: 32, height: 32)
                                .background(FuelColors.surfaceSecondary)
                                .clipShape(Circle())
                        }
                        .padding(.trailing, FuelSpacing.screenHorizontal)
                        .padding(.top, FuelSpacing.md)
                    }
                }
            }
    }
}

// MARK: - Preview

#Preview("Sheets") {
    struct PreviewWrapper: View {
        @State private var showSheet = false
        @State private var showActionSheet = false
        @State private var showConfirmation = false

        var body: some View {
            VStack(spacing: 16) {
                Button("Show Bottom Sheet") { showSheet = true }
                Button("Show Action Sheet") { showActionSheet = true }
                Button("Show Confirmation") { showConfirmation = true }
            }
            .sheet(isPresented: $showSheet) {
                VStack {
                    Text("Sheet Content")
                    Spacer()
                }
                .presentationDetents([.medium])
            }

            FuelActionSheet(
                isPresented: $showActionSheet,
                title: "Options",
                message: "Choose an action",
                actions: [
                    .init(title: "Edit", icon: "pencil") {},
                    .init(title: "Share", icon: "square.and.arrow.up") {},
                    .init(title: "Delete", icon: "trash", style: .destructive) {},
                    .init(title: "Cancel", style: .cancel) {}
                ]
            )

            FuelConfirmationDialog(
                isPresented: $showConfirmation,
                title: "Delete Meal?",
                message: "This action cannot be undone.",
                confirmTitle: "Delete",
                confirmStyle: .destructive
            ) {}
        }
    }

    return PreviewWrapper()
}
