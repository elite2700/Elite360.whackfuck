import Foundation
import FirebaseFirestore

struct HandicapRecord: Codable, Identifiable {
    @DocumentID var id: String?
    var userID: String
    var courseID: String
    var courseName: String
    var date: Date
    var grossScore: Int
    var adjustedGrossScore: Int
    var courseRating: Double
    var slopeRating: Int
    var scoreDifferential: Double
    var isExceptional: Bool

    static let collectionName = "handicapRecords"
}

struct HandicapSnapshot: Codable {
    var handicapIndex: Double
    var calculatedAt: Date
    var recordsUsed: Int
    var lowestDifferential: Double
    var highestUsedDifferential: Double
    var trend: HandicapTrend
}

enum HandicapTrend: String, Codable {
    case improving, stable, declining
}
