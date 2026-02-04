import SwiftUI
import AuthenticationServices

/// Sign In Screen
/// User creates account with Sign in with Apple

struct SignInScreen: View {
    @Bindable var viewModel: OnboardingViewModel

    @State private var isLoading = false
    @State private var error: String?

    var body: some View {
        OnboardingScreenLayout(
            title: "Save your progress",
            subtitle: "Create an account to sync across devices and never lose your data."
        ) {
            VStack(spacing: FuelSpacing.xl) {
                // Benefits
                VStack(spacing: FuelSpacing.md) {
                    benefitRow(icon: "icloud.fill", title: "Sync across devices", description: "Access your data anywhere")
                    benefitRow(icon: "lock.shield.fill", title: "Secure backup", description: "Never lose your progress")
                    benefitRow(icon: "person.2.fill", title: "Family sharing", description: "Share premium with family")
                }
                .padding(.horizontal, FuelSpacing.screenHorizontal)

                Spacer()
                    .frame(height: FuelSpacing.lg)

                // Sign in with Apple button
                SignInWithAppleButton(.signUp, onRequest: { request in
                    request.requestedScopes = [.fullName, .email]
                }, onCompletion: { result in
                    handleSignInResult(result)
                })
                .signInWithAppleButtonStyle(.black)
                .frame(height: 56)
                .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd, style: .continuous))
                .padding(.horizontal, FuelSpacing.screenHorizontal)

                // Error message
                if let error {
                    Text(error)
                        .font(FuelTypography.caption)
                        .foregroundStyle(FuelColors.error)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, FuelSpacing.screenHorizontal)
                }

                // Skip option
                Button {
                    FuelHaptics.shared.tap()
                    viewModel.nextStep()
                } label: {
                    Text("Continue without account")
                        .font(FuelTypography.subheadline)
                        .foregroundStyle(FuelColors.textSecondary)
                }

                // Privacy note
                Text("We only use your Apple ID for authentication. Your data stays private.")
                    .font(FuelTypography.caption)
                    .foregroundStyle(FuelColors.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, FuelSpacing.screenHorizontal)
            }
        } footer: {
            EmptyView()
        }
        .overlay {
            if isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()

                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            }
        }
    }

    private func benefitRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: FuelSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(FuelColors.primary)
                .frame(width: 44)

            VStack(alignment: .leading, spacing: FuelSpacing.xxxs) {
                Text(title)
                    .font(FuelTypography.headline)
                    .foregroundStyle(FuelColors.textPrimary)

                Text(description)
                    .font(FuelTypography.caption)
                    .foregroundStyle(FuelColors.textSecondary)
            }

            Spacer()
        }
        .padding(FuelSpacing.md)
        .background(FuelColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd, style: .continuous))
    }

    private func handleSignInResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                isLoading = true
                error = nil

                // In production, send credential to your server
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 1_000_000_000)

                    isLoading = false
                    FuelHaptics.shared.success()
                    viewModel.nextStep()
                }
            }

        case .failure(let authError):
            if let asError = authError as? ASAuthorizationError,
               asError.code == .canceled {
                // User cancelled - don't show error
                return
            }

            error = "Sign in failed. Please try again."
            FuelHaptics.shared.error()
        }
    }
}

#Preview {
    SignInScreen(viewModel: OnboardingViewModel())
}
