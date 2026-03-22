import Foundation

/// Engine for calculating all golf game types in real-time.
final class GameEngine {
    static let shared = GameEngine()
    private init() {}

    // MARK: - Nassau

    struct NassauResult {
        var frontNine: [String: Double]   // playerID -> winnings
        var backNine: [String: Double]
        var overall: [String: Double]
        var presses: [NassauPress]
        var total: [String: Double]
    }

    struct NassauPress {
        var startHole: Int
        var initiatedBy: String
        var stakes: Double
        var results: [String: Double]
    }

    func calculateNassau(
        scorecards: [String: Scorecard],
        stakes: Double,
        useNet: Bool,
        presses: [NassauPress] = []
    ) -> NassauResult {
        var front: [String: Double] = [:]
        var back: [String: Double] = [:]
        var overall: [String: Double] = [:]

        let players = Array(scorecards.keys)
        guard players.count >= 2 else {
            return NassauResult(frontNine: front, backNine: back, overall: overall, presses: presses, total: [:])
        }

        // Calculate totals per segment
        for pid in players {
            guard let card = scorecards[pid] else { continue }
            let scores = useNet ? netScores(card) : card.holeScores.map(\.strokes)
            front[pid] = Double(scores.prefix(9).reduce(0, +))
            back[pid] = Double(scores.dropFirst(9).prefix(9).reduce(0, +))
            overall[pid] = Double(scores.reduce(0, +))
        }

        // Convert to winnings (head-to-head for 2 players, low score for groups)
        let frontWinnings = distributeWinnings(scores: front, stakes: stakes)
        let backWinnings = distributeWinnings(scores: back, stakes: stakes)
        let overallWinnings = distributeWinnings(scores: overall, stakes: stakes)

        var total: [String: Double] = [:]
        for pid in players {
            total[pid] = (frontWinnings[pid] ?? 0) + (backWinnings[pid] ?? 0) + (overallWinnings[pid] ?? 0)
        }

        return NassauResult(
            frontNine: frontWinnings,
            backNine: backWinnings,
            overall: overallWinnings,
            presses: presses,
            total: total
        )
    }

    // MARK: - Skins

    struct SkinsResult {
        var skinWinners: [Int: String]        // hole -> winner playerID
        var carryoverHoles: [Int]
        var skinValues: [Int: Double]         // hole -> value
        var playerTotals: [String: Double]    // playerID -> total won
    }

    func calculateSkins(
        scorecards: [String: Scorecard],
        stakePerSkin: Double,
        useNet: Bool
    ) -> SkinsResult {
        var winners: [Int: String] = [:]
        var carryovers: [Int] = []
        var values: [Int: Double] = [:]
        var totals: [String: Double] = [:]
        var carryover = 0.0

        let holeCount = scorecards.values.first?.holeScores.count ?? 18

        for hole in 0..<holeCount {
            let holeNum = hole + 1
            var bestScore = Int.max
            var bestPlayers: [String] = []

            for (pid, card) in scorecards {
                guard hole < card.holeScores.count, card.holeScores[hole].isComplete else { continue }
                let score = useNet ? netScore(card, hole: hole) : card.holeScores[hole].strokes
                if score < bestScore {
                    bestScore = score
                    bestPlayers = [pid]
                } else if score == bestScore {
                    bestPlayers.append(pid)
                }
            }

            let skinValue = stakePerSkin + carryover

            if bestPlayers.count == 1, let winner = bestPlayers.first {
                winners[holeNum] = winner
                values[holeNum] = skinValue
                totals[winner, default: 0] += skinValue
                carryover = 0
            } else {
                carryovers.append(holeNum)
                carryover += stakePerSkin
            }
        }

        return SkinsResult(
            skinWinners: winners,
            carryoverHoles: carryovers,
            skinValues: values,
            playerTotals: totals
        )
    }

    // MARK: - Wolf

    struct WolfResult {
        var holeResults: [WolfHoleResult]
        var playerTotals: [String: Double]
    }

    struct WolfHoleResult {
        var holeNumber: Int
        var wolf: String
        var partner: String?
        var isLoneWolf: Bool
        var wolfTeamScore: Int
        var otherTeamScore: Int
        var wolfWon: Bool
        var pointValue: Double
    }

