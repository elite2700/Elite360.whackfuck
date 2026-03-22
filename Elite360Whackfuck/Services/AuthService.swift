import Foundation
import FirebaseAuth
import AuthenticationServices

final class AuthService {
    static let shared = AuthService()
    private let auth = Auth.auth()

    private init() {}

    var currentUser: User? { auth.currentUser }
    var currentUserID: String? { auth.currentUser?.uid }
    var isAuthenticated: Bool { auth.currentUser != nil }

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

    // MARK: - Google Sign-In (placeholder — requires GoogleSignIn SDK setup)

    func signInWithGoogle(idToken: String, accessToken: String) async throws -> User {
        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
        let result = try await auth.signIn(with: credential)
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

    func addAuthStateListener(_ handler: @escaping (User?) -> Void) -> AuthStateDidChangeListenerHandle {
        auth.addStateDidChangeListener { _, user in handler(user) }
    }

    func removeAuthStateListener(_ handle: AuthStateDidChangeListenerHandle) {
        auth.removeStateDidChangeListener(handle)
    }
}
