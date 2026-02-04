import SwiftUI

/// Fuel Design System - Animations
/// Premium motion design with physics-based springs
public struct FuelAnimations {

    // MARK: - Spring Animations

    /// Quick responsive spring - Micro-interactions
    /// Use for: Button press, toggle, small UI feedback
    public static let springQuick = Animation.spring(response: 0.25, dampingFraction: 0.8)

    /// Standard spring - Most interactions
    /// Use for: Card expansion, modal presentation, selection
    public static let spring = Animation.spring(response: 0.35, dampingFraction: 0.7)

    /// Bouncy spring - Playful interactions
    /// Use for: Celebrations, achievements, success states
    public static let springBouncy = Animation.spring(response: 0.4, dampingFraction: 0.6)

    /// Slow spring - Deliberate movements
    /// Use for: Large element transitions, hero animations
    public static let springSlow = Animation.spring(response: 0.5, dampingFraction: 0.7)

    /// Extra bouncy - Celebration moments
    /// Use for: Confetti, achievement popups
    public static let springCelebration = Animation.spring(response: 0.6, dampingFraction: 0.5)

    // MARK: - Ease Animations

    /// Quick ease out - Fast feedback
    public static let easeQuick = Animation.easeOut(duration: 0.15)

    /// Standard ease - General transitions
    public static let ease = Animation.easeOut(duration: 0.25)

    /// Smooth ease in/out - Balanced transitions
    public static let easeSmooth = Animation.easeInOut(duration: 0.3)

    /// Slow ease - Deliberate transitions
    public static let easeSlow = Animation.easeInOut(duration: 0.4)

    // MARK: - Special Animations

    /// Pulse animation - Attention grabbing
    public static let pulse = Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true)

    /// Gentle pulse - Subtle attention
    public static let pulseGentle = Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: true)

    /// Loading spin - Continuous rotation
    public static let spin = Animation.linear(duration: 1.0).repeatForever(autoreverses: false)

    /// Shake animation - Error feedback
    public static let shake = Animation.spring(response: 0.2, dampingFraction: 0.3)

    // MARK: - Timing Curves

    /// Custom bezier for premium feel
    public static let premiumCurve = Animation.timingCurve(0.2, 0.8, 0.2, 1, duration: 0.4)

    // MARK: - Delays

    /// Stagger delay for list items
    public static func staggerDelay(index: Int, baseDelay: Double = 0.05) -> Animation {
        spring.delay(Double(index) * baseDelay)
    }
}

// MARK: - Transition Presets

extension AnyTransition {

    /// Page transition - Horizontal slide with fade
    public static let pageForward = AnyTransition.asymmetric(
        insertion: .move(edge: .trailing).combined(with: .opacity),
        removal: .move(edge: .leading).combined(with: .opacity)
    )

    /// Page transition backward
    public static let pageBackward = AnyTransition.asymmetric(
        insertion: .move(edge: .leading).combined(with: .opacity),
        removal: .move(edge: .trailing).combined(with: .opacity)
    )

    /// Bottom sheet presentation
    public static let bottomSheet = AnyTransition.move(edge: .bottom).combined(with: .opacity)

    /// Scale and fade - Modal presentation
    public static let scaleAndFade = AnyTransition.scale(scale: 0.9).combined(with: .opacity)

    /// Pop in - Attention grabbing
    public static let popIn = AnyTransition.scale(scale: 0.5).combined(with: .opacity)

    /// Slide up with fade
    public static let slideUp = AnyTransition.move(edge: .bottom)
        .combined(with: .opacity)

    /// Blur transition
    public static let blur = AnyTransition.modifier(
        active: BlurModifier(radius: 10, opacity: 0),
        identity: BlurModifier(radius: 0, opacity: 1)
    )
}

// MARK: - Animation Modifiers

/// Blur transition modifier
struct BlurModifier: ViewModifier {
    let radius: CGFloat
    let opacity: Double

    func body(content: Content) -> some View {
        content
            .blur(radius: radius)
            .opacity(opacity)
    }
}

