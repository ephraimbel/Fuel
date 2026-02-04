import SwiftUI

/// About View
/// App information, version, and legal links

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: FuelSpacing.xl) {
                // App info
                appInfoSection

                // Links
                linksSection

                // Credits
                creditsSection
            }
            .padding(.horizontal, FuelSpacing.screenHorizontal)
            .padding(.vertical, FuelSpacing.lg)
        }
        .background(FuelColors.background)
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - App Info Section

    private var appInfoSection: some View {
        VStack(spacing: FuelSpacing.lg) {
            // Logo
            ZStack {
                Circle()
                    .fill(FuelColors.primaryLight)
                    .frame(width: 100, height: 100)

                Image(systemName: "flame.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(FuelColors.primary)
            }

            // App name and version
            VStack(spacing: FuelSpacing.xs) {
                Text("Fuel")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(FuelColors.textPrimary)

                Text("AI-Powered Calorie Tracking")
                    .font(FuelTypography.subheadline)
                    .foregroundStyle(FuelColors.textSecondary)

                Text("Version \(appVersion)")
                    .font(FuelTypography.caption)
                    .foregroundStyle(FuelColors.textTertiary)
                    .padding(.top, FuelSpacing.xxs)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, FuelSpacing.xl)
    }

    // MARK: - Links Section

    private var linksSection: some View {
        VStack(alignment: .leading, spacing: FuelSpacing.sm) {
            Text("LEGAL")
                .font(FuelTypography.caption)
                .foregroundStyle(FuelColors.textTertiary)

            VStack(spacing: 0) {
                linkRow(
                    icon: "doc.text.fill",
                    title: "Terms of Service",
                    url: "https://fuel.app/terms"
                )

                Divider()
                    .padding(.leading, FuelSpacing.md + 32 + FuelSpacing.md)

                linkRow(
                    icon: "hand.raised.fill",
                    title: "Privacy Policy",
                    url: "https://fuel.app/privacy"
                )

                Divider()
                    .padding(.leading, FuelSpacing.md + 32 + FuelSpacing.md)

                linkRow(
                    icon: "doc.badge.gearshape.fill",
                    title: "Open Source Licenses",
                    url: nil,
                    action: showLicenses
                )
            }
            .background(FuelColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
        }
    }

    private func linkRow(
        icon: String,
        title: String,
        url: String?,
        action: (() -> Void)? = nil
    ) -> some View {
        Button {
            if let url = url, let link = URL(string: url) {
                UIApplication.shared.open(link)
            } else {
                action?()
            }
            FuelHaptics.shared.tap()
        } label: {
            HStack(spacing: FuelSpacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(FuelColors.textSecondary)
                    .frame(width: 32)

                Text(title)
                    .font(FuelTypography.subheadline)
                    .foregroundStyle(FuelColors.textPrimary)

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12))
                    .foregroundStyle(FuelColors.textTertiary)
            }
            .padding(FuelSpacing.md)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Credits Section

    private var creditsSection: some View {
        VStack(alignment: .leading, spacing: FuelSpacing.sm) {
            Text("CREDITS")
                .font(FuelTypography.caption)
                .foregroundStyle(FuelColors.textTertiary)

            VStack(spacing: FuelSpacing.md) {
                HStack(spacing: FuelSpacing.md) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 24))
                        .foregroundStyle(.purple)

                    VStack(alignment: .leading, spacing: FuelSpacing.xxxs) {
                        Text("Powered by OpenAI")
                            .font(FuelTypography.subheadlineMedium)
                            .foregroundStyle(FuelColors.textPrimary)

                        Text("GPT-4 Vision for food recognition")
                            .font(FuelTypography.caption)
                            .foregroundStyle(FuelColors.textTertiary)
                    }
                }

                Divider()

                HStack(spacing: FuelSpacing.md) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.green)

                    VStack(alignment: .leading, spacing: FuelSpacing.xxxs) {
                        Text("Open Food Facts")
                            .font(FuelTypography.subheadlineMedium)
                            .foregroundStyle(FuelColors.textPrimary)

                        Text("Food database and barcode data")
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

    // MARK: - Computed Properties

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    // MARK: - Actions

    private func showLicenses() {
        // TODO: Show licenses view
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AboutView()
    }
}
