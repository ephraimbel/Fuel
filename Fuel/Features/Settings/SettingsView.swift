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

                    // Debug section (only in debug builds)
                    #if DEBUG
                    debugSection
                    #endif

                    // App info
                    appInfoSection
                }
                .padding(.horizontal, FuelSpacing.screenHorizontal)
                .padding(.bottom, FuelSpacing.screenBottom)
            }
            .scrollIndicators(.hidden)
            .background(FuelColors.backgroundGradient)
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

    // MARK: - Debug Section

    #if DEBUG
    @State private var showingMockDataAlert = false

    private var debugSection: some View {
        SettingsSection(title: "DEVELOPER") {
            Button {
                showingMockDataAlert = true
                FuelHaptics.shared.tap()
            } label: {
                SettingsRow(
                    icon: "wand.and.stars",
                    iconColor: .purple,
                    title: "Load Demo Data",
                    subtitle: "Fill app with sample data",
                    showChevron: false
                )
            }
            .alert("Load Demo Data?", isPresented: $showingMockDataAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Load Data") {
                    loadMockData()
                }
            } message: {
                Text("This will replace all existing data with sample meals, weight entries, and achievements for the past 2 weeks.")
            }

            Button {
                resetOnboarding()
            } label: {
                SettingsRow(
                    icon: "arrow.counterclockwise",
                    iconColor: .orange,
                    title: "Reset Onboarding",
                    subtitle: "Show onboarding again",
                    showChevron: false
                )
            }
        }
    }

    private func loadMockData() {
        MockDataService.shared.generateMockData(in: modelContext)
        FuelHaptics.shared.celebration()
        ToastManager.shared.show("Demo data loaded!", type: .success)
        NotificationCenter.default.post(name: .demoDataLoaded, object: nil)
    }

    private func resetOnboarding() {
        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
        FuelHaptics.shared.tap()
    }
    #endif

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
            .overlay(
                RoundedRectangle(cornerRadius: FuelSpacing.radiusLg)
                    .stroke(FuelColors.border.opacity(0.3), lineWidth: 0.5)
            )
            .cardShadow()
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
    static let demoDataLoaded = Notification.Name("demoDataLoaded")
}

// MARK: - Mock Data Service

#if DEBUG
final class MockDataService {
    static let shared = MockDataService()
    private init() {}

    func generateMockData(in context: ModelContext) {
        // Clear existing data first
        do {
            try context.delete(model: Meal.self)
            try context.delete(model: FoodItem.self)
            try context.delete(model: WeightEntry.self)
            try context.delete(model: Achievement.self)
            try context.delete(model: User.self)
        } catch {
            print("Error clearing data: \(error)")
        }

        // Create user
        let user = createMockUser()
        context.insert(user)

        // Create meals for the past 14 days using MealService flow
        createMockMeals(for: user, days: 14, in: context)

        // Create weight entries for the past 30 days
        createMockWeightEntries(for: user, days: 30, in: context)

        // Create achievements
        createMockAchievements(for: user, in: context)

        // Save
        try? context.save()
    }

    private func createMockUser() -> User {
        let user = User(
            name: "Alex",
            gender: .male,
            heightCm: 178,
            currentWeightKg: 82.5,
            targetWeightKg: 77,
            activityLevel: .moderate,
            fitnessGoal: .lose
        )

        let calendar = Calendar.current
        user.birthDate = calendar.date(byAdding: .year, value: -28, to: Date())
        user.dailyCalorieTarget = 2100
        user.dailyProteinTarget = 165
        user.dailyCarbsTarget = 210
        user.dailyFatTarget = 70
        user.currentStreak = 7
        user.longestStreak = 14
        user.totalMealsLogged = 42
        user.streakLastUpdatedAt = Date()
        user.subscriptionTier = .premium
        user.trialEndsAt = calendar.date(byAdding: .day, value: 7, to: Date())

        return user
    }

    // MARK: - Food Data

