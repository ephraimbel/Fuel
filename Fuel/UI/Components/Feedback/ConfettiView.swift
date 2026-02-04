import SwiftUI

/// Fuel Design System - Confetti Celebration
/// Premium celebration animation for achievements and milestones

public struct ConfettiView: View {
    let isActive: Bool
    let intensity: Intensity
    let colors: [Color]

    @State private var particles: [ConfettiParticleState] = []

    public enum Intensity {
        case low      // 30 particles
        case medium   // 60 particles
        case high     // 100 particles

        var count: Int {
            switch self {
            case .low: return 30
            case .medium: return 60
            case .high: return 100
            }
        }
    }

    public init(
        isActive: Bool,
        intensity: Intensity = .medium,
        colors: [Color]? = nil
    ) {
        self.isActive = isActive
        self.intensity = intensity
        self.colors = colors ?? [
            FuelColors.primary,
            FuelColors.success,
            FuelColors.gold,
            FuelColors.protein,
            FuelColors.carbs,
            FuelColors.fat
        ]
    }

    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    ConfettiPiece(
                        color: particle.color,
                        shape: particle.shape
                    )
                    .position(particle.position)
                    .rotationEffect(.degrees(particle.rotation))
                    .scaleEffect(particle.scale)
                    .opacity(particle.opacity)
                }
            }
            .onChange(of: isActive) { _, newValue in
                if newValue {
                    triggerConfetti(in: geometry.size)
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func triggerConfetti(in size: CGSize) {
        // Haptic feedback
        FuelHaptics.shared.celebration()

        // Create particles
        particles = (0..<intensity.count).map { _ in
            ConfettiParticleState(
                color: colors.randomElement() ?? FuelColors.primary,
                shape: ConfettiShape.allCases.randomElement() ?? .rectangle,
                position: CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: -20
                ),
                rotation: 0,
                scale: CGFloat.random(in: 0.5...1.2),
                opacity: 1.0,
                velocity: CGVector(
                    dx: CGFloat.random(in: -100...100),
                    dy: CGFloat.random(in: 200...600)
                ),
                rotationSpeed: CGFloat.random(in: -360...360)
            )
        }

        // Animate particles
        animateParticles(size: size)
    }

    private func animateParticles(size: CGSize) {
        let duration: Double = 3.0
        let steps = 60
        let stepDuration = duration / Double(steps)

        for step in 0..<steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(step)) {
                let progress = Double(step) / Double(steps)

                withAnimation(.linear(duration: stepDuration)) {
                    for i in particles.indices {
                        // Apply gravity and velocity
                        particles[i].position.x += particles[i].velocity.dx * 0.016
                        particles[i].position.y += particles[i].velocity.dy * 0.016
                        particles[i].velocity.dy += 15 // Gravity

                        // Rotation
                        particles[i].rotation += particles[i].rotationSpeed * 0.016

                        // Fade out toward end
                        if progress > 0.7 {
                            particles[i].opacity = 1.0 - ((progress - 0.7) / 0.3)
                        }

                        // Add some horizontal drift
                        particles[i].velocity.dx *= 0.99
                    }
                }

                // Additional haptic at peak
                if step == 15 {
                    FuelHaptics.shared.milestone()
                }
            }
        }

        // Clear particles after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.5) {
            particles = []
        }
    }
}

// MARK: - Particle State

struct ConfettiParticleState: Identifiable {
    let id = UUID()
    let color: Color
    let shape: ConfettiShape
    var position: CGPoint
    var rotation: Double
    var scale: CGFloat
    var opacity: Double
    var velocity: CGVector
    var rotationSpeed: CGFloat
}

// MARK: - Confetti Shapes

enum ConfettiShape: CaseIterable {
    case rectangle
    case circle
    case triangle
    case star
}

struct ConfettiPiece: View {
    let color: Color
    let shape: ConfettiShape

