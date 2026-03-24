import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var analyticsVM = AnalyticsViewModel()
    @State private var recentRounds: [GolfRound] = []
    @State private var friendActivity: [FriendActivityItem] = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Welcome Header
                    welcomeCard

                    // Handicap Card
                    if let hcp = authVM.currentProfile?.handicapIndex {
                        handicapCard(index: hcp)
                    }

                    // Quick Actions
                    quickActions

                    // Recent Rounds
                    recentRoundsSection

                    // Friends Activity (stub)
                    friendsActivity
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Elite360")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: ProfileView()) {
                        Image(systemName: "person.circle.fill")
                            .foregroundStyle(.green)
                            .font(.title2)
                    }
                }
            }
            .task {
                if let uid = authVM.currentProfile?.id {
                    await analyticsVM.loadHistory(for: uid)
                    recentRounds = Array(analyticsVM.roundHistory.prefix(5))
                    await loadFriendActivity()
                }
            }
        }
    }

    // MARK: - Subviews

    private var welcomeCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Welcome back,")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(authVM.currentProfile?.displayName ?? "Golfer")
                    .font(.title2.bold())
            }
            Spacer()
            Image(systemName: "figure.golf")
                .font(.system(size: 40))
                .foregroundStyle(.green)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func handicapCard(index: Double) -> some View {
        VStack(spacing: 8) {
            Text("Handicap Index")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(String(format: "%.1f", index))
                .font(.system(size: 48, weight: .black, design: .rounded))
                .foregroundStyle(.green)
            if let analytics = analyticsVM.currentAnalytics {
                HStack(spacing: 16) {
                    StatPill(label: "Avg Score", value: String(format: "%.0f", analytics.averageScore))
                    StatPill(label: "Avg Putts", value: String(format: "%.1f", analytics.averagePutts))
                    StatPill(label: "GIR", value: String(format: "%.0f%%", analytics.girPercentage))
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var quickActions: some View {
        HStack(spacing: 12) {
            NavigationLink(destination: StartRoundView()) {
                QuickActionButton(icon: "play.fill", title: "Start Round", color: .green)
            }
            NavigationLink(destination: GamesLibraryView()) {
                QuickActionButton(icon: "trophy.fill", title: "Games", color: .orange)
            }
            NavigationLink(destination: AnalyticsDashboardView()) {
                QuickActionButton(icon: "chart.bar.fill", title: "Stats", color: .blue)
            }
        }
    }

    private var recentRoundsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Rounds")
                .font(.headline)

            if recentRounds.isEmpty {
                Text("No rounds yet. Start your first round!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                ForEach(recentRounds) { round in
                    RoundRowView(round: round)
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var friendsActivity: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Friends Activity")
                    .font(.headline)
                Spacer()
                NavigationLink("See All") {
                    FriendsListView()
                        .environmentObject(authVM)
                }
                .font(.caption)
            }

            if friendActivity.isEmpty {
                Text("Add friends to see their activity here")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                ForEach(friendActivity) { item in
                    HStack(spacing: 12) {
                        Image(systemName: "person.circle.fill")
                            .foregroundStyle(.green)
                            .font(.title3)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.playerName)
                                .font(.subheadline.bold())
                            Text("Shot \(item.score) at \(item.courseName)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(item.date.relativeFormatted)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func loadFriendActivity() async {
        guard let friendIDs = authVM.currentProfile?.friendIDs, !friendIDs.isEmpty else { return }

        var items: [FriendActivityItem] = []
        let db = FirestoreService.shared

        for friendID in friendIDs.prefix(10) {
            let rounds: [GolfRound] = (try? await db.query(
                collection: GolfRound.collectionName,
                field: "playerIDs",
                arrayContains: friendID
            )) ?? []

            if let latest = rounds.sorted(by: { $0.date > $1.date }).first,
               let card = latest.scorecards[friendID],
               card.totalGross > 0 {
                items.append(FriendActivityItem(
                    id: friendID + latest.id.unsafelyUnwrapped,
                    playerName: card.playerName,
                    courseName: latest.courseName,
                    score: card.totalGross,
                    date: latest.date
                ))
            }
        }
        friendActivity = items.sorted { $0.date > $1.date }
    }
}

struct FriendActivityItem: Identifiable {
    let id: String
    let playerName: String
    let courseName: String
    let score: Int
    let date: Date
}

// MARK: - Supporting Views

struct StatPill: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.subheadline.bold())
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.green.opacity(0.1))
        .clipShape(Capsule())
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct RoundRowView: View {
    let round: GolfRound

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(round.courseName)
                    .font(.subheadline.bold())
                Text(round.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing) {
                if let firstCard = round.scorecards.values.first {
                    Text("\(firstCard.totalGross)")
                        .font(.title3.bold())
                        .foregroundStyle(.green)
                }
                Text("\(round.playerIDs.count) players")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
