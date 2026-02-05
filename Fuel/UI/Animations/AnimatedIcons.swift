import SwiftUI

/// Animated Flame Icon
/// Pulsing flame with gradient background and particle embers for streak display

struct AnimatedFlameIcon: View {
    @State private var isAnimating = false
    @State private var hasAppeared = false
    @State private var glowOpacity: Double = 0.3

    var body: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.orange.opacity(glowOpacity), .clear],
                        center: .center,
                        startRadius: 20,
                        endRadius: 50
                    )
                )
                .frame(width: 80, height: 80)
                .blur(radius: 8)
                .animation(
                    .easeInOut(duration: 1.2)
                    .repeatForever(autoreverses: true),
                    value: glowOpacity
                )

            // Gradient background circle
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.6, blue: 0.0),
                            Color(red: 1.0, green: 0.3, blue: 0.0),
                            Color(red: 0.9, green: 0.1, blue: 0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 64, height: 64)
                .scaleEffect(hasAppeared ? 1 : 0)
                .animation(
                    .spring(response: 0.5, dampingFraction: 0.6)
                    .delay(0.2),
                    value: hasAppeared
                )
                .shadow(color: .orange.opacity(0.5), radius: 8, x: 0, y: 4)

            // Particle embers
            ForEach(0..<5, id: \.self) { index in
                EmberParticle(delay: Double(index) * 0.3)
            }

            // Flame icon with pulse animation
            Image(systemName: "flame.fill")
                .font(.system(size: 28))
                .foregroundStyle(.white)
                .scaleEffect(isAnimating ? 1.1 : 0.95)
                .opacity(hasAppeared ? 1 : 0)
                .shadow(color: .white.opacity(0.5), radius: 2)
                .animation(
                    .easeInOut(duration: 0.6)
                    .repeatForever(autoreverses: true),
                    value: isAnimating
                )
        }
        .onAppear {
            hasAppeared = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isAnimating = true
                glowOpacity = 0.6
            }
        }
    }
}

/// Ember Particle
/// Small particle that rises and fades

private struct EmberParticle: View {
    let delay: Double

    @State private var isAnimating = false
    @State private var randomX: CGFloat = CGFloat.random(in: -15...15)

    var body: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [.yellow, .orange],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 4, height: 4)
            .offset(
                x: randomX,
                y: isAnimating ? -45 : 0
            )
            .opacity(isAnimating ? 0 : 0.8)
            .blur(radius: isAnimating ? 2 : 0)
            .onAppear {
                startAnimation()
            }
    }

    private func startAnimation() {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(.easeOut(duration: 1.5)) {
                isAnimating = true
            }
            // Repeat
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                isAnimating = false
                randomX = CGFloat.random(in: -15...15)
                startAnimation()
            }
        }
    }
}

/// Animated Trophy Icon
/// Trophy with shimmer effect for best streak display

struct AnimatedTrophyIcon: View {
    @State private var shimmerOffset: CGFloat = -1
    @State private var hasAppeared = false

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(FuelColors.gold.opacity(0.15))
                .frame(width: 48, height: 48)
                .scaleEffect(hasAppeared ? 1 : 0)
                .animation(
                    .spring(response: 0.5, dampingFraction: 0.6)
                    .delay(0.3),
                    value: hasAppeared
                )

            // Trophy icon
            Image(systemName: "trophy.fill")
                .font(.system(size: 22))
                .foregroundStyle(FuelColors.gold)
                .opacity(hasAppeared ? 1 : 0)
                .overlay(
                    // Shimmer effect
                    LinearGradient(
                        colors: [
                            .clear,
                            .white.opacity(0.4),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: 20)
                    .offset(x: shimmerOffset * 30)
                    .mask(
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 22))
                    )
                )
        }
        .onAppear {
            hasAppeared = true
            // Start shimmer animation after initial appearance
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                startShimmer()
            }
        }
    }

    private func startShimmer() {
        withAnimation(.linear(duration: 1.5)) {
            shimmerOffset = 1
        }

        // Repeat every 4 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            shimmerOffset = -1
            startShimmer()
        }
    }
}

