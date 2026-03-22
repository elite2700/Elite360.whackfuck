import Foundation
import FirebaseFirestore

struct MoneyPot: Codable {
    var totalPot: Double
    var perPlayerStake: Double
    var ledger: [LedgerEntry]
    var settlements: [Settlement]
    var isSettled: Bool
}

struct LedgerEntry: Codable, Identifiable {
    var id: String { playerID + "-" + gameType + "-hole\(holeNumber)" }
    var playerID: String
    var playerName: String
    var gameType: String
    var holeNumber: Int
    var amount: Double
    var description: String
    var timestamp: Date
}

struct Settlement: Codable, Identifiable {
    var id: String { fromPlayerID + "->" + toPlayerID }
    var fromPlayerID: String
    var fromPlayerName: String
    var toPlayerID: String
    var toPlayerName: String
    var amount: Double
    var isPaid: Bool
    var method: String?
}

struct PlayerBalance: Identifiable {
    var id: String { playerID }
    var playerID: String
    var playerName: String
    var totalWinnings: Double
    var totalLosses: Double
    var netBalance: Double
    var gameBreakdown: [String: Double]
}
