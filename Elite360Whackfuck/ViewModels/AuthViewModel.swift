import Foundation
import FirebaseAuth
import AuthenticationServices
import CryptoKit

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = true
    @Published var currentProfile: UserProfile?
    @Published var friends: [Friend] = []
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
                    await self?.loadFriends()
                } else {
                    self?.currentProfile = nil
                    self?.friends = []
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

            // Optimistic local update so UI reflects changes immediately
            if var profile = currentProfile {
                for (key, value) in updates {
                    switch key {
                    case "displayName": profile.displayName = value as? String ?? profile.displayName
                    case "username": profile.username = value as? String ?? profile.username
                    case "homeCourse": profile.homeCourse = value as? String
                    case "handicapIndex": profile.handicapIndex = value as? Double
                    case "photoURL": profile.photoURL = value as? String
                    case "isPremium": profile.isPremium = value as? Bool ?? profile.isPremium
                    default: break
                    }
                }
                profile.updatedAt = Date()
                currentProfile = profile
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Friends (subcollection: users/{uid}/friends)

    func loadFriends() async {
        guard let uid = auth.currentUserID else { return }
        do {
            friends = try await db.getSubcollection(
                parentCollection: UserProfile.collectionName,
                parentID: uid,
                subcollection: Friend.collectionName
            )
        } catch {
            friends = []
        }
    }

    func addFriend(_ friend: Friend) async {
        guard let uid = auth.currentUserID else { return }
        do {
            error = nil
            let docID = try await db.createInSubcollection(
                friend,
                parentCollection: UserProfile.collectionName,
                parentID: uid,
                subcollection: Friend.collectionName
            )
            var saved = friend
            saved.id = docID
            friends.append(saved)
            friends.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func updateFriend(_ friend: Friend, fields: [String: Any]) async {
        guard let uid = auth.currentUserID, let fid = friend.id else {
            self.error = "Unable to update friend: missing information"
            return
        }
        do {
            error = nil
            try await db.updateInSubcollection(
                parentCollection: UserProfile.collectionName,
                parentID: uid,
                subcollection: Friend.collectionName,
                documentID: fid,
                fields: fields
            )
            if let idx = friends.firstIndex(where: { $0.id == fid }) {
                var updated = friends[idx]
                for (key, value) in fields {
                    switch key {
                    case "name": updated.name = value as? String ?? updated.name
                    case "email": updated.email = value as? String
                    case "phone": updated.phone = value as? String
                    case "handicap": updated.handicap = value as? Double
                    default: break
                    }
                }
                friends[idx] = updated
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func deleteFriend(_ friend: Friend) async {
        guard let uid = auth.currentUserID, let fid = friend.id else { return }
        do {
            error = nil
            try await db.deleteFromSubcollection(
                parentCollection: UserProfile.collectionName,
                parentID: uid,
                subcollection: Friend.collectionName,
                documentID: fid
            )
            friends.removeAll { $0.id == fid }
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
