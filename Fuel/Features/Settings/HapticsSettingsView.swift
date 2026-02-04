import SwiftUI

/// Haptics Settings View
/// Configure haptic feedback and sounds

struct HapticsSettingsView: View {
    @State private var hapticsEnabled = true
    @State private var soundsEnabled = false

    var body: some View {
        ScrollView {
            VStack(spacing: FuelSpacing.xl) {
                // Haptics
                hapticsSection

                // Sounds
                soundsSection

                // Preview
                previewSection
            }
            .padding(.horizontal, FuelSpacing.screenHorizontal)
            .padding(.vertical, FuelSpacing.lg)
        }
        .background(FuelColors.background)
        .navigationTitle("Haptics & Sounds")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Haptics Section

    private var hapticsSection: some View {
        VStack(alignment: .leading, spacing: FuelSpacing.sm) {
            Text("HAPTIC FEEDBACK")
                .font(FuelTypography.caption)
                .foregroundStyle(FuelColors.textTertiary)

            VStack(spacing: 0) {
                HStack(spacing: FuelSpacing.md) {
                    Image(systemName: "hand.tap.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.orange)
                        .frame(width: 32)

                    VStack(alignment: .leading, spacing: FuelSpacing.xxxs) {
                        Text("Haptic Feedback")
                            .font(FuelTypography.subheadlineMedium)
                            .foregroundStyle(FuelColors.textPrimary)

                        Text("Feel tactile responses when interacting")
                            .font(FuelTypography.caption)
                            .foregroundStyle(FuelColors.textTertiary)
                    }

                    Spacer()

                    Toggle("", isOn: $hapticsEnabled)
                        .labelsHidden()
                        .tint(FuelColors.primary)
                        .onChange(of: hapticsEnabled) { _, enabled in
                            FuelHaptics.shared.setEnabled(enabled)
                            if enabled {
                                FuelHaptics.shared.success()
                            }
                        }
                }
                .padding(FuelSpacing.md)
            }
            .background(FuelColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))

            Text("Haptic feedback provides tactile responses for button presses, achievements, and other interactions.")
                .font(FuelTypography.caption)
                .foregroundStyle(FuelColors.textTertiary)
                .padding(.horizontal, FuelSpacing.sm)
        }
    }

    // MARK: - Sounds Section

    private var soundsSection: some View {
        VStack(alignment: .leading, spacing: FuelSpacing.sm) {
            Text("SOUNDS")
                .font(FuelTypography.caption)
                .foregroundStyle(FuelColors.textTertiary)

            VStack(spacing: 0) {
                HStack(spacing: FuelSpacing.md) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.blue)
                        .frame(width: 32)

                    VStack(alignment: .leading, spacing: FuelSpacing.xxxs) {
                        Text("Sound Effects")
                            .font(FuelTypography.subheadlineMedium)
                            .foregroundStyle(FuelColors.textPrimary)

                        Text("Play sounds for achievements and actions")
                            .font(FuelTypography.caption)
                            .foregroundStyle(FuelColors.textTertiary)
                    }

                    Spacer()

                    Toggle("", isOn: $soundsEnabled)
                        .labelsHidden()
                        .tint(FuelColors.primary)
                        .onChange(of: soundsEnabled) { _, _ in
                            FuelHaptics.shared.tap()
                        }
                }
                .padding(FuelSpacing.md)
            }
            .background(FuelColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
        }
    }

    // MARK: - Preview Section

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: FuelSpacing.sm) {
            Text("PREVIEW")
                .font(FuelTypography.caption)
                .foregroundStyle(FuelColors.textTertiary)

            VStack(spacing: FuelSpacing.sm) {
                previewButton(title: "Tap", icon: "hand.point.up.fill") {
                    FuelHaptics.shared.tap()
                }

                previewButton(title: "Success", icon: "checkmark.circle.fill") {
                    FuelHaptics.shared.success()
                }

                previewButton(title: "Error", icon: "xmark.circle.fill") {
                    FuelHaptics.shared.error()
                }

                previewButton(title: "Celebration", icon: "party.popper.fill") {
                    FuelHaptics.shared.celebration()
                }
            }
            .padding(FuelSpacing.md)
            .background(FuelColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
        }
    }

    private func previewButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(FuelColors.primary)

                Text(title)
                    .font(FuelTypography.subheadline)
                    .foregroundStyle(FuelColors.textPrimary)

                Spacer()

                Text("Try it")
                    .font(FuelTypography.caption)
                    .foregroundStyle(FuelColors.primary)
            }
            .padding(.vertical, FuelSpacing.sm)
        }
        .disabled(!hapticsEnabled)
        .opacity(hapticsEnabled ? 1 : 0.5)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        HapticsSettingsView()
    }
}