/// Pressable button style with scale effect
public struct PressableButtonStyle: ButtonStyle {
    let scale: CGFloat

    public init(scale: CGFloat = 0.96) {
        self.scale = scale
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(FuelAnimations.springQuick, value: configuration.isPressed)
    }
}

/// Bounce effect modifier
public struct BounceEffect: ViewModifier {
    @State private var animate = false
    let trigger: Bool

    public func body(content: Content) -> some View {
        content
            .scaleEffect(animate ? 1.0 : 0.8)
            .opacity(animate ? 1.0 : 0)
            .onChange(of: trigger) { _, newValue in
                if newValue {
                    withAnimation(FuelAnimations.springBouncy) {
                        animate = true
                    }
                }
            }
    }
}

/// Shake effect for errors
public struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 10
    var shakesPerUnit = 3
    var animatableData: CGFloat

    public func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(
            CGAffineTransform(translationX: amount * sin(animatableData * .pi * CGFloat(shakesPerUnit)), y: 0)
        )
    }
}

/// Counting number animation
public struct CountingAnimation: Animatable, ViewModifier {
    var value: Double
    let formatter: (Double) -> String

    public var animatableData: Double {
        get { value }
        set { value = newValue }
    }

    public func body(content: Content) -> some View {
        Text(formatter(value))
    }
}

// MARK: - View Extensions

extension View {
    /// Apply pressable button style
    public func pressable(scale: CGFloat = 0.96) -> some View {
        buttonStyle(PressableButtonStyle(scale: scale))
    }

    /// Apply bounce effect on trigger
    public func bounceEffect(trigger: Bool) -> some View {
        modifier(BounceEffect(trigger: trigger))
    }

    /// Apply shake effect
    public func shake(trigger: Bool, amount: CGFloat = 10) -> some View {
        modifier(ShakeEffect(amount: trigger ? amount : 0, animatableData: trigger ? 1 : 0))
    }

    /// Animate number counting
    public func countAnimation(
        value: Double,
        formatter: @escaping (Double) -> String = { String(Int($0)) }
    ) -> some View {
        modifier(CountingAnimation(value: value, formatter: formatter))
    }

    /// Staggered appearance animation
    public func staggeredAppearance(index: Int, baseDelay: Double = 0.05) -> some View {
        self
            .opacity(0)
            .offset(y: 20)
            .animation(
                FuelAnimations.spring.delay(Double(index) * baseDelay),
                value: true
            )
    }
}

// MARK: - Celebration Effects

/// Confetti particle for celebration animations
public struct ConfettiParticle: View {
    let color: Color
    let size: CGFloat
    @State private var rotation: Double = 0

    public var body: some View {
        RoundedRectangle(cornerRadius: 2, style: .continuous)
            .fill(color)
            .frame(width: size, height: size)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                rotation = Double.random(in: 0...360)
            }
    }
}

/// Number reveal animation (for calorie count-up)
public struct NumberRevealAnimation: View {
    let targetValue: Int
    let duration: Double
    let onComplete: (() -> Void)?

    @State private var currentValue: Int = 0
    @State private var hasStarted = false

    public init(targetValue: Int, duration: Double = 1.5, onComplete: (() -> Void)? = nil) {
        self.targetValue = targetValue
        self.duration = duration
        self.onComplete = onComplete
    }

    public var body: some View {
        Text("\(currentValue)")
            .contentTransition(.numericText())
            .onAppear {
                guard !hasStarted else { return }
                hasStarted = true
                animateCount()
            }
    }

    private func animateCount() {
        let steps = 60
        let stepDuration = duration / Double(steps)
        let increment = targetValue / steps

        for i in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(i)) {
                withAnimation(.none) {
                    currentValue = min(increment * i, targetValue)
                }

                // Haptic at intervals
                if i % 15 == 0 {
                    FuelHaptics.shared.tick()
                }
            }
        }

        // Final value
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            currentValue = targetValue
            FuelHaptics.shared.success()
            onComplete?()
        }
    }
}
