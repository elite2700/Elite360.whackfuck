import SwiftUI
import MapKit

struct StartRoundView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var roundVM = RoundViewModel()
    @StateObject private var gamesVM = GamesLibraryViewModel()
    @StateObject private var locationService = LocationService.shared

    @State private var searchText = ""
    @State private var selectedCourse: GolfCourse?
    @State private var addedPlayers: [UserProfile] = []
    @State private var selectedGames: [GameFormat] = []
    @State private var stakes: [GameFormat: Double] = [:]
    @State private var useNetScoring = true
    @State private var showingScorecard = false
    @State private var step: SetupStep = .course

    enum SetupStep: Int, CaseIterable {
        case course, players, games, review
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress Bar
                stepIndicator

                TabView(selection: $step) {
                    courseSelection.tag(SetupStep.course)
                    playerSelection.tag(SetupStep.players)
                    gameSelection.tag(SetupStep.games)
                    reviewScreen.tag(SetupStep.review)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: step)
            }
            .navigationTitle("New Round")
            .navigationBarTitleDisplayMode(.inline)
            .fullScreenCover(isPresented: $showingScorecard) {
                if roundVM.currentRound != nil {
                    LiveScorecardView()
                        .environmentObject(roundVM)
                }
            }
        }
    }

    // MARK: - Step Indicator

    private var stepIndicator: some View {
        HStack(spacing: 4) {
            ForEach(SetupStep.allCases, id: \.rawValue) { s in
                Capsule()
                    .fill(s.rawValue <= step.rawValue ? Color.green : Color.gray.opacity(0.3))
                    .frame(height: 4)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    // MARK: - Course Selection

    private var courseSelection: some View {
        VStack(spacing: 16) {
            Text("Select Course")
                .font(.title2.bold())

            // Map preview
            Map {
                if let loc = locationService.currentLocation {
                    Marker("You", coordinate: loc.coordinate)
                }
            }
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)

            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                TextField("Search courses...", text: $searchText)
            }
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal)

            // Preview selection or placeholder
            if let course = selectedCourse {
                selectedCourseCard(course)
            } else {
                Text("Search or select from nearby courses")
                    .foregroundStyle(.secondary)
                    .padding(.top, 20)
            }

            Spacer()

            nextButton(enabled: selectedCourse != nil) {
                step = .players
            }
        }
        .padding(.vertical)
    }

    private func selectedCourseCard(_ course: GolfCourse) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(course.name).font(.headline)
            HStack {
                Label("\(course.par) par", systemImage: "flag.fill")
                Spacer()
                Label("Rating: \(String(format: "%.1f", course.courseRating))", systemImage: "star.fill")
                Spacer()
                Label("Slope: \(course.slopeRating)", systemImage: "mountain.2.fill")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding()
        .background(.green.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }

    // MARK: - Player Selection

    private var playerSelection: some View {
        VStack(spacing: 16) {
            Text("Add Players")
                .font(.title2.bold())

            // Current user auto-added
            if let profile = authVM.currentProfile {
                PlayerChip(name: profile.displayName, isHost: true)
            }

            ForEach(addedPlayers) { player in
                PlayerChip(name: player.displayName, isHost: false)
            }

            // Add player action
            Button {
                // Would show friend picker
            } label: {
                Label("Add Player", systemImage: "plus.circle.fill")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.green.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)

            Spacer()

            HStack {
                backButton { step = .course }
                nextButton(enabled: true) { step = .games }
            }
        }
        .padding(.vertical)
    }

    // MARK: - Game Selection

    private var gameSelection: some View {
        VStack(spacing: 16) {
            Text("Choose Games")
                .font(.title2.bold())

            Toggle("Use Net Scoring", isOn: $useNetScoring)
                .padding(.horizontal)

            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(GameFormat.allCases.filter { $0 != .custom }) { format in
                        GameSelectionRow(
                            format: format,
                            isSelected: selectedGames.contains(format),
                            stakes: stakes[format] ?? 0
                        ) {
                            if selectedGames.contains(format) {
                                selectedGames.removeAll { $0 == format }
                            } else {
                                selectedGames.append(format)
                            }
                        } onStakesChange: { value in
                            stakes[format] = value
                        }
                    }
                }
                .padding(.horizontal)
            }

            HStack {
                backButton { step = .players }
                nextButton(enabled: true) { step = .review }
            }
        }
        .padding(.vertical)
    }

    // MARK: - Review

    private var reviewScreen: some View {
        VStack(spacing: 16) {
            Text("Review & Start")
                .font(.title2.bold())

            VStack(alignment: .leading, spacing: 12) {
                if let course = selectedCourse {
                    Label(course.name, systemImage: "mappin.circle.fill")
                }
                Label("\(addedPlayers.count + 1) players", systemImage: "person.2.fill")
                Label("\(selectedGames.count) games selected", systemImage: "trophy.fill")
                Label(useNetScoring ? "Net scoring" : "Gross scoring", systemImage: "number")

                ForEach(selectedGames) { game in
                    HStack {
                        Text("  \(game.rawValue)")
                            .font(.subheadline)
                        Spacer()
                        Text("$\(String(format: "%.0f", stakes[game] ?? 0))")
                            .font(.subheadline.bold())
                    }
                }
            }
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)

            Spacer()

            HStack {
                backButton { step = .games }

                Button {
                    Task { await startRound() }
                } label: {
                    Text("TEE OFF!")
                        .font(.headline.bold())
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.green)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding(.vertical)
    }

    // MARK: - Actions

    private func startRound() async {
        guard let course = selectedCourse else { return }
        var players = [authVM.currentProfile].compactMap { $0 } + addedPlayers

        let activeGames = selectedGames.map { format in
            ActiveGame(
                gameType: format.rawValue,
                customGameID: nil,
                stakes: stakes[format] ?? 0,
                isGrossScoring: !useNetScoring,
                teamAssignments: nil,
                gameState: [:]
            )
        }

        await roundVM.createRound(course: course, players: players, games: activeGames)
        showingScorecard = true
    }

    // MARK: - Buttons

    private func nextButton(enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text("Next")
                .font(.headline)
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding()
                .background(enabled ? .green : .gray)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(!enabled)
        .padding(.horizontal)
    }

    private func backButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text("Back")
                .font(.headline)
                .foregroundStyle(.primary)
                .padding()
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.leading)
    }
}