    var body: some View {
        Group {
            switch shape {
            case .rectangle:
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(color)
                    .frame(width: 8, height: 12)

            case .circle:
                Circle()
                    .fill(color)
                    .frame(width: 10, height: 10)

            case .triangle:
                Triangle()
                    .fill(color)
                    .frame(width: 10, height: 10)

            case .star:
                Image(systemName: "star.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(color)
            }
        }
    }
}

// MARK: - Triangle Shape

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Confetti Modifier

public struct ConfettiModifier: ViewModifier {
    @Binding var isActive: Bool
    let intensity: ConfettiView.Intensity

    public func body(content: Content) -> some View {
        ZStack {
            content
            ConfettiView(isActive: isActive, intensity: intensity)
        }
    }
}

extension View {
    /// Add confetti celebration overlay
    public func confetti(
        isActive: Binding<Bool>,
        intensity: ConfettiView.Intensity = .medium
    ) -> some View {
        modifier(ConfettiModifier(isActive: isActive, intensity: intensity))
    }
}

// MARK: - Achievement Celebration

/// Full celebration view for achievements
public struct AchievementCelebration: View {
    let title: String
    let description: String
    let icon: String
    @Binding var isPresented: Bool

    @State private var showContent = false
    @State private var showConfetti = false

    public init(
        title: String,
        description: String,
        icon: String,
        isPresented: Binding<Bool>
    ) {
        self.title = title
        self.description = description
        self.icon = icon
        self._isPresented = isPresented
    }

    public var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }

            // Confetti
            ConfettiView(isActive: showConfetti, intensity: .high)

            // Content
            VStack(spacing: FuelSpacing.xl) {
                // Badge
                ZStack {
                    Circle()
                        .fill(FuelColors.goldGradient)
                        .frame(width: 100, height: 100)
                        .shadow(color: FuelColors.gold.opacity(0.5), radius: 20, y: 10)

                    Image(systemName: icon)
                        .font(.system(size: 44, weight: .bold))
                        .foregroundStyle(.white)
                }
                .scaleEffect(showContent ? 1 : 0.5)
                .opacity(showContent ? 1 : 0)

                // Text
                VStack(spacing: FuelSpacing.sm) {
                    Text("Achievement Unlocked!")
                        .font(FuelTypography.caption)
                        .foregroundStyle(FuelColors.gold)
                        .textCase(.uppercase)
                        .tracking(2)

                    Text(title)
                        .font(FuelTypography.title1)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    Text(description)
                        .font(FuelTypography.body)
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                .scaleEffect(showContent ? 1 : 0.8)
                .opacity(showContent ? 1 : 0)

                // Dismiss button
                Button {
                    dismiss()
                } label: {
                    Text("Awesome!")
                        .font(FuelTypography.headline)
                        .foregroundStyle(.black)
                        .frame(width: 200)
                        .padding(.vertical, FuelSpacing.md)
                        .background(FuelColors.gold)
                        .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd, style: .continuous))
                }
                .scaleEffect(showContent ? 1 : 0.8)
                .opacity(showContent ? 1 : 0)
            }
            .padding(FuelSpacing.xxl)
        }
        .onAppear {
            FuelHaptics.shared.celebration()

            withAnimation(FuelAnimations.springCelebration.delay(0.1)) {
                showContent = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showConfetti = true
            }
        }
    }

    private func dismiss() {
        FuelHaptics.shared.tap()
        withAnimation(FuelAnimations.springQuick) {
            showContent = false
            isPresented = false
        }
    }
}

// MARK: - Preview

#Preview("Confetti") {
    struct PreviewWrapper: View {
        @State private var showConfetti = false
        @State private var showAchievement = false

        var body: some View {
            ZStack {
                VStack(spacing: 20) {
                    FuelButton("Trigger Confetti") {
                        showConfetti = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            showConfetti = false
                        }
                    }

                    FuelButton("Show Achievement", style: .secondary) {
                        showAchievement = true
                    }
                }
                .confetti(isActive: $showConfetti)

                if showAchievement {
                    AchievementCelebration(
                        title: "First Week",
                        description: "You've logged meals for 7 consecutive days!",
                        icon: "flame.fill",
                        isPresented: $showAchievement
                    )
                }
            }
        }
    }

    return PreviewWrapper()
}
