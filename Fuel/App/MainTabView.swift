import SwiftUI

/// Main Tab View
/// Primary navigation container with custom tab bar

struct MainTabView: View {
    @Environment(AppState.self) private var appState
    @State private var showAddSheet = false

    var body: some View {
        @Bindable var state = appState

        ZStack(alignment: .bottom) {
            // Tab content
            TabView(selection: $state.selectedTab) {
                DashboardView()
                    .tag(Tab.home)

                FoodSearchView()
                    .tag(Tab.search)

                // Placeholder for add tab (handled by FAB)
                Color.clear
                    .tag(Tab.add)

                ProgressTabView()
                    .tag(Tab.progress)

                ProfileView()
                    .tag(Tab.profile)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // Custom tab bar
            customTabBar
        }
        .ignoresSafeArea(.keyboard)
        .sheet(isPresented: $showAddSheet) {
            AddMealSheet()
                .presentationDetents([.medium, .large])
                .presentationCornerRadius(FuelSpacing.radiusXxl)
        }
    }

    // MARK: - Custom Tab Bar

    private var customTabBar: some View {
        HStack(spacing: 0) {
            tabButton(for: .home)
            tabButton(for: .search)

            // Center FAB
            Button {
                FuelHaptics.shared.impact()
                showAddSheet = true
            } label: {
                ZStack {
                    Circle()
                        .fill(FuelColors.primaryGradient)
                        .frame(width: 56, height: 56)
                        .shadow(color: FuelColors.primary.opacity(0.4), radius: 12, y: 6)

                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            .offset(y: -20)

            tabButton(for: .progress)
            tabButton(for: .profile)
        }
        .padding(.horizontal, FuelSpacing.sm)
        .padding(.top, FuelSpacing.sm)
        .padding(.bottom, FuelSpacing.safeAreaBottom)
        .background(
            FuelColors.surface
                .shadow(color: .black.opacity(0.08), radius: 8, y: -4)
                .ignoresSafeArea(.all, edges: .bottom)
        )
    }

    private func tabButton(for tab: Tab) -> some View {
        let isSelected = appState.selectedTab == tab

        return Button {
            guard !isSelected else { return }
            FuelHaptics.shared.select()
            withAnimation(FuelAnimations.spring) {
                appState.selectedTab = tab
            }
        } label: {
            VStack(spacing: FuelSpacing.xxs) {
                Image(systemName: isSelected ? tab.selectedIcon : tab.icon)
                    .font(.system(size: 22, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? FuelColors.primary : FuelColors.textTertiary)
                    .frame(height: 24)

                Text(tab.title)
                    .font(FuelTypography.caption)
                    .foregroundStyle(isSelected ? FuelColors.primary : FuelColors.textTertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, FuelSpacing.xxs)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Dashboard View

struct DashboardView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: FuelSpacing.lg) {
                    // Header
                    FuelLargeTitleBar(title: "Today", subtitle: formattedDate) {
                        FuelIconButton(icon: "bell") {
                            // Notifications
                        }
                    }

                    // Calorie ring
                    CalorieRing(
                        consumed: appState.dailyCaloriesConsumed,
                        target: appState.dailyCalorieTarget
                    )
                    .padding(.vertical, FuelSpacing.md)

                    // Macro summary
                    MacroSummary(
                        protein: (appState.dailyProtein, 150),
                        carbs: (appState.dailyCarbs, 250),
                        fat: (appState.dailyFat, 65),
                        layout: .horizontal
                    )
                    .padding(.horizontal, FuelSpacing.screenHorizontal)
                    .padding(.vertical, FuelSpacing.md)
                    .background(FuelColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusLg))
                    .padding(.horizontal, FuelSpacing.screenHorizontal)

                    // Meal cards
                    VStack(spacing: FuelSpacing.cardSpacing) {
                        ForEach(MealType.allCases, id: \.self) { mealType in
                            MealCard(
                                mealType: mealType.displayName,
                                mealIcon: mealType.icon,
                                calories: 0,
                                items: [],
                                time: Date(),
                                onTap: {},
                                onAdd: {
                                    appState.showCamera = true
                                }
                            )
                        }
                    }
                    .padding(.horizontal, FuelSpacing.screenHorizontal)

                    // Spacer for tab bar
                    Spacer()
                        .frame(height: 100)
                }
            }
            .background(FuelColors.background)
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: Date())
    }
}

// MARK: - Placeholder Tab Views

struct FoodSearchView: View {
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: FuelSpacing.lg) {
                FuelSearchBar(text: $searchText)
                    .padding(.horizontal, FuelSpacing.screenHorizontal)
                    .padding(.top, FuelSpacing.md)

                if searchText.isEmpty {
                    EmptyState.noSearchResults(query: "")
                } else {
                    // Search results would go here
                    EmptyState.noSearchResults(query: searchText)
                }

                Spacer()
            }
            .background(FuelColors.background)
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct ProgressTabView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: FuelSpacing.lg) {
                    FuelLargeTitleBar(title: "Progress") {
                        FuelSegmentedControl(
                            options: ["Week", "Month", "Year"],
                            selectedIndex: .constant(0)
                        )
                        .frame(width: 180)
                    }

                    // Weight chart placeholder
                    FuelCard {
                        VStack(alignment: .leading, spacing: FuelSpacing.md) {
                            Text("Weight Trend")
                                .font(FuelTypography.headline)
                                .foregroundStyle(FuelColors.textPrimary)

                            Text("Chart coming soon")
                                .font(FuelTypography.body)
                                .foregroundStyle(FuelColors.textSecondary)
                                .frame(height: 200)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal, FuelSpacing.screenHorizontal)

                    // Weekly rings
                    FuelCard {
                        VStack(alignment: .leading, spacing: FuelSpacing.md) {
                            Text("This Week")
                                .font(FuelTypography.headline)
                                .foregroundStyle(FuelColors.textPrimary)

                            WeeklyCalorieRings(dailyData: [
                                (1800, 2000), (2100, 2000), (1950, 2000), (0, 2000),
                                (0, 2000), (0, 2000), (0, 2000)
                            ])
                        }
                    }
                    .padding(.horizontal, FuelSpacing.screenHorizontal)

                    Spacer()
                        .frame(height: 100)
                }
            }
            .background(FuelColors.background)
        }
    }
}

