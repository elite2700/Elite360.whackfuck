import SwiftUI

struct GamesLibraryView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var premiumManager: PremiumManager
    @StateObject private var vm = GamesLibraryViewModel()
    @State private var showCustomCreator = false
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Error Banner
                    if let error = vm.error {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.yellow)
                            Text(error)
                                .font(.caption)
                            Spacer()
                            Button("Retry") {
                                Task {
                                    vm.error = nil
                                    if let uid = authVM.currentProfile?.id {
                                        await vm.loadCustomGames(userID: uid)
                                    }
                                }
                            }
                            .font(.caption.bold())
                        }
                        .padding()
                        .background(.red.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding(.horizontal)
                    }

                    // Search
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("Search games...", text: $searchText)
                    }
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal)

                    // Featured / Free Games
                    Section {
                        ForEach(filteredGames.filter { !$0.isPremiumOnly }) { format in
                            GameLibraryCard(format: format, isPremium: premiumManager.isPremium)
                        }
                    } header: {
                        sectionHeader("Free Games")
                    }

                    // Premium Games
                    Section {
                        ForEach(filteredGames.filter(\.isPremiumOnly)) { format in
                            GameLibraryCard(format: format, isPremium: premiumManager.isPremium)
                        }
                    } header: {
                        sectionHeader("Premium Games", icon: "crown.fill", color: .yellow)
                    }

                    // Custom Games
                    Section {
                        if vm.customGames.isEmpty {
                            Button {
                                showCustomCreator = true
                            } label: {
                                Label("Create Your First Custom Game", systemImage: "plus.circle.fill")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(.green.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .padding(.horizontal)
                        } else {
                            ForEach(vm.customGames) { game in
                                CustomGameCard(game: game)
                            }
                        }
                    } header: {
                        HStack {
                            sectionHeader("Custom Games", icon: "wrench.and.screwdriver.fill", color: .purple)
                            Spacer()
                            Button {
                                showCustomCreator = true
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(.green)
                            }
                            .padding(.trailing)
                        }
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Games Library")
            .sheet(isPresented: $showCustomCreator) {
                CustomGameCreatorView()
            }
            .task {
                if let uid = authVM.currentProfile?.id {
                    await vm.loadCustomGames(userID: uid)
                }
            }
        }
    }

    private var filteredGames: [GameFormat] {
        if searchText.isEmpty { return GameFormat.allCases.filter { $0 != .custom } }
        return GameFormat.allCases.filter {
            $0 != .custom && $0.rawValue.localizedCaseInsensitiveContains(searchText)
        }
    }

    private func sectionHeader(_ title: String, icon: String = "gamecontroller.fill", color: Color = .green) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(title)
                .font(.headline)
            Spacer()
        }
        .padding(.horizontal)
    }
}

struct GameLibraryCard: View {
    let format: GameFormat
    let isPremium: Bool

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(format.rawValue)
                            .font(.subheadline.bold())
                        if format.isPremiumOnly && !isPremium {
                            Image(systemName: "lock.fill")
                                .font(.caption)
                                .foregroundStyle(.yellow)
                        }
                    }
                    Text("\(format.minPlayers)-\(format.maxPlayers) players")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .foregroundStyle(.secondary)
            }

            if isExpanded {
                Text(format.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
        .onTapGesture {
            withAnimation { isExpanded.toggle() }
        }
    }
}

struct CustomGameCard: View {
    let game: CustomGameDefinition

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(game.name)
                .font(.subheadline.bold())
            Text(game.description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            HStack {
                Label(game.isTeamGame ? "Team" : "Individual", systemImage: game.isTeamGame ? "person.2" : "person")
                Spacer()
                Label(game.scoringType.rawValue, systemImage: "number")
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
}

// MARK: - Custom Game Creator

struct CustomGameCreatorView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var description = ""
    @State private var isTeamGame = false
    @State private var scoringType: CustomGameDefinition.ScoringType = .perHole
    @State private var pointsPerHole: Double = 1
    @State private var pressEnabled = false
    @State private var pressThreshold = 2
    @State private var autoPress = false
    @State private var useNetScoring = true
    @State private var minStakes: Double = 0
    @State private var maxStakes: Double = 100
    @State private var specialRules: [CustomGameDefinition.SpecialRule] = []

    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Info") {
                    TextField("Game Name", text: $name)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Game Type") {
                    Toggle("Team Game", isOn: $isTeamGame)
                    Toggle("Net Scoring", isOn: $useNetScoring)

                    Picker("Scoring Type", selection: $scoringType) {
                        Text("Per Hole").tag(CustomGameDefinition.ScoringType.perHole)
                        Text("Per Point").tag(CustomGameDefinition.ScoringType.perPoint)
                        Text("Aggregate").tag(CustomGameDefinition.ScoringType.aggregate)
                        Text("Match Play").tag(CustomGameDefinition.ScoringType.matchPlay)
                    }
                }

                Section("Stakes") {
                    HStack {
                        Text("Points per hole")
                        Spacer()
                        TextField("1", value: $pointsPerHole, format: .number)
                            .keyboardType(.decimalPad)
                            .frame(width: 60)
                            .multilineTextAlignment(.trailing)
                    }
                }

                Section("Presses") {
                    Toggle("Enable Presses", isOn: $pressEnabled)
                    if pressEnabled {
                        Stepper("Press when down by \(pressThreshold)", value: $pressThreshold, in: 1...5)
                        Toggle("Auto-Press", isOn: $autoPress)
                    }
                }

                Section("Special Rules") {
                    ForEach(specialRules) { rule in
                        VStack(alignment: .leading) {
                            Text(rule.trigger).font(.caption.bold())
                            Text(rule.effect).font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                    Button("Add Rule") {
                        specialRules.append(
                            CustomGameDefinition.SpecialRule(
                                trigger: "New trigger",
                                effect: "New effect",
                                pointValue: 1
                            )
                        )
                    }
                }
            }
            .navigationTitle("Create Game")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        // Save would go through GamesLibraryViewModel
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}