    func calculateWolf(
        scorecards: [String: Scorecard],
        playerOrder: [String],
        wolfChoices: [Int: WolfChoice],
        stakes: Double
    ) -> WolfResult {
        var results: [WolfHoleResult] = []
        var totals: [String: Double] = [:]

        for (pid, _) in scorecards {
            totals[pid] = 0
        }

        let holeCount = scorecards.values.first?.holeScores.count ?? 18

        for hole in 0..<holeCount {
            let wolfIndex = hole % playerOrder.count
            let wolf = playerOrder[wolfIndex]

            guard let choice = wolfChoices[hole + 1] else { continue }

            let isLone = choice.partner == nil
            let multiplier: Double = isLone ? 3.0 : 1.0

            var wolfTeam = [wolf]
            var otherTeam = playerOrder.filter { $0 != wolf }
            if let partner = choice.partner {
                wolfTeam.append(partner)
                otherTeam.removeAll { $0 == partner }
            }

            let wolfScore = bestScore(of: wolfTeam, in: scorecards, hole: hole)
            let otherScore = bestScore(of: otherTeam, in: scorecards, hole: hole)

            let wolfWon = wolfScore < otherScore
            let pointVal = stakes * multiplier

            if wolfWon {
                for pid in wolfTeam { totals[pid, default: 0] += pointVal }
                for pid in otherTeam { totals[pid, default: 0] -= pointVal / Double(otherTeam.count) }
            } else if wolfScore > otherScore {
                for pid in wolfTeam { totals[pid, default: 0] -= pointVal }
                for pid in otherTeam { totals[pid, default: 0] += pointVal / Double(wolfTeam.count) }
            }

            results.append(WolfHoleResult(
                holeNumber: hole + 1,
                wolf: wolf,
                partner: choice.partner,
                isLoneWolf: isLone,
                wolfTeamScore: wolfScore,
                otherTeamScore: otherScore,
                wolfWon: wolfWon,
                pointValue: pointVal
            ))
        }

        return WolfResult(holeResults: results, playerTotals: totals)
    }

    struct WolfChoice {
        var partner: String?
    }

    // MARK: - Bingo Bango Bongo

    struct BBBResult {
        var holePoints: [Int: [String: Int]]  // hole -> playerID -> points
        var playerTotals: [String: Int]
        var moneyTotals: [String: Double]
    }

    func calculateBingoBangoBongo(
        scorecards: [String: Scorecard],
        stakePerPoint: Double
    ) -> BBBResult {
        var holePoints: [Int: [String: Int]] = [:]
        var totals: [String: Int] = [:]

        // Simplified: award 1 point each for bingo/bango/bongo per hole
        // In full implementation, would use shot-by-shot data
        let holeCount = scorecards.values.first?.holeScores.count ?? 18

        for hole in 0..<holeCount {
            var points: [String: Int] = [:]
            let holeNum = hole + 1

            // Bingo: lowest score on hole (approximation for "first on green")
            // Bango: closest to pin — use fewest putts as proxy
            // Bongo: first to hole out — lowest total strokes

            var lowestStrokes = Int.max
            var lowestStrokesPlayer: String?
            var lowestPutts = Int.max
            var lowestPuttsPlayer: String?

            for (pid, card) in scorecards {
                guard hole < card.holeScores.count, card.holeScores[hole].isComplete else { continue }
                let s = card.holeScores[hole]
                if s.strokes < lowestStrokes {
                    lowestStrokes = s.strokes
                    lowestStrokesPlayer = pid
                }
                if s.putts < lowestPutts {
                    lowestPutts = s.putts
                    lowestPuttsPlayer = pid
                }
            }

            if let p = lowestStrokesPlayer {
                points[p, default: 0] += 1  // Bingo
                points[p, default: 0] += 1  // Bongo
            }
            if let p = lowestPuttsPlayer {
                points[p, default: 0] += 1  // Bango
            }

            holePoints[holeNum] = points
            for (pid, pts) in points {
                totals[pid, default: 0] += pts
            }
        }

        let avgPoints = totals.values.isEmpty ? 0 : Double(totals.values.reduce(0, +)) / Double(totals.count)
        var money: [String: Double] = [:]
        for (pid, pts) in totals {
            money[pid] = (Double(pts) - avgPoints) * stakePerPoint
        }

        return BBBResult(holePoints: holePoints, playerTotals: totals, moneyTotals: money)
    }