struct ProfileView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: FuelSpacing.lg) {
                    // Profile header
                    VStack(spacing: FuelSpacing.md) {
                        Circle()
                            .fill(FuelColors.primaryLight)
                            .frame(width: 80, height: 80)
                            .overlay(
                                Text("U")
                                    .font(FuelTypography.title1)
                                    .foregroundStyle(FuelColors.primary)
                            )

                        Text("User")
                            .font(FuelTypography.title2)
                            .foregroundStyle(FuelColors.textPrimary)

                        if !appState.isPremium {
                            Button {
                                appState.showPaywall = true
                            } label: {
                                HStack(spacing: FuelSpacing.xs) {
                                    Image(systemName: "crown.fill")
                                    Text("Upgrade to Premium")
                                }
                                .font(FuelTypography.subheadlineMedium)
                                .foregroundStyle(.white)
                                .padding(.horizontal, FuelSpacing.md)
                                .padding(.vertical, FuelSpacing.sm)
                                .background(FuelColors.primaryGradient)
                                .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.vertical, FuelSpacing.xl)

                    // Settings sections
                    settingsSection(title: "Account", items: [
                        ("person.fill", "Personal Info"),
                        ("target", "Goals"),
                        ("bell.fill", "Notifications")
                    ])

                    settingsSection(title: "App", items: [
                        ("paintbrush.fill", "Appearance"),
                        ("hand.raised.fill", "Privacy"),
                        ("questionmark.circle.fill", "Help & Support")
                    ])

                    // Sign out
                    FuelButton("Sign Out", style: .tertiary) {
                        AuthService.shared.signOut()
                    }
                    .padding(.horizontal, FuelSpacing.screenHorizontal)

                    // Version
                    Text("Version 1.0.0")
                        .font(FuelTypography.caption)
                        .foregroundStyle(FuelColors.textTertiary)

                    Spacer()
                        .frame(height: 100)
                }
            }
            .background(FuelColors.background)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func settingsSection(title: String, items: [(String, String)]) -> some View {
        VStack(alignment: .leading, spacing: FuelSpacing.sm) {
            Text(title)
                .font(FuelTypography.caption)
                .foregroundStyle(FuelColors.textTertiary)
                .textCase(.uppercase)
                .padding(.horizontal, FuelSpacing.screenHorizontal)

            VStack(spacing: 0) {
                ForEach(items, id: \.1) { icon, title in
                    HStack(spacing: FuelSpacing.md) {
                        Image(systemName: icon)
                            .font(.system(size: 18))
                            .foregroundStyle(FuelColors.textSecondary)
                            .frame(width: 28)

                        Text(title)
                            .font(FuelTypography.body)
                            .foregroundStyle(FuelColors.textPrimary)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(FuelColors.textTertiary)
                    }
                    .padding(.horizontal, FuelSpacing.md)
                    .padding(.vertical, FuelSpacing.sm)

                    if items.last?.1 != title {
                        Divider()
                            .padding(.leading, FuelSpacing.md + 28 + FuelSpacing.md)
                    }
                }
            }
            .background(FuelColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
            .padding(.horizontal, FuelSpacing.screenHorizontal)
        }
    }
}

// MARK: - Add Meal Sheet

struct AddMealSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState

