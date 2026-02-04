import SwiftUI

/// Reusable layout for onboarding screens
/// Provides consistent structure with title, content, and footer

struct OnboardingScreenLayout<Content: View, Footer: View>: View {
    let title: String
    let subtitle: String?
    let content: Content
    let footer: Footer

    init(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer
    ) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
        self.footer = footer()
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: FuelSpacing.sm) {
                Text(title)
                    .font(FuelTypography.title1)
                    .foregroundStyle(FuelColors.textPrimary)
                    .multilineTextAlignment(.center)

                if let subtitle {
                    Text(subtitle)
                        .font(FuelTypography.body)
                        .foregroundStyle(FuelColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, FuelSpacing.screenHorizontal)
            .padding(.top, FuelSpacing.xl)
            .padding(.bottom, FuelSpacing.lg)

            // Content
            ScrollView(showsIndicators: false) {
                content
                    .padding(.bottom, FuelSpacing.xxl)
            }

            Spacer(minLength: 0)

            // Footer
            footer
                .padding(.bottom, FuelSpacing.xxl)
        }
    }
}

// MARK: - Without Footer

extension OnboardingScreenLayout where Footer == EmptyView {
    init(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
        self.footer = EmptyView()
    }
}

#Preview {
    OnboardingScreenLayout(
        title: "Sample Screen",
        subtitle: "This is a sample subtitle for the onboarding screen."
    ) {
        VStack {
            Text("Content goes here")
        }
    } footer: {
        FuelButton("Continue") {}
            .padding(.horizontal, FuelSpacing.screenHorizontal)
    }
}
