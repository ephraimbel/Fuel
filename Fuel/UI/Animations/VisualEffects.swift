import SwiftUI

/// Visual Effects
/// Premium gradients, glows, and glassmorphism effects

// MARK: - Glow Effect Modifier

struct GlowEffect: ViewModifier {
    let color: Color
    let radius: CGFloat
    let opacity: Double

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(opacity), radius: radius / 2, x: 0, y: 0)
            .shadow(color: color.opacity(opacity * 0.5), radius: radius, x: 0, y: 0)
    }
}

extension View {
    /// Add colored glow effect
    func glow(color: Color, radius: CGFloat = 10, opacity: Double = 0.5) -> some View {
        modifier(GlowEffect(color: color, radius: radius, opacity: opacity))
    }
}

// MARK: - Gradient Progress Ring

struct GradientProgressRing: View {
    let progress: Double
    let lineWidth: CGFloat
    let colors: [Color]
    let backgroundColor: Color

    @State private var animatedProgress: Double = 0

    init(
        progress: Double,
        lineWidth: CGFloat = 8,
        colors: [Color] = [FuelColors.primary, FuelColors.primaryDark],
        backgroundColor: Color = FuelColors.surfaceSecondary
    ) {
        self.progress = min(max(progress, 0), 1)
        self.lineWidth = lineWidth
        self.colors = colors
        self.backgroundColor = backgroundColor
    }

    var body: some View {
        ZStack {
            // Background
            Circle()
                .stroke(backgroundColor, lineWidth: lineWidth)

            // Gradient progress
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    AngularGradient(
                        colors: colors + [colors.first ?? FuelColors.primary],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            // Glow at progress tip
            if animatedProgress > 0.05 {
                Circle()
                    .fill(colors.last ?? FuelColors.primary)
                    .frame(width: lineWidth, height: lineWidth)
                    .offset(y: -(UIScreen.main.bounds.width * 0.1)) // Approximate radius
                    .rotationEffect(.degrees(360 * animatedProgress - 90))
                    .glow(color: colors.last ?? FuelColors.primary, radius: 8, opacity: 0.6)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.easeOut(duration: 0.5)) {
                animatedProgress = newValue
            }
        }
    }
}

// MARK: - Glass Card

struct GlassCard<Content: View>: View {
    let cornerRadius: CGFloat
    @ViewBuilder let content: () -> Content

    init(cornerRadius: CGFloat = FuelSpacing.radiusLg, @ViewBuilder content: @escaping () -> Content) {
        self.cornerRadius = cornerRadius
        self.content = content
    }

    var body: some View {
        content()
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        .white.opacity(0.5),
                                        .white.opacity(0.2),
                                        .white.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
    }
}

// MARK: - Shimmer Effect

struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [
                            .clear,
                            .white.opacity(0.4),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 0.5)
                    .offset(x: -geometry.size.width * 0.25 + phase * geometry.size.width * 1.5)
                    .mask(content)
                }
            )
            .onAppear {
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

extension View {
    /// Add shimmer animation effect
    func shimmer() -> some View {
        modifier(ShimmerEffect())
    }
}

// MARK: - Gradient Border

struct GradientBorder: ViewModifier {
    let colors: [Color]
    let lineWidth: CGFloat
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: colors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: lineWidth
                    )
            )
    }
}

extension View {
    /// Add gradient border
    func gradientBorder(
        colors: [Color],
        lineWidth: CGFloat = 2,
        cornerRadius: CGFloat = FuelSpacing.radiusMd
    ) -> some View {
        modifier(GradientBorder(colors: colors, lineWidth: lineWidth, cornerRadius: cornerRadius))
    }
}

// MARK: - Breathing Glow

struct BreathingGlow: ViewModifier {
    let color: Color
    let minOpacity: Double
    let maxOpacity: Double
    let duration: Double

    @State private var isGlowing = false

    func body(content: Content) -> some View {
        content
            .shadow(
                color: color.opacity(isGlowing ? maxOpacity : minOpacity),
                radius: isGlowing ? 15 : 8,
                x: 0,
                y: 0
            )
            .onAppear {
                withAnimation(
                    .easeInOut(duration: duration)
                    .repeatForever(autoreverses: true)
                ) {
                    isGlowing = true
                }
            }
    }
}

extension View {
    /// Add pulsing glow animation
    func breathingGlow(
        color: Color,
        minOpacity: Double = 0.2,
        maxOpacity: Double = 0.5,
        duration: Double = 1.5
    ) -> some View {
        modifier(BreathingGlow(
            color: color,
            minOpacity: minOpacity,
            maxOpacity: maxOpacity,
            duration: duration
        ))
    }
}

// MARK: - Neon Text

struct NeonText: ViewModifier {
    let color: Color

    func body(content: Content) -> some View {
        content
            .foregroundStyle(color)
            .shadow(color: color.opacity(0.8), radius: 2, x: 0, y: 0)
            .shadow(color: color.opacity(0.5), radius: 8, x: 0, y: 0)
            .shadow(color: color.opacity(0.3), radius: 16, x: 0, y: 0)
    }
}

extension View {
    /// Add neon glow to text
    func neonGlow(color: Color) -> some View {
        modifier(NeonText(color: color))
    }
}

// MARK: - Gradient Text

struct GradientText: ViewModifier {
    let colors: [Color]

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: colors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .mask(content)
            )
    }
}

extension View {
    /// Apply gradient to text
    func gradientForeground(colors: [Color]) -> some View {
        modifier(GradientText(colors: colors))
    }
}

// MARK: - Soft Shadow Card

struct SoftShadowCard: ViewModifier {
    let color: Color
    let radius: CGFloat

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.08), radius: radius * 0.3, x: 0, y: radius * 0.1)
            .shadow(color: color.opacity(0.05), radius: radius * 0.6, x: 0, y: radius * 0.2)
            .shadow(color: color.opacity(0.03), radius: radius, x: 0, y: radius * 0.3)
    }
}

extension View {
    /// Add soft layered shadow
    func softShadow(color: Color = .black, radius: CGFloat = 20) -> some View {
        modifier(SoftShadowCard(color: color, radius: radius))
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 30) {
        // Gradient Progress Ring
        GradientProgressRing(
            progress: 0.75,
            colors: [.orange, .red, .pink]
        )
        .frame(width: 100, height: 100)

        // Glass Card
        GlassCard {
            Text("Glass Effect")
                .font(.headline)
                .padding()
        }

        // Shimmer
        RoundedRectangle(cornerRadius: 12)
            .fill(FuelColors.surface)
            .frame(height: 60)
            .shimmer()

        // Breathing Glow
        Circle()
            .fill(FuelColors.primary)
            .frame(width: 50, height: 50)
            .breathingGlow(color: FuelColors.primary)

        // Neon Text
        Text("PREMIUM")
            .font(.system(size: 24, weight: .bold))
            .neonGlow(color: FuelColors.primary)
    }
    .padding()
    .background(FuelColors.background)
}
