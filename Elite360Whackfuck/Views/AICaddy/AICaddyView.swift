import SwiftUI

struct AICaddyView: View {
    @State private var distanceToPin = ""
    @State private var selectedLie: ShotContext.LieType = .fairway
    @State private var selectedElevation: ShotContext.ElevationChange = .level
    @State private var selectedWind: ShotContext.WindDirection = .calm
    @State private var windSpeed = ""
    @State private var advice: [AICaddyAdvice] = []
    @State private var isLoading = false
    @State private var clubs = defaultClubs

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "brain")
                            .font(.system(size: 40))
                            .foregroundStyle(.green)
                        Text("AI Caddy")
                            .font(.title2.bold())
                        Text("Get smart recommendations for your next shot")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()

                    // Shot Context Input
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Shot Details")
                            .font(.headline)

                        HStack {
                            Text("Distance to Pin (yds)")
                            Spacer()
                            TextField("150", text: $distanceToPin)
                                .keyboardType(.numberPad)
                                .frame(width: 80)
                                .textFieldStyle(.roundedBorder)
                                .multilineTextAlignment(.trailing)
                        }

                        Picker("Lie", selection: $selectedLie) {
                            ForEach(ShotContext.LieType.allCases, id: \.self) { lie in
                                Text(lie.rawValue.capitalized).tag(lie)
                            }
                        }

                        Picker("Elevation", selection: $selectedElevation) {
                            ForEach(ShotContext.ElevationChange.allCases, id: \.self) { elev in
                                Text(elev.rawValue.capitalized).tag(elev)
                            }
                        }

                        Picker("Wind", selection: $selectedWind) {
                            ForEach(ShotContext.WindDirection.allCases, id: \.self) { wind in
                                Text(wind.rawValue.capitalized).tag(wind)
                            }
                        }

                        if selectedWind != .calm {
                            HStack {
                                Text("Wind Speed (mph)")
                                Spacer()
                                TextField("10", text: $windSpeed)
                                    .keyboardType(.numberPad)
                                    .frame(width: 80)
                                    .textFieldStyle(.roundedBorder)
                                    .multilineTextAlignment(.trailing)
                            }
                        }
                    }
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal)

                    // Get Advice Button
                    Button {
                        Task { await getAdvice() }
                    } label: {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .tint(.black)
                            }
                            Text(isLoading ? "Analyzing..." : "Get Recommendation")
                                .font(.headline)
                        }
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.green)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(distanceToPin.isEmpty || isLoading)
                    .padding(.horizontal)

                    // Advice Cards
                    ForEach(advice) { tip in
                        AdviceCard(advice: tip)
                            .padding(.horizontal)
                    }

                    // Club Distances Reference
                    clubDistancesSection
                }
            }
            .navigationTitle("AI Caddy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func getAdvice() async {
        isLoading = true
        let context = ShotContext(
            distanceToPin: Int(distanceToPin) ?? 150,
            lie: selectedLie,
            elevation: selectedElevation,
            windSpeed: Double(windSpeed),
            windDirection: selectedWind,
            temperature: nil,
            targetType: .green
        )

        do {
            let clubAdvice = try await AICaddyService.shared.recommendClub(context: context, clubs: clubs)
            let strategy = try await AICaddyService.shared.shotStrategy(
                context: context,
                holeInfo: HoleInfo(number: 1, par: 4, yardage: Int(distanceToPin) ?? 150, handicapRank: 1)
            )
            advice = [clubAdvice, strategy]
        } catch {
            advice = [AICaddyAdvice(
                type: .clubSelection,
                title: "Club Selection",
                message: quickClubRecommendation(distance: Int(distanceToPin) ?? 150),
                confidence: 0.6,
                timestamp: Date()
            )]
        }
        isLoading = false
    }

    private func quickClubRecommendation(distance: Int) -> String {
        let sorted = clubs.sorted { abs($0.averageDistance - distance) < abs($1.averageDistance - distance) }
        if let best = sorted.first {
            return "Based on your distances, try your \(best.name) (avg \(best.averageDistance) yds).\nAdjust for lie and conditions."
        }
        return "Try a mid-iron and aim for the center of the green."
    }

    private var clubDistancesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your Club Distances")
                .font(.headline)

            ForEach(clubs) { club in
                HStack {
                    Text(club.name)
                        .font(.subheadline)
                    Spacer()
                    Text("\(club.minDistance)-\(club.maxDistance) yds")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("avg \(club.averageDistance)")
                        .font(.caption.bold())
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal)
    }

    static var defaultClubs: [ClubData] {
        [
            ClubData(name: "Driver", averageDistance: 250, minDistance: 230, maxDistance: 275),
            ClubData(name: "3-Wood", averageDistance: 230, minDistance: 215, maxDistance: 245),
            ClubData(name: "5-Wood", averageDistance: 210, minDistance: 195, maxDistance: 225),
            ClubData(name: "4-Iron", averageDistance: 195, minDistance: 180, maxDistance: 210),
            ClubData(name: "5-Iron", averageDistance: 185, minDistance: 170, maxDistance: 200),
            ClubData(name: "6-Iron", averageDistance: 175, minDistance: 160, maxDistance: 185),
            ClubData(name: "7-Iron", averageDistance: 165, minDistance: 150, maxDistance: 175),
            ClubData(name: "8-Iron", averageDistance: 150, minDistance: 140, maxDistance: 160),
            ClubData(name: "9-Iron", averageDistance: 140, minDistance: 125, maxDistance: 150),
            ClubData(name: "PW", averageDistance: 125, minDistance: 115, maxDistance: 135),
            ClubData(name: "GW", averageDistance: 110, minDistance: 100, maxDistance: 120),
            ClubData(name: "SW", averageDistance: 90, minDistance: 80, maxDistance: 100),
            ClubData(name: "LW", averageDistance: 70, minDistance: 60, maxDistance: 85),
        ]
    }
}

struct AdviceCard: View {
    let advice: AICaddyAdvice

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: iconFor(advice.type))
                    .foregroundStyle(.green)
                Text(advice.title)
                    .font(.subheadline.bold())
                Spacer()
                Text("\(Int(advice.confidence * 100))%")
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(.green.opacity(0.2))
                    .clipShape(Capsule())
            }
            Text(advice.message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.green.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.green.opacity(0.2)))
    }

    private func iconFor(_ type: AICaddyAdvice.AdviceType) -> String {
        switch type {
        case .clubSelection: return "bag.fill"
        case .shotStrategy: return "scope"
        case .courseManagement: return "map.fill"
        case .postRoundInsight: return "chart.bar.fill"
        case .practiceRecommendation: return "figure.golf"
        }
    }
}
