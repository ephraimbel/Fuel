import SwiftUI
import UserNotifications

/// Notifications Screen
/// Asks user to enable notifications for meal reminders

struct NotificationsScreen: View {
    @Bindable var viewModel: OnboardingViewModel

    @State private var showingTimePicker = false
    @State private var selectedReminder: MealReminderTime?

    var body: some View {
        OnboardingScreenLayout(
            title: "Stay on track with reminders",
            subtitle: "We'll remind you to log your meals at the right times."
        ) {
            VStack(spacing: FuelSpacing.lg) {
                // Illustration
                ZStack {
                    Circle()
                        .fill(FuelColors.primaryLight)
                        .frame(width: 120, height: 120)

                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(FuelColors.primary)
                }
                .padding(.vertical, FuelSpacing.lg)

                // Reminder times
                VStack(spacing: FuelSpacing.sm) {
                    ForEach($viewModel.mealReminderTimes) { $reminder in
                        ReminderTimeRow(
                            reminder: $reminder,
                            onTimeTap: {
                                selectedReminder = reminder
                                showingTimePicker = true
                            }
                        )
                    }
                }
                .padding(.horizontal, FuelSpacing.screenHorizontal)
            }
        } footer: {
            VStack(spacing: FuelSpacing.md) {
                FuelButton("Enable Notifications") {
                    requestNotificationPermission()
                }

                Button {
                    FuelHaptics.shared.tap()
                    viewModel.notificationsEnabled = false
                    viewModel.nextStep()
                } label: {
                    Text("Maybe later")
                        .font(FuelTypography.subheadline)
                        .foregroundStyle(FuelColors.textSecondary)
                }
            }
            .padding(.horizontal, FuelSpacing.screenHorizontal)
        }
        .onAppear {
            if viewModel.mealReminderTimes.isEmpty {
                viewModel.mealReminderTimes = MealReminderTime.defaults
            }
        }
        .sheet(isPresented: $showingTimePicker) {
            if let reminder = selectedReminder,
               let index = viewModel.mealReminderTimes.firstIndex(where: { $0.id == reminder.id }) {
                TimePickerSheet(
                    time: $viewModel.mealReminderTimes[index].time,
                    mealType: reminder.mealType
                )
                .presentationDetents([.height(300)])
            }
        }
    }

    private func requestNotificationPermission() {
        FuelHaptics.shared.tap()

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
                viewModel.notificationsEnabled = granted
                if granted {
                    FuelHaptics.shared.success()
                }
                viewModel.nextStep()
            }
        }
    }
}

// MARK: - Reminder Time Row

struct ReminderTimeRow: View {
    @Binding var reminder: MealReminderTime
    let onTimeTap: () -> Void

    var body: some View {
        HStack(spacing: FuelSpacing.md) {
            // Meal icon
            ZStack {
                RoundedRectangle(cornerRadius: FuelSpacing.radiusMd, style: .continuous)
                    .fill(reminder.isEnabled ? FuelColors.primaryLight : FuelColors.surfaceSecondary)
                    .frame(width: 44, height: 44)

                Image(systemName: reminder.mealType.icon)
                    .font(.system(size: 18))
                    .foregroundStyle(reminder.isEnabled ? FuelColors.primary : FuelColors.textTertiary)
            }

            // Meal type and time
            VStack(alignment: .leading, spacing: FuelSpacing.xxxs) {
                Text(reminder.mealType.displayName)
                    .font(FuelTypography.headline)
                    .foregroundStyle(FuelColors.textPrimary)

                Button {
                    FuelHaptics.shared.tap()
                    onTimeTap()
                } label: {
                    Text(reminder.time, style: .time)
                        .font(FuelTypography.subheadline)
                        .foregroundStyle(FuelColors.primary)
                }
            }

            Spacer()

            // Toggle
            Toggle("", isOn: $reminder.isEnabled)
                .tint(FuelColors.primary)
                .labelsHidden()
                .onChange(of: reminder.isEnabled) { _, _ in
                    FuelHaptics.shared.select()
                }
        }
        .padding(FuelSpacing.md)
        .background(FuelColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd, style: .continuous))
    }
}

// MARK: - Time Picker Sheet

struct TimePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var time: Date
    let mealType: MealType

    var body: some View {
        NavigationStack {
            VStack {
                DatePicker(
                    "Time",
                    selection: $time,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .onChange(of: time) { _, _ in
                    FuelHaptics.shared.select()
                }
            }
            .padding()
            .navigationTitle("\(mealType.displayName) Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        FuelHaptics.shared.tap()
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NotificationsScreen(viewModel: OnboardingViewModel())
}
