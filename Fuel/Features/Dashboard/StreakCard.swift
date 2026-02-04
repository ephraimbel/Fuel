import SwiftUI

/// Streak Card
/// Shows current logging streak with fire animation

struct StreakCard: View {
    let currentStreak: Int
    let longestStreak: Int

    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: FuelSpacing.md) {
            // Fire icon with animation
            ZStack {
                // Glow effect
                Circle()
                    .fill(FuelColors.gold.opacity(0.3))
                    .frame(width: 56, height: 56)
                    .scaleEffect(isAnimating ? 1.2 : 1.0)
                    .opacity(isAnimating ? 0.5 : 0.8)

                // Fire icon
                Image(systemName: "flame.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [FuelColors.gold, .orange, .red],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
            }

            // Streak info
            VStack(alignment: .leading, spacing: FuelSpacing.xxxs) {
                HStack(alignment: .firstTextBaseline, spacing: FuelSpacing.xs) {
                    Text("\(currentStreak)")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(FuelColors.textPrimary)

                    Text("day streak")
                        .font(FuelTypography.subheadline)
                        .foregroundStyle(FuelColors.textSecondary)
                }

                Text("Keep it up! 🔥")
                    .font(FuelTypography.caption)
                    .foregroundStyle(FuelColors.textTertiary)
            }

            Spacer()

            // Longest streak
            VStack(alignment: .trailing, spacing: FuelSpacing.xxxs) {
                Text("Best")
                    .font(FuelTypography.caption)
                    .foregroundStyle(FuelColors.textTertiary)

                Text("\(longestStreak)")
                    .font(FuelTypography.headline)
                    .foregroundStyle(FuelColors.textSecondary)
            }
        }
        .padding(FuelSpacing.md)
        .background(
            LinearGradient(
                colors: [
                    FuelColors.gold.opacity(0.1),
                    FuelColors.gold.opacity(0.05)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
        .overlay(
            RoundedRectangle(cornerRadius: FuelSpacing.radiusMd)
                .stroke(FuelColors.gold.opacity(0.3), lineWidth: 1)
        )
        .onAppear {
            withAnimation(
                Animation.easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true)
            ) {
                isAnimating = true
            }
            FuelHaptics.shared.streak()
        }
    }
}

// MARK: - Milestone Streak Card

struct MilestoneStreakCard: View {
    let milestone: Int
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: FuelSpacing.lg) {
            // Celebration icon
            ZStack {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(FuelColors.gold.opacity(0.2))
                        .frame(width: CGFloat(80 + index * 30), height: CGFloat(80 + index * 30))
                }

                Image(systemName: "flame.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [FuelColors.gold, .orange, .red],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
            }

            // Text
            VStack(spacing: FuelSpacing.sm) {
                Text("🎉 Milestone Reached!")
                    .font(FuelTypography.headline)
                    .foregroundStyle(FuelColors.textPrimary)

                Text("\(milestone) Day Streak")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(FuelColors.gold)

                Text("You're on fire! Keep the momentum going.")
                    .font(FuelTypography.body)
                    .foregroundStyle(FuelColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            // Dismiss button
            Button {
                onDismiss()
            } label: {
                Text("Continue")
                    .font(FuelTypography.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, FuelSpacing.md)
                    .background(FuelColors.primary)
                    .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
            }
        }
        .padding(FuelSpacing.xl)
        .background(FuelColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusLg))
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: FuelSpacing.lg) {
        StreakCard(currentStreak: 7, longestStreak: 14)

        MilestoneStreakCard(milestone: 7) {}
    }
    .padding()
    .background(FuelColors.background)
}
