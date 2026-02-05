import SwiftUI

/// Custom Refresh Control
/// Premium pull-to-refresh with animated ring indicator

struct RefreshableScrollView<Content: View>: View {
    let onRefresh: () async -> Void
    @ViewBuilder let content: () -> Content

    @State private var pullProgress: CGFloat = 0
    @State private var isRefreshing = false

    private let threshold: CGFloat = 80

    var body: some View {
        ScrollView {
            GeometryReader { geometry in
                let offset = geometry.frame(in: .global).minY
                Color.clear
                    .preference(key: ScrollOffsetKey.self, value: offset)
            }
            .frame(height: 0)

            // Refresh indicator
            ZStack {
                if isRefreshing {
                    RefreshSpinner()
                        .transition(.scale.combined(with: .opacity))
                } else if pullProgress > 0 {
                    RefreshPullIndicator(progress: pullProgress)
                        .transition(.opacity)
                }
            }
            .frame(height: isRefreshing ? 60 : max(pullProgress * threshold, 0))
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isRefreshing)

            content()
        }
        .onPreferenceChange(ScrollOffsetKey.self) { offset in
            guard !isRefreshing else { return }

            if offset > 0 {
                pullProgress = min(offset / threshold, 1.5)

                // Haptic at threshold
                if pullProgress >= 1.0 && pullProgress < 1.05 {
                    FuelHaptics.shared.impact()
                }
            } else {
                pullProgress = 0
            }
        }
        .onChange(of: pullProgress) { oldValue, newValue in
            // Trigger refresh when released past threshold
            if oldValue >= 1.0 && newValue < 1.0 && !isRefreshing {
                triggerRefresh()
            }
        }
    }

    private func triggerRefresh() {
        guard !isRefreshing else { return }
        isRefreshing = true
        FuelHaptics.shared.impact()

        Task {
            await onRefresh()

            // Minimum display time for refresh animation
            try? await Task.sleep(nanoseconds: 500_000_000)

            await MainActor.run {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                    isRefreshing = false
                }
                FuelHaptics.shared.success()
            }
        }
    }
}

// MARK: - Scroll Offset Key

private struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Pull Indicator

private struct RefreshPullIndicator: View {
    let progress: CGFloat

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(FuelColors.primary.opacity(0.2), lineWidth: 3)

            // Progress ring
            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(
                    FuelColors.primary,
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            // Arrow or checkmark
            Image(systemName: progress >= 1.0 ? "checkmark" : "arrow.down")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(FuelColors.primary)
                .scaleEffect(progress >= 1.0 ? 1.2 : 1.0)
                .animation(.spring(response: 0.25, dampingFraction: 0.6), value: progress >= 1.0)
        }
        .frame(width: 32, height: 32)
        .scaleEffect(0.8 + (min(progress, 1.0) * 0.2))
        .opacity(min(progress * 2, 1.0))
    }
}

// MARK: - Refresh Spinner

private struct RefreshSpinner: View {
    @State private var isSpinning = false
    @State private var ringProgress: CGFloat = 0.3

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(FuelColors.primary.opacity(0.2), lineWidth: 3)

            // Spinning segment
            Circle()
                .trim(from: 0, to: ringProgress)
                .stroke(
                    FuelColors.primary,
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .rotationEffect(.degrees(isSpinning ? 360 : 0))

            // Center icon
            Image(systemName: "flame.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(FuelColors.primary)
                .scaleEffect(isSpinning ? 1.1 : 0.9)
        }
        .frame(width: 32, height: 32)
        .onAppear {
            // Continuous spin
            withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                isSpinning = true
            }
            // Pulsing ring
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                ringProgress = 0.7
            }
        }
    }
}

// MARK: - View Modifier for Easy Usage

struct CustomRefreshable: ViewModifier {
    let action: () async -> Void

    func body(content: Content) -> some View {
        RefreshableScrollView(onRefresh: action) {
            content
        }
    }
}

extension View {
    /// Apply custom refresh control with premium animations
    func customRefreshable(action: @escaping () async -> Void) -> some View {
        modifier(CustomRefreshable(action: action))
    }
}

// MARK: - Preview

#Preview {
    RefreshableScrollView {
        try? await Task.sleep(nanoseconds: 2_000_000_000)
    } content: {
        VStack(spacing: 16) {
            ForEach(0..<10, id: \.self) { i in
                RoundedRectangle(cornerRadius: 12)
                    .fill(FuelColors.surface)
                    .frame(height: 80)
                    .overlay(Text("Item \(i + 1)"))
            }
        }
        .padding()
    }
    .background(FuelColors.background)
}
