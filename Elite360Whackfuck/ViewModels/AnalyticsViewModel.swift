import Foundation

@MainActor
final class AnalyticsViewModel: ObservableObject {
    @Published var roundHistory: [GolfRound] = []
    @Published var handicapRecords: [HandicapRecord] = []
    @Published var trends: [PerformanceTrend] = []
    @Published var currentAnalytics: RoundAnalytics?
    @Published var leaderboard: [LeaderboardEntry] = []
    @Published var headToHeadRecords: [HeadToHead] = []
    @Published var isLoading = false

    private let db = FirestoreService.shared

    func loadHistory(for userID: String) async {
        isLoading = true
        do {
            roundHistory = try await db.query(
                collection: GolfRound.collectionName,
                field: "playerIDs",
                arrayContains: userID
            )
            roundHistory.sort { $0.date > $1.date }

            handicapRecords = try await HandicapService.shared.fetchRecords(for: userID)
            handicapRecords.sort { $0.date > $1.date }

            calculateTrends(for: userID)
            calculateCurrentAnalytics(for: userID)
        } catch {
            // Handle gracefully
        }
        isLoading = false
    }

    private func calculateTrends(for userID: String) {
        trends = []

        // Scoring trend
        for record in handicapRecords.suffix(20).reversed() {
            trends.append(PerformanceTrend(
                date: record.date,
                value: Double(record.grossScore),
                category: .scoring
            ))
        }

        // Handicap trend
        var runningDiffs: [Double] = []
        for record in handicapRecords.reversed() {
            runningDiffs.append(record.scoreDifferential)
            if let snapshot = HandicapService.shared.calculateHandicapIndex(from: runningDiffs) {
                trends.append(PerformanceTrend(
                    date: record.date,
                    value: snapshot.handicapIndex,
                    category: .handicap
                ))
            }
        }

        // GIR / Fairway / Putting trends from rounds
        for round in roundHistory.prefix(20) {
            guard let card = round.scorecards[userID] else { continue }
            let holes = card.holeScores.filter(\.isComplete)
            guard !holes.isEmpty else { continue }

            trends.append(PerformanceTrend(
                date: round.date,
                value: Double(card.greensInRegulation) / Double(holes.count) * 100,
                category: .gir
            ))

            trends.append(PerformanceTrend(
                date: round.date,
                value: Double(card.totalPutts) / Double(holes.count),
                category: .putting
            ))

            trends.append(PerformanceTrend(
                date: round.date,
                value: Double(card.fairwaysHit) / 14.0 * 100,
                category: .fairways
            ))
        }
    }

    private func calculateCurrentAnalytics(for userID: String) {
        let recentRounds = roundHistory.prefix(10).compactMap { $0.scorecards[userID] }
        guard !recentRounds.isEmpty else { return }

        let avgScore = recentRounds.map { Double($0.totalGross) }.reduce(0, +) / Double(recentRounds.count)
        let avgPutts = recentRounds.map { Double($0.totalPutts) }.reduce(0, +) / Double(recentRounds.count)

        let totalHoles = recentRounds.flatMap(\.holeScores).filter(\.isComplete)
        let fwPct = Double(recentRounds.map(\.fairwaysHit).reduce(0, +)) / (14.0 * Double(recentRounds.count)) * 100
        let girPct = Double(recentRounds.map(\.greensInRegulation).reduce(0, +)) / Double(totalHoles.count) * 100

        currentAnalytics = RoundAnalytics(
            averageScore: avgScore,
            averagePutts: avgPutts,
            fairwayPercentage: fwPct,
            girPercentage: girPct,
            scramblingPercentage: 0 // would need more data
        )
    }

    // MARK: - Leaderboards

    func loadLeaderboard(friendIDs: [String], category: StatCategory) async {
        // Load profiles and compare
        leaderboard = []
        var entries: [LeaderboardEntry] = []

        for friendID in friendIDs {
            let records: [HandicapRecord] = (try? await HandicapService.shared.fetchRecords(for: friendID)) ?? []
            guard !records.isEmpty else { continue }
            let profile: UserProfile? = try? await db.getDocument(from: UserProfile.collectionName, documentID: friendID)

            let value: Double
            switch category {
            case .handicap: value = profile?.handicapIndex ?? 99
            case .scoring: value = records.map { Double($0.grossScore) }.reduce(0, +) / Double(records.count)
            default: value = 0
            }

            entries.append(LeaderboardEntry(
                playerID: friendID,
                playerName: profile?.displayName ?? "Unknown",
                photoURL: profile?.photoURL,
                value: value,
                rank: 0
            ))
        }

        entries.sort { $0.value < $1.value }
        for i in entries.indices {
            entries[i].rank = i + 1
        }
        leaderboard = entries
    }

    // MARK: - Export

    func exportCSV(for userID: String) -> String {
        var csv = "Date,Course,Gross Score,Net Score,Putts,FIR,GIR,Differential\n"
        for record in handicapRecords {
            csv += "\(record.date),\(record.courseName),\(record.grossScore),"
            csv += "\(record.adjustedGrossScore),0,0,0,\(String(format: "%.1f", record.scoreDifferential))\n"
        }
        return csv
    }
}
