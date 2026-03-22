import Foundation

struct RoundAnalytics {
    var averageScore: Double
    var averagePutts: Double
    var fairwayPercentage: Double
    var girPercentage: Double
    var scramblingPercentage: Double
    var averageDrivingDistance: Double?

    var strokesGainedDriving: Double?
    var strokesGainedApproach: Double?
    var strokesGainedShortGame: Double?
    var strokesGainedPutting: Double?
}

struct PerformanceTrend: Identifiable {
    var id = UUID()
    var date: Date
    var value: Double
    var category: StatCategory
}

enum StatCategory: String, CaseIterable, Identifiable {
    var id: String { rawValue }

    case scoring = "Scoring"
    case putting = "Putting"
    case fairways = "Fairways"
    case gir = "Greens in Regulation"
    case scrambling = "Scrambling"
    case handicap = "Handicap"
}

struct HeadToHead: Identifiable {
    var id: String { playerAID + "-" + playerBID }
    var playerAID: String
    var playerAName: String
    var playerBID: String
    var playerBName: String
    var playerAWins: Int
    var playerBWins: Int
    var ties: Int
    var totalMoneyExchanged: Double
    var playerANetMoney: Double
}

struct LeaderboardEntry: Identifiable {
    var id: String { playerID }
    var playerID: String
    var playerName: String
    var photoURL: String?
    var value: Double
    var rank: Int
}
