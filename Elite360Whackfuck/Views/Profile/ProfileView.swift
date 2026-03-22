import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var premiumManager: PremiumManager

    @State private var isEditingHandicap = false
    @State private var handicapText = ""
    @State private var showFriends = false
    @State private var showPremium = false
    @State private var friendSearch = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Profile Header
                    profileHeader

                    // Handicap Section
                    handicapSection

                    // Friends
                    friendsSection

                    // Settings
                    settingsSection

                    // Premium
                    premiumBanner

                    // Sign Out
                    Button(role: .destructive) {
                        authVM.signOut()
                    } label: {
                        Text("Sign Out")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.red.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)

                    // Legal
                    VStack(spacing: 4) {
                        Text("Elite360.Whackfuck v1.0")
                        Text("For entertainment purposes only. No real-money gambling facilitation.")
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Profile")
            .sheet(isPresented: $showFriends) {
                FriendsListView()
                    .environmentObject(authVM)
            }
            .sheet(isPresented: $showPremium) {
                PremiumView()
                    .environmentObject(premiumManager)
            }
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        VStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(.green.opacity(0.2))
                    .frame(width: 80, height: 80)
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.green)
            }

            Text(authVM.currentProfile?.displayName ?? "Golfer")
                .font(.title2.bold())

            Text("@\(authVM.currentProfile?.username ?? "username")")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let home = authVM.currentProfile?.homeCourse, !home.isEmpty {
                Label(home, systemImage: "mappin.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if premiumManager.isPremium {
                HStack {
                    Image(systemName: "crown.fill")
                        .foregroundStyle(.yellow)
                    Text("PREMIUM")
                        .font(.caption.bold())
                        .foregroundStyle(.yellow)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(.yellow.opacity(0.1))
                .clipShape(Capsule())
            }
        }
        .padding()
    }

    // MARK: - Handicap

    private var handicapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Handicap Index")
                    .font(.headline)
                Spacer()
                Button("Edit") { isEditingHandicap = true }
                    .font(.caption)
            }

            if let hcp = authVM.currentProfile?.handicapIndex {
                Text(String(format: "%.1f", hcp))
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundStyle(.green)
            } else {
                Text("Not set")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal)
        .alert("Update Handicap", isPresented: $isEditingHandicap) {
            TextField("Handicap Index", text: $handicapText)
                .keyboardType(.decimalPad)
            Button("Save") {
                if let value = Double(handicapText) {
                    Task { await authVM.updateProfile(["handicapIndex": value]) }
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: - Friends

    private var friendsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Friends")
                    .font(.headline)
                Spacer()
                Button("Manage") { showFriends = true }
                    .font(.caption)
            }

            let count = authVM.currentProfile?.friendIDs.count ?? 0
            Text("\(count) friends")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal)
    }

    // MARK: - Settings

    private var settingsSection: some View {
        VStack(spacing: 0) {
            SettingsRow(icon: "person.text.rectangle", title: "Edit Profile") {}
            Divider().padding(.leading, 52)
            SettingsRow(icon: "mappin", title: "Home Course") {}
            Divider().padding(.leading, 52)
            SettingsRow(icon: "bell", title: "Notifications") {}
            Divider().padding(.leading, 52)
            SettingsRow(icon: "lock.shield", title: "Privacy") {}
        }
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal)
    }

    // MARK: - Premium Banner

    private var premiumBanner: some View {
        Group {
            if !premiumManager.isPremium {
                Button { showPremium = true } label: {
                    HStack {
                        Image(systemName: "crown.fill")
                            .foregroundStyle(.yellow)
                        VStack(alignment: .leading) {
                            Text("Go Premium")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text("Unlock all games, AI caddy, advanced stats")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(
                        LinearGradient(colors: [.yellow.opacity(0.1), .orange.opacity(0.1)], startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal)
            }
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .foregroundStyle(.green)
                    .frame(width: 24)
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
    }
}

// MARK: - Friends List

struct FriendsListView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            VStack {
                // Search
                HStack {
                    Image(systemName: "magnifyingglass")
                    TextField("Search by username...", text: $searchText)
                }
                .padding()
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding()

                List {
                    Section("Friends (\(authVM.currentProfile?.friendIDs.count ?? 0))") {
                        if authVM.currentProfile?.friendIDs.isEmpty ?? true {
                            Text("No friends yet. Search to add some!")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(authVM.currentProfile?.friendIDs ?? [], id: \.self) { friendID in
                                HStack {
                                    Image(systemName: "person.circle.fill")
                                        .foregroundStyle(.green)
                                    Text(friendID.prefix(8))
                                    Spacer()
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