    typealias FoodData = (name: String, cal: Int, p: Double, c: Double, f: Double, fiber: Double, sugar: Double, sodium: Double, satFat: Double, chol: Double, source: FoodSource)

    private let breakfastOptions: [[FoodData]] = [
        [("Greek Yogurt", 130, 17.0, 8.0, 3.0, 0.0, 6.0, 65.0, 1.5, 10.0, .database),
         ("Mixed Berries", 60, 1.0, 14.0, 0.5, 3.0, 9.0, 1.0, 0.0, 0.0, .manual),
         ("Granola", 120, 3.0, 20.0, 4.0, 2.0, 6.0, 85.0, 0.5, 0.0, .barcode)],
        [("Scrambled Eggs (2)", 180, 12.0, 2.0, 14.0, 0.0, 1.0, 320.0, 4.0, 370.0, .manual),
         ("Toast", 80, 4.0, 14.0, 1.0, 1.5, 1.5, 150.0, 0.2, 0.0, .database),
         ("Avocado", 120, 1.5, 6.0, 11.0, 5.0, 0.5, 5.0, 1.5, 0.0, .aiScan)],
        [("Oatmeal", 150, 5.0, 27.0, 3.0, 4.0, 1.0, 2.0, 0.5, 0.0, .database),
         ("Banana", 105, 1.3, 27.0, 0.4, 3.0, 14.0, 1.0, 0.1, 0.0, .quickAdd),
         ("Almond Butter", 95, 3.5, 3.0, 8.0, 1.5, 1.0, 35.0, 0.7, 0.0, .barcode)],
        [("Protein Smoothie", 280, 30.0, 25.0, 6.0, 3.0, 18.0, 180.0, 1.0, 15.0, .quickAdd),
         ("Chia Seeds", 60, 2.0, 5.0, 4.0, 5.0, 0.0, 2.0, 0.4, 0.0, .database)]
    ]

    private let lunchOptions: [[FoodData]] = [
        [("Grilled Chicken", 280, 53.0, 0.0, 6.0, 0.0, 0.0, 450.0, 1.5, 125.0, .aiScan),
         ("Mixed Greens", 25, 2.0, 4.0, 0.5, 2.0, 1.0, 30.0, 0.0, 0.0, .manual),
         ("Dressing", 90, 0.0, 1.0, 10.0, 0.0, 1.0, 280.0, 1.5, 5.0, .manual)],
        [("Turkey Sandwich", 350, 30.0, 35.0, 12.0, 3.0, 4.0, 820.0, 3.0, 55.0, .aiScan),
         ("Apple", 95, 0.5, 25.0, 0.3, 4.5, 19.0, 2.0, 0.0, 0.0, .quickAdd)],
        [("Quinoa Bowl", 420, 14.0, 60.0, 12.0, 7.0, 3.0, 380.0, 1.5, 0.0, .database),
         ("Hummus", 70, 2.0, 6.0, 5.0, 1.5, 0.5, 150.0, 0.5, 0.0, .barcode)],
        [("Salmon Poke", 450, 35.0, 45.0, 14.0, 2.0, 8.0, 680.0, 2.5, 65.0, .aiScan)]
    ]

    private let dinnerOptions: [[FoodData]] = [
        [("Atlantic Salmon", 350, 40.0, 0.0, 20.0, 0.0, 0.0, 85.0, 4.0, 95.0, .aiScan),
         ("Asparagus", 40, 4.0, 7.0, 0.5, 3.5, 2.0, 15.0, 0.1, 0.0, .manual),
         ("Sweet Potato", 180, 4.0, 41.0, 0.3, 6.5, 13.0, 70.0, 0.0, 0.0, .database)],
        [("Chicken Stir-fry", 380, 30.0, 25.0, 18.0, 4.0, 6.0, 720.0, 3.5, 85.0, .aiScan),
         ("Jasmine Rice", 200, 4.0, 44.0, 0.5, 0.5, 0.0, 2.0, 0.1, 0.0, .database)],
        [("Lean Beef Pasta", 520, 35.0, 50.0, 18.0, 3.0, 5.0, 650.0, 6.0, 80.0, .aiScan),
         ("Side Salad", 50, 2.0, 8.0, 1.0, 2.5, 3.0, 45.0, 0.1, 0.0, .manual)],
        [("Grilled Fish Tacos", 480, 38.0, 45.0, 16.0, 4.0, 4.0, 580.0, 3.0, 70.0, .aiScan)]
    ]

