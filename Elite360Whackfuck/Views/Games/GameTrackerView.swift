import SwiftUI

struct GameTrackerView: View {
    @EnvironmentObject var roundVM: RoundViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if roundVM.gameResults.isEmpty {
                        ContentUnavailableView(
                            "No Active Games",
                            systemImage: "trophy",
                            description: Text("Games will appear here as scores are entered")
                        )
                    }

                    // Nassau Tracker
                    if let nassau = roundVM.gameResults["nassau"] as? GameEngine.NassauResult {
                        nassauCard(nassau)
                    }

                    // Skins Tracker
                    if let skins = roundVM.gameResults["skins"] as? GameEngine.SkinsResult {
                        skinsCard(skins)
                    }

                    // Match Play Tracker
                    if let match = roundVM.gameResults["matchPlay"] as? GameEngine.MatchPlayResult {
                        matchPlayCard(match)
                    }

                    // Snake Tracker
                    if let snake = roundVM.gameResults["snake"] as? GameEngine.SnakeResult {
                        snakeCard(snake)
                    }

                    // Stableford Tracker
                    if let stableford = roundVM.gameResults["stableford"] as? GameEngine.StablefordResult {
                        stablefordCard(stableford)
                    }

                    // Wolf Tracker
                    if let wolf = roundVM.gameResults["wolf"] as? GameEngine.WolfResult {
                        wolfCard(wolf)
                    }

                    // Bingo Bango Bongo Tracker
                    if let bbb = roundVM.gameResults["bingoBangoBongo"] as? GameEngine.BBBResult {
                        bbbCard(bbb)
                    }

                    // Las Vegas Tracker
                    if let lv = roundVM.gameResults["lasVegas"] as? GameEngine.LasVegasResult {
                        lasVegasCard(lv)
                    }

                    // Sixes Tracker
                    if let sixes = roundVM.gameResults["sixes"] as? GameEngine.SixesResult {
                        sixesCard(sixes)
                    }

                    // 9-Point Tracker
                    if let np = roundVM.gameResults["ninePoint"] as? GameEngine.NinePointResult {
                        ninePointCard(np)
                    }

                    // Dots Tracker
                    if let dots = roundVM.gameResults["dots"] as? GameEngine.DotsResult {
                        dotsCard(dots)
                    }

                    // Best Ball Tracker
                    if let bb = roundVM.gameResults["bestBall"] as? GameEngine.BestBallResult {
                        bestBallCard(bb)
                    }

