import SwiftUI

/// Achievements View
/// Shows all achievements with their status

struct AchievementsView: View {
    @State private var selectedCategory: AchievementCategory = .all

    private let achievements: [AchievementItem] = AchievementItem.allAchievements

    var filteredAchievements: [AchievementItem] {
        if selectedCategory == .all {
            return achievements
        }
        return achievements.filter { $0.category == selectedCategory }
    }

    var earnedCount: Int {
        achievements.filter { $0.isEarned }.count
    }

    var body: some View {
        ScrollView {
            VStack(spacing: FuelSpacing.lg) {
                // Progress summary
                progressSummary

                // Category filter
                categoryFilter

                // Achievements grid
                achievementsGrid
            }
            .padding(.horizontal, FuelSpacing.screenHorizontal)
            .padding(.vertical, FuelSpacing.lg)
        }
        .background(FuelColors.background)
        .navigationTitle("Achievements")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Progress Summary

    private var progressSummary: some View {
        HStack(spacing: FuelSpacing.xl) {
            // Trophy
            ZStack {
                Circle()
                    .fill(FuelColors.gold.opacity(0.2))
                    .frame(width: 80, height: 80)

                Image(systemName: "trophy.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(FuelColors.gold)
            }

            // Stats
            VStack(alignment: .leading, spacing: FuelSpacing.sm) {
                Text("\(earnedCount) of \(achievements.count)")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(FuelColors.textPrimary)

                Text("Achievements Earned")
                    .font(FuelTypography.subheadline)
                    .foregroundStyle(FuelColors.textSecondary)

                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(FuelColors.surfaceSecondary)
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(FuelColors.gold)
                            .frame(
                                width: geometry.size.width * CGFloat(earnedCount) / CGFloat(achievements.count),
                                height: 8
                            )
                    }
                }
                .frame(height: 8)
            }
        }
        .padding(FuelSpacing.lg)
        .background(FuelColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusLg))
    }

    // MARK: - Category Filter

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: FuelSpacing.sm) {
                ForEach(AchievementCategory.allCases, id: \.self) { category in
                    Button {
                        withAnimation(FuelAnimations.spring) {
                            selectedCategory = category
                        }
                        FuelHaptics.shared.tap()
                    } label: {
                        Text(category.displayName)
                            .font(FuelTypography.subheadlineMedium)
                            .foregroundStyle(
                                selectedCategory == category
                                    ? .white
                                    : FuelColors.textSecondary
                            )
                            .padding(.horizontal, FuelSpacing.md)
                            .padding(.vertical, FuelSpacing.sm)
                            .background(
                                selectedCategory == category
                                    ? FuelColors.primary
                                    : FuelColors.surface
                            )
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    // MARK: - Achievements Grid

    private var achievementsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: FuelSpacing.md) {
            ForEach(filteredAchievements) { achievement in
                achievementCard(achievement)
            }
        }
    }

    private func achievementCard(_ achievement: AchievementItem) -> some View {
        VStack(spacing: FuelSpacing.md) {
            // Icon
            ZStack {
                Circle()
                    .fill(achievement.isEarned ? achievement.color.opacity(0.2) : FuelColors.surfaceSecondary)
                    .frame(width: 60, height: 60)

                Image(systemName: achievement.icon)
                    .font(.system(size: 28))
                    .foregroundStyle(achievement.isEarned ? achievement.color : FuelColors.textTertiary)
            }

            // Info
            VStack(spacing: FuelSpacing.xxxs) {
                Text(achievement.title)
                    .font(FuelTypography.subheadlineMedium)
                    .foregroundStyle(achievement.isEarned ? FuelColors.textPrimary : FuelColors.textTertiary)
                    .multilineTextAlignment(.center)

                Text(achievement.description)
                    .font(FuelTypography.caption)
                    .foregroundStyle(FuelColors.textTertiary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }

            // Status
            if achievement.isEarned, let date = achievement.earnedDate {
                Text(formatDate(date))
                    .font(FuelTypography.caption)
                    .foregroundStyle(achievement.color)
            } else if let progress = achievement.progress {
                // Progress indicator
                VStack(spacing: FuelSpacing.xxxs) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(FuelColors.surfaceSecondary)
                                .frame(height: 4)

                            RoundedRectangle(cornerRadius: 2)
                                .fill(FuelColors.primary)
                                .frame(width: geometry.size.width * progress, height: 4)
                        }
                    }
                    .frame(height: 4)

                    Text("\(Int(progress * 100))%")
                        .font(FuelTypography.caption)
                        .foregroundStyle(FuelColors.textTertiary)
                }
            } else {
                Text("Locked")
                    .font(FuelTypography.caption)
                    .foregroundStyle(FuelColors.textTertiary)
            }
        }
        .padding(FuelSpacing.md)
        .frame(maxWidth: .infinity)
        .background(FuelColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
        .opacity(achievement.isEarned ? 1.0 : 0.7)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Achievement Category

enum AchievementCategory: String, CaseIterable {
    case all
    case streaks
    case logging
    case weight
    case nutrition

    var displayName: String {
        switch self {
        case .all: return "All"
        case .streaks: return "Streaks"
        case .logging: return "Logging"
        case .weight: return "Weight"
        case .nutrition: return "Nutrition"
        }
    }
}

// MARK: - Achievement Item

struct AchievementItem: Identifiable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let color: Color
    let category: AchievementCategory
    let isEarned: Bool
    let earnedDate: Date?
    let progress: Double?

    static var allAchievements: [AchievementItem] {
        let calendar = Calendar.current
        let today = Date()

        return [
            // Streak achievements
            AchievementItem(
                id: "streak_3",
                title: "Getting Started",
                description: "Log meals for 3 days in a row",
                icon: "flame.fill",
                color: .orange,
                category: .streaks,
                isEarned: true,
                earnedDate: calendar.date(byAdding: .day, value: -10, to: today),
                progress: nil
            ),
            AchievementItem(
                id: "streak_7",
                title: "Week Warrior",
                description: "Log meals for 7 days in a row",
                icon: "flame.fill",
                color: .orange,
                category: .streaks,
                isEarned: true,
                earnedDate: calendar.date(byAdding: .day, value: -3, to: today),
                progress: nil
            ),
            AchievementItem(
                id: "streak_14",
                title: "Two Week Champion",
                description: "Log meals for 14 days in a row",
                icon: "flame.fill",
                color: .orange,
                category: .streaks,
                isEarned: false,
                earnedDate: nil,
                progress: 0.5
            ),
            AchievementItem(
                id: "streak_30",
                title: "Monthly Master",
                description: "Log meals for 30 days in a row",
                icon: "flame.fill",
                color: .orange,
                category: .streaks,
                isEarned: false,
                earnedDate: nil,
                progress: 0.23
            ),

            // Logging achievements
            AchievementItem(
                id: "first_meal",
                title: "First Bite",
                description: "Log your first meal",
                icon: "fork.knife",
                color: FuelColors.primary,
                category: .logging,
                isEarned: true,
                earnedDate: calendar.date(byAdding: .day, value: -15, to: today),
                progress: nil
            ),
            AchievementItem(
                id: "scan_10",
                title: "Scanner Pro",
                description: "Scan 10 barcodes",
                icon: "barcode.viewfinder",
                color: .blue,
                category: .logging,
                isEarned: true,
                earnedDate: calendar.date(byAdding: .day, value: -5, to: today),
                progress: nil
            ),
            AchievementItem(
                id: "ai_scan_5",
                title: "AI Explorer",
                description: "Use AI food scanning 5 times",
                icon: "camera.fill",
                color: .purple,
                category: .logging,
                isEarned: false,
                earnedDate: nil,
                progress: 0.6
            ),
            AchievementItem(
                id: "meals_100",
                title: "Century Club",
                description: "Log 100 meals",
                icon: "star.fill",
                color: FuelColors.gold,
                category: .logging,
                isEarned: false,
                earnedDate: nil,
                progress: 0.45
            ),

            // Weight achievements
            AchievementItem(
                id: "first_weigh",
                title: "Stepping Up",
                description: "Log your first weight",
                icon: "scalemass.fill",
                color: FuelColors.primary,
                category: .weight,
                isEarned: true,
                earnedDate: calendar.date(byAdding: .day, value: -14, to: today),
                progress: nil
            ),
            AchievementItem(
                id: "weight_5",
                title: "First 5",
                description: "Lose your first 5 pounds",
                icon: "scalemass.fill",
                color: FuelColors.success,
                category: .weight,
                isEarned: true,
                earnedDate: calendar.date(byAdding: .day, value: -2, to: today),
                progress: nil
            ),
            AchievementItem(
                id: "weight_10",
                title: "Double Digits",
                description: "Lose 10 pounds",
                icon: "scalemass.fill",
                color: FuelColors.success,
                category: .weight,
                isEarned: false,
                earnedDate: nil,
                progress: 0.5
            ),

            // Nutrition achievements
            AchievementItem(
                id: "protein_goal",
                title: "Protein Pro",
                description: "Hit protein goal 5 days in a row",
                icon: "bolt.fill",
                color: FuelColors.protein,
                category: .nutrition,
                isEarned: true,
                earnedDate: calendar.date(byAdding: .day, value: -1, to: today),
                progress: nil
            ),
            AchievementItem(
                id: "under_budget",
                title: "Budget Boss",
                description: "Stay under calorie goal for 7 days",
                icon: "checkmark.seal.fill",
                color: FuelColors.success,
                category: .nutrition,
                isEarned: false,
                earnedDate: nil,
                progress: 0.71
            ),
            AchievementItem(
                id: "balanced_week",
                title: "Balance Master",
                description: "Hit all macro goals for a week",
                icon: "chart.pie.fill",
                color: .purple,
                category: .nutrition,
                isEarned: false,
                earnedDate: nil,
                progress: nil
            )
        ]
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AchievementsView()
    }
}
