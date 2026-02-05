import SwiftUI
import SwiftData
import AuthenticationServices
import OSLog

/// Sign In Screen
/// User creates account with Sign in with Apple

private let logger = Logger(subsystem: "com.fuel.app", category: "SignIn")

struct SignInScreen: View {
    @Environment(\.modelContext) private var modelContext
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
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                error = "Invalid credential received."
                FuelHaptics.shared.error()
                return
            }

            isLoading = true
            error = nil

            Task { @MainActor in
                await processAppleCredential(appleIDCredential)
            }

        case .failure(let authError):
            if let asError = authError as? ASAuthorizationError,
               asError.code == .canceled {
                // User cancelled - don't show error
                logger.info("User cancelled Sign in with Apple")
                return
            }

            logger.error("Sign in failed: \(authError.localizedDescription)")
            error = "Sign in failed. Please try again."
            FuelHaptics.shared.error()
        }
    }

    @MainActor
    private func processAppleCredential(_ credential: ASAuthorizationAppleIDCredential) async {
        let userID = credential.user

        // Get name (only available on first sign-in)
        var fullName: String?
        if let name = credential.fullName {
            fullName = [name.givenName, name.familyName]
                .compactMap { $0 }
                .joined(separator: " ")
            if fullName?.isEmpty == true {
                fullName = nil
            }
        }

        // Get email (only available on first sign-in)
        let email = credential.email

        logger.info("Processing Apple credential for user: \(userID.prefix(8))...")

        // Process credential through AuthService
        AuthService.shared.processExternalCredential(credential)

        // Update the User model in SwiftData
        updateUserModel(appleUserID: userID, email: email, name: fullName)

        isLoading = false
        logger.info("Sign in completed successfully")
        viewModel.nextStep()
    }

    private func updateUserModel(appleUserID: String, email: String?, name: String?) {
        // Fetch or create user in SwiftData
        let descriptor = FetchDescriptor<User>()
        let existingUsers = (try? modelContext.fetch(descriptor)) ?? []

        let user: User
        if let existingUser = existingUsers.first {
            user = existingUser
        } else {
            user = User()
            modelContext.insert(user)
        }

        // Update Apple ID info
        user.appleUserID = appleUserID
        if let email = email {
            user.email = email
        }
        if let name = name {
            user.name = name
        }
        user.lastActiveAt = Date()

        // Save context
        do {
            try modelContext.save()
            logger.info("User model updated with Apple ID")
        } catch {
            logger.error("Failed to save user model: \(error.localizedDescription)")
        }
    }
}

#Preview {
    SignInScreen(viewModel: OnboardingViewModel())
}