    // MARK: - Stableford

    struct StablefordResult {
        var holePoints: [String: [Int]]   // playerID -> points per hole
        var totalPoints: [String: Int]
        var moneyResults: [String: Double]
    }

    func calculateStableford(
        scorecards: [String: Scorecard],
        holePars: [Int],
        stakes: Double,
        useNet: Bool
    ) -> StablefordResult {
        var holePoints: [String: [Int]] = [:]
        var totalPoints: [String: Int] = [:]

        for (pid, card) in scorecards {
            var points: [Int] = []
            for (i, score) in card.holeScores.enumerated() {
                let par = i < holePars.count ? holePars[i] : 4
                let strokes = useNet ? netScore(card, hole: i) : score.strokes
                let diff = strokes - par
                let pts: Int
                switch diff {
                case ...(-3): pts = 5  // albatross or better
                case -2: pts = 4       // eagle
                case -1: pts = 3       // birdie
                case 0:  pts = 2       // par
                case 1:  pts = 1       // bogey
                default: pts = 0       // double bogey+
                }
                points.append(pts)
            }
            holePoints[pid] = points
            totalPoints[pid] = points.reduce(0, +)
        }

        let avgPts = totalPoints.values.isEmpty ? 0 : Double(totalPoints.values.reduce(0, +)) / Double(totalPoints.count)
        var money: [String: Double] = [:]
        for (pid, pts) in totalPoints {
            money[pid] = (Double(pts) - avgPts) * stakes
        }

        return StablefordResult(holePoints: holePoints, totalPoints: totalPoints, moneyResults: money)
    }

    // MARK: - Match Play

    struct MatchPlayResult {
        var holeResults: [Int: MatchPlayHole]
        var currentStatus: String  // e.g., "Player A 2 UP with 5 to play"
        var isComplete: Bool
        var winner: String?
        var margin: String?
    }

    struct MatchPlayHole {
        var holeNumber: Int
        var winner: String?  // nil = halved
    }

    func calculateMatchPlay(
        playerA: String,
        playerB: String,
        scorecards: [String: Scorecard],
        useNet: Bool
    ) -> MatchPlayResult {
        var holes: [Int: MatchPlayHole] = [:]
        var aUp = 0
        let holeCount = scorecards.values.first?.holeScores.count ?? 18
        var lastCompletedHole = 0

        for hole in 0..<holeCount {
            guard let cardA = scorecards[playerA],
                  let cardB = scorecards[playerB],
                  hole < cardA.holeScores.count,
                  hole < cardB.holeScores.count,
                  cardA.holeScores[hole].isComplete,
                  cardB.holeScores[hole].isComplete else { break }

            lastCompletedHole = hole + 1
            let scoreA = useNet ? netScore(cardA, hole: hole) : cardA.holeScores[hole].strokes
            let scoreB = useNet ? netScore(cardB, hole: hole) : cardB.holeScores[hole].strokes

            let winner: String?
            if scoreA < scoreB { aUp += 1; winner = playerA }
            else if scoreB < scoreA { aUp -= 1; winner = playerB }
            else { winner = nil }

            holes[hole + 1] = MatchPlayHole(holeNumber: hole + 1, winner: winner)
        }

        let remaining = holeCount - lastCompletedHole
        let isComplete = remaining == 0 || abs(aUp) > remaining
        let leadingPlayer = aUp > 0 ? playerA : playerB
        let margin = abs(aUp)

        let status: String
        if aUp == 0 { status = "All Square" }
        else if isComplete {
            status = "\(scorecards[leadingPlayer]?.playerName ?? leadingPlayer) wins \(margin) & \(remaining)"
        } else {
            status = "\(scorecards[leadingPlayer]?.playerName ?? leadingPlayer) \(margin) UP with \(remaining) to play"
        }

        return MatchPlayResult(
            holeResults: holes,
            currentStatus: status,
            isComplete: isComplete,
            winner: isComplete && aUp != 0 ? leadingPlayer : nil,
            margin: isComplete && aUp != 0 ? "\(margin) & \(remaining)" : nil
        )
    }

