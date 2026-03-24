import Foundation
import FirebaseAuth
import FirebaseCore
import AuthenticationServices

final class AuthService {
    static let shared = AuthService()
    private lazy var auth: Auth = Auth.auth()

    static var isFirebaseConfigured: Bool {
        FirebaseApp.app() != nil
    }

    private init() {}

    var currentUser: User? { Self.isFirebaseConfigured ? auth.currentUser : nil }
    var currentUserID: String? { Self.isFirebaseConfigured ? auth.currentUser?.uid : nil }
    var isAuthenticated: Bool { Self.isFirebaseConfigured && auth.currentUser != nil }

    // MARK: - Email Auth

    func signUp(email: String, password: String) async throws -> User {
        let result = try await auth.createUser(withEmail: email, password: password)
        return result.user
    }

    func signIn(email: String, password: String) async throws -> User {
        let result = try await auth.signIn(withEmail: email, password: password)
        return result.user
    }

    // MARK: - Apple Sign-In

    func signInWithApple(credential: ASAuthorizationAppleIDCredential, nonce: String) async throws -> User {
        let oauthCredential = OAuthProvider.appleCredential(
            withIDToken: String(data: credential.identityToken ?? Data(), encoding: .utf8) ?? "",
            rawNonce: nonce,
            fullName: credential.fullName
        )
        let result = try await auth.signIn(with: oauthCredential)
        return result.user
    }

    // MARK: - Sign Out

    func signOut() throws {
        try auth.signOut()
    }

    // MARK: - Password Reset

    func resetPassword(email: String) async throws {
        try await auth.sendPasswordReset(withEmail: email)
    }

    // MARK: - Auth State Listener

    func addAuthStateListener(_ handler: @escaping (User?) -> Void) -> AuthStateDidChangeListenerHandle? {
        guard Self.isFirebaseConfigured else {
            handler(nil)
            return nil
        }
        return auth.addStateDidChangeListener { _, user in handler(user) }
    }

    func removeAuthStateListener(_ handle: AuthStateDidChangeListenerHandle?) {
        guard let handle else { return }
        auth.removeStateDidChangeListener(handle)
    }
}
