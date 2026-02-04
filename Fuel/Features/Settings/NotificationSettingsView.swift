import SwiftUI

/// Notification Settings View
/// Configure meal reminders and notifications

struct NotificationSettingsView: View {
    @State private var notificationsEnabled = true
    @State private var breakfastReminder = true
    @State private var lunchReminder = true
    @State private var dinnerReminder = true
    @State private var snackReminder = false

    @State private var breakfastTime = Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? Date()
    @State private var lunchTime = Calendar.current.date(from: DateComponents(hour: 12, minute: 30)) ?? Date()
    @State private var dinnerTime = Calendar.current.date(from: DateComponents(hour: 18, minute: 30)) ?? Date()

    @State private var weeklyProgressEnabled = true
    @State private var streakReminder = true
    @State private var achievementNotifications = true

    var body: some View {
        ScrollView {
            VStack(spacing: FuelSpacing.xl) {
                // Master toggle
                masterToggleSection

                // Meal reminders
                if notificationsEnabled {
                    mealRemindersSection

                    // Other notifications
                    otherNotificationsSection
                }

                // Permissions note
                permissionsNote
            }
            .padding(.horizontal, FuelSpacing.screenHorizontal)
            .padding(.vertical, FuelSpacing.lg)
        }
        .background(FuelColors.background)
        .navigationTitle("Reminders")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Master Toggle

    private var masterToggleSection: some View {
        VStack(spacing: 0) {
            HStack(spacing: FuelSpacing.md) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.red)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: FuelSpacing.xxxs) {
                    Text("Notifications")
                        .font(FuelTypography.subheadlineMedium)
                        .foregroundStyle(FuelColors.textPrimary)

                    Text("Enable to receive reminders")
                        .font(FuelTypography.caption)
                        .foregroundStyle(FuelColors.textTertiary)
                }

                Spacer()

                Toggle("", isOn: $notificationsEnabled)
                    .labelsHidden()
                    .tint(FuelColors.primary)
                    .onChange(of: notificationsEnabled) { _, _ in
                        FuelHaptics.shared.tap()
                    }
            }
            .padding(FuelSpacing.md)
        }
        .background(FuelColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
    }

    // MARK: - Meal Reminders

    private var mealRemindersSection: some View {
        VStack(alignment: .leading, spacing: FuelSpacing.sm) {
            Text("MEAL REMINDERS")
                .font(FuelTypography.caption)
                .foregroundStyle(FuelColors.textTertiary)

            VStack(spacing: 0) {
                mealReminderRow(
                    icon: "sunrise.fill",
                    iconColor: .orange,
                    name: "Breakfast",
                    isEnabled: $breakfastReminder,
                    time: $breakfastTime
                )

                Divider()
                    .padding(.leading, FuelSpacing.md + 32 + FuelSpacing.md)

                mealReminderRow(
                    icon: "sun.max.fill",
                    iconColor: .yellow,
                    name: "Lunch",
                    isEnabled: $lunchReminder,
                    time: $lunchTime
                )

                Divider()
                    .padding(.leading, FuelSpacing.md + 32 + FuelSpacing.md)

                mealReminderRow(
                    icon: "moon.stars.fill",
                    iconColor: .indigo,
                    name: "Dinner",
                    isEnabled: $dinnerReminder,
                    time: $dinnerTime
                )
            }
            .background(FuelColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
        }
    }

    private func mealReminderRow(
        icon: String,
        iconColor: Color,
        name: String,
        isEnabled: Binding<Bool>,
        time: Binding<Date>
    ) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: FuelSpacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(iconColor)
                    .frame(width: 32)

                Text(name)
                    .font(FuelTypography.subheadlineMedium)
                    .foregroundStyle(FuelColors.textPrimary)

                Spacer()

                Toggle("", isOn: isEnabled)
                    .labelsHidden()
                    .tint(FuelColors.primary)
                    .onChange(of: isEnabled.wrappedValue) { _, _ in
                        FuelHaptics.shared.tap()
                    }
            }
            .padding(FuelSpacing.md)

            if isEnabled.wrappedValue {
                HStack {
                    Spacer()
                        .frame(width: 32 + FuelSpacing.md)

                    DatePicker(
                        "Time",
                        selection: time,
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .tint(FuelColors.primary)

                    Spacer()
                }
                .padding(.horizontal, FuelSpacing.md)
                .padding(.bottom, FuelSpacing.md)
            }
        }
    }

    // MARK: - Other Notifications

    private var otherNotificationsSection: some View {
        VStack(alignment: .leading, spacing: FuelSpacing.sm) {
            Text("OTHER NOTIFICATIONS")
                .font(FuelTypography.caption)
                .foregroundStyle(FuelColors.textTertiary)

            VStack(spacing: 0) {
                notificationToggleRow(
                    icon: "chart.bar.fill",
                    iconColor: .blue,
                    name: "Weekly Progress",
                    description: "Summary of your week",
                    isEnabled: $weeklyProgressEnabled
                )

                Divider()
                    .padding(.leading, FuelSpacing.md + 32 + FuelSpacing.md)

                notificationToggleRow(
                    icon: "flame.fill",
                    iconColor: .orange,
                    name: "Streak Reminders",
                    description: "Don't break your streak",
                    isEnabled: $streakReminder
                )

                Divider()
                    .padding(.leading, FuelSpacing.md + 32 + FuelSpacing.md)

                notificationToggleRow(
                    icon: "trophy.fill",
                    iconColor: FuelColors.gold,
                    name: "Achievements",
                    description: "Celebrate your milestones",
                    isEnabled: $achievementNotifications
                )
            }
            .background(FuelColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
        }
    }

    private func notificationToggleRow(
        icon: String,
        iconColor: Color,
        name: String,
        description: String,
        isEnabled: Binding<Bool>
    ) -> some View {
        HStack(spacing: FuelSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(iconColor)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: FuelSpacing.xxxs) {
                Text(name)
                    .font(FuelTypography.subheadlineMedium)
                    .foregroundStyle(FuelColors.textPrimary)

                Text(description)
                    .font(FuelTypography.caption)
                    .foregroundStyle(FuelColors.textTertiary)
            }

            Spacer()

            Toggle("", isOn: isEnabled)
                .labelsHidden()
                .tint(FuelColors.primary)
                .onChange(of: isEnabled.wrappedValue) { _, _ in
                    FuelHaptics.shared.tap()
                }
        }
        .padding(FuelSpacing.md)
    }

    // MARK: - Permissions Note

    private var permissionsNote: some View {
        Button {
            openNotificationSettings()
        } label: {
            HStack(spacing: FuelSpacing.sm) {
                Image(systemName: "gear")
                    .foregroundStyle(FuelColors.textSecondary)

                Text("Manage notification permissions in Settings")
                    .font(FuelTypography.caption)
                    .foregroundStyle(FuelColors.textSecondary)

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12))
                    .foregroundStyle(FuelColors.textTertiary)
            }
            .padding(FuelSpacing.md)
            .background(FuelColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
        }
    }

    // MARK: - Actions

    private func openNotificationSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        NotificationSettingsView()
    }
}
