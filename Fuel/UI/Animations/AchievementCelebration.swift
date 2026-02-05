import SwiftUI

/// Achievement Celebration Components
/// Premium animations for achievement unlocks and displays

// MARK: - Achievement Card with Celebration

struct CelebrationAchievementCard: View {
    let achievement: ProgressAchievement
    let isNew: Bool
    let onTap: () -> Void

    @State private var hasAppeared = false
    @State private var shimmerOffset: CGFloat = -1
    @State private var showConfetti = false
    @State private var iconBounce = false

    var body: some View {
        Button {
            FuelHaptics.shared.tap()
            onTap()
        } label: {
            HStack(spacing: FuelSpacing.md) {
                // Animated icon
                achievementIcon

                // Content
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: FuelSpacing.xs) {
                        Text(achievement.title)
                            .font(FuelTypography.subheadlineMedium)
                            .foregroundStyle(FuelColors.textPrimary)

                        if isNew {
                            newBadge
                        }
                    }

                    Text(achievement.description)
                        .font(FuelTypography.caption)
                        .foregroundStyle(FuelColors.textTertiary)
                        .lineLimit(1)
                }

                Spacer()

                Text(achievement.formattedDate)
                    .font(FuelTypography.caption)
                    .foregroundStyle(FuelColors.textTertiary)
            }
            .padding(FuelSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: FuelSpacing.radiusMd)
                    .fill(FuelColors.surface)
                    .overlay(
                        // Shimmer border for new achievements
                        RoundedRectangle(cornerRadius: FuelSpacing.radiusMd)
                            .stroke(
                                isNew ? shimmerGradient : Color.clear.asLinearGradient(),
                                lineWidth: 2
                            )
                    )
            )
            .shadow(
                color: isNew ? achievement.color.opacity(0.3) : .black.opacity(0.04),
                radius: isNew ? 12 : 8,
                x: 0,
                y: isNew ? 4 : 2
            )
        }
        .buttonStyle(AchievementButtonStyle())
        .overlay {
            if showConfetti {
                MiniConfettiView()
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            if !hasAppeared {
                hasAppeared = true
                if isNew {
                    triggerCelebration()
                }
            }
        }
    }

    // MARK: - Achievement Icon

    private var achievementIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: FuelSpacing.radiusSm)
                .fill(achievement.color.opacity(0.12))
                .frame(width: 40, height: 40)

            Image(systemName: achievement.icon)
                .font(.system(size: 18))
                .foregroundStyle(achievement.color)
                .scaleEffect(iconBounce ? 1.2 : 1.0)
                .animation(
                    .spring(response: 0.3, dampingFraction: 0.5),
                    value: iconBounce
                )
        }
    }

    // MARK: - New Badge

    private var newBadge: some View {
        Text("NEW")
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [FuelColors.gold, FuelColors.gold.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .scaleEffect(hasAppeared ? 1 : 0)
            .animation(
                .spring(response: 0.4, dampingFraction: 0.6).delay(0.3),
                value: hasAppeared
            )
    }

    // MARK: - Shimmer Gradient

    private var shimmerGradient: LinearGradient {
        LinearGradient(
            colors: [
                achievement.color.opacity(0.3),
                achievement.color.opacity(0.8),
                FuelColors.gold,
                achievement.color.opacity(0.8),
                achievement.color.opacity(0.3)
            ],
            startPoint: UnitPoint(x: shimmerOffset, y: 0),
            endPoint: UnitPoint(x: shimmerOffset + 0.5, y: 1)
        )
    }

    // MARK: - Celebration

    private func triggerCelebration() {
        // Start shimmer
        withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
            shimmerOffset = 1.5
        }

        // Icon bounce
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            iconBounce = true
            FuelHaptics.shared.success()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                iconBounce = false
            }
        }

        // Mini confetti
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            showConfetti = true

            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showConfetti = false
            }
        }
    }
}

// MARK: - Achievement Button Style

private struct AchievementButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Mini Confetti View

struct MiniConfettiView: View {
    @State private var particles: [MiniConfettiParticle] = []

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                        .opacity(particle.opacity)
                }
            }
            .onAppear {
                createParticles(in: geometry.size)
                animateParticles()
            }
        }
    }

    private func createParticles(in size: CGSize) {
        let colors: [Color] = [
            FuelColors.gold,
            FuelColors.primary,
            .orange,
            .yellow,
            FuelColors.success
        ]

        particles = (0..<15).map { _ in
            MiniConfettiParticle(
                position: CGPoint(
                    x: size.width / 2 + CGFloat.random(in: -20...20),
                    y: size.height / 2
                ),
                color: colors.randomElement() ?? FuelColors.gold,
                size: CGFloat.random(in: 4...8),
                velocity: CGVector(
                    dx: CGFloat.random(in: -80...80),
                    dy: CGFloat.random(in: -120 ... -60)
                ),
                opacity: 1.0
            )
        }
    }

    private func animateParticles() {
        Timer.scheduledTimer(withTimeInterval: 1/60, repeats: true) { timer in
            var allFaded = true

            for i in particles.indices {
                particles[i].position.x += particles[i].velocity.dx * 0.016
                particles[i].position.y += particles[i].velocity.dy * 0.016
                particles[i].velocity.dy += 200 * 0.016 // Gravity
                particles[i].opacity -= 0.015

                if particles[i].opacity > 0 {
                    allFaded = false
                }
            }

            if allFaded {
                timer.invalidate()
            }
        }
    }
}

private struct MiniConfettiParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    let color: Color
    let size: CGFloat
    var velocity: CGVector
    var opacity: Double
}

// MARK: - Color Extension

extension Color {
    func asLinearGradient() -> LinearGradient {
        LinearGradient(colors: [self], startPoint: .top, endPoint: .bottom)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        CelebrationAchievementCard(
            achievement: ProgressAchievement(
                id: "1",
                title: "First Week Complete",
                description: "Logged meals for 7 consecutive days",
                icon: "star.fill",
                color: FuelColors.gold,
                earnedDate: Date()
            ),
            isNew: true,
            onTap: {}
        )

        CelebrationAchievementCard(
            achievement: ProgressAchievement(
                id: "2",
                title: "Protein Pro",
                description: "Hit protein goal 5 days in a row",
                icon: "bolt.fill",
                color: FuelColors.protein,
                earnedDate: Date().addingTimeInterval(-86400 * 3)
            ),
            isNew: false,
            onTap: {}
        )
    }
    .padding()
    .background(FuelColors.background)
}