struct PlayerChip: View {
    let name: String
    let isHost: Bool

    var body: some View {
        HStack {
            Image(systemName: "person.circle.fill")
                .foregroundStyle(.green)
            Text(name)
                .font(.subheadline)
            Spacer()
            if isHost {
                Text("HOST")
                    .font(.caption2.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(.green)
                    .foregroundStyle(.black)
                    .clipShape(Capsule())
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal)
    }
}

struct GameSelectionRow: View {
    let format: GameFormat
    let isSelected: Bool
    let stakes: Double
    let onToggle: () -> Void
    let onStakesChange: (Double) -> Void

    @State private var stakeText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Button(action: onToggle) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isSelected ? .green : .gray)
                        .font(.title3)
                }
                VStack(alignment: .leading) {
                    HStack {
                        Text(format.rawValue).font(.subheadline.bold())
                        if format.isPremiumOnly {
                            Image(systemName: "crown.fill")
                                .font(.caption2)
                                .foregroundStyle(.yellow)
                        }
                    }
                    Text(format.description)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Spacer()
            }

            if isSelected {
                HStack {
                    Text("$ per unit:")
                        .font(.caption)
                    TextField("0", text: $stakeText)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                        .onChange(of: stakeText) { _, newVal in
                            onStakesChange(Double(newVal) ?? 0)
                        }
                }
                .padding(.leading, 36)
            }
        }
        .padding()
        .background(isSelected ? .green.opacity(0.05) : .clear)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? .green : .gray.opacity(0.2))
        )
    }
}
