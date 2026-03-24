import Foundation
import FirebaseFirestore

@MainActor
final class RoundViewModel: ObservableObject {
    @Published var currentRound: GolfRound?
    @Published var scorecards: [String: Scorecard] = [:]
    @Published var currentHole: Int = 1
    @Published var isLoading = false
    @Published var error: String?
    @Published var gameResults: [String: Any] = [:]

    private let db = FirestoreService.shared
    private let gameEngine = GameEngine.shared
    private var listener: ListenerRegistration?

    // MARK: - Round Lifecycle

    func createRound(
        course: GolfCourse,
        players: [UserProfile],
        games: [ActiveGame]
    ) async {
        guard let courseID = course.id else { return }
        isLoading = true

        var cards: [String: Scorecard] = [:]
        for player in players {
            guard let pid = player.id else { continue }
            let courseHcp = HandicapService.shared.courseHandicap(
                index: player.handicapIndex ?? 0,
                slopeRating: course.slopeRating
            )
            let emptyHoles = course.holes.map { hole in
                HoleScore(
                    holeNumber: hole.number,
                    strokes: 0,
                    putts: 0,
                    fairwayHit: nil,
                    greenInRegulation: false,
                    penalties: 0,
                    sandShots: 0,
                    isComplete: false
                )
            }
            cards[pid] = Scorecard(
                playerID: pid,
                playerName: player.displayName,
                courseHandicap: courseHcp,
                holeScores: emptyHoles,
                totalGross: 0,
                totalNet: 0,
                totalPutts: 0,
                fairwaysHit: 0,
                greensInRegulation: 0
            )
        }

        let round = GolfRound(
            id: nil,
            courseID: courseID,
            courseName: course.name,
            playerIDs: players.compactMap(\.id),
            createdBy: players.first?.id ?? "",
            date: Date(),
            status: .inProgress,
            scorecards: cards,
            activeGames: games,
            moneyPot: MoneyPot(totalPot: 0, perPlayerStake: 0, ledger: [], settlements: [], isSettled: false),
            courseRating: course.courseRating,
            slopeRating: course.slopeRating,
            holePars: course.holes.sorted(by: { $0.number < $1.number }).map(\.par)
        )

        do {
            let docID = try await db.create(round, in: GolfRound.collectionName)
            var saved = round
            saved.id = docID
            currentRound = saved
            scorecards = cards
            startListening(roundID: docID)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Score Entry

    func updateScore(
        playerID: String,
        hole: Int,
        strokes: Int,
        putts: Int,
        fairwayHit: Bool?,
        gir: Bool,
        penalties: Int = 0,
        sandShots: Int = 0
    ) async {
        guard var card = scorecards[playerID],
              let roundID = currentRound?.id else { return }

        let index = hole - 1
        guard index >= 0, index < card.holeScores.count else { return }

        card.holeScores[index] = HoleScore(
            holeNumber: hole,
            strokes: strokes,
            putts: putts,
            fairwayHit: fairwayHit,
            greenInRegulation: gir,
            penalties: penalties,
            sandShots: sandShots,
            isComplete: true
        )

        // Recalculate totals
        card.totalGross = card.holeScores.filter(\.isComplete).reduce(0) { $0 + $1.strokes }
        card.totalPutts = card.holeScores.filter(\.isComplete).reduce(0) { $0 + $1.putts }
        card.fairwaysHit = card.holeScores.filter(\.isComplete).compactMap(\.fairwayHit).filter { $0 }.count
        card.greensInRegulation = card.holeScores.filter(\.isComplete).filter(\.greenInRegulation).count

        let netStrokes = GameEngine.shared.calculateStableford(
            scorecards: [playerID: card],
            holePars: currentRound?.activeGames.isEmpty == false ? [] : [],
            stakes: 0,
            useNet: true
        )
        _ = netStrokes  // Net calculated in game engine

        scorecards[playerID] = card

        do {
            try await db.updateFields(
                in: GolfRound.collectionName,
                documentID: roundID,
                fields: ["scorecards.\(playerID)": card.asDictionary()]
            )
            recalculateGames()
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Game Calculation

    func recalculateGames() {
        guard let round = currentRound else { return }
        let holePars = round.holePars.isEmpty ? Array(repeating: 4, count: 18) : round.holePars

        for game in round.activeGames {
            guard let format = GameFormat(rawValue: game.gameType) else { continue }

            switch format {
            case .nassau:
                let result = gameEngine.calculateNassau(
                    scorecards: scorecards,
                    stakes: game.stakes,
                    useNet: !game.isGrossScoring
                )
                gameResults["nassau"] = result

            case .skins:
                let result = gameEngine.calculateSkins(
                    scorecards: scorecards,
                    stakePerSkin: game.stakes,
                    useNet: !game.isGrossScoring
                )
                gameResults["skins"] = result

            case .stableford:
                let result = gameEngine.calculateStableford(
                    scorecards: scorecards,
                    holePars: holePars,
                    stakes: game.stakes,
                    useNet: !game.isGrossScoring
                )
                gameResults["stableford"] = result

            case .matchPlay:
                let players = Array(scorecards.keys)
                if players.count >= 2 {
                    let result = gameEngine.calculateMatchPlay(
                        playerA: players[0],
                        playerB: players[1],
                        scorecards: scorecards,
                        useNet: !game.isGrossScoring
                    )
                    gameResults["matchPlay"] = result
                }

            case .snake:
                let result = gameEngine.calculateSnake(scorecards: scorecards, stakes: game.stakes)
                gameResults["snake"] = result

            case .wolf:
                let players = Array(scorecards.keys)
                if players.count == 4 {
                    let result = gameEngine.calculateWolf(
                        scorecards: scorecards,
                        playerOrder: players,
                        wolfChoices: [:],
                        stakes: game.stakes
                    )
                    gameResults["wolf"] = result
                }

            case .bingoBangoBongo:
                let result = gameEngine.calculateBingoBangoBongo(
                    scorecards: scorecards,
                    stakePerPoint: game.stakes
                )
                gameResults["bingoBangoBongo"] = result

            case .lasVegas:
                let teams = game.teamAssignments ?? [:]
                let team1 = teams.filter { $0.value == 1 }.map(\.key)
                let team2 = teams.filter { $0.value == 2 }.map(\.key)
                if team1.count == 2, team2.count == 2 {
                    let result = gameEngine.calculateLasVegas(
                        team1: team1,
                        team2: team2,
                        scorecards: scorecards,
                        stakes: game.stakes
                    )
                    gameResults["lasVegas"] = result
                }

            case .sixes:
                let players = Array(scorecards.keys)
                if players.count == 4 {
                    let result = gameEngine.calculateSixes(
                        players: players,
                        scorecards: scorecards,
                        stakes: game.stakes,
                        useNet: !game.isGrossScoring
                    )
                    gameResults["sixes"] = result
                }

            case .ninePoint:
                let players = Array(scorecards.keys)
                if players.count == 3 {
                    let result = gameEngine.calculateNinePoint(
                        players: players,
                        scorecards: scorecards,
                        stakes: game.stakes,
                        useNet: !game.isGrossScoring
                    )
                    gameResults["ninePoint"] = result
                }

            case .dots:
                let result = gameEngine.calculateDots(
                    scorecards: scorecards,
                    holePars: holePars,
                    stakePerDot: game.stakes
                )
                gameResults["dots"] = result

            case .bestBall:
                let teams = game.teamAssignments ?? [:]
                let team1 = teams.filter { $0.value == 1 }.map(\.key)
                let team2 = teams.filter { $0.value == 2 }.map(\.key)
                if !team1.isEmpty, !team2.isEmpty {
                    let result = gameEngine.calculateBestBall(
                        team1: team1,
                        team2: team2,
                        scorecards: scorecards,
                        stakes: game.stakes,
                        useNet: !game.isGrossScoring
                    )
                    gameResults["bestBall"] = result
                }

            case .banker:
                let players = Array(scorecards.keys)
                if players.count >= 2 {
                    let result = gameEngine.calculateBanker(
                        players: players,
                        scorecards: scorecards,
                        stakes: game.stakes,
                        useNet: !game.isGrossScoring
                    )
                    gameResults["banker"] = result
                }

            case .custom:
                break
            }
        }
    }

    // MARK: - Round Completion

    func completeRound() async {
        guard let roundID = currentRound?.id else { return }
        do {
            try await db.updateFields(
                in: GolfRound.collectionName,
                documentID: roundID,
                fields: ["status": GolfRound.RoundStatus.completed.rawValue]
            )
            currentRound?.status = .completed

            // Save handicap records for each player
            for (pid, card) in scorecards {
                guard let round = currentRound else { continue }
                let diff = HandicapService.shared.scoreDifferential(
                    adjustedGross: card.totalGross,
                    courseRating: round.courseRating,
                    slopeRating: round.slopeRating
                )
                let record = HandicapRecord(
                    userID: pid,
                    courseID: round.courseID,
                    courseName: round.courseName,
                    date: round.date,
                    grossScore: card.totalGross,
                    adjustedGrossScore: card.totalGross,
                    courseRating: round.courseRating,
                    slopeRating: round.slopeRating,
                    scoreDifferential: diff,
                    isExceptional: false
                )
                try? await HandicapService.shared.saveRecord(record)
                _ = try? await HandicapService.shared.recalculateAndSave(userID: pid)
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Real-time Sync

    func startListening(roundID: String) {
        listener?.remove()
        listener = db.listen(to: GolfRound.collectionName, documentID: roundID) { [weak self] (round: GolfRound?) in
            Task { @MainActor in
                guard let round else { return }
                self?.currentRound = round
                self?.scorecards = round.scorecards
                self?.recalculateGames()
            }
        }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }
}

// MARK: - Codable Helper

extension Scorecard {
    func asDictionary() -> [String: Any] {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(self),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return [:]
        }
        return dict
    }
}
