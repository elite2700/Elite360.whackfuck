import Foundation
import FirebaseAuth
import FirebaseCore
import AuthenticationServices
import GoogleSignIn

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

    // MARK: - Google Sign-In

    func signInWithGoogle(presenting: UIViewController? = nil) async throws -> User {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Firebase clientID not found"])
        }
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        guard let windowScene = await UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = await windowScene.windows.first?.rootViewController else {
            throw NSError(domain: "AuthService", code: -2, userInfo: [NSLocalizedDescriptionKey: "No root view controller found"])
        }

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presenting ?? rootVC)
        guard let idToken = result.user.idToken?.tokenString else {
            throw NSError(domain: "AuthService", code: -3, userInfo: [NSLocalizedDescriptionKey: "Google Sign-In failed: missing ID token"])
        }
        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: result.user.accessToken.tokenString
        )
        let authResult = try await auth.signIn(with: credential)
        return authResult.user
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