    // MARK: - Las Vegas

    struct LasVegasResult {
        var holeResults: [Int: LasVegasHole]
        var teamTotals: [Int: Int]  // team -> combined number
        var moneyResults: [String: Double]
    }

    struct LasVegasHole {
        var holeNumber: Int
        var team1Number: Int  // e.g., 45
        var team2Number: Int  // e.g., 56
        var difference: Int
        var winningTeam: Int?
    }

    func calculateLasVegas(
        team1: [String],
        team2: [String],
        scorecards: [String: Scorecard],
        stakes: Double
    ) -> LasVegasResult {
        var holes: [Int: LasVegasHole] = [:]
        var teamTotals: [Int: Int] = [1: 0, 2: 0]
        let holeCount = scorecards.values.first?.holeScores.count ?? 18

        for hole in 0..<holeCount {
            let t1scores = team1.compactMap { scorecards[$0]?.holeScores[safe: hole]?.strokes }.sorted()
            let t2scores = team2.compactMap { scorecards[$0]?.holeScores[safe: hole]?.strokes }.sorted()

            guard t1scores.count == 2, t2scores.count == 2 else { continue }

            // Lower score first: 4,5 -> 45; flip if team lost hole: 5,4 -> 54
            let t1num = t1scores[0] * 10 + t1scores[1]
            let t2num = t2scores[0] * 10 + t2scores[1]
            let diff = abs(t1num - t2num)

            let winner: Int? = t1num < t2num ? 1 : (t2num < t1num ? 2 : nil)
            teamTotals[1, default: 0] += t1num
            teamTotals[2, default: 0] += t2num

            holes[hole + 1] = LasVegasHole(
                holeNumber: hole + 1,
                team1Number: t1num,
                team2Number: t2num,
                difference: diff,
                winningTeam: winner
            )
        }

        let totalDiff = (teamTotals[1] ?? 0) - (teamTotals[2] ?? 0)
        var money: [String: Double] = [:]
        let perPlayer = Double(abs(totalDiff)) * stakes

        if totalDiff < 0 { // team 1 wins (lower is better)
            for pid in team1 { money[pid] = perPlayer }
            for pid in team2 { money[pid] = -perPlayer }
        } else if totalDiff > 0 {
            for pid in team2 { money[pid] = perPlayer }
            for pid in team1 { money[pid] = -perPlayer }
        }

        return LasVegasResult(holeResults: holes, teamTotals: teamTotals, moneyResults: money)
    }

    // MARK: - Snake

    struct SnakeResult {
        var currentSnakeHolder: String?
        var threePuttHoles: [Int: String]  // hole -> player who 3-putted
        var moneyResult: [String: Double]
    }

    func calculateSnake(
        scorecards: [String: Scorecard],
        stakes: Double
    ) -> SnakeResult {
        var holder: String?
        var threePutts: [Int: String] = [:]
        let holeCount = scorecards.values.first?.holeScores.count ?? 18

        for hole in 0..<holeCount {
            for (pid, card) in scorecards {
                guard hole < card.holeScores.count, card.holeScores[hole].isComplete else { continue }
                if card.holeScores[hole].putts >= 3 {
                    holder = pid
                    threePutts[hole + 1] = pid
                }
            }
        }

        var money: [String: Double] = [:]
        let playerCount = scorecards.count
        if let snake = holder {
            money[snake] = -stakes * Double(playerCount - 1)
            for pid in scorecards.keys where pid != snake {
                money[pid] = stakes
            }
        }

        return SnakeResult(currentSnakeHolder: holder, threePuttHoles: threePutts, moneyResult: money)
    }

    // MARK: - 9-Point / Niners

    struct NinePointResult {
        var holePoints: [Int: [String: Int]]
        var totalPoints: [String: Int]
        var moneyResults: [String: Double]
    }

