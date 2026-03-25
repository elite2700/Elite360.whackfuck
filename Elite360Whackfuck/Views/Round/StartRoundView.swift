import SwiftUI
import MapKit

struct StartRoundView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var roundVM = RoundViewModel()
    @StateObject private var gamesVM = GamesLibraryViewModel()
    @StateObject private var locationService = LocationService.shared

    @State private var searchText = ""
    @State private var selectedCourse: GolfCourse?
    @State private var searchResults: [GolfCourse] = []
    @State private var isSearching = false
    @State private var showManualEntry = false
    @State private var showAddPlayer = false
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
                if let course = selectedCourse {
                    Marker(course.name, coordinate: .init(latitude: course.latitude, longitude: course.longitude))
                        .tint(.green)
                }
            }
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)

            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                TextField("Search courses...", text: $searchText)
                    .onSubmit { Task { await searchCourses() } }
                if isSearching {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal)
            .onChange(of: searchText) {
                Task {
                    try? await Task.sleep(for: .milliseconds(300))
                    await searchCourses()
                }
            }

            // Search results
            if !searchResults.isEmpty && selectedCourse == nil {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(searchResults) { course in
                            Button {
                                selectedCourse = course
                                searchResults = []
                            } label: {
                                courseRow(course)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(maxHeight: 200)
            }

            // Preview selection or manual entry
            if let course = selectedCourse {
                selectedCourseCard(course)
                Button("Change Course") {
                    selectedCourse = nil
                    searchText = ""
                }
                .font(.caption)
            } else if searchResults.isEmpty && !searchText.isEmpty && !isSearching {
                VStack(spacing: 8) {
                    Text("No courses found")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Button("Add Course Manually") {
                        showManualEntry = true
                    }
                    .font(.subheadline.bold())
                    .foregroundStyle(.green)
                }
                .padding(.top, 12)
            } else if searchText.isEmpty {
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
        .sheet(isPresented: $showManualEntry) {
            ManualCourseEntryView { course in
                selectedCourse = course
                showManualEntry = false
            }
        }
    }

    private func courseRow(_ course: GolfCourse) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(course.name).font(.subheadline.bold()).foregroundStyle(.primary)
                Text("\(course.city), \(course.state)").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("Par \(course.par)").font(.caption).foregroundStyle(.secondary)
                Text("Slope \(course.slopeRating)").font(.caption2).foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func searchCourses() async {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.count >= 2 else {
            searchResults = []
            return
        }
        isSearching = true
        do {
            searchResults = try await GolfCourseAPIService.shared.searchCourses(query: query)
        } catch {
            searchResults = []
        }
        isSearching = false
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
                PlayerChip(name: profile.displayName, isHost: true, onRemove: nil)
            }

            ForEach(addedPlayers) { player in
                PlayerChip(name: player.displayName, isHost: false) {
                    addedPlayers.removeAll { $0.id == player.id }
                }
            }

            // Add player action
            Button {
                showAddPlayer = true
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
        .sheet(isPresented: $showAddPlayer) {
            AddPlayerSheet(addedPlayers: $addedPlayers)
                .environmentObject(authVM)
        }
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
    var onRemove: (() -> Void)?

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
            } else if let onRemove {
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.red.opacity(0.7))
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal)
    }
}

// MARK: - Add Player Sheet

struct AddPlayerSheet: View {
    @Binding var addedPlayers: [UserProfile]
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var guestName = ""

