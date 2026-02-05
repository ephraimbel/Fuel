import SwiftUI
import SwiftData

/// Personal Info Settings View
/// Edit height, weight, and activity level

struct PersonalInfoSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var heightCm: Double = 175
    @State private var weightKg: Double = 75
    @State private var activityLevel: ActivityLevel = .moderate
    @State private var gender: Gender = .male
    @State private var birthYear: Int = 1990

    @State private var useMetric = true
    @State private var hasChanges = false
    @State private var isLoaded = false

    var body: some View {
        ScrollView {
            VStack(spacing: FuelSpacing.xl) {
                // Basic info
                basicInfoSection

                // Body measurements
                measurementsSection

                // Activity level
                activitySection

                // Recalculate note
                recalculateNote
            }
            .padding(.horizontal, FuelSpacing.screenHorizontal)
            .padding(.vertical, FuelSpacing.lg)
        }
        .background(FuelColors.background)
        .navigationTitle("Personal Info")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if hasChanges {
                    Button("Save") {
                        saveInfo()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            loadUserInfo()
        }
    }

    // MARK: - Data Loading

    private func loadUserInfo() {
        guard !isLoaded else { return }

        let descriptor = FetchDescriptor<User>()
        guard let user = try? modelContext.fetch(descriptor).first else { return }

        heightCm = user.heightCm
        weightKg = user.currentWeightKg
        activityLevel = user.activityLevel
        gender = user.gender

        // Calculate birth year from birthDate
        if let birthDate = user.birthDate {
            let calendar = Calendar.current
            birthYear = calendar.component(.year, from: birthDate)
        }

        // Set unit preference
        useMetric = user.preferredUnits == .metric

        isLoaded = true
    }

    // MARK: - Basic Info Section

    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: FuelSpacing.sm) {
            Text("BASIC INFO")
                .font(FuelTypography.caption)
                .foregroundStyle(FuelColors.textTertiary)

            VStack(spacing: 0) {
                // Gender
                HStack {
                    Text("Gender")
                        .font(FuelTypography.subheadline)
                        .foregroundStyle(FuelColors.textPrimary)

                    Spacer()

                    Picker("Gender", selection: $gender) {
                        ForEach(Gender.allCases, id: \.self) { gender in
                            Text(gender.displayName).tag(gender)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(FuelColors.primary)
                    .onChange(of: gender) { _, _ in
                        hasChanges = true
                    }
                }
                .padding(FuelSpacing.md)

                Divider()
                    .padding(.leading, FuelSpacing.md)

                // Birth year
                HStack {
                    Text("Birth Year")
                        .font(FuelTypography.subheadline)
                        .foregroundStyle(FuelColors.textPrimary)

                    Spacer()

                    Picker("Birth Year", selection: $birthYear) {
                        ForEach((1940...2010).reversed(), id: \.self) { year in
                            Text(String(year)).tag(year)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(FuelColors.primary)
                    .onChange(of: birthYear) { _, _ in
                        hasChanges = true
                    }
                }
                .padding(FuelSpacing.md)
            }
            .background(FuelColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
        }
    }

    // MARK: - Measurements Section

    private var measurementsSection: some View {
        VStack(alignment: .leading, spacing: FuelSpacing.sm) {
            HStack {
                Text("MEASUREMENTS")
                    .font(FuelTypography.caption)
                    .foregroundStyle(FuelColors.textTertiary)

                Spacer()

                // Unit toggle
                Button {
                    useMetric.toggle()
                    FuelHaptics.shared.tap()
                } label: {
                    Text(useMetric ? "Metric" : "Imperial")
                        .font(FuelTypography.caption)
                        .foregroundStyle(FuelColors.primary)
                }
            }

            VStack(spacing: FuelSpacing.md) {
                // Height
                VStack(alignment: .leading, spacing: FuelSpacing.sm) {
                    Text("Height")
                        .font(FuelTypography.subheadline)
                        .foregroundStyle(FuelColors.textSecondary)

                    HStack {
                        Text(formattedHeight)
                            .font(FuelTypography.title2)
                            .foregroundStyle(FuelColors.textPrimary)

                        Spacer()

                        Stepper("", value: $heightCm, in: 120...220, step: 1)
                            .labelsHidden()
                            .onChange(of: heightCm) { _, _ in
                                hasChanges = true
                                FuelHaptics.shared.select()
                            }
                    }

                    Slider(value: $heightCm, in: 120...220, step: 1)
                        .tint(FuelColors.primary)
                        .onChange(of: heightCm) { _, _ in
                            hasChanges = true
                        }
                }

                Divider()

                // Weight
                VStack(alignment: .leading, spacing: FuelSpacing.sm) {
                    Text("Current Weight")
                        .font(FuelTypography.subheadline)
                        .foregroundStyle(FuelColors.textSecondary)

                    HStack {
                        Text(formattedWeight)
                            .font(FuelTypography.title2)
                            .foregroundStyle(FuelColors.textPrimary)

                        Spacer()

                        Stepper("", value: $weightKg, in: 30...200, step: 0.5)
                            .labelsHidden()
                            .onChange(of: weightKg) { _, _ in
                                hasChanges = true
                                FuelHaptics.shared.select()
                            }
                    }

                    Slider(value: $weightKg, in: 30...200, step: 0.5)
                        .tint(FuelColors.primary)
                        .onChange(of: weightKg) { _, _ in
                            hasChanges = true
                        }
                }
            }
            .padding(FuelSpacing.md)
            .background(FuelColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
        }
    }

    // MARK: - Activity Section

    private var activitySection: some View {
        VStack(alignment: .leading, spacing: FuelSpacing.sm) {
            Text("ACTIVITY LEVEL")
                .font(FuelTypography.caption)
                .foregroundStyle(FuelColors.textTertiary)

            VStack(spacing: 0) {
                ForEach(ActivityLevel.allCases, id: \.self) { level in
                    activityRow(level)

                    if level != ActivityLevel.allCases.last {
                        Divider()
                            .padding(.leading, FuelSpacing.md + 32 + FuelSpacing.md)
                    }
                }
            }
            .background(FuelColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
        }
    }

    private func activityRow(_ level: ActivityLevel) -> some View {
        Button {
            activityLevel = level
            hasChanges = true
            FuelHaptics.shared.select()
        } label: {
            HStack(spacing: FuelSpacing.md) {
                // Icon
                Image(systemName: level.icon)
                    .font(.system(size: 18))
                    .foregroundStyle(activityLevel == level ? FuelColors.primary : FuelColors.textSecondary)
                    .frame(width: 32)

                // Text
                VStack(alignment: .leading, spacing: FuelSpacing.xxxs) {
                    Text(level.displayName)
                        .font(FuelTypography.subheadlineMedium)
                        .foregroundStyle(FuelColors.textPrimary)

                    Text(level.description)
                        .font(FuelTypography.caption)
                        .foregroundStyle(FuelColors.textTertiary)
                }

                Spacer()

                // Checkmark
                if activityLevel == level {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(FuelColors.primary)
                }
            }
            .padding(FuelSpacing.md)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Recalculate Note

    private var recalculateNote: some View {
        HStack(spacing: FuelSpacing.sm) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(FuelColors.primary)

            Text("Changing your personal info will recalculate your recommended calorie goal.")
                .font(FuelTypography.caption)
                .foregroundStyle(FuelColors.textSecondary)
        }
        .padding(FuelSpacing.md)
        .background(FuelColors.primaryLight)
        .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
    }

    // MARK: - Computed Properties

    private var formattedHeight: String {
        if useMetric {
            return "\(Int(heightCm)) cm"
        } else {
            let totalInches = heightCm / 2.54
            let feet = Int(totalInches / 12)
            let inches = Int(totalInches.truncatingRemainder(dividingBy: 12))
            return "\(feet)' \(inches)\""
        }
    }

    private var formattedWeight: String {
        if useMetric {
            return String(format: "%.1f kg", weightKg)
        } else {
            let lbs = weightKg * 2.20462
            return String(format: "%.1f lbs", lbs)
        }
    }

    // MARK: - Actions

    private func saveInfo() {
        let descriptor = FetchDescriptor<User>()
        guard let user = try? modelContext.fetch(descriptor).first else {
            FuelHaptics.shared.error()
            return
        }

        // Update personal info
        user.heightCm = heightCm
        user.currentWeightKg = weightKg
        user.activityLevel = activityLevel
        user.gender = gender
        user.preferredUnits = useMetric ? .metric : .imperial
        user.lastActiveAt = Date()

        // Convert birth year to birth date (January 1st of that year)
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = birthYear
        components.month = 1
        components.day = 1
        user.birthDate = calendar.date(from: components)

        // Recalculate TDEE and goals based on new personal info
        user.dailyCalorieTarget = user.calculateCalorieTarget()
        let macros = user.calculateMacroTargets()
        user.dailyProteinTarget = macros.protein
        user.dailyCarbsTarget = macros.carbs
        user.dailyFatTarget = macros.fat

        // Persist changes
        do {
            try modelContext.save()
            hasChanges = false
            FuelHaptics.shared.success()
        } catch {
            FuelHaptics.shared.error()
            #if DEBUG
            print("Failed to save personal info: \(error)")
            #endif
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PersonalInfoSettingsView()
    }
}
