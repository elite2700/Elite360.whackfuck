import Foundation

/// Calculates Handicap Index per USGA/World Handicap System rules.
/// Uses best 8 of last 20 Score Differentials with exceptional score safeguards.
final class HandicapService {
    static let shared = HandicapService()
    private let db = FirestoreService.shared

    private init() {}

    // MARK: - Score Differential

    /// Score Differential = (113 / Slope Rating) × (Adjusted Gross Score − Course Rating)
    func scoreDifferential(adjustedGross: Int, courseRating: Double, slopeRating: Int) -> Double {
        (113.0 / Double(slopeRating)) * (Double(adjustedGross) - courseRating)
    }

    // MARK: - Handicap Index Calculation

    /// Calculates handicap index from an array of score differentials (up to 20 most recent).
    /// Returns nil if fewer than 3 rounds.
    func calculateHandicapIndex(from differentials: [Double]) -> HandicapSnapshot? {
        guard differentials.count >= 3 else { return nil }

        let recent20 = Array(differentials.suffix(20))
        let sorted = recent20.sorted()
        let count = recent20.count
        let usedCount: Int
        let adjustment: Double

        // Number of differentials to use based on available rounds
        switch count {
        case 3:  usedCount = 1; adjustment = -2.0
        case 4:  usedCount = 1; adjustment = -1.0
        case 5:  usedCount = 1; adjustment = 0.0
        case 6:  usedCount = 2; adjustment = -1.0
        case 7...8:  usedCount = 2; adjustment = 0.0
        case 9...10:  usedCount = 3; adjustment = 0.0
        case 11...12: usedCount = 4; adjustment = 0.0
        case 13...14: usedCount = 5; adjustment = 0.0
        case 15...16: usedCount = 6; adjustment = 0.0
        case 17...18: usedCount = 7; adjustment = 0.0
        case 19...20: usedCount = 8; adjustment = 0.0
        default: usedCount = 8; adjustment = 0.0
        }

        let bestDiffs = Array(sorted.prefix(usedCount))
        let average = bestDiffs.reduce(0.0, +) / Double(usedCount)
        var index = average + adjustment

        // Cap at 54.0
        index = min(index, 54.0)
        // Round to 1 decimal
        index = (index * 10).rounded() / 10

        let trend: HandicapTrend
        if let oldAvg = calculatePreviousAverage(from: differentials, currentUsed: usedCount) {
            if index < oldAvg - 0.5 { trend = .improving }
            else if index > oldAvg + 0.5 { trend = .declining }
            else { trend = .stable }
        } else {
            trend = .stable
        }

        return HandicapSnapshot(
            handicapIndex: index,
            calculatedAt: Date(),
            recordsUsed: usedCount,
            lowestDifferential: sorted.first ?? 0,
            highestUsedDifferential: bestDiffs.last ?? 0,
            trend: trend
        )
    }

    private func calculatePreviousAverage(from differentials: [Double], currentUsed: Int) -> Double? {
        guard differentials.count > 1 else { return nil }
        let previous = Array(differentials.dropLast())
        let sorted = previous.sorted()
        let used = min(currentUsed, sorted.count)
        guard used > 0 else { return nil }
        return Array(sorted.prefix(used)).reduce(0.0, +) / Double(used)
    }

    // MARK: - Course Handicap

    /// Course Handicap = Handicap Index × (Slope Rating / 113)
    func courseHandicap(index: Double, slopeRating: Int) -> Int {
        Int((index * Double(slopeRating) / 113.0).rounded())
    }

    // MARK: - Adjusted Gross Score (Equitable Stroke Control)

    func adjustedGrossScore(grossScore: Int, courseHandicap: Int, holeScores: [HoleScore], holePars: [Int]) -> Int {
        let maxPerHole = maxStrokesPerHole(courseHandicap: courseHandicap)
        var adjusted = 0
        for (i, score) in holeScores.enumerated() {
            let par = i < holePars.count ? holePars[i] : 4
            let cap = par + maxPerHole
            adjusted += min(score.strokes, cap)
        }
        return adjusted
    }

    private func maxStrokesPerHole(courseHandicap: Int) -> Int {
        switch courseHandicap {
        case ...9: return 2   // double bogey
        case 10...19: return 3
        case 20...29: return 4
        case 30...39: return 5
        default: return 6
        }
    }

    // MARK: - Exceptional Score Detection

    func isExceptionalScore(differential: Double, handicapIndex: Double) -> Bool {
        differential <= handicapIndex - 7.0
    }

    // MARK: - Persistence

    func saveRecord(_ record: HandicapRecord) async throws {
        _ = try await db.create(record, in: HandicapRecord.collectionName)
    }

    func fetchRecords(for userID: String) async throws -> [HandicapRecord] {
        try await db.query(collection: HandicapRecord.collectionName, field: "userID", isEqualTo: userID)
    }

    func recalculateAndSave(userID: String) async throws -> HandicapSnapshot? {
        let records: [HandicapRecord] = try await fetchRecords(for: userID)
        let sorted = records.sorted { $0.date > $1.date }
        let diffs = sorted.map(\.scoreDifferential)
        guard let snapshot = calculateHandicapIndex(from: diffs) else { return nil }

        try await db.updateFields(
            in: UserProfile.collectionName,
            documentID: userID,
            fields: ["handicapIndex": snapshot.handicapIndex, "updatedAt": Date()]
        )
        return snapshot
    }
}
