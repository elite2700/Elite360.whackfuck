import Foundation
import FirebaseFirestore

// MARK: - Game Definitions

enum GameFormat: String, Codable, CaseIterable, Identifiable {
    var id: String { rawValue }

    case nassau = "Nassau"
    case skins = "Skins"
    case wolf = "Wolf"
    case bingoBangoBongo = "Bingo Bango Bongo"
    case dots = "Dots / Garbage"
    case lasVegas = "Las Vegas"
    case sixes = "Sixes / Round Robin"
    case stableford = "Stableford"
    case matchPlay = "Match Play"
    case snake = "Snake"
    case banker = "Banker"
    case ninePoint = "9-Point / Niners"
    case bestBall = "Best Ball"
    case custom = "Custom"

    var description: String {
        switch self {
        case .nassau: return "Three separate bets: front 9, back 9, and overall 18. Optional presses when trailing."
        case .skins: return "Each hole is worth a 'skin'. Ties carry over to the next hole. Gross or net options."
        case .wolf: return "Rotating 'Wolf' chooses to go alone (1v3) or pick a partner (2v2) after seeing drives."
        case .bingoBangoBongo: return "Points for: first on green (Bingo), closest to pin once all on (Bango), first to hole out (Bongo)."
        case .dots: return "Side bets for pars, birdies, sand saves, greenies, and other achievements."
        case .lasVegas: return "Pair team scores as a two-digit number (e.g., 4&5 = 45). Lowest combo wins the hole."
        case .sixes: return "Rotating partners every 6 holes. Three different pairings per round."
        case .stableford: return "Points-based scoring: double bogey+ = 0, bogey = 1, par = 2, birdie = 3, eagle = 4, albatross = 5."
        case .matchPlay: return "Hole-by-hole competition. Win the hole, halve it, or lose it. First to be up by more holes than remain wins."
        case .snake: return "Last player to 3-putt holds the 'snake'. Whoever has it at the end pays everyone."
        case .banker: return "One player 'banks' each hole. Others bet against the banker. Rotate banker assignment."
        case .ninePoint: return "9 points distributed each hole among 3 players: 5-3-1 for all different, 4-4-1 for two tied, 3-3-3 all tied."
        case .bestBall: return "Team format: best score among team members counts on each hole."
        case .custom: return "Build your own game with custom rules, points, and triggers."
        }
    }

    var minPlayers: Int {
        switch self {
        case .wolf: return 4
        case .ninePoint: return 3
        case .sixes: return 4
        case .lasVegas: return 4
        default: return 2
        }
    }

    var maxPlayers: Int {
        switch self {
        case .wolf: return 4
        case .ninePoint: return 3
        case .lasVegas: return 4
        default: return 8
        }
    }

    var isPremiumOnly: Bool {
        switch self {
        case .nassau, .skins: return false
        default: return true
        }
    }
}

struct CustomGameDefinition: Codable, Identifiable {
    @DocumentID var id: String?
    var name: String
    var createdBy: String
    var description: String
    var isTeamGame: Bool
    var scoringType: ScoringType
    var pointsPerHole: Double
    var pressEnabled: Bool
    var pressThreshold: Int
    var autoPress: Bool
    var useNetScoring: Bool
    var minStakes: Double
    var maxStakes: Double
    var specialRules: [SpecialRule]
    var createdAt: Date

    enum ScoringType: String, Codable {
        case perHole, perPoint, aggregate, matchPlay
    }

    struct SpecialRule: Codable, Identifiable {
        var id = UUID().uuidString
        var trigger: String
        var effect: String
        var pointValue: Double
    }

    static let collectionName = "customGames"
}
