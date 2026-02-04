import SwiftUI

/// Fuel Design System - Skeleton Loaders
/// Placeholder content while data is loading

// MARK: - Skeleton Shape

public struct SkeletonShape: View {
    let cornerRadius: CGFloat

    @State private var isAnimating = false

    public init(cornerRadius: CGFloat = FuelSpacing.radiusSm) {
        self.cornerRadius = cornerRadius
    }

    public var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        FuelColors.surfaceSecondary,
                        FuelColors.surfaceSecondary.opacity(0.5),
                        FuelColors.surfaceSecondary
                    ],
                    startPoint: isAnimating ? .leading : .trailing,
                    endPoint: isAnimating ? .trailing : .leading
                )
            )
            .onAppear {
                withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                    isAnimating = true
                }
            }
    }
}

// MARK: - Skeleton Text

public struct SkeletonText: View {
    let lines: Int
    let lineHeight: CGFloat
    let spacing: CGFloat

    public init(lines: Int = 1, lineHeight: CGFloat = 16, spacing: CGFloat = FuelSpacing.xs) {
        self.lines = lines
        self.lineHeight = lineHeight
        self.spacing = spacing
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            ForEach(0..<lines, id: \.self) { index in
                SkeletonShape()
                    .frame(height: lineHeight)
                    .frame(maxWidth: index == lines - 1 && lines > 1 ? .infinity : nil)
                    .scaleEffect(x: index == lines - 1 && lines > 1 ? 0.7 : 1, anchor: .leading)
            }
        }
    }
}

// MARK: - Skeleton Card

public struct SkeletonCard: View {
    public init() {}

    public var body: some View {
        FuelCard {
            VStack(alignment: .leading, spacing: FuelSpacing.md) {
                HStack(spacing: FuelSpacing.sm) {
                    // Icon placeholder
                    SkeletonShape()
                        .frame(width: 48, height: 48)

                    // Text placeholders
                    VStack(alignment: .leading, spacing: FuelSpacing.xs) {
                        SkeletonShape()
                            .frame(width: 120, height: 18)

                        SkeletonShape()
                            .frame(width: 80, height: 14)
                    }

                    Spacer()

                    // Button placeholder
                    SkeletonShape()
                        .frame(width: 24, height: 24)
                        .clipShape(Circle())
                }
            }
        }
    }
}

// MARK: - Skeleton Meal Card

public struct SkeletonMealCard: View {
    public init() {}

    public var body: some View {
        FuelCard {
            VStack(alignment: .leading, spacing: FuelSpacing.sm) {
                // Header
                HStack {
                    SkeletonShape()
                        .frame(width: 24, height: 24)
                        .clipShape(Circle())

                    SkeletonShape()
                        .frame(width: 80, height: 18)

                    Spacer()

                    SkeletonShape()
                        .frame(width: 60, height: 16)

                    SkeletonShape()
                        .frame(width: 24, height: 24)
                        .clipShape(Circle())
                }

                // Content
                HStack(spacing: FuelSpacing.sm) {
                    SkeletonShape()
                        .frame(width: 48, height: 48)

                    VStack(alignment: .leading, spacing: FuelSpacing.xxs) {
                        SkeletonShape()
                            .frame(width: 150, height: 16)

                        SkeletonShape()
                            .frame(width: 80, height: 14)
                    }

                    Spacer()
                }
            }
        }
    }
}

// MARK: - Skeleton Dashboard

public struct SkeletonDashboard: View {
    public init() {}

    public var body: some View {
        VStack(spacing: FuelSpacing.lg) {
            // Calorie ring placeholder
            ZStack {
                Circle()
                    .stroke(FuelColors.surfaceSecondary, lineWidth: FuelSpacing.ringLineWidth)
                    .frame(width: 200, height: 200)

                VStack(spacing: FuelSpacing.xs) {
                    SkeletonShape()
                        .frame(width: 80, height: 40)

                    SkeletonShape()
                        .frame(width: 100, height: 16)
                }
            }

            // Macro bars placeholder
            VStack(spacing: FuelSpacing.md) {
                ForEach(0..<3, id: \.self) { _ in
                    VStack(alignment: .leading, spacing: FuelSpacing.xs) {
                        HStack {
                            SkeletonShape()
                                .frame(width: 70, height: 16)
                            Spacer()
                            SkeletonShape()
                                .frame(width: 50, height: 14)
                        }
                        SkeletonShape()
                            .frame(height: FuelSpacing.progressBarHeight)
                    }
                }
            }
            .padding()
            .background(FuelColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusLg))

            // Meal cards placeholder
            ForEach(0..<3, id: \.self) { _ in
                SkeletonMealCard()
            }
        }
    }
}

// MARK: - Skeleton List

public struct SkeletonList: View {
    let rows: Int

    public init(rows: Int = 5) {
        self.rows = rows
    }

    public var body: some View {
        VStack(spacing: FuelSpacing.sm) {
            ForEach(0..<rows, id: \.self) { _ in
                HStack(spacing: FuelSpacing.md) {
                    SkeletonShape()
                        .frame(width: 44, height: 44)

                    VStack(alignment: .leading, spacing: FuelSpacing.xxs) {
                        SkeletonShape()
                            .frame(width: 140, height: 16)

                        SkeletonShape()
                            .frame(width: 80, height: 14)
                    }

                    Spacer()

                    SkeletonShape()
                        .frame(width: 50, height: 16)
                }
                .padding(.vertical, FuelSpacing.xs)
            }
        }
    }
}

// MARK: - Loading Modifier

public struct SkeletonModifier: ViewModifier {
    let isLoading: Bool

    public func body(content: Content) -> some View {
        if isLoading {
            content
                .redacted(reason: .placeholder)
                .shimmering()
        } else {
            content
        }
    }
}

// MARK: - Shimmer Effect

public struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    public func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [
                            .clear,
                            Color.white.opacity(0.2),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: -geometry.size.width + (phase * geometry.size.width * 2))
                }
            )
            .mask(content)
            .onAppear {
                withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

extension View {
    /// Apply loading skeleton effect
    public func skeleton(isLoading: Bool) -> some View {
        modifier(SkeletonModifier(isLoading: isLoading))
    }

    /// Apply shimmer animation
    public func shimmering() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Preview

#Preview("Skeleton Loaders") {
    ScrollView {
        VStack(spacing: 24) {
            // Text skeleton
            VStack(alignment: .leading) {
                Text("Skeleton Text")
                    .font(FuelTypography.headline)
                SkeletonText(lines: 3)
            }
            .padding()

            Divider()

            // Cards
            VStack(alignment: .leading) {
                Text("Skeleton Cards")
                    .font(FuelTypography.headline)
                SkeletonCard()
                SkeletonMealCard()
            }
            .padding()

            Divider()

            // List
            VStack(alignment: .leading) {
                Text("Skeleton List")
                    .font(FuelTypography.headline)
                SkeletonList(rows: 3)
            }
            .padding()
        }
    }
}
