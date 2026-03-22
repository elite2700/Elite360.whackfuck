import Foundation

@MainActor
final class MoneyViewModel: ObservableObject {
    @Published var balances: [PlayerBalance] = []
    @Published var settlements: [Settlement] = []
    @Published var ledger: [LedgerEntry] = []
    @Published var totalPot: Double = 0

    private let db = FirestoreService.shared

    func calculateBalances(from round: GolfRound, gameResults: [String: Any]) {
        var playerMoney: [String: Double] = [:]
        var breakdown: [String: [String: Double]] = [:]

        // Aggregate money from all game results
        for (gameType, result) in gameResults {
            var moneyMap: [String: Double] = [:]

            if let nassau = result as? GameEngine.NassauResult {
                moneyMap = nassau.total
            } else if let skins = result as? GameEngine.SkinsResult {
                moneyMap = skins.playerTotals
            } else if let stableford = result as? GameEngine.StablefordResult {
                moneyMap = stableford.moneyResults
            } else if let snake = result as? GameEngine.SnakeResult {
                moneyMap = snake.moneyResult
            } else if let dots = result as? GameEngine.DotsResult {
                moneyMap = dots.moneyResults
            } else if let bbb = result as? GameEngine.BBBResult {
                moneyMap = bbb.moneyTotals
            } else if let bestBall = result as? GameEngine.BestBallResult {
                moneyMap = bestBall.moneyResults
            } else if let lv = result as? GameEngine.LasVegasResult {
                moneyMap = lv.moneyResults
            } else if let banker = result as? GameEngine.BankerResult {
                moneyMap = banker.playerTotals
            } else if let sixes = result as? GameEngine.SixesResult {
                moneyMap = sixes.playerTotals
            } else if let ninePoint = result as? GameEngine.NinePointResult {
                moneyMap = ninePoint.moneyResults
            }

            for (pid, amount) in moneyMap {
                playerMoney[pid, default: 0] += amount
                breakdown[pid, default: [:]][gameType, default: 0] += amount
            }
        }

        // Build balances
        balances = round.playerIDs.map { pid in
            let net = playerMoney[pid] ?? 0
            return PlayerBalance(
                playerID: pid,
                playerName: round.scorecards[pid]?.playerName ?? "Unknown",
                totalWinnings: max(0, net),
                totalLosses: min(0, net),
                netBalance: net,
                gameBreakdown: breakdown[pid] ?? [:]
            )
        }
        balances.sort { $0.netBalance > $1.netBalance }

        totalPot = balances.filter { $0.netBalance > 0 }.reduce(0) { $0 + $1.netBalance }

        // Calculate settlements (who owes whom)
        calculateSettlements()
    }

    private func calculateSettlements() {
        settlements = []

        var payers = balances.filter { $0.netBalance < 0 }
            .map { (id: $0.playerID, name: $0.playerName, amount: abs($0.netBalance)) }
        var receivers = balances.filter { $0.netBalance > 0 }
            .map { (id: $0.playerID, name: $0.playerName, amount: $0.netBalance) }

        // Minimize transactions using greedy approach
        payers.sort { $0.amount > $1.amount }
        receivers.sort { $0.amount > $1.amount }

        var pi = 0, ri = 0
        while pi < payers.count && ri < receivers.count {
            let transferAmount = min(payers[pi].amount, receivers[ri].amount)
            if transferAmount > 0.01 {
                settlements.append(Settlement(
                    fromPlayerID: payers[pi].id,
                    fromPlayerName: payers[pi].name,
                    toPlayerID: receivers[ri].id,
                    toPlayerName: receivers[ri].name,
                    amount: (transferAmount * 100).rounded() / 100,
                    isPaid: false,
                    method: nil
                ))
            }

            payers[pi].amount -= transferAmount
            receivers[ri].amount -= transferAmount

            if payers[pi].amount < 0.01 { pi += 1 }
            if receivers[ri].amount < 0.01 { ri += 1 }
        }
    }

    func markSettlementPaid(index: Int) {
        guard index < settlements.count else { return }
        settlements[index].isPaid = true
    }

    func exportSettlement() -> String {
        var text = "=== SETTLEMENT SUMMARY ===\n\n"
        for s in settlements {
            let status = s.isPaid ? "[PAID]" : "[PENDING]"
            text += "\(s.fromPlayerName) owes \(s.toPlayerName): $\(String(format: "%.2f", s.amount)) \(status)\n"
        }
        text += "\nTotal pot: $\(String(format: "%.2f", totalPot))\n"
        return text
    }
}
