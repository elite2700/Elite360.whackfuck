import SwiftUI

struct PostRoundView: View {
    @EnvironmentObject var roundVM: RoundViewModel
    @EnvironmentObject var moneyVM: MoneyViewModel
    @Environment(\.dismiss) private var dismiss

    var onDone: (() -> Void)? = nil
    @State private var showExport = false
    @State private var selectedTab = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("View", selection: $selectedTab) {
                    Text("Summary").tag(0)
                    Text("Settlement").tag(1)
                    Text("Stats").tag(2)
                }
                .pickerStyle(.segmented)
                .padding()

                TabView(selection: $selectedTab) {
                    summaryTab.tag(0)
                    settlementTab.tag(1)
                    statsTab.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("Round Complete")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        if let onDone {
                            onDone()
                        } else {
                            dismiss()
                        }
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    ShareLink(item: moneyVM.exportSettlement()) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .onAppear {
                if let round = roundVM.currentRound {
                    moneyVM.calculateBalances(from: round, gameResults: roundVM.gameResults)
                }
            }
        }
    }

    // MARK: - Summary Tab

    private var summaryTab: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Course Info
                VStack(spacing: 4) {
                    Text(roundVM.currentRound?.courseName ?? "")
                        .font(.title2.bold())
                    Text(roundVM.currentRound?.date.formatted(date: .long, time: .omitted) ?? "")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()

                // Final Scores
                ForEach(roundVM.scorecards.sorted(by: { $0.value.totalGross < $1.value.totalGross }), id: \.key) { pid, card in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(card.playerName)
                                .font(.headline)
                            HStack(spacing: 12) {
                                Label("\(card.totalPutts) putts", systemImage: "circle.fill")
                                Label("\(card.greensInRegulation) GIR", systemImage: "flag.fill")
                                Label("\(card.fairwaysHit) FIR", systemImage: "arrow.up.right")
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("\(card.totalGross)")
                                .font(.title.bold())
                                .foregroundStyle(.green)
                            Text("Net: \(card.totalNet)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
        }
    }

    // MARK: - Settlement Tab

    private var settlementTab: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Total Pot
                VStack(spacing: 4) {
                    Text("Total Pot")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("$\(String(format: "%.2f", moneyVM.totalPot))")
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .foregroundStyle(.green)
                }
                .padding()

                // Balances
                VStack(alignment: .leading, spacing: 12) {
                    Text("Balances")
                        .font(.headline)

                    ForEach(moneyVM.balances) { balance in
                        HStack {
                            Text(balance.playerName)
                                .font(.subheadline)
                            Spacer()
                            Text(balance.netBalance >= 0
                                 ? "+$\(String(format: "%.2f", balance.netBalance))"
                                 : "-$\(String(format: "%.2f", abs(balance.netBalance)))")
                                .font(.subheadline.bold())
                                .foregroundStyle(balance.netBalance >= 0 ? .green : .red)
                        }

                        // Game breakdown
                        ForEach(balance.gameBreakdown.sorted(by: { $0.key < $1.key }), id: \.key) { game, amount in
                            HStack {
                                Text("  \(game)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("$\(String(format: "%.0f", amount))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Divider()
                    }
                }
                .padding()
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 14))

                // Settlements
                VStack(alignment: .leading, spacing: 12) {
                    Text("Who Pays Whom")
                        .font(.headline)

                    ForEach(Array(moneyVM.settlements.enumerated()), id: \.element.id) { index, settlement in
                        HStack {
                            VStack(alignment: .leading) {
                                Text("\(settlement.fromPlayerName)")
                                    .font(.subheadline.bold())
                                Text("pays \(settlement.toPlayerName)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("$\(String(format: "%.2f", settlement.amount))")
                                .font(.headline.bold())
                                .foregroundStyle(.orange)

                            Button {
                                moneyVM.markSettlementPaid(index: index)
                            } label: {
                                Image(systemName: settlement.isPaid ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(settlement.isPaid ? .green : .gray)
                            }
                        }
                        .padding()
                        .background(settlement.isPaid ? .green.opacity(0.05) : .clear)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
                .padding()
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 14))

                // Disclaimer
                Text("Elite360.Whackfuck is for entertainment purposes only.\nSettle payments manually via Venmo, PayPal, or cash.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .padding()
        }
    }

    // MARK: - Stats Tab

    private var statsTab: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Round Statistics")
                    .font(.headline)

                ForEach(roundVM.scorecards.sorted(by: { $0.key < $1.key }), id: \.key) { pid, card in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(card.playerName)
                            .font(.subheadline.bold())

                        HStack {
                            statBox("Score", value: "\(card.totalGross)")
                            statBox("Putts", value: "\(card.totalPutts)")
                            statBox("GIR", value: "\(card.greensInRegulation)")
                            statBox("FIR", value: "\(card.fairwaysHit)")
                        }
                    }
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
        }
    }

    private func statBox(_ label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.bold())
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