    private let snackOptions: [[FoodData]] = [
        [("Protein Shake", 150, 25.0, 5.0, 3.0, 1.0, 2.0, 200.0, 0.5, 25.0, .quickAdd)],
        [("Greek Yogurt", 100, 17.0, 6.0, 0.7, 0.0, 4.0, 55.0, 0.4, 8.0, .database)],
        [("Mixed Nuts", 170, 5.0, 6.0, 15.0, 2.0, 1.0, 3.0, 1.5, 0.0, .barcode)],
        [("Protein Bar", 200, 20.0, 22.0, 6.0, 3.0, 8.0, 180.0, 2.5, 5.0, .barcode)],
        [("Hummus & Veggies", 145, 4.0, 15.0, 6.0, 4.0, 3.0, 280.0, 0.8, 0.0, .manual)]
    ]

    // MARK: - Meal Photo URLs

    private let breakfastPhotos = [
        "https://images.unsplash.com/photo-1533089860892-a7c6f0a88666?w=400&h=400&fit=crop",
        "https://images.unsplash.com/photo-1525351484163-7529414344d8?w=400&h=400&fit=crop",
        "https://images.unsplash.com/photo-1494597564530-871f2b93ac55?w=400&h=400&fit=crop",
        "https://images.unsplash.com/photo-1484723091739-30a097e8f929?w=400&h=400&fit=crop",
        "https://images.unsplash.com/photo-1517673132405-a56a62b18caf?w=400&h=400&fit=crop"
    ]

    private let lunchPhotos = [
        "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400&h=400&fit=crop",
        "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400&h=400&fit=crop",
        "https://images.unsplash.com/photo-1547592180-85f173990554?w=400&h=400&fit=crop",
        "https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?w=400&h=400&fit=crop",
        "https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=400&h=400&fit=crop"
    ]

    private let dinnerPhotos = [
        "https://images.unsplash.com/photo-1467003909585-2f8a72700288?w=400&h=400&fit=crop",
        "https://images.unsplash.com/photo-1432139555190-58524dae6a55?w=400&h=400&fit=crop",
        "https://images.unsplash.com/photo-1473093295043-cdd812d0e601?w=400&h=400&fit=crop",
        "https://images.unsplash.com/photo-1559847844-5315695dadae?w=400&h=400&fit=crop",
        "https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=400&h=400&fit=crop"
    ]

    private let snackPhotos = [
        "https://images.unsplash.com/photo-1571091718767-18b5b1457add?w=400&h=400&fit=crop",
        "https://images.unsplash.com/photo-1486297678162-eb2a19b0a32d?w=400&h=400&fit=crop",
        "https://images.unsplash.com/photo-1599490659213-e2b9527bd087?w=400&h=400&fit=crop",
        "https://images.unsplash.com/photo-1621939514649-280e2ee25f60?w=400&h=400&fit=crop",
        "https://images.unsplash.com/photo-1470119693884-47d3a1d1f180?w=400&h=400&fit=crop"
    ]

    private func photoURL(for type: MealType) -> String? {
        switch type {
        case .breakfast: return breakfastPhotos.randomElement()
        case .lunch: return lunchPhotos.randomElement()
        case .dinner: return dinnerPhotos.randomElement()
        case .snack: return snackPhotos.randomElement()
        }
    }

    // MARK: - Create Meals via MealService

    private func createMockMeals(for user: User, days: Int, in context: ModelContext) {
        let calendar = Calendar.current
        let service = MealService.shared

        for dayOffset in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }

            // Breakfast
            let breakfastFoods = breakfastOptions.randomElement()!
            for food in breakfastFoods {
                let item = makeFoodItem(from: food)
                service.addFoodItem(item, to: .breakfast, date: date, in: context)
            }
            let breakfast = service.getOrCreateMeal(type: .breakfast, date: date, in: context)
            breakfast.photoURL = photoURL(for: .breakfast)
            breakfast.user = user

            // Lunch
            let lunchFoods = lunchOptions.randomElement()!
            for food in lunchFoods {
                let item = makeFoodItem(from: food)
                service.addFoodItem(item, to: .lunch, date: date, in: context)
            }
            let lunch = service.getOrCreateMeal(type: .lunch, date: date, in: context)
            lunch.photoURL = photoURL(for: .lunch)
            lunch.user = user

            // Dinner
            let dinnerFoods = dinnerOptions.randomElement()!
            for food in dinnerFoods {
                let item = makeFoodItem(from: food)
                service.addFoodItem(item, to: .dinner, date: date, in: context)
            }
            let dinner = service.getOrCreateMeal(type: .dinner, date: date, in: context)
            dinner.photoURL = photoURL(for: .dinner)
            dinner.user = user

            // Snack (50% chance)
            if Bool.random() {
                let snackFoods = snackOptions.randomElement()!
                for food in snackFoods {
                    let item = makeFoodItem(from: food)
                    service.addFoodItem(item, to: .snack, date: date, in: context)
                }
                let snack = service.getOrCreateMeal(type: .snack, date: date, in: context)
                snack.photoURL = photoURL(for: .snack)
                snack.user = user
            }
        }
    }

    private func makeFoodItem(from food: FoodData) -> FoodItem {
        FoodItem(
            name: food.name,
            servingSize: 1,
            servingUnit: "serving",
            calories: food.cal,
            protein: food.p,
            carbs: food.c,
            fat: food.f,
            fiber: food.fiber,
            sugar: food.sugar,
            sodium: food.sodium,
            saturatedFat: food.satFat,
            cholesterol: food.chol,
            source: food.source
        )
    }

    // MARK: - Weight Entries

    private func createMockWeightEntries(for user: User, days: Int, in context: ModelContext) {
        let calendar = Calendar.current
        let startWeight = 85.0
        let currentWeight = 82.5
        let weightLoss = startWeight - currentWeight

        for dayOffset in stride(from: days, through: 0, by: -3) {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }

            let progress = 1.0 - (Double(dayOffset) / Double(days))
            let targetWeight = startWeight - (weightLoss * progress)
            let variance = Double.random(in: -0.4...0.4)

            let entry = WeightEntry(weightKg: targetWeight + variance, recordedAt: date, source: .manual)
            entry.user = user
            context.insert(entry)
        }
    }

    // MARK: - Achievements

    private func createMockAchievements(for user: User, in context: ModelContext) {
        let calendar = Calendar.current

        // Unlocked achievements
        let unlocked: [AchievementType] = [.firstDay, .firstMeal, .firstWeighIn, .firstScan, .streak3, .streak7, .meals10, .perfectDay]
        for (index, type) in unlocked.enumerated() {
            let achievement = Achievement(achievementType: type)
            achievement.isUnlocked = true
            achievement.progress = 1.0
            achievement.currentValue = type.targetValue
            achievement.unlockedAt = calendar.date(byAdding: .day, value: -(index * 2), to: Date())
            achievement.user = user
            context.insert(achievement)
        }

        // In-progress
        let inProgress: [(AchievementType, Int)] = [(.streak14, 7), (.meals50, 42), (.scans25, 12)]
        for (type, current) in inProgress {
            let achievement = Achievement(achievementType: type)
            achievement.currentValue = current
            achievement.progress = Double(current) / Double(type.targetValue)
            achievement.user = user
            context.insert(achievement)
        }
    }
}
#endif

// MARK: - Preview

#Preview {
    SettingsView()
}