    func calculateNinePoint(
        players: [String],  // exactly 3 players
        scorecards: [String: Scorecard],
        stakes: Double,
        useNet: Bool
    ) -> NinePointResult {
        guard players.count == 3 else {
            return NinePointResult(holePoints: [:], totalPoints: [:], moneyResults: [:])
        }

        var holePoints: [Int: [String: Int]] = [:]
        var totals: [String: Int] = [:]

        let holeCount = scorecards.values.first?.holeScores.count ?? 18

        for hole in 0..<holeCount {
            let holeNum = hole + 1
            var scores: [(String, Int)] = []

            for pid in players {
                guard let card = scorecards[pid], hole < card.holeScores.count else { continue }
                let s = useNet ? netScore(card, hole: hole) : card.holeScores[hole].strokes
                scores.append((pid, s))
            }

            guard scores.count == 3 else { continue }
            scores.sort { $0.1 < $1.1 }

            var points: [String: Int] = [:]

            if scores[0].1 == scores[1].1 && scores[1].1 == scores[2].1 {
                // All tied: 3-3-3
                for (pid, _) in scores { points[pid] = 3 }
            } else if scores[0].1 == scores[1].1 {
                // Two tied for best: 4-4-1
                points[scores[0].0] = 4
                points[scores[1].0] = 4
                points[scores[2].0] = 1
            } else if scores[1].1 == scores[2].1 {
                // Two tied for worst: 5-2-2
                points[scores[0].0] = 5
                points[scores[1].0] = 2
                points[scores[2].0] = 2
            } else {
                // All different: 5-3-1
                points[scores[0].0] = 5
                points[scores[1].0] = 3
                points[scores[2].0] = 1
            }

            holePoints[holeNum] = points
            for (pid, pts) in points {
                totals[pid, default: 0] += pts
            }
        }

        // Money: each point worth stakes; settle against average
        let avgPts = Double(totals.values.reduce(0, +)) / 3.0
        var money: [String: Double] = [:]
        for (pid, pts) in totals {
            money[pid] = (Double(pts) - avgPts) * stakes
        }

        return NinePointResult(holePoints: holePoints, totalPoints: totals, moneyResults: money)
    }

    // MARK: - Sixes / Round Robin

    struct SixesResult {
        var segments: [SixesSegment]
        var playerTotals: [String: Double]
    }

    struct SixesSegment {
        var holes: ClosedRange<Int>
        var team1: [String]
        var team2: [String]
        var team1Score: Int
        var team2Score: Int
        var winner: Int?
        var pointValue: Double
    }

    func calculateSixes(
        players: [String],  // exactly 4 players
        scorecards: [String: Scorecard],
        stakes: Double,
        useNet: Bool
    ) -> SixesResult {
        guard players.count == 4 else {
            return SixesResult(segments: [], playerTotals: [:])
        }

        // Three pairings rotating every 6 holes:
        // Holes 1-6: AB vs CD, Holes 7-12: AC vs BD, Holes 13-18: AD vs BC
        let pairings: [([String], [String])] = [
            ([players[0], players[1]], [players[2], players[3]]),
            ([players[0], players[2]], [players[1], players[3]]),
            ([players[0], players[3]], [players[1], players[2]])
        ]

        var segments: [SixesSegment] = []
        var totals: [String: Double] = [:]

        for (i, (team1, team2)) in pairings.enumerated() {
            let startHole = i * 6
            let endHole = min(startHole + 5, 17)

            var t1score = 0, t2score = 0

            for hole in startHole...endHole {
                let t1best = team1.compactMap { pid -> Int? in
                    guard let card = scorecards[pid], hole < card.holeScores.count else { return nil }
                    return useNet ? netScore(card, hole: hole) : card.holeScores[hole].strokes
                }.min() ?? 0

                let t2best = team2.compactMap { pid -> Int? in
                    guard let card = scorecards[pid], hole < card.holeScores.count else { return nil }
                    return useNet ? netScore(card, hole: hole) : card.holeScores[hole].strokes
                }.min() ?? 0

                t1score += t1best
                t2score += t2best
            }

            let winner: Int? = t1score < t2score ? 1 : (t2score < t1score ? 2 : nil)

            if let w = winner {
                let winners = w == 1 ? team1 : team2
                let losers = w == 1 ? team2 : team1
                for pid in winners { totals[pid, default: 0] += stakes }
                for pid in losers { totals[pid, default: 0] -= stakes }
            }

            segments.append(SixesSegment(
                holes: (startHole + 1)...(endHole + 1),
                team1: team1,
                team2: team2,
                team1Score: t1score,
                team2Score: t2score,
                winner: winner,
                pointValue: stakes
            ))
        }

        return SixesResult(segments: segments, playerTotals: totals)
    }

