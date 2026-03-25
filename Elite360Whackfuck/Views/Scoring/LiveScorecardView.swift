import SwiftUI

struct LiveScorecardView: View {
    @EnvironmentObject var roundVM: RoundViewModel
    @StateObject private var locationService = LocationService.shared
    @StateObject private var moneyVM = MoneyViewModel()
    @Environment(\.dismiss) private var dismiss

    @State private var showAICaddy = false
    @State private var showGameTracker = false
    @State private var showPostRound = false
    @State private var selectedPlayerID: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Hole Navigation
                holeNavigator

                // Distance Bar
                if let dist = locationService.distanceToGreen {
                    distanceBar(yards: dist)
                }

                // Scorecard Grid
                ScrollView {
                    // Error Banner
                    if let error = roundVM.error {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.yellow)
                            Text(error)
                                .font(.caption)
                            Spacer()
                            Button("Dismiss") { roundVM.error = nil }
                                .font(.caption.bold())
                        }
                        .padding()
                        .background(.red.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding(.horizontal)
                    }

                    VStack(spacing: 0) {
                        scorecardHeader
                        scorecardRows
                    }
                    .padding(.horizontal)

                    // Game Tracker Cards
                    if !roundVM.gameResults.isEmpty {
                        gameTrackerSection
                    }
                }

                // Bottom Toolbar
                bottomToolbar
            }
            .navigationTitle("Hole \(roundVM.currentHole)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Pause") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("AI Caddy", systemImage: "brain") { showAICaddy = true }
                        Button("Game Tracker", systemImage: "trophy") { showGameTracker = true }
                        Button("Finish Round", systemImage: "flag.checkered") {
                            Task {
                                await roundVM.completeRound()
                                showPostRound = true
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showAICaddy) {
                AICaddyView()
            }
            .sheet(isPresented: $showGameTracker) {
                GameTrackerView()
                    .environmentObject(roundVM)
            }
            .fullScreenCover(isPresented: $showPostRound) {
                PostRoundView(onDone: {
                    showPostRound = false
                    dismiss()
                })
                    .environmentObject(roundVM)
                    .environmentObject(moneyVM)
            }
        }
    }

    // MARK: - Hole Navigator

    private var holeNavigator: some View {
        HStack {
            Button {
                if roundVM.currentHole > 1 { roundVM.currentHole -= 1 }
            } label: {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.green)
            }
            .disabled(roundVM.currentHole <= 1)

            Spacer()

            VStack(spacing: 2) {
                Text("HOLE \(roundVM.currentHole)")
                    .font(.headline.bold())
                if let round = roundVM.currentRound {
                    let par = round.holePars[safe: roundVM.currentHole - 1] ?? 4
                    Text("Par \(par)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button {
                if roundVM.currentHole < 18 { roundVM.currentHole += 1 }
            } label: {
                Image(systemName: "chevron.right.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.green)
            }
            .disabled(roundVM.currentHole >= 18)
        }
        .padding()
        .background(.ultraThinMaterial)
    }

    // MARK: - Distance Bar

    private func distanceBar(yards: Int) -> some View {
        HStack {
            Image(systemName: "location.fill")
                .foregroundStyle(.blue)
            Text("\(yards) yds to green")
                .font(.subheadline.bold())
            Spacer()
            Image(systemName: "flag.fill")
                .foregroundStyle(.yellow)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.blue.opacity(0.1))
    }

    // MARK: - Scorecard

    private var scorecardHeader: some View {
        HStack(spacing: 0) {
            Text("Player")
                .frame(width: 100, alignment: .leading)
                .font(.caption.bold())
            ForEach(1...18, id: \.self) { hole in
                Text("\(hole)")
                    .frame(width: 28)
                    .font(.caption2)
                    .foregroundStyle(hole == roundVM.currentHole ? .green : .secondary)
                    .fontWeight(hole == roundVM.currentHole ? .bold : .regular)
            }
            Text("TOT")
                .frame(width: 36)
                .font(.caption.bold())
        }
        .padding(.vertical, 8)
        .background(.gray.opacity(0.1))
    }

    private var scorecardRows: some View {
        ForEach(Array(roundVM.scorecards.keys.sorted()), id: \.self) { playerID in
            if let card = roundVM.scorecards[playerID] {
                HStack(spacing: 0) {
                    Text(card.playerName)
                        .frame(width: 100, alignment: .leading)
                        .font(.caption)
                        .lineLimit(1)
                    ForEach(0..<18) { i in
                        let score = i < card.holeScores.count ? card.holeScores[i] : nil
                        let holePar = roundVM.currentRound?.holePars[safe: i] ?? 4
                        ZStack {
                            if score?.isComplete == true {
                                Text("\(score!.strokes)")
                                    .font(.caption2.bold())
                                    .foregroundStyle(scoreColor(strokes: score!.strokes, par: holePar))
                            } else if i + 1 == roundVM.currentHole {
                                Circle()
                                    .fill(.green.opacity(0.2))
                                    .frame(width: 24, height: 24)
                            }
                        }
                        .frame(width: 28, height: 28)
                        .onTapGesture {
                            selectedPlayerID = playerID
                            roundVM.currentHole = i + 1
                        }
                    }
                    Text(card.totalGross > 0 ? "\(card.totalGross)" : "-")
                        .frame(width: 36)
                        .font(.caption.bold())
                }
                .padding(.vertical, 4)
                Divider()
            }
        }
    }

    // MARK: - Game Tracker Section

    private var gameTrackerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Game Tracker")
                .font(.headline)
                .padding(.horizontal)

            ForEach(Array(roundVM.gameResults.keys.sorted()), id: \.self) { key in
                GameResultCard(gameType: key, gameResults: roundVM.gameResults)
                    .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }

    // MARK: - Bottom Toolbar

    private var bottomToolbar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                // Quick score entry for current hole
                ForEach(Array(roundVM.scorecards.keys.sorted()), id: \.self) { pid in
                    if let card = roundVM.scorecards[pid] {
                        let holePar = roundVM.currentRound?.holePars[safe: roundVM.currentHole - 1] ?? 4
                        ScoreEntryChip(
                            playerName: String(card.playerName.prefix(8)),
                            currentScore: card.holeScores[safe: roundVM.currentHole - 1]?.strokes ?? 0,
                            par: holePar
                        ) { newScore in
                            Task {
                                await roundVM.updateScore(
                                    playerID: pid,
                                    hole: roundVM.currentHole,
                                    strokes: newScore,
                                    putts: 2,
                                    fairwayHit: nil,
                                    gir: false
                                )
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(.ultraThinMaterial)
    }

    private func scoreColor(strokes: Int, par: Int) -> Color {
        let diff = strokes - par
        switch diff {
        case ...(-2): return .yellow
        case -1: return .red
        case 0: return .primary
        case 1: return .blue
        default: return .purple
        }
    }
}

// MARK: - Score Entry Chip

struct ScoreEntryChip: View {
    let playerName: String
    let currentScore: Int
    let par: Int
    let onScoreChange: (Int) -> Void

    @State private var score: Int

    init(playerName: String, currentScore: Int, par: Int, onScoreChange: @escaping (Int) -> Void) {
        self.playerName = playerName
        self.currentScore = currentScore
        self.par = par
        self.onScoreChange = onScoreChange
        _score = State(initialValue: currentScore == 0 ? par : currentScore)
    }

    private var scoreLabel: String {
        let diff = score - par
        switch diff {
        case ...(-2): return "Eagle"
        case -1: return "Birdie"
        case 0: return "Par"
        case 1: return "Bogey"
        case 2: return "2x Bogey"
        default: return "+\(diff)"
        }
    }

    private var scoreLabelColor: Color {
        let diff = score - par
        switch diff {
        case ...(-2): return .yellow
        case -1: return .red
        case 0: return .primary
        case 1: return .blue
        default: return .purple
        }
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(playerName)
                .font(.caption2)
                .lineLimit(1)

            Text("Par \(par)")
                .font(.caption2)
                .foregroundStyle(.secondary)

            HStack(spacing: 6) {
                Button { if score > 1 { score -= 1; onScoreChange(score) } } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.green)
                }
                Text("\(score)")
                    .font(.title2.bold())
                    .frame(width: 30)
                Button { if score < 15 { score += 1; onScoreChange(score) } } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.green)
                }
            }

            Text(scoreLabel)
                .font(.caption2.bold())
                .foregroundStyle(scoreLabelColor)

            // Quick-select par-relative scores
            HStack(spacing: 4) {
                ForEach(max(1, par - 1)...(par + 2), id: \.self) { val in
                    Button {
                        score = val
                        onScoreChange(score)
                    } label: {
                        Text("\(val)")
                            .font(.caption2.bold())
                            .frame(width: 24, height: 24)
                            .background(score == val ? .green : .gray.opacity(0.2))
                            .foregroundStyle(score == val ? .black : .primary)
                            .clipShape(Circle())
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(.green.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct GameResultCard: View {
    let gameType: String
    let gameResults: [String: Any]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(gameType.capitalized)
                .font(.subheadline.bold())

            if let skins = gameResults[gameType] as? GameEngine.SkinsResult {
                ForEach(skins.playerTotals.sorted(by: { $0.value > $1.value }), id: \.key) { pid, total in
                    HStack {
                        Text(pid.prefix(8))
                        Spacer()
                        Text("$\(String(format: "%.0f", total))")
                            .foregroundStyle(total >= 0 ? .green : .red)
                    }
                    .font(.caption)
                }
            } else {
                Text("In progress...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
