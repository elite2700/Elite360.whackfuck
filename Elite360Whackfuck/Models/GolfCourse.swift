import Foundation
import FirebaseFirestore

struct GolfCourse: Codable, Identifiable {
    @DocumentID var id: String?
    var name: String
    var nameLowercase: String?
    var city: String
    var state: String
    var country: String
    var latitude: Double
    var longitude: Double
    var courseRating: Double
    var slopeRating: Int
    var par: Int
    var holes: [HoleInfo]

    static let collectionName = "courses"
}

struct HoleInfo: Codable, Identifiable {
    var id: Int { number }
    var number: Int
    var par: Int
    var yardage: Int
    var handicapRank: Int
    var latitude: Double?
    var longitude: Double?
    var greenLatitude: Double?
    var greenLongitude: Double?
}