    var body: some View {
        NavigationStack {
            VStack(spacing: FuelSpacing.xl) {
                // Options
                VStack(spacing: FuelSpacing.md) {
                    addOption(
                        icon: "camera.viewfinder",
                        title: "Scan with AI",
                        subtitle: "Take a photo of your meal"
                    ) {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            appState.showCamera = true
                        }
                    }

                    addOption(
                        icon: "barcode.viewfinder",
                        title: "Scan Barcode",
                        subtitle: "Scan packaged food"
                    ) {
                        // Barcode scanner
                    }

                    addOption(
                        icon: "magnifyingglass",
                        title: "Search Food",
                        subtitle: "Search our database"
                    ) {
                        dismiss()
                        appState.selectedTab = .search
                    }

                    addOption(
                        icon: "plus.circle",
                        title: "Quick Add",
                        subtitle: "Add calories directly"
                    ) {
                        // Quick add
                    }
                }
                .padding(.horizontal, FuelSpacing.screenHorizontal)

                Spacer()
            }
            .padding(.top, FuelSpacing.lg)
            .background(FuelColors.surface)
            .navigationTitle("Add Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        FuelHaptics.shared.tap()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(FuelColors.textSecondary)
                    }
                }
            }
        }
    }

    private func addOption(
        icon: String,
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            FuelHaptics.shared.tap()
            action()
        } label: {
            HStack(spacing: FuelSpacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: FuelSpacing.radiusMd)
                        .fill(FuelColors.primaryLight)
                        .frame(width: 48, height: 48)

                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundStyle(FuelColors.primary)
                }

                VStack(alignment: .leading, spacing: FuelSpacing.xxxs) {
                    Text(title)
                        .font(FuelTypography.headline)
                        .foregroundStyle(FuelColors.textPrimary)

                    Text(subtitle)
                        .font(FuelTypography.caption)
                        .foregroundStyle(FuelColors.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(FuelColors.textTertiary)
            }
            .padding(FuelSpacing.md)
            .background(FuelColors.surfaceSecondary)
            .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusLg))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MainTabView()
        .environment(AppState())
}
