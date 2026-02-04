import Foundation
import AuthenticationServices

/// Authentication Service
/// Handles Sign in with Apple and session management

@Observable
public final class AuthService: NSObject {
    // MARK: - Singleton

    public static let shared = AuthService()

    // MARK: - State

    public private(set) var isAuthenticated = false
    public private(set) var currentUser: AuthUser?
    public private(set) var isLoading = false
    public private(set) var error: AuthError?

    // MARK: - Keys

    private let userIDKey = "com.fuel.auth.userID"
    private let userEmailKey = "com.fuel.auth.email"
    private let userNameKey = "com.fuel.auth.name"

    // MARK: - Continuation

    private var signInContinuation: CheckedContinuation<AuthUser, Error>?

    // MARK: - Initialization

    private override init() {
        super.init()
        checkExistingCredentials()
    }

    // MARK: - Public Methods

    /// Sign in with Apple
    @MainActor
    public func signInWithApple() async throws -> AuthUser {
        isLoading = true
        error = nil

        defer { isLoading = false }

        return try await withCheckedThrowingContinuation { continuation in
            self.signInContinuation = continuation

            let provider = ASAuthorizationAppleIDProvider()
            let request = provider.createRequest()
            request.requestedScopes = [.fullName, .email]

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.performRequests()
        }
    }

    /// Sign out
    @MainActor
    public func signOut() {
        // Clear stored credentials
        UserDefaults.standard.removeObject(forKey: userIDKey)
        UserDefaults.standard.removeObject(forKey: userEmailKey)
        UserDefaults.standard.removeObject(forKey: userNameKey)

        // Clear keychain
        KeychainHelper.shared.delete(key: userIDKey)

        isAuthenticated = false
        currentUser = nil

        FuelHaptics.shared.tap()
    }

    /// Check if existing credentials are valid
    @MainActor
    public func checkExistingCredentials() {
        guard let userID = KeychainHelper.shared.read(key: userIDKey) else {
            isAuthenticated = false
            return
        }

        // Verify credential state
        let provider = ASAuthorizationAppleIDProvider()
        provider.getCredentialState(forUserID: userID) { [weak self] state, _ in
            DispatchQueue.main.async {
                switch state {
                case .authorized:
                    self?.restoreSession(userID: userID)
                case .revoked, .notFound:
                    self?.signOut()
                default:
                    break
                }
            }
        }
    }

    /// Delete account
    @MainActor
    public func deleteAccount() async throws {
        isLoading = true
        error = nil

        defer { isLoading = false }

        // In production, call backend to delete user data
        // await backendService.deleteAccount()

        signOut()

        FuelHaptics.shared.success()
    }

    // MARK: - Private Methods

    private func restoreSession(userID: String) {
        let email = UserDefaults.standard.string(forKey: userEmailKey)
        let name = UserDefaults.standard.string(forKey: userNameKey)

        currentUser = AuthUser(
            id: userID,
            email: email,
            fullName: name
        )
        isAuthenticated = true
    }

    private func saveCredentials(user: AuthUser) {
        // Save to keychain
        KeychainHelper.shared.save(key: userIDKey, value: user.id)

        // Save non-sensitive data to UserDefaults
        if let email = user.email {
            UserDefaults.standard.set(email, forKey: userEmailKey)
        }
        if let name = user.fullName {
            UserDefaults.standard.set(name, forKey: userNameKey)
        }
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AuthService: ASAuthorizationControllerDelegate {
    public func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            signInContinuation?.resume(throwing: AuthError.invalidCredential)
            signInContinuation = nil
            return
        }

        let userID = appleIDCredential.user

        // Get name (only available on first sign-in)
        var fullName: String?
        if let name = appleIDCredential.fullName {
            fullName = [name.givenName, name.familyName]
                .compactMap { $0 }
                .joined(separator: " ")
            if fullName?.isEmpty == true {
                fullName = nil
            }
        }

        // Get email (only available on first sign-in)
        let email = appleIDCredential.email

        let user = AuthUser(
            id: userID,
            email: email,
            fullName: fullName
        )

        // Save credentials
        saveCredentials(user: user)

        DispatchQueue.main.async { [weak self] in
            self?.currentUser = user
            self?.isAuthenticated = true
            FuelHaptics.shared.success()
            self?.signInContinuation?.resume(returning: user)
            self?.signInContinuation = nil
        }
    }

    public func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        let authError: AuthError

        if let asError = error as? ASAuthorizationError {
            switch asError.code {
            case .canceled:
                authError = .canceled
            case .invalidResponse:
                authError = .invalidResponse
            case .notHandled:
                authError = .notHandled
            case .failed:
                authError = .failed
            case .notInteractive:
                authError = .notInteractive
            default:
                authError = .unknown(error)
            }
        } else {
            authError = .unknown(error)
        }

        DispatchQueue.main.async { [weak self] in
            self?.error = authError
            FuelHaptics.shared.error()
            self?.signInContinuation?.resume(throwing: authError)
            self?.signInContinuation = nil
        }
    }
}

// MARK: - Auth User

public struct AuthUser: Identifiable, Codable {
    public let id: String
    public let email: String?
    public let fullName: String?

    public var displayName: String {
        fullName ?? email ?? "User"
    }

    public var initials: String {
        guard let name = fullName else { return "U" }
        let components = name.components(separatedBy: " ")
        let initials = components.prefix(2).compactMap { $0.first }.map { String($0) }
        return initials.joined()
    }
}

// MARK: - Auth Error

public enum AuthError: LocalizedError {
    case canceled
    case invalidCredential
    case invalidResponse
    case notHandled
    case failed
    case notInteractive
    case unknown(Error)

    public var errorDescription: String? {
        switch self {
        case .canceled:
            return "Sign in was canceled"
        case .invalidCredential:
            return "Invalid credential received"
        case .invalidResponse:
            return "Invalid response from Apple"
        case .notHandled:
            return "Request not handled"
        case .failed:
            return "Sign in failed"
        case .notInteractive:
            return "Interactive sign in required"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Keychain Helper

final class KeychainHelper {
    static let shared = KeychainHelper()

    private init() {}

    func save(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]

        // Delete existing item
        SecItemDelete(query as CFDictionary)

        // Add new item
        SecItemAdd(query as CFDictionary, nil)
    }

    func read(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &result)

        guard let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]

        SecItemDelete(query as CFDictionary)
    }
}
