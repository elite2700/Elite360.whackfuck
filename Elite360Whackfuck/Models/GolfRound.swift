import Foundation
import FirebaseFirestore

struct GolfRound: Codable, Identifiable {
    @DocumentID var id: String?
    var courseID: String
    var courseName: String
    var playerIDs: [String]
    var createdBy: String
    var date: Date
    var status: RoundStatus
    var scorecards: [String: Scorecard]  // keyed by userID
    var activeGames: [ActiveGame]
    var moneyPot: MoneyPot?
    var courseRating: Double
    var slopeRating: Int
    var holePars: [Int]  // par per hole (index 0 = hole 1)

    enum RoundStatus: String, Codable {
        case setup, inProgress, completed, cancelled
    }

    static let collectionName = "rounds"
}

struct Scorecard: Codable {
    var playerID: String
    var playerName: String
    var courseHandicap: Int
    var holeScores: [HoleScore]
    var totalGross: Int
    var totalNet: Int
    var totalPutts: Int
    var fairwaysHit: Int
    var greensInRegulation: Int
}

struct HoleScore: Codable, Identifiable {
    var id: Int { holeNumber }
    var holeNumber: Int
    var strokes: Int
    var putts: Int
    var fairwayHit: Bool?
    var greenInRegulation: Bool
    var penalties: Int
    var sandShots: Int
    var isComplete: Bool
}

struct ActiveGame: Codable, Identifiable {
    var id: String { gameType + "-" + String(stakes) }
    var gameType: String
    var customGameID: String?
    var stakes: Double
    var isGrossScoring: Bool
    var teamAssignments: [String: Int]?  // playerID -> team number
    var gameState: [String: AnyCodable]  // flexible state per game type
}

struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) { self.value = value }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let int = try? container.decode(Int.self) { value = int }
        else if let double = try? container.decode(Double.self) { value = double }
        else if let string = try? container.decode(String.self) { value = string }
        else if let bool = try? container.decode(Bool.self) { value = bool }
        else if let array = try? container.decode([AnyCodable].self) { value = array.map(\.value) }
        else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues(\.value)
        } else { value = NSNull() }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let v as Int: try container.encode(v)
        case let v as Double: try container.encode(v)
        case let v as String: try container.encode(v)
        case let v as Bool: try container.encode(v)
        default: try container.encodeNil()
        }
    }
}
