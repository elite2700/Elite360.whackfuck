import Foundation

struct AICaddyAdvice: Identifiable {
    var id = UUID()
    var type: AdviceType
    var title: String
    var message: String
    var confidence: Double
    var timestamp: Date

    enum AdviceType: String {
        case clubSelection = "Club Selection"
        case shotStrategy = "Shot Strategy"
        case courseManagement = "Course Management"
        case postRoundInsight = "Post-Round Insight"
        case practiceRecommendation = "Practice Tip"
    }
}

struct ShotContext {
    var distanceToPin: Int
    var lie: LieType
    var elevation: ElevationChange
    var windSpeed: Double?
    var windDirection: WindDirection?
    var temperature: Double?
    var targetType: TargetType

    enum LieType: String, CaseIterable {
        case fairway, rough, deepRough, bunker, hardpan, divot, uphill, downhill, sidehill
    }

    enum ElevationChange: String, CaseIterable {
        case uphill, downhill, level
    }

    enum WindDirection: String, CaseIterable {
        case headwind, tailwind, leftToRight, rightToLeft, calm
    }

    enum TargetType: String, CaseIterable {
        case green, fairway, layup
    }
}

struct ClubData: Identifiable {
    var id: String { name }
    var name: String
    var averageDistance: Int
    var minDistance: Int
    var maxDistance: Int
}
