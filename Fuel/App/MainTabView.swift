import SwiftUI

/// Main Tab View
/// Primary navigation container with custom tab bar

enum FullScreenDestination: Identifiable {
    case foodScanner
    case createFood

    var id: String {
        switch self {
        case .foodScanner: return "foodScanner"
        case .createFood: return "createFood"
        }
    }
}

struct MainTabView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    @State private var fullScreenDestination: FullScreenDestination?
    @State private var showQuickAdd = false
    @State private var showPreviousMeals = false
    @State private var selectedMealType: MealType = .suggested()

    private var showAddSheet: Binding<Bool> {
        Binding(
            get: { appState.showAddMealSheet },
            set: { appState.showAddMealSheet = $0 }
        )
    }

    var body: some View {
        @Bindable var state = appState

        ZStack(alignment: .bottom) {
            // Tab content - direct view switching for instant, glitch-free transitions
            Group {
                switch state.selectedTab {
                case .home:
                    DashboardView()
                case .history:
                    NavigationStack {
                        MealHistoryView()
                    }
                case .progress:
                    ProgressScreen()
                case .profile:
                    SettingsView()
                }
            }
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.15), value: state.selectedTab)

            // Custom tab bar
            customTabBar
        }
        .ignoresSafeArea(.keyboard)
        .sheet(isPresented: showAddSheet) {
            AddMealSheet(
                onScanMeal: {
                    appState.showAddMealSheet = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        fullScreenDestination = .foodScanner
                    }
                },
                onPreviousMeals: {
                    appState.showAddMealSheet = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showPreviousMeals = true
                    }
                },
                onQuickAdd: {
                    appState.showAddMealSheet = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showQuickAdd = true
                    }
                },
                onCreateFood: {
                    appState.showAddMealSheet = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        fullScreenDestination = .createFood
                    }
                }
            )
            .presentationDetents([.height(360)])
            .presentationCornerRadius(FuelSpacing.radiusXxl)
        }
        .fullScreenCover(item: $fullScreenDestination) { destination in
            switch destination {
            case .foodScanner:
                FoodScannerView()
                    .environment(appState)
            case .createFood:
                NavigationStack {
                    CreateCustomFoodView(mealType: selectedMealType) { foodItem in
                        MealService.shared.addFoodItem(
                            foodItem,
                            to: selectedMealType,
                            date: Date(),
                            in: modelContext
                        )
                        FuelHaptics.shared.success()
                        fullScreenDestination = nil
                    }
                }
            }
        }
        .sheet(isPresented: $showQuickAdd) {
            QuickAddView(mealType: selectedMealType) { foodItem in
                MealService.shared.addFoodItem(
                    foodItem,
                    to: selectedMealType,
                    date: Date(),
                    in: modelContext
                )
                FuelHaptics.shared.success()
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showPreviousMeals) {
            PreviousMealsView()
                .presentationDetents([.medium, .large])
        }
    }

    // MARK: - Custom Tab Bar

    private var customTabBar: some View {
        VStack {
            Spacer()

            HStack(alignment: .bottom, spacing: 12) {
                // Tab buttons in glass capsule
                HStack(spacing: 0) {
                    ForEach(Tab.allCases, id: \.self) { tab in
                        tabButton(for: tab)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Capsule()
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            .white.opacity(0.5),
                                            .white.opacity(0.1),
                                            .clear
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .shadow(color: .black.opacity(0.15), radius: 24, y: 10)
                )

                // Add Button
                Button {
                    FuelHaptics.shared.impact()
                    selectedMealType = .suggested()
                    appState.showAddMealSheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(FuelColors.primary)
                        .clipShape(Circle())
                        .shadow(color: FuelColors.primary.opacity(0.25), radius: 12, y: 6)
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(.horizontal, FuelSpacing.screenHorizontal)
            .padding(.bottom, 8)
        }
    }

    private func tabButton(for tab: Tab) -> some View {
        let isSelected = appState.selectedTab == tab

        return Button {
            guard !isSelected else { return }
            FuelHaptics.shared.select()
            appState.selectedTab = tab
        } label: {
            Image(systemName: isSelected ? tab.selectedIcon : tab.icon)
                .font(.system(size: 22, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? FuelColors.primary : FuelColors.textTertiary)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(isSelected ? FuelColors.primary.opacity(0.15) : .clear)
                )
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Scale Button Style

struct ScaleButtonStyle: ButtonStyle {
    var scale: Double = 0.96

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Add Meal Sheet

struct AddMealSheet: View {
    @Environment(\.dismiss) private var dismiss

    let onScanMeal: () -> Void
    let onPreviousMeals: () -> Void
    let onQuickAdd: () -> Void
    let onCreateFood: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Handle
            Capsule()
                .fill(Color(.systemGray4))
                .frame(width: 36, height: 5)
                .padding(.top, FuelSpacing.sm)
                .padding(.bottom, FuelSpacing.xl)

            // Title
            Text("Log Food")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(FuelColors.textPrimary)
                .padding(.bottom, FuelSpacing.xl)

            // Options
            VStack(spacing: FuelSpacing.sm) {
                // Primary action - Scan Meal
                primaryOption(
                    icon: "camera.viewfinder",
                    title: "Scan Meal",
                    subtitle: "AI camera, barcode, or photo"
                ) {
                    onScanMeal()
                }

                // Previous Meals
                primaryOption(
                    icon: "clock.arrow.circlepath",
                    title: "Previous Meals",
                    subtitle: "Re-log a meal you've had before",
                    accentColor: Color(.systemGreen)
                ) {
                    onPreviousMeals()
                }

                // Secondary actions
                HStack(spacing: FuelSpacing.sm) {
                    secondaryOption(
                        icon: "flame",
                        title: "Quick Add",
                        color: Color(.systemOrange)
                    ) {
                        onQuickAdd()
                    }

                    secondaryOption(
                        icon: "plus.square",
                        title: "Create",
                        color: Color(.systemBlue)
                    ) {
                        onCreateFood()
                    }
                }
            }
            .padding(.horizontal, FuelSpacing.screenHorizontal)

            Spacer()
        }
        .background(FuelColors.surface)
    }

    // Primary action button (full width, prominent)
    private func primaryOption(
        icon: String,
        title: String,
        subtitle: String,
        accentColor: Color? = nil,
        action: @escaping () -> Void
    ) -> some View {
        let color = accentColor ?? FuelColors.primary
        return Button {
            FuelHaptics.shared.tap()
            action()
        } label: {
            HStack(spacing: FuelSpacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(color)
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(FuelColors.textPrimary)

                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(FuelColors.textSecondary)
                }

                Spacer()

                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(color)
            }
            .padding(FuelSpacing.md)
            .background(color.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusLg))
            .overlay(
                RoundedRectangle(cornerRadius: FuelSpacing.radiusLg)
                    .stroke(color.opacity(0.15), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // Secondary action button (compact, side by side)
    private func secondaryOption(
        icon: String,
        title: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            FuelHaptics.shared.tap()
            action()
        } label: {
            VStack(spacing: FuelSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(color)
                    .frame(width: 52, height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(color.opacity(0.1))
                    )

                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(FuelColors.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, FuelSpacing.md)
            .background(FuelColors.surfaceSecondary)
            .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusLg))
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

#Preview {
    MainTabView()
        .environment(AppState())
}