    var body: some View {
        NavigationStack {
            List {
                // Guest entry
                Section("Add Guest") {
                    HStack {
                        TextField("Player name", text: $guestName)
                            .textContentType(.name)
                            .submitLabel(.done)
                            .onSubmit { addGuest() }
                        Button("Add") { addGuest() }
                            .disabled(guestName.trimmingCharacters(in: .whitespaces).isEmpty)
                            .buttonStyle(.borderedProminent)
                            .tint(.green)
                    }
                }

                // Friends list
                Section("Friends") {
                    if authVM.friends.isEmpty {
                        Text("No friends yet. Add friends in your profile.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(authVM.friends) { friend in
                            let alreadyAdded = addedPlayers.contains { $0.id == friend.id }
                            Button {
                                guard !alreadyAdded else { return }
                                addedPlayers.append(friendToPlayer(friend))
                            } label: {
                                HStack {
                                    Image(systemName: "person.circle.fill")
                                        .foregroundStyle(.green)
                                    VStack(alignment: .leading) {
                                        Text(friend.name)
                                            .foregroundStyle(.primary)
                                        if let hcp = friend.handicap {
                                            Text("Handicap: \(String(format: "%.1f", hcp))")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    Spacer()
                                    if alreadyAdded {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.green)
                                    }
                                }
                            }
                            .disabled(alreadyAdded)
                        }
                    }
                }
            }
            .navigationTitle("Add Player")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func addGuest() {
        let name = guestName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        addedPlayers.append(guestPlayer(name: name))
        guestName = ""
    }

    private func friendToPlayer(_ friend: Friend) -> UserProfile {
        UserProfile(
            id: friend.id ?? UUID().uuidString,
            email: friend.email ?? "",
            displayName: friend.name,
            photoURL: nil,
            homeCourse: nil,
            handicapIndex: friend.handicap,
            username: friend.name.lowercased().replacingOccurrences(of: " ", with: ""),
            friendIDs: [],
            groupIDs: [],
            isPremium: false,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    private func guestPlayer(name: String) -> UserProfile {
        UserProfile(
            id: UUID().uuidString,
            email: "",
            displayName: name,
            photoURL: nil,
            homeCourse: nil,
            handicapIndex: nil,
            username: name.lowercased().replacingOccurrences(of: " ", with: ""),
            friendIDs: [],
            groupIDs: [],
            isPremium: false,
            createdAt: Date(),
            updatedAt: Date()
        )
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

// MARK: - Manual Course Entry

struct ManualCourseEntryView: View {
    let onSave: (GolfCourse) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var city = ""
    @State private var state = ""
    @State private var courseRating = ""
    @State private var slopeRating = ""
    @State private var par = "72"
    @State private var holeCount = 18
    @State private var isSaving = false

    var isValid: Bool {
        !name.isEmpty && Double(courseRating) != nil && Int(slopeRating) != nil && Int(par) != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Course Info") {
                    TextField("Course Name", text: $name)
                    TextField("City", text: $city)
                    TextField("State", text: $state)
                }
                Section("Ratings") {
                    TextField("Course Rating (e.g. 71.2)", text: $courseRating)
                        .keyboardType(.decimalPad)
                    TextField("Slope Rating (e.g. 128)", text: $slopeRating)
                        .keyboardType(.numberPad)
                    TextField("Par (e.g. 72)", text: $par)
                        .keyboardType(.numberPad)
                    Picker("Holes", selection: $holeCount) {
                        Text("18 Holes").tag(18)
                        Text("9 Holes").tag(9)
                    }
                }
            }
            .navigationTitle("Add Course")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { Task { await saveCourse() } }
                        .disabled(!isValid || isSaving)
                }
            }
        }
    }

    private func saveCourse() async {
        guard let rating = Double(courseRating),
              let slope = Int(slopeRating),
              let coursePar = Int(par) else { return }
        isSaving = true

        let defaultHolePar = coursePar / holeCount
        let remainder = coursePar % holeCount
        let holes = (1...holeCount).map { num in
            HoleInfo(
                number: num,
                par: defaultHolePar + (num <= remainder ? 1 : 0),
                yardage: 0,
                handicapRank: num
            )
        }

        var course = GolfCourse(
            name: name,
            nameLowercase: name.lowercased(),
            city: city,
            state: state,
            country: "US",
            latitude: 0,
            longitude: 0,
            courseRating: rating,
            slopeRating: slope,
            par: coursePar,
            holes: holes
        )

        if let docID = try? await FirestoreService.shared.create(course, in: GolfCourse.collectionName) {
            course.id = docID
        }
        onSave(course)
    }
}