    // MARK: - Dots / Garbage

    struct DotsResult {
        var playerDots: [String: [DotAward]]
        var playerTotals: [String: Int]
        var moneyResults: [String: Double]
    }

    struct DotAward {
        var holeNumber: Int
        var type: DotType
        var points: Int
    }

    enum DotType: String {
        case birdie = "Birdie"
        case eagle = "Eagle"
        case sandSave = "Sand Save"
        case greenie = "Greenie"
        case par = "Par"
        case chipIn = "Chip-In"
        case longestDrive = "Longest Drive"
    }

    func calculateDots(
        scorecards: [String: Scorecard],
        holePars: [Int],
        stakePerDot: Double
    ) -> DotsResult {
        var playerDots: [String: [DotAward]] = [:]
        var totals: [String: Int] = [:]

        for (pid, card) in scorecards {
            var dots: [DotAward] = []

            for (i, score) in card.holeScores.enumerated() {
                let par = i < holePars.count ? holePars[i] : 4
                let holeNum = i + 1

                if score.strokes <= par - 2 {
                    dots.append(DotAward(holeNumber: holeNum, type: .eagle, points: 4))
                } else if score.strokes == par - 1 {
                    dots.append(DotAward(holeNumber: holeNum, type: .birdie, points: 2))
                }

                if score.sandShots > 0 && score.strokes <= par {
                    dots.append(DotAward(holeNumber: holeNum, type: .sandSave, points: 2))
                }

                if score.greenInRegulation {
                    dots.append(DotAward(holeNumber: holeNum, type: .greenie, points: 1))
                }
            }

            playerDots[pid] = dots
            totals[pid] = dots.reduce(0) { $0 + $1.points }
        }

        let avgDots = totals.values.isEmpty ? 0.0 : Double(totals.values.reduce(0, +)) / Double(totals.count)
        var money: [String: Double] = [:]
        for (pid, pts) in totals {
            money[pid] = (Double(pts) - avgDots) * stakePerDot
        }

        return DotsResult(playerDots: playerDots, playerTotals: totals, moneyResults: money)
    }

    // MARK: - Best Ball

    struct BestBallResult {
        var holeWinners: [Int: Int]  // hole -> winning team
        var teamScores: [Int: [Int]] // team -> score per hole
        var teamTotals: [Int: Int]
        var moneyResults: [String: Double]
    }

    func calculateBestBall(
        team1: [String],
        team2: [String],
        scorecards: [String: Scorecard],
        stakes: Double,
        useNet: Bool
    ) -> BestBallResult {
        var winners: [Int: Int] = [:]
        var teamScores: [Int: [Int]] = [1: [], 2: []]
        let holeCount = scorecards.values.first?.holeScores.count ?? 18

        for hole in 0..<holeCount {
            let t1best = team1.compactMap { pid -> Int? in
                guard let card = scorecards[pid], hole < card.holeScores.count else { return nil }
                return useNet ? netScore(card, hole: hole) : card.holeScores[hole].strokes
            }.min() ?? 99

            let t2best = team2.compactMap { pid -> Int? in
                guard let card = scorecards[pid], hole < card.holeScores.count else { return nil }
                return useNet ? netScore(card, hole: hole) : card.holeScores[hole].strokes
            }.min() ?? 99

            teamScores[1]?.append(t1best)
            teamScores[2]?.append(t2best)

            if t1best < t2best { winners[hole + 1] = 1 }
            else if t2best < t1best { winners[hole + 1] = 2 }
        }

        let t1total = teamScores[1]?.reduce(0, +) ?? 0
        let t2total = teamScores[2]?.reduce(0, +) ?? 0

        var money: [String: Double] = [:]
        if t1total < t2total {
            for pid in team1 { money[pid] = stakes }
            for pid in team2 { money[pid] = -stakes }
        } else if t2total < t1total {
            for pid in team2 { money[pid] = stakes }
            for pid in team1 { money[pid] = -stakes }
        }

        return BestBallResult(
            holeWinners: winners,
            teamScores: teamScores,
            teamTotals: [1: t1total, 2: t2total],
            moneyResults: money
        )
    }

