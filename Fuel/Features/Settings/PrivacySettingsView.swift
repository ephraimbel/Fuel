import SwiftUI

/// Privacy Settings View
/// Configure privacy and data settings

struct PrivacySettingsView: View {
    @State private var analyticsEnabled = true
    @State private var crashReportsEnabled = true
    @State private var personalizedAds = false

    var body: some View {
        ScrollView {
            VStack(spacing: FuelSpacing.xl) {
                // Data collection
                dataCollectionSection

                // Data usage
                dataUsageSection

                // Data deletion
                dataDeletionSection
            }
            .padding(.horizontal, FuelSpacing.screenHorizontal)
            .padding(.vertical, FuelSpacing.lg)
        }
        .background(FuelColors.background)
        .navigationTitle("Privacy")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Data Collection

    private var dataCollectionSection: some View {
        VStack(alignment: .leading, spacing: FuelSpacing.sm) {
            Text("DATA COLLECTION")
                .font(FuelTypography.caption)
                .foregroundStyle(FuelColors.textTertiary)

            VStack(spacing: 0) {
                privacyToggleRow(
                    icon: "chart.bar.fill",
                    iconColor: .blue,
                    title: "Analytics",
                    description: "Help us improve the app",
                    isEnabled: $analyticsEnabled
                )

                Divider()
                    .padding(.leading, FuelSpacing.md + 32 + FuelSpacing.md)

                privacyToggleRow(
                    icon: "ant.fill",
                    iconColor: .orange,
                    title: "Crash Reports",
                    description: "Send crash data to fix bugs",
                    isEnabled: $crashReportsEnabled
                )

                Divider()
                    .padding(.leading, FuelSpacing.md + 32 + FuelSpacing.md)

                privacyToggleRow(
                    icon: "megaphone.fill",
                    iconColor: .purple,
                    title: "Personalized Ads",
                    description: "See relevant advertisements",
                    isEnabled: $personalizedAds
                )
            }
            .background(FuelColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
        }
    }

    private func privacyToggleRow(
        icon: String,
        iconColor: Color,
        title: String,
        description: String,
        isEnabled: Binding<Bool>
    ) -> some View {
        HStack(spacing: FuelSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(iconColor)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: FuelSpacing.xxxs) {
                Text(title)
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

    // MARK: - Data Usage

    private var dataUsageSection: some View {
        VStack(alignment: .leading, spacing: FuelSpacing.sm) {
            Text("YOUR DATA")
                .font(FuelTypography.caption)
                .foregroundStyle(FuelColors.textTertiary)

            VStack(spacing: FuelSpacing.md) {
                HStack(spacing: FuelSpacing.md) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(FuelColors.success)

                    VStack(alignment: .leading, spacing: FuelSpacing.xxxs) {
                        Text("Your Data is Secure")
                            .font(FuelTypography.subheadlineMedium)
                            .foregroundStyle(FuelColors.textPrimary)

                        Text("All data is encrypted and stored securely. We never sell your personal information.")
                            .font(FuelTypography.caption)
                            .foregroundStyle(FuelColors.textTertiary)
                    }
                }
            }
            .padding(FuelSpacing.md)
            .background(FuelColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
        }
    }

    // MARK: - Data Deletion

    private var dataDeletionSection: some View {
        VStack(alignment: .leading, spacing: FuelSpacing.sm) {
            Text("DATA MANAGEMENT")
                .font(FuelTypography.caption)
                .foregroundStyle(FuelColors.textTertiary)

            VStack(spacing: 0) {
                Button {
                    // Request data
                    FuelHaptics.shared.tap()
                } label: {
                    HStack(spacing: FuelSpacing.md) {
                        Image(systemName: "arrow.down.doc.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(.blue)
                            .frame(width: 32)

                        VStack(alignment: .leading, spacing: FuelSpacing.xxxs) {
                            Text("Request Your Data")
                                .font(FuelTypography.subheadlineMedium)
                                .foregroundStyle(FuelColors.textPrimary)

                            Text("Download a copy of your data")
                                .font(FuelTypography.caption)
                                .foregroundStyle(FuelColors.textTertiary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(FuelColors.textTertiary)
                    }
                    .padding(FuelSpacing.md)
                }

                Divider()
                    .padding(.leading, FuelSpacing.md + 32 + FuelSpacing.md)

                Button {
                    // Delete data
                    FuelHaptics.shared.warning()
                } label: {
                    HStack(spacing: FuelSpacing.md) {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(FuelColors.error)
                            .frame(width: 32)

                        VStack(alignment: .leading, spacing: FuelSpacing.xxxs) {
                            Text("Delete All Data")
                                .font(FuelTypography.subheadlineMedium)
                                .foregroundStyle(FuelColors.error)

                            Text("Permanently delete your data")
                                .font(FuelTypography.caption)
                                .foregroundStyle(FuelColors.textTertiary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(FuelColors.textTertiary)
                    }
                    .padding(FuelSpacing.md)
                }
            }
            .background(FuelColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PrivacySettingsView()
    }
}
