import SwiftUI

/// Streak Card
/// Shows current logging streak with fire animation

struct StreakCard: View {
    let currentStreak: Int
    let longestStreak: Int

    var body: some View {
        HStack(spacing: FuelSpacing.md) {
            // Fire icon
            Image(systemName: "flame.fill")
                .font(.system(size: 18))
                .foregroundStyle(.orange)
                .frame(width: 36, height: 36)
                .background(.orange.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusSm))

            // Streak info
            VStack(alignment: .leading, spacing: 2) {
                Text("\(currentStreak) day streak")
                    .font(FuelTypography.subheadlineMedium)
                    .foregroundStyle(FuelColors.textPrimary)

                Text("Longest: \(longestStreak) days")
                    .font(FuelTypography.caption)
                    .foregroundStyle(FuelColors.textTertiary)
            }

            Spacer()

            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(FuelColors.textTertiary)
        }
        .padding(FuelSpacing.md)
        .background(FuelColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusLg))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
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
