import SwiftUI

/// Personal Info Settings View
/// Edit height, weight, and activity level

struct PersonalInfoSettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var heightCm: Double = 175
    @State private var weightKg: Double = 75
    @State private var activityLevel: ActivityLevel = .moderate
    @State private var gender: Gender = .male
    @State private var birthYear: Int = 1990

    @State private var useMetric = true
    @State private var hasChanges = false

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
        FuelHaptics.shared.success()
        // TODO: Save info and recalculate goals
        hasChanges = false
    }
}

// MARK: - Activity Level

enum ActivityLevel: String, CaseIterable {
    case sedentary
    case light
    case moderate
    case active
    case veryActive

    var displayName: String {
        switch self {
        case .sedentary: return "Sedentary"
        case .light: return "Lightly Active"
        case .moderate: return "Moderately Active"
        case .active: return "Active"
        case .veryActive: return "Very Active"
        }
    }

    var description: String {
        switch self {
        case .sedentary: return "Little to no exercise"
        case .light: return "Light exercise 1-3 days/week"
        case .moderate: return "Moderate exercise 3-5 days/week"
        case .active: return "Hard exercise 6-7 days/week"
        case .veryActive: return "Very hard exercise, physical job"
        }
    }

    var icon: String {
        switch self {
        case .sedentary: return "figure.stand"
        case .light: return "figure.walk"
        case .moderate: return "figure.run"
        case .active: return "figure.highintensity.intervaltraining"
        case .veryActive: return "flame.fill"
        }
    }

    var multiplier: Double {
        switch self {
        case .sedentary: return 1.2
        case .light: return 1.375
        case .moderate: return 1.55
        case .active: return 1.725
        case .veryActive: return 1.9
        }
    }
}

// MARK: - Gender

enum Gender: String, CaseIterable {
    case male
    case female
    case other

    var displayName: String {
        switch self {
        case .male: return "Male"
        case .female: return "Female"
        case .other: return "Other"
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PersonalInfoSettingsView()
    }
}