/// Animated Check Circle
/// Bouncy checkmark for completion states

struct AnimatedCheckCircle: View {
    let color: Color
    let size: CGFloat
    let delay: Double

    @State private var hasAppeared = false

    init(color: Color = FuelColors.success, size: CGFloat = 24, delay: Double = 0) {
        self.color = color
        self.size = size
        self.delay = delay
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.15))
                .frame(width: size, height: size)

            Image(systemName: "checkmark")
                .font(.system(size: size * 0.5, weight: .bold))
                .foregroundStyle(color)
                .scaleEffect(hasAppeared ? 1 : 0)
                .animation(
                    .spring(response: 0.4, dampingFraction: 0.5)
                    .delay(delay),
                    value: hasAppeared
                )
        }
        .onAppear {
            hasAppeared = true
        }
    }
}

/// Animated Sparkle
/// Small sparkle that pops in and fades

struct AnimatedSparkle: View {
    let delay: Double

    @State private var isVisible = false
    @State private var rotation: Double = 0

    var body: some View {
        Image(systemName: "sparkle")
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(FuelColors.gold)
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1 : 0.3)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(
                    .spring(response: 0.3, dampingFraction: 0.6)
                    .delay(delay)
                ) {
                    isVisible = true
                }

                withAnimation(
                    .linear(duration: 2)
                    .repeatForever(autoreverses: false)
                    .delay(delay)
                ) {
                    rotation = 360
                }
            }
    }
}

/// Pulsing Dot
/// Small dot that pulses for active states

struct PulsingDot: View {
    let color: Color
    let size: CGFloat

    @State private var isPulsing = false

    init(color: Color = FuelColors.primary, size: CGFloat = 8) {
        self.color = color
        self.size = size
    }

    var body: some View {
        ZStack {
            // Pulse ring
            Circle()
                .stroke(color.opacity(0.3), lineWidth: 2)
                .frame(width: size * 2, height: size * 2)
                .scaleEffect(isPulsing ? 1.5 : 1)
                .opacity(isPulsing ? 0 : 0.5)

            // Core dot
            Circle()
                .fill(color)
                .frame(width: size, height: size)
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 1.2)
                .repeatForever(autoreverses: false)
            ) {
                isPulsing = true
            }
        }
    }
}

/// Animated Arrow
/// Arrow that bounces to indicate direction

struct AnimatedArrow: View {
    enum Direction {
        case up, down, left, right

        var rotation: Double {
            switch self {
            case .up: return -90
            case .down: return 90
            case .left: return 180
            case .right: return 0
            }
        }

        var offset: CGSize {
            switch self {
            case .up: return CGSize(width: 0, height: -3)
            case .down: return CGSize(width: 0, height: 3)
            case .left: return CGSize(width: -3, height: 0)
            case .right: return CGSize(width: 3, height: 0)
            }
        }
    }

    let direction: Direction
    let color: Color

    @State private var isBouncing = false

    var body: some View {
        Image(systemName: "arrow.right")
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(color)
            .rotationEffect(.degrees(direction.rotation))
            .offset(isBouncing ? direction.offset : .zero)
            .animation(
                .easeInOut(duration: 0.6)
                .repeatForever(autoreverses: true),
                value: isBouncing
            )
            .onAppear {
                isBouncing = true
            }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 40) {
        HStack(spacing: 40) {
            AnimatedFlameIcon()
            AnimatedTrophyIcon()
        }

        HStack(spacing: 20) {
            AnimatedCheckCircle()
            AnimatedSparkle(delay: 0)
            PulsingDot()
        }

        HStack(spacing: 20) {
            AnimatedArrow(direction: .up, color: FuelColors.success)
            AnimatedArrow(direction: .down, color: FuelColors.error)
            AnimatedArrow(direction: .right, color: FuelColors.primary)
        }
    }
    .padding()
    .background(FuelColors.background)
}