                    // Banker Tracker
                    if let banker = roundVM.gameResults["banker"] as? GameEngine.BankerResult {
                        bankerCard(banker)
                    }
                }
                .padding()
            }
            .navigationTitle("Game Tracker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Nassau

    private func nassauCard(_ result: GameEngine.NassauResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Nassau", systemImage: "3.square.fill")
                .font(.headline)

            HStack {
                nassauSegment("Front 9", result: result.frontNine)
                nassauSegment("Back 9", result: result.backNine)
                nassauSegment("Overall", result: result.overall)
            }

            Divider()

            Text("Totals")
                .font(.subheadline.bold())
            ForEach(result.total.sorted(by: { $0.value > $1.value }), id: \.key) { pid, amount in
                MoneyRow(name: roundVM.scorecards[pid]?.playerName ?? pid, amount: amount)
            }
        }
        .gameCard()
    }

    private func nassauSegment(_ title: String, result: [String: Double]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.bold())
            ForEach(result.sorted(by: { $0.value > $1.value }), id: \.key) { pid, amount in
                HStack {
                    Text(roundVM.scorecards[pid]?.playerName.prefix(6) ?? "")
                        .font(.caption2)
                    Spacer()
                    Text(amount >= 0 ? "+$\(Int(amount))" : "-$\(Int(abs(amount)))")
                        .font(.caption2.bold())
                        .foregroundStyle(amount >= 0 ? .green : .red)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Skins

    private func skinsCard(_ result: GameEngine.SkinsResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Skins", systemImage: "star.circle.fill")
                .font(.headline)

            // Skin winners
            ForEach(result.skinWinners.sorted(by: { $0.key < $1.key }), id: \.key) { hole, winner in
                HStack {
                    Text("Hole \(hole)")
                        .font(.caption)
                    Spacer()
                    Text(roundVM.scorecards[winner]?.playerName ?? winner)
                        .font(.caption.bold())
                    Text("$\(Int(result.skinValues[hole] ?? 0))")
                        .font(.caption.bold())
                        .foregroundStyle(.green)
                }
            }

            if !result.carryoverHoles.isEmpty {
                Text("Carryovers: \(result.carryoverHoles.map(String.init).joined(separator: ", "))")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            Divider()
            ForEach(result.playerTotals.sorted(by: { $0.value > $1.value }), id: \.key) { pid, total in
                MoneyRow(name: roundVM.scorecards[pid]?.playerName ?? pid, amount: total)
            }
        }
        .gameCard()
    }

    // MARK: - Match Play

    private func matchPlayCard(_ result: GameEngine.MatchPlayResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Match Play", systemImage: "person.2.fill")
                .font(.headline)

            Text(result.currentStatus)
                .font(.title3.bold())
                .foregroundStyle(.green)
                .frame(maxWidth: .infinity, alignment: .center)

            if result.isComplete, let winner = result.winner {
                Text("\(roundVM.scorecards[winner]?.playerName ?? winner) WINS!")
                    .font(.headline)
                    .foregroundStyle(.yellow)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .gameCard()
    }

    // MARK: - Snake

    private func snakeCard(_ result: GameEngine.SnakeResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Snake", systemImage: "arrow.triangle.branch")
                .font(.headline)

            if let holder = result.currentSnakeHolder {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text("\(roundVM.scorecards[holder]?.playerName ?? holder) has the Snake!")
                        .font(.subheadline.bold())
                        .foregroundStyle(.red)
                }
            } else {
                Text("No 3-putts yet!")
                    .font(.subheadline)
                    .foregroundStyle(.green)
            }

            Divider()
            ForEach(result.moneyResult.sorted(by: { $0.value > $1.value }), id: \.key) { pid, amount in
                MoneyRow(name: roundVM.scorecards[pid]?.playerName ?? pid, amount: amount)
            }
        }
        .gameCard()
    }

    // MARK: - Stableford

    private func stablefordCard(_ result: GameEngine.StablefordResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Stableford", systemImage: "star.fill")
                .font(.headline)

            ForEach(result.totalPoints.sorted(by: { $0.value > $1.value }), id: \.key) { pid, pts in
                HStack {
                    Text(roundVM.scorecards[pid]?.playerName ?? pid)
                        .font(.subheadline)
                    Spacer()
                    Text("\(pts) pts")
                        .font(.subheadline.bold())
                    Text(result.moneyResults[pid].map { $0 >= 0 ? "+$\(Int($0))" : "-$\(Int(abs($0)))" } ?? "$0")
                        .font(.caption)
                        .foregroundStyle((result.moneyResults[pid] ?? 0) >= 0 ? .green : .red)
                }
            }
        }
        .gameCard()
    }

    // MARK: - Wolf

    private func wolfCard(_ result: GameEngine.WolfResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Wolf", systemImage: "pawprint.fill")
                .font(.headline)

            ForEach(result.playerTotals.sorted(by: { $0.value > $1.value }), id: \.key) { pid, total in
                MoneyRow(name: roundVM.scorecards[pid]?.playerName ?? pid, amount: total)
            }
        }
        .gameCard()
    }

    // MARK: - Bingo Bango Bongo

    private func bbbCard(_ result: GameEngine.BBBResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Bingo Bango Bongo", systemImage: "target")
                .font(.headline)

            ForEach(result.playerTotals.sorted(by: { $0.value > $1.value }), id: \.key) { pid, pts in
                HStack {
                    Text(roundVM.scorecards[pid]?.playerName ?? pid)
                        .font(.subheadline)
                    Spacer()
                    Text("\(pts) pts")
                        .font(.subheadline.bold())
                    Text(result.moneyTotals[pid].map { $0 >= 0 ? "+$\(Int($0))" : "-$\(Int(abs($0)))" } ?? "$0")
                        .font(.caption)
                        .foregroundStyle((result.moneyTotals[pid] ?? 0) >= 0 ? .green : .red)
                }
            }
        }
        .gameCard()
    }

    // MARK: - Las Vegas

    private func lasVegasCard(_ result: GameEngine.LasVegasResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Las Vegas", systemImage: "dice.fill")
                .font(.headline)

            HStack {
                VStack {
                    Text("Team 1").font(.caption.bold())
                    Text("\(result.teamTotals[1] ?? 0)")
                        .font(.title3.bold())
                }
                .frame(maxWidth: .infinity)
                Text("vs").font(.caption).foregroundStyle(.secondary)
                VStack {
                    Text("Team 2").font(.caption.bold())
                    Text("\(result.teamTotals[2] ?? 0)")
                        .font(.title3.bold())
                }
                .frame(maxWidth: .infinity)
            }

            Divider()
            ForEach(result.moneyResults.sorted(by: { $0.value > $1.value }), id: \.key) { pid, amount in
                MoneyRow(name: roundVM.scorecards[pid]?.playerName ?? pid, amount: amount)
            }
        }
        .gameCard()
    }

    // MARK: - Sixes

    private func sixesCard(_ result: GameEngine.SixesResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Sixes / Round Robin", systemImage: "arrow.triangle.2.circlepath")
                .font(.headline)

            ForEach(Array(result.segments.enumerated()), id: \.offset) { _, segment in
                HStack {
                    Text("Holes \(segment.holes.lowerBound)-\(segment.holes.upperBound)")
                        .font(.caption.bold())
                    Spacer()
                    Text("\(segment.team1Score)")
                        .font(.caption.bold())
                        .foregroundStyle(segment.winner == 1 ? .green : .primary)
                    Text("vs")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("\(segment.team2Score)")
                        .font(.caption.bold())
                        .foregroundStyle(segment.winner == 2 ? .green : .primary)
                }
            }

            Divider()
            ForEach(result.playerTotals.sorted(by: { $0.value > $1.value }), id: \.key) { pid, total in
                MoneyRow(name: roundVM.scorecards[pid]?.playerName ?? pid, amount: total)
            }
        }
        .gameCard()
    }

    // MARK: - 9-Point

    private func ninePointCard(_ result: GameEngine.NinePointResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("9-Point / Niners", systemImage: "9.circle.fill")
                .font(.headline)

            ForEach(result.totalPoints.sorted(by: { $0.value > $1.value }), id: \.key) { pid, pts in
                HStack {
                    Text(roundVM.scorecards[pid]?.playerName ?? pid)
                        .font(.subheadline)
                    Spacer()
                    Text("\(pts) pts")
                        .font(.subheadline.bold())
                    Text(result.moneyResults[pid].map { $0 >= 0 ? "+$\(Int($0))" : "-$\(Int(abs($0)))" } ?? "$0")
                        .font(.caption)
                        .foregroundStyle((result.moneyResults[pid] ?? 0) >= 0 ? .green : .red)
                }
            }
        }
        .gameCard()
    }

    // MARK: - Dots / Garbage

    private func dotsCard(_ result: GameEngine.DotsResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Dots / Garbage", systemImage: "circle.grid.3x3.fill")
                .font(.headline)

            ForEach(result.playerTotals.sorted(by: { $0.value > $1.value }), id: \.key) { pid, pts in
                HStack {
                    Text(roundVM.scorecards[pid]?.playerName ?? pid)
                        .font(.subheadline)
                    Spacer()
                    Text("\(pts) dots")
                        .font(.subheadline.bold())
                    Text(result.moneyResults[pid].map { $0 >= 0 ? "+$\(Int($0))" : "-$\(Int(abs($0)))" } ?? "$0")
                        .font(.caption)
                        .foregroundStyle((result.moneyResults[pid] ?? 0) >= 0 ? .green : .red)
                }
            }
        }
        .gameCard()
    }

    // MARK: - Best Ball

    private func bestBallCard(_ result: GameEngine.BestBallResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Best Ball", systemImage: "figure.golf")
                .font(.headline)

            HStack {
                VStack {
                    Text("Team 1").font(.caption.bold())
                    Text("\(result.teamTotals[1] ?? 0)")
                        .font(.title3.bold())
                }
                .frame(maxWidth: .infinity)
                Text("vs").font(.caption).foregroundStyle(.secondary)
                VStack {
                    Text("Team 2").font(.caption.bold())
                    Text("\(result.teamTotals[2] ?? 0)")
                        .font(.title3.bold())
                }
                .frame(maxWidth: .infinity)
            }

            Divider()
            ForEach(result.moneyResults.sorted(by: { $0.value > $1.value }), id: \.key) { pid, amount in
                MoneyRow(name: roundVM.scorecards[pid]?.playerName ?? pid, amount: amount)
            }
        }
        .gameCard()
    }

    // MARK: - Banker

    private func bankerCard(_ result: GameEngine.BankerResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Banker", systemImage: "banknote.fill")
                .font(.headline)

            ForEach(result.playerTotals.sorted(by: { $0.value > $1.value }), id: \.key) { pid, total in
                MoneyRow(name: roundVM.scorecards[pid]?.playerName ?? pid, amount: total)
            }
        }
        .gameCard()
    }
}

// MARK: - Shared Components

struct MoneyRow: View {
    let name: String
    let amount: Double

    var body: some View {
        HStack {
            Text(name)
                .font(.subheadline)
            Spacer()
            Text(amount >= 0 ? "+$\(String(format: "%.0f", amount))" : "-$\(String(format: "%.0f", abs(amount)))")
                .font(.subheadline.bold())
                .foregroundStyle(amount >= 0 ? .green : .red)
        }
    }
}

extension View {
    func gameCard() -> some View {
        self
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
