import SwiftUI

/// Staggered Animation View Modifier
/// Adds entrance animation with configurable delay

struct StaggeredEntrance: ViewModifier {
    let index: Int
    let baseDelay: Double
    let delayIncrement: Double

    @State private var isVisible = false

    private var delay: Double {
        baseDelay + (Double(index) * delayIncrement)
    }

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 20)
            .onAppear {
                withAnimation(
                    .spring(response: 0.5, dampingFraction: 0.8)
                    .delay(delay)
                ) {
                    isVisible = true
                }

                // Subtle haptic tick as section appears
                DispatchQueue.main.asyncAfter(deadline: .now() + delay + 0.1) {
                    FuelHaptics.shared.select()
                }
            }
    }
}

/// Fade Scale Entrance
/// Fades in and scales up slightly

struct FadeScaleEntrance: ViewModifier {
    let delay: Double

    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1 : 0.95)
            .onAppear {
                withAnimation(
                    .spring(response: 0.4, dampingFraction: 0.75)
                    .delay(delay)
                ) {
                    isVisible = true
                }
            }
    }
}

/// Slide In From Side
/// Slides in from left or right

struct SlideInEntrance: ViewModifier {
    enum Direction {
        case left, right
    }

    let direction: Direction
    let delay: Double

    @State private var isVisible = false

    private var offset: CGFloat {
        direction == .left ? -30 : 30
    }

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(x: isVisible ? 0 : offset)
            .onAppear {
                withAnimation(
                    .spring(response: 0.45, dampingFraction: 0.8)
                    .delay(delay)
                ) {
                    isVisible = true
                }
            }
    }
}

/// Pop In Animation
/// Bouncy scale animation for emphasis

struct PopInEntrance: ViewModifier {
    let delay: Double

    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1 : 0.5)
            .onAppear {
                withAnimation(
                    .spring(response: 0.35, dampingFraction: 0.6)
                    .delay(delay)
                ) {
                    isVisible = true
                }
            }
    }
}

// MARK: - View Extensions

extension View {
    /// Adds staggered entrance animation based on index
    func staggeredEntrance(
        index: Int,
        baseDelay: Double = 0,
        delayIncrement: Double = 0.1
    ) -> some View {
        modifier(StaggeredEntrance(
            index: index,
            baseDelay: baseDelay,
            delayIncrement: delayIncrement
        ))
    }

    /// Adds fade and scale entrance animation
    func fadeScaleEntrance(delay: Double = 0) -> some View {
        modifier(FadeScaleEntrance(delay: delay))
    }

    /// Adds slide in entrance animation
    func slideInEntrance(from direction: SlideInEntrance.Direction = .left, delay: Double = 0) -> some View {
        modifier(SlideInEntrance(direction: direction, delay: delay))
    }

    /// Adds pop in entrance animation
    func popInEntrance(delay: Double = 0) -> some View {
        modifier(PopInEntrance(delay: delay))
    }
}

/// Animated Section Container
/// Wraps content with entrance animation and optional haptic

struct AnimatedSection<Content: View>: View {
    let index: Int
    let hapticOnAppear: Bool
    @ViewBuilder let content: () -> Content

    @State private var isVisible = false

    private var delay: Double {
        Double(index) * 0.1
    }

    init(
        index: Int,
        hapticOnAppear: Bool = true,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.index = index
        self.hapticOnAppear = hapticOnAppear
        self.content = content
    }

    var body: some View {
        content()
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 20)
            .onAppear {
                withAnimation(
                    .spring(response: 0.5, dampingFraction: 0.8)
                    .delay(delay)
                ) {
                    isVisible = true
                }

                if hapticOnAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay + 0.15) {
                        FuelHaptics.shared.select()
                    }
                }
            }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            ForEach(0..<5) { index in
                AnimatedSection(index: index) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.3))
                        .frame(height: 100)
                        .overlay(Text("Section \(index + 1)"))
                }
            }
        }
        .padding()
    }
}
