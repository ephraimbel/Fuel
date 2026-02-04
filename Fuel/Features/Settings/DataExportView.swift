import SwiftUI

/// Data Export View
/// Export user data in various formats

struct DataExportView: View {
    @State private var selectedFormat: ExportFormat = .csv
    @State private var selectedDateRange: DateRangeOption = .all
    @State private var includePhotos = false
    @State private var isExporting = false
    @State private var showingShareSheet = false

    var body: some View {
        ScrollView {
            VStack(spacing: FuelSpacing.xl) {
                // Format selection
                formatSection

                // Date range
                dateRangeSection

                // Options
                optionsSection

                // Export button
                exportButton

                // Info
                infoSection
            }
            .padding(.horizontal, FuelSpacing.screenHorizontal)
            .padding(.vertical, FuelSpacing.lg)
        }
        .background(FuelColors.background)
        .navigationTitle("Export Data")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Format Section

    private var formatSection: some View {
        VStack(alignment: .leading, spacing: FuelSpacing.sm) {
            Text("EXPORT FORMAT")
                .font(FuelTypography.caption)
                .foregroundStyle(FuelColors.textTertiary)

            VStack(spacing: 0) {
                ForEach(ExportFormat.allCases, id: \.self) { format in
                    formatRow(format)

                    if format != ExportFormat.allCases.last {
                        Divider()
                            .padding(.leading, FuelSpacing.md + 32 + FuelSpacing.md)
                    }
                }
            }
            .background(FuelColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
        }
    }

    private func formatRow(_ format: ExportFormat) -> some View {
        Button {
            selectedFormat = format
            FuelHaptics.shared.select()
        } label: {
            HStack(spacing: FuelSpacing.md) {
                Image(systemName: format.icon)
                    .font(.system(size: 18))
                    .foregroundStyle(format.color)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: FuelSpacing.xxxs) {
                    Text(format.displayName)
                        .font(FuelTypography.subheadlineMedium)
                        .foregroundStyle(FuelColors.textPrimary)

                    Text(format.description)
                        .font(FuelTypography.caption)
                        .foregroundStyle(FuelColors.textTertiary)
                }

                Spacer()

                if selectedFormat == format {
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

    // MARK: - Date Range Section

    private var dateRangeSection: some View {
        VStack(alignment: .leading, spacing: FuelSpacing.sm) {
            Text("DATE RANGE")
                .font(FuelTypography.caption)
                .foregroundStyle(FuelColors.textTertiary)

            VStack(spacing: 0) {
                ForEach(DateRangeOption.allCases, id: \.self) { option in
                    dateRangeRow(option)

                    if option != DateRangeOption.allCases.last {
                        Divider()
                            .padding(.leading, FuelSpacing.md)
                    }
                }
            }
            .background(FuelColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
        }
    }

    private func dateRangeRow(_ option: DateRangeOption) -> some View {
        Button {
            selectedDateRange = option
            FuelHaptics.shared.select()
        } label: {
            HStack {
                Text(option.displayName)
                    .font(FuelTypography.subheadline)
                    .foregroundStyle(FuelColors.textPrimary)

                Spacer()

                if selectedDateRange == option {
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

    // MARK: - Options Section

    private var optionsSection: some View {
        VStack(alignment: .leading, spacing: FuelSpacing.sm) {
            Text("OPTIONS")
                .font(FuelTypography.caption)
                .foregroundStyle(FuelColors.textTertiary)

            HStack(spacing: FuelSpacing.md) {
                Image(systemName: "photo.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.purple)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: FuelSpacing.xxxs) {
                    Text("Include Photos")
                        .font(FuelTypography.subheadlineMedium)
                        .foregroundStyle(FuelColors.textPrimary)

                    Text("Export meal photos (larger file size)")
                        .font(FuelTypography.caption)
                        .foregroundStyle(FuelColors.textTertiary)
                }

                Spacer()

                Toggle("", isOn: $includePhotos)
                    .labelsHidden()
                    .tint(FuelColors.primary)
                    .onChange(of: includePhotos) { _, _ in
                        FuelHaptics.shared.tap()
                    }
            }
            .padding(FuelSpacing.md)
            .background(FuelColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
        }
    }

    // MARK: - Export Button

    private var exportButton: some View {
        Button {
            exportData()
        } label: {
            HStack(spacing: FuelSpacing.sm) {
                if isExporting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "square.and.arrow.up")
                }

                Text(isExporting ? "Exporting..." : "Export Data")
            }
            .font(FuelTypography.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, FuelSpacing.md)
            .background(isExporting ? FuelColors.textSecondary : FuelColors.primary)
            .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
        }
        .disabled(isExporting)
    }

    // MARK: - Info Section

    private var infoSection: some View {
        HStack(spacing: FuelSpacing.sm) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(FuelColors.primary)

            Text("Your export will include all logged meals, nutrition data, and weight entries within the selected date range.")
                .font(FuelTypography.caption)
                .foregroundStyle(FuelColors.textSecondary)
        }
        .padding(FuelSpacing.md)
        .background(FuelColors.primaryLight)
        .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
    }

    // MARK: - Actions

    private func exportData() {
        isExporting = true
        FuelHaptics.shared.tap()

        // Simulate export
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isExporting = false
            showingShareSheet = true
            FuelHaptics.shared.success()
        }
    }
}

// MARK: - Export Format

enum ExportFormat: String, CaseIterable {
    case csv
    case json
    case pdf

    var displayName: String {
        switch self {
        case .csv: return "CSV Spreadsheet"
        case .json: return "JSON Data"
        case .pdf: return "PDF Report"
        }
    }

    var description: String {
        switch self {
        case .csv: return "Open in Excel, Numbers, etc."
        case .json: return "For developers and apps"
        case .pdf: return "Formatted document"
        }
    }

    var icon: String {
        switch self {
        case .csv: return "tablecells"
        case .json: return "curlybraces"
        case .pdf: return "doc.fill"
        }
    }

    var color: Color {
        switch self {
        case .csv: return .green
        case .json: return .orange
        case .pdf: return .red
        }
    }
}

// MARK: - Date Range Option

enum DateRangeOption: String, CaseIterable {
    case week
    case month
    case threeMonths
    case year
    case all

    var displayName: String {
        switch self {
        case .week: return "Last 7 days"
        case .month: return "Last 30 days"
        case .threeMonths: return "Last 3 months"
        case .year: return "Last year"
        case .all: return "All time"
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        DataExportView()
    }
}