    // MARK: - Banker

    struct BankerResult {
        var holeResults: [Int: BankerHole]
        var playerTotals: [String: Double]
    }

    struct BankerHole {
        var holeNumber: Int
        var banker: String
        var bankerScore: Int
        var challengers: [(String, Int)]
        var bankerProfit: Double
    }

    func calculateBanker(
        players: [String],
        scorecards: [String: Scorecard],
        stakes: Double,
        useNet: Bool
    ) -> BankerResult {
        var results: [Int: BankerHole] = [:]
        var totals: [String: Double] = [:]
        let holeCount = scorecards.values.first?.holeScores.count ?? 18

        for hole in 0..<holeCount {
            let bankerIndex = hole % players.count
            let banker = players[bankerIndex]
            let bankerCard = scorecards[banker]
            let bankerSc = useNet
                ? netScore(bankerCard!, hole: hole)
                : bankerCard?.holeScores[safe: hole]?.strokes ?? 99

            var challengers: [(String, Int)] = []
            var profit = 0.0

            for pid in players where pid != banker {
                guard let card = scorecards[pid], hole < card.holeScores.count else { continue }
                let sc = useNet ? netScore(card, hole: hole) : card.holeScores[hole].strokes
                challengers.append((pid, sc))

                if bankerSc < sc {
                    profit += stakes
                    totals[pid, default: 0] -= stakes
                } else if sc < bankerSc {
                    profit -= stakes
                    totals[pid, default: 0] += stakes
                }
            }

            totals[banker, default: 0] += profit

            results[hole + 1] = BankerHole(
                holeNumber: hole + 1,
                banker: banker,
                bankerScore: bankerSc,
                challengers: challengers,
                bankerProfit: profit
            )
        }

        return BankerResult(holeResults: results, playerTotals: totals)
    }

    // MARK: - Helpers

    private func netScores(_ card: Scorecard) -> [Int] {
        let allocation = allocateHandicapStrokes(courseHandicap: card.courseHandicap, holes: 18)
        return card.holeScores.enumerated().map { i, s in
            s.strokes - (i < allocation.count ? allocation[i] : 0)
        }
    }

    private func netScore(_ card: Scorecard, hole: Int) -> Int {
        let allocation = allocateHandicapStrokes(courseHandicap: card.courseHandicap, holes: 18)
        let extra = hole < allocation.count ? allocation[hole] : 0
        return (card.holeScores[safe: hole]?.strokes ?? 0) - extra
    }

    private func allocateHandicapStrokes(courseHandicap: Int, holes: Int) -> [Int] {
        // Simple allocation: distribute strokes starting from hardest holes
        var strokes = Array(repeating: 0, count: holes)
        var remaining = courseHandicap
        var round = 0
        while remaining > 0 {
            for i in 0..<holes where remaining > 0 {
                if round == 0 || (remaining > 0 && round > 0) {
                    strokes[i] += 1
                    remaining -= 1
                }
            }
            round += 1
        }
        return strokes
    }

    private func bestScore(of players: [String], in scorecards: [String: Scorecard], hole: Int) -> Int {
        players.compactMap { scorecards[$0]?.holeScores[safe: hole]?.strokes }.min() ?? 99
    }

    private func distributeWinnings(scores: [String: Double], stakes: Double) -> [String: Double] {
        let sorted = scores.sorted { $0.value < $1.value }
        guard sorted.count >= 2 else { return [:] }

        var winnings: [String: Double] = [:]
        let bestScore = sorted[0].value
        let winners = sorted.filter { $0.value == bestScore }

        if winners.count == sorted.count {
            // All tied
            for s in sorted { winnings[s.key] = 0 }
        } else {
            let totalPool = stakes * Double(sorted.count - winners.count)
            let perWinner = totalPool / Double(winners.count)
            for s in sorted {
                if s.value == bestScore {
                    winnings[s.key] = perWinner
                } else {
                    winnings[s.key] = -stakes
                }
            }
        }
        return winnings
    }
}

// MARK: - Safe Array Access

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
