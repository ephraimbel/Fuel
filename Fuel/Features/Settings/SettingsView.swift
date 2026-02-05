import SwiftUI
import SwiftData

/// Settings View
/// Main settings screen with all app configuration options

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var showingSignOutAlert = false
    @State private var showingDeleteAccountAlert = false
    @State private var isProcessing = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: FuelSpacing.sectionSpacing) {
                    // Profile section
                    profileSection

                    // Goals section
                    goalsSection

                    // Preferences section
                    preferencesSection

                    // Notifications section
                    notificationsSection

                    // Data section
                    dataSection

                    // Support section
                    supportSection

                    // Account section
                    accountSection

                    // App info
                    appInfoSection
                }
                .padding(.horizontal, FuelSpacing.screenHorizontal)
                .padding(.bottom, FuelSpacing.screenBottom)
            }
            .scrollIndicators(.hidden)
            .background(FuelColors.background)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        FuelHaptics.shared.tap()
                        dismiss()
                    }
                }
            }
            .alert("Sign Out", isPresented: $showingSignOutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .alert("Delete Account", isPresented: $showingDeleteAccountAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    deleteAccount()
                }
            } message: {
                Text("This will permanently delete your account and all data. This action cannot be undone.")
            }
        }
    }

    // MARK: - Profile Section

    private var profileSection: some View {
        SettingsSection(title: "PROFILE") {
            NavigationLink {
                ProfileSettingsView()
            } label: {
                SettingsRow(
                    icon: "person.fill",
                    iconColor: FuelColors.primary,
                    title: "Edit Profile",
                    subtitle: "Name, photo, email"
                )
            }
        }
    }

    // MARK: - Goals Section

    private var goalsSection: some View {
        SettingsSection(title: "GOALS") {
            NavigationLink {
                GoalSettingsView()
            } label: {
                SettingsRow(
                    icon: "target",
                    iconColor: FuelColors.success,
                    title: "Calorie & Macro Goals",
                    subtitle: "Daily targets"
                )
            }

            NavigationLink {
                PersonalInfoSettingsView()
            } label: {
                SettingsRow(
                    icon: "figure.stand",
                    iconColor: FuelColors.textSecondary,
                    title: "Personal Info",
                    subtitle: "Height, weight, activity"
                )
            }
        }
    }

    // MARK: - Preferences Section

    private var preferencesSection: some View {
        SettingsSection(title: "PREFERENCES") {
            NavigationLink {
                UnitsSettingsView()
            } label: {
                SettingsRow(
                    icon: "ruler",
                    iconColor: FuelColors.gold,
                    title: "Units",
                    subtitle: "Weight, height, energy"
                )
            }

            NavigationLink {
                AppearanceSettingsView()
            } label: {
                SettingsRow(
                    icon: "paintbrush.fill",
                    iconColor: .purple,
                    title: "Appearance",
                    subtitle: "Theme, display"
                )
            }

            NavigationLink {
                HapticsSettingsView()
            } label: {
                SettingsRow(
                    icon: "hand.tap.fill",
                    iconColor: .orange,
                    title: "Haptics & Sounds",
                    subtitle: "Feedback preferences"
                )
            }
        }
    }

    // MARK: - Notifications Section

    private var notificationsSection: some View {
        SettingsSection(title: "NOTIFICATIONS") {
            NavigationLink {
                NotificationSettingsView()
            } label: {
                SettingsRow(
                    icon: "bell.fill",
                    iconColor: .red,
                    title: "Reminders",
                    subtitle: "Meal logging reminders"
                )
            }
        }
    }

    // MARK: - Data Section

    private var dataSection: some View {
        SettingsSection(title: "DATA") {
            NavigationLink {
                DataExportView()
            } label: {
                SettingsRow(
                    icon: "square.and.arrow.up",
                    iconColor: .blue,
                    title: "Export Data",
                    subtitle: "Download your data"
                )
            }

            NavigationLink {
                PrivacySettingsView()
            } label: {
                SettingsRow(
                    icon: "hand.raised.fill",
                    iconColor: .indigo,
                    title: "Privacy",
                    subtitle: "Data & privacy settings"
                )
            }
        }
    }

    // MARK: - Support Section

    private var supportSection: some View {
        SettingsSection(title: "SUPPORT") {
            NavigationLink {
                HelpCenterView()
            } label: {
                SettingsRow(
                    icon: "questionmark.circle.fill",
                    iconColor: .cyan,
                    title: "Help Center",
                    subtitle: "FAQs and guides"
                )
            }

            Button {
                sendFeedback()
            } label: {
                SettingsRow(
                    icon: "envelope.fill",
                    iconColor: .green,
                    title: "Send Feedback",
                    subtitle: "Report issues or suggestions"
                )
            }

            NavigationLink {
                AboutView()
            } label: {
                SettingsRow(
                    icon: "info.circle.fill",
                    iconColor: .gray,
                    title: "About",
                    subtitle: "Version, terms, privacy"
                )
            }
        }
    }

    // MARK: - Account Section

    private var accountSection: some View {
        SettingsSection(title: "ACCOUNT") {
            NavigationLink {
                SubscriptionSettingsView()
            } label: {
                SettingsRow(
                    icon: "crown.fill",
                    iconColor: FuelColors.gold,
                    title: "Subscription",
                    subtitle: "Manage your plan"
                )
            }

            Button {
                showingSignOutAlert = true
                FuelHaptics.shared.tap()
            } label: {
                SettingsRow(
                    icon: "rectangle.portrait.and.arrow.right",
                    iconColor: FuelColors.textSecondary,
                    title: "Sign Out",
                    showChevron: false
                )
            }

            Button {
                showingDeleteAccountAlert = true
                FuelHaptics.shared.warning()
            } label: {
                SettingsRow(
                    icon: "trash.fill",
                    iconColor: FuelColors.error,
                    title: "Delete Account",
                    titleColor: FuelColors.error,
                    showChevron: false
                )
            }
        }
    }

    // MARK: - App Info Section

    private var appInfoSection: some View {
        VStack(spacing: FuelSpacing.sm) {
            Image(systemName: "flame.fill")
                .font(.system(size: 32))
                .foregroundStyle(FuelColors.primary)

            Text("Fuel")
                .font(FuelTypography.headline)
                .foregroundStyle(FuelColors.textPrimary)

            Text("Version \(appVersion)")
                .font(FuelTypography.caption)
                .foregroundStyle(FuelColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, FuelSpacing.xl)
        .padding(.bottom, FuelSpacing.lg)
    }

    // MARK: - Computed Properties

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    // MARK: - Actions

    private func signOut() {
        guard !isProcessing else { return }
        isProcessing = true
        FuelHaptics.shared.tap()

        // Sign out from auth service
        AuthService.shared.signOut()

        isProcessing = false
        // Post notification to reset app state to onboarding
        NotificationCenter.default.post(name: .userDidSignOut, object: nil)
        dismiss()
    }

    private func deleteAccount() {
        guard !isProcessing else { return }
        isProcessing = true
        FuelHaptics.shared.heavy()

        // First, sign out from auth
        AuthService.shared.signOut()

        // Delete all user data from SwiftData
        deleteAllUserData()

        isProcessing = false
        // Post notification to reset app state to onboarding
        NotificationCenter.default.post(name: .userDidDeleteAccount, object: nil)
        dismiss()
    }

    private func deleteAllUserData() {
        // Delete all meals
        let mealDescriptor = FetchDescriptor<Meal>()
        if let meals = try? modelContext.fetch(mealDescriptor) {
            for meal in meals {
                modelContext.delete(meal)
            }
        }

        // Delete all food items
        let foodDescriptor = FetchDescriptor<FoodItem>()
        if let foods = try? modelContext.fetch(foodDescriptor) {
            for food in foods {
                modelContext.delete(food)
            }
        }

        // Delete all weight entries
        let weightDescriptor = FetchDescriptor<WeightEntry>()
        if let entries = try? modelContext.fetch(weightDescriptor) {
            for entry in entries {
                modelContext.delete(entry)
            }
        }

        // Delete all achievements
        let achievementDescriptor = FetchDescriptor<Achievement>()
        if let achievements = try? modelContext.fetch(achievementDescriptor) {
            for achievement in achievements {
                modelContext.delete(achievement)
            }
        }

        // Delete user profile
        let userDescriptor = FetchDescriptor<User>()
        if let users = try? modelContext.fetch(userDescriptor) {
            for user in users {
                // Delete profile photo if exists
                if let avatarPath = user.avatarURL {
                    try? FileManager.default.removeItem(atPath: avatarPath)
                }
                modelContext.delete(user)
            }
        }

        // Save changes
        try? modelContext.save()
    }

    private func sendFeedback() {
        FuelHaptics.shared.tap()
        // Open email composer or feedback form
        if let url = URL(string: "mailto:support@fuel.app?subject=Fuel%20Feedback") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Settings Section

struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String?
    @ViewBuilder let content: Content

    init(title: String, icon: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header
            HStack(spacing: FuelSpacing.xs) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(FuelColors.textTertiary)
                }

                Text(title)
                    .font(FuelTypography.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(FuelColors.textTertiary)
                    .textCase(.uppercase)
                    .tracking(0.5)

                Spacer()
            }
            .padding(.bottom, FuelSpacing.xs)

            VStack(spacing: 0) {
                content
            }
            .background(FuelColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusLg))
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        }
    }
}

// MARK: - Settings Row

struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    var subtitle: String? = nil
    var titleColor: Color = FuelColors.textPrimary
    var showChevron: Bool = true

    var body: some View {
        HStack(spacing: FuelSpacing.md) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(iconColor)
                .frame(width: 32, height: 32)
                .background(iconColor.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusSm))

            // Text
            VStack(alignment: .leading, spacing: FuelSpacing.xxxs) {
                Text(title)
                    .font(FuelTypography.subheadlineMedium)
                    .foregroundStyle(titleColor)

                if let subtitle {
                    Text(subtitle)
                        .font(FuelTypography.caption)
                        .foregroundStyle(FuelColors.textTertiary)
                }
            }

            Spacer()

            // Chevron
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(FuelColors.textTertiary)
            }
        }
        .padding(FuelSpacing.md)
        .contentShape(Rectangle())
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let userDidSignOut = Notification.Name("userDidSignOut")
    static let userDidDeleteAccount = Notification.Name("userDidDeleteAccount")
}

// MARK: - Preview

#Preview {
    SettingsView()
}
