import SwiftUI
import Charts

struct AnalyticsDashboardView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var vm = AnalyticsViewModel()
    @State private var selectedCategory: StatCategory = .scoring
    @State private var showExport = false

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
                                        await vm.loadHistory(for: uid)
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

                    // Overview Cards
                    if let analytics = vm.currentAnalytics {
                        overviewSection(analytics)
                    }

                    // Category Picker
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(StatCategory.allCases) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    // Trend Chart
                    trendChart

                    // Round History
                    historySection

                    // Leaderboard
                    leaderboardSection

                    // Export
                    Button {
                        showExport = true
                    } label: {
                        Label("Export Statistics", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.regularMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Analytics")
            .task {
                if let uid = authVM.currentProfile?.id {
                    await vm.loadHistory(for: uid)
                }
            }
            .sheet(isPresented: $showExport) {
                if let uid = authVM.currentProfile?.id {
                    ShareLink(item: vm.exportCSV(for: uid)) {
                        Label("Share CSV", systemImage: "doc.text")
                    }
                }
            }
        }
    }

    // MARK: - Overview

    private func overviewSection(_ analytics: RoundAnalytics) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                AnalyticsCard(
                    title: "Avg Score",
                    value: String(format: "%.0f", analytics.averageScore),
                    icon: "number",
                    color: .green
                )
                AnalyticsCard(
                    title: "Avg Putts",
                    value: String(format: "%.1f", analytics.averagePutts),
                    icon: "circle.fill",
                    color: .blue
                )
            }
            HStack(spacing: 12) {
                AnalyticsCard(
                    title: "Fairways",
                    value: String(format: "%.0f%%", analytics.fairwayPercentage),
                    icon: "arrow.up.right",
                    color: .orange
                )
                AnalyticsCard(
                    title: "GIR",
                    value: String(format: "%.0f%%", analytics.girPercentage),
                    icon: "flag.fill",
                    color: .purple
                )
            }
            if let handicap = authVM.currentProfile?.handicapIndex {
                HStack {
                    Image(systemName: "chart.line.downtrend.xyaxis")
                        .foregroundStyle(.green)
                    Text("Handicap Index: ")
                        .font(.subheadline)
                    Text(String(format: "%.1f", handicap))
                        .font(.title2.bold())
                        .foregroundStyle(.green)
                    Spacer()
                }
                .padding()
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Trend Chart

    private var trendChart: some View {
        VStack(alignment: .leading) {
            Text("\(selectedCategory.rawValue) Trend")
                .font(.headline)
                .padding(.horizontal)

            let filteredTrends = vm.trends.filter { $0.category == selectedCategory }

            if filteredTrends.isEmpty {
                Text("Play more rounds to see trends")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
            } else {
                Chart(filteredTrends) { trend in
                    LineMark(
                        x: .value("Date", trend.date),
                        y: .value(selectedCategory.rawValue, trend.value)
                    )
                    .foregroundStyle(.green)
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Date", trend.date),
                        y: .value(selectedCategory.rawValue, trend.value)
                    )
                    .foregroundStyle(.green)
                }
                .frame(height: 200)
                .padding(.horizontal)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal)
    }

    // MARK: - History

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Round History")
                .font(.headline)
                .padding(.horizontal)

            if vm.roundHistory.isEmpty {
                Text("No rounds recorded yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                ForEach(vm.roundHistory.prefix(10)) { round in
                    RoundRowView(round: round)
                        .padding(.horizontal)
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal)
    }

    // MARK: - Leaderboard

    private var leaderboardSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Friend Leaderboard")
                .font(.headline)

            if vm.leaderboard.isEmpty {
                Text("Add friends to compare stats")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                ForEach(vm.leaderboard) { entry in
                    HStack {
                        Text("#\(entry.rank)")
                            .font(.caption.bold())
                            .foregroundStyle(entry.rank <= 3 ? .yellow : .secondary)
                            .frame(width: 30)
                        Text(entry.playerName)
                            .font(.subheadline)
                        Spacer()
                        Text(String(format: "%.1f", entry.value))
                            .font(.subheadline.bold())
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal)
    }
}

struct AnalyticsCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Spacer()
            }
            Text(value)
                .font(.title2.bold())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
