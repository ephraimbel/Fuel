import SwiftUI

/// Units Settings View
/// Configure measurement units for the app

struct UnitsSettingsView: View {
    @State private var weightUnit: WeightUnit = .kg
    @State private var heightUnit: HeightUnit = .cm
    @State private var energyUnit: EnergyUnit = .calories

    var body: some View {
        ScrollView {
            VStack(spacing: FuelSpacing.xl) {
                // Weight unit
                unitSection(
                    title: "WEIGHT",
                    icon: "scalemass.fill",
                    iconColor: .blue,
                    selection: $weightUnit,
                    options: WeightUnit.allCases
                )

                // Height unit
                unitSection(
                    title: "HEIGHT",
                    icon: "ruler.fill",
                    iconColor: .green,
                    selection: $heightUnit,
                    options: HeightUnit.allCases
                )

                // Energy unit
                unitSection(
                    title: "ENERGY",
                    icon: "flame.fill",
                    iconColor: .orange,
                    selection: $energyUnit,
                    options: EnergyUnit.allCases
                )
            }
            .padding(.horizontal, FuelSpacing.screenHorizontal)
            .padding(.vertical, FuelSpacing.lg)
        }
        .background(FuelColors.background)
        .navigationTitle("Units")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Unit Section

    private func unitSection<T: UnitOption>(
        title: String,
        icon: String,
        iconColor: Color,
        selection: Binding<T>,
        options: [T]
    ) -> some View {
        VStack(alignment: .leading, spacing: FuelSpacing.sm) {
            Text(title)
                .font(FuelTypography.caption)
                .foregroundStyle(FuelColors.textTertiary)

            VStack(spacing: 0) {
                // Header
                HStack(spacing: FuelSpacing.md) {
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundStyle(iconColor)
                        .frame(width: 32)

                    Text(title.capitalized)
                        .font(FuelTypography.subheadlineMedium)
                        .foregroundStyle(FuelColors.textPrimary)

                    Spacer()
                }
                .padding(FuelSpacing.md)

                Divider()
                    .padding(.leading, FuelSpacing.md)

                // Options
                ForEach(options, id: \.rawValue) { option in
                    unitOptionRow(option: option, selection: selection)

                    if option.rawValue != options.last?.rawValue {
                        Divider()
                            .padding(.leading, FuelSpacing.md + FuelSpacing.lg)
                    }
                }
            }
            .background(FuelColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
        }
    }

    private func unitOptionRow<T: UnitOption>(
        option: T,
        selection: Binding<T>
    ) -> some View {
        Button {
            selection.wrappedValue = option
            FuelHaptics.shared.select()
        } label: {
            HStack(spacing: FuelSpacing.md) {
                Spacer()
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: FuelSpacing.xxxs) {
                    Text(option.displayName)
                        .font(FuelTypography.subheadline)
                        .foregroundStyle(FuelColors.textPrimary)

                    if let example = option.example {
                        Text("e.g., \(example)")
                            .font(FuelTypography.caption)
                            .foregroundStyle(FuelColors.textTertiary)
                    }
                }

                Spacer()

                if selection.wrappedValue.rawValue == option.rawValue {
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
}

// MARK: - Unit Option Protocol

protocol UnitOption: RawRepresentable, CaseIterable where RawValue == String {
    var displayName: String { get }
    var example: String? { get }
}

// MARK: - Weight Unit

enum WeightUnit: String, CaseIterable, UnitOption {
    case kg
    case lbs

    var displayName: String {
        switch self {
        case .kg: return "Kilograms (kg)"
        case .lbs: return "Pounds (lbs)"
        }
    }

    var example: String? {
        switch self {
        case .kg: return "75 kg"
        case .lbs: return "165 lbs"
        }
    }
}

// MARK: - Height Unit

enum HeightUnit: String, CaseIterable, UnitOption {
    case cm
    case ft

    var displayName: String {
        switch self {
        case .cm: return "Centimeters (cm)"
        case .ft: return "Feet & Inches (ft, in)"
        }
    }

    var example: String? {
        switch self {
        case .cm: return "175 cm"
        case .ft: return "5' 9\""
        }
    }
}

// MARK: - Energy Unit

enum EnergyUnit: String, CaseIterable, UnitOption {
    case calories
    case kilojoules

    var displayName: String {
        switch self {
        case .calories: return "Calories (kcal)"
        case .kilojoules: return "Kilojoules (kJ)"
        }
    }

    var example: String? {
        switch self {
        case .calories: return "2000 kcal"
        case .kilojoules: return "8400 kJ"
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        UnitsSettingsView()
    }
}
