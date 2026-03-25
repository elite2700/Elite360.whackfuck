import Foundation
import FirebaseFirestore

struct UserProfile: Codable, Identifiable {
    @DocumentID var id: String?
    var email: String
    var displayName: String
    var photoURL: String?
    var homeCourse: String?
    var handicapIndex: Double?
    var username: String
    var friendIDs: [String]
    var groupIDs: [String]
    var isPremium: Bool
    var createdAt: Date
    var updatedAt: Date

    static let collectionName = "users"
}

/// A contact in the user's personal friends list (stored as subcollection users/{uid}/friends)
struct Friend: Codable, Identifiable {
    @DocumentID var id: String?
    var name: String
    var email: String?
    var phone: String?
    var handicap: Double?
    var createdAt: Date

    static let collectionName = "friends"
}

struct FriendRequest: Codable, Identifiable {
    @DocumentID var id: String?
    var fromUserID: String
    var toUserID: String
    var fromDisplayName: String
    var status: RequestStatus
    var createdAt: Date

    enum RequestStatus: String, Codable {
        case pending, accepted, declined
    }

    static let collectionName = "friendRequests"
}

struct GolfGroup: Codable, Identifiable {
    @DocumentID var id: String?
    var name: String
    var memberIDs: [String]
    var createdBy: String
    var createdAt: Date

    static let collectionName = "groups"
}
