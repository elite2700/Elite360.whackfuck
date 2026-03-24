import Foundation
import FirebaseAuth
import AuthenticationServices
import CryptoKit

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = true
    @Published var currentProfile: UserProfile?
    @Published var error: String?

    private var authHandle: AuthStateDidChangeListenerHandle?
    private let auth = AuthService.shared
    private let db = FirestoreService.shared
    private var currentNonce: String?

    init() {
        authHandle = auth.addAuthStateListener { [weak self] user in
            Task { @MainActor in
                self?.isAuthenticated = user != nil
                if let uid = user?.uid {
                    await self?.loadProfile(uid: uid)
                } else {
                    self?.currentProfile = nil
                }
                self?.isLoading = false
            }
        }
    }

    deinit {
        auth.removeAuthStateListener(authHandle)
    }

    // MARK: - Email Auth

    func signUp(email: String, password: String, displayName: String, username: String) async {
        do {
            error = nil
            let user = try await auth.signUp(email: email, password: password)
            let profile = UserProfile(
                id: user.uid,
                email: email,
                displayName: displayName,
                photoURL: nil,
                homeCourse: nil,
                handicapIndex: nil,
                username: username.lowercased(),
                friendIDs: [],
                groupIDs: [],
                isPremium: false,
                createdAt: Date(),
                updatedAt: Date()
            )
            try await db.setDocument(profile, in: UserProfile.collectionName, documentID: user.uid)
            currentProfile = profile
        } catch {
            self.error = error.localizedDescription
        }
    }

    func signIn(email: String, password: String) async {
        do {
            error = nil
            _ = try await auth.signIn(email: email, password: password)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func signOut() {
        do {
            try auth.signOut()
            currentProfile = nil
        } catch {
            self.error = error.localizedDescription
        }
    }

    func resetPassword(email: String) async {
        do {
            error = nil
            try await auth.resetPassword(email: email)
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Apple Sign-In

    func handleAppleSignIn(result: Result<ASAuthorization, Error>) async {
        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let nonce = currentNonce else { return }
            do {
                let user = try await auth.signInWithApple(credential: appleIDCredential, nonce: nonce)
                await ensureProfileExists(user: user, name: appleIDCredential.fullName)
            } catch {
                self.error = error.localizedDescription
            }
        case .failure(let err):
            self.error = err.localizedDescription
        }
    }

    func prepareAppleSignIn() -> String {
        let nonce = randomNonceString()
        currentNonce = nonce
        return sha256(nonce)
    }

    // MARK: - Google Sign-In

    func signInWithGoogle() async {
        do {
            error = nil
            let user = try await auth.signInWithGoogle()
            await ensureProfileExists(user: user, name: nil)
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Profile

    func loadProfile(uid: String) async {
        do {
            currentProfile = try await db.getDocument(from: UserProfile.collectionName, documentID: uid)
        } catch {
            // Profile may not exist yet
            currentProfile = nil
        }
    }

    func updateProfile(_ updates: [String: Any]) async {
        guard let uid = auth.currentUserID else { return }
        do {
            var fields = updates
            fields["updatedAt"] = Date()
            try await db.updateFields(in: UserProfile.collectionName, documentID: uid, fields: fields)
            await loadProfile(uid: uid)
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Helpers

    private func ensureProfileExists(user: User, name: PersonNameComponents?) async {
        do {
            let _: UserProfile = try await db.getDocument(from: UserProfile.collectionName, documentID: user.uid)
        } catch {
            let displayName = [name?.givenName, name?.familyName].compactMap { $0 }.joined(separator: " ")
            let profile = UserProfile(
                id: user.uid,
                email: user.email ?? "",
                displayName: displayName.isEmpty ? "Golfer" : displayName,
                photoURL: user.photoURL?.absoluteString,
                homeCourse: nil,
                handicapIndex: nil,
                username: user.uid.prefix(8).lowercased(),
                friendIDs: [],
                groupIDs: [],
                isPremium: false,
                createdAt: Date(),
                updatedAt: Date()
            )
            try? await db.setDocument(profile, in: UserProfile.collectionName, documentID: user.uid)
            currentProfile = profile
        }
    }

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        guard errorCode == errSecSuccess else { return "" }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    private func sha256(_ input: String) -> String {
        let data = Data(input.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}
