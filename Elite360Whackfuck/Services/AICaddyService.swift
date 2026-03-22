import Foundation
import GoogleGenerativeAI

/// AI Caddy using Google Generative AI for golf advice.
final class AICaddyService {
    static let shared = AICaddyService()

    // In production, load from secure config / Firebase Remote Config
    private let model: GenerativeModel

    private init() {
        // API key should be stored securely — this is a placeholder
        model = GenerativeModel(name: "gemini-pro", apiKey: "YOUR_API_KEY_HERE")
    }

    // MARK: - Club Recommendation

    func recommendClub(context: ShotContext, clubs: [ClubData]) async throws -> AICaddyAdvice {
        let prompt = buildClubPrompt(context: context, clubs: clubs)
        let response = try await model.generateContent(prompt)
        let text = response.text ?? "I'd suggest your \(suggestClubFallback(distance: context.distanceToPin, clubs: clubs))."

        return AICaddyAdvice(
            type: .clubSelection,
            title: "Club Selection",
            message: text,
            confidence: 0.8,
            timestamp: Date()
        )
    }

    // MARK: - Shot Strategy

    func shotStrategy(context: ShotContext, holeInfo: HoleInfo) async throws -> AICaddyAdvice {
        let prompt = """
        Golf shot strategy advice. Hole: Par \(holeInfo.par), \(holeInfo.yardage) yards.
        Current situation: \(context.distanceToPin) yards to pin, lie is \(context.lie.rawValue), \
        elevation \(context.elevation.rawValue).
        Wind: \(context.windSpeed ?? 0) mph \(context.windDirection?.rawValue ?? "calm").
        Give concise, actionable advice for this shot. Keep it under 3 sentences.
        """
        let response = try await model.generateContent(prompt)

        return AICaddyAdvice(
            type: .shotStrategy,
            title: "Shot Strategy",
            message: response.text ?? "Aim for the center of the green and play safe.",
            confidence: 0.75,
            timestamp: Date()
        )
    }

    // MARK: - Post-Round Analysis

    func postRoundAnalysis(scorecard: Scorecard, coursePar: Int) async throws -> [AICaddyAdvice] {
        let overPar = scorecard.totalGross - coursePar
        let girPct = Double(scorecard.greensInRegulation) / Double(scorecard.holeScores.count) * 100
        let fwPct = Double(scorecard.fairwaysHit) / 14.0 * 100 // typical 14 par-4/5 holes
        let pph = Double(scorecard.totalPutts) / Double(scorecard.holeScores.count)

        let prompt = """
        Analyze this golf round and provide 3 specific improvement tips:
        - Score: \(scorecard.totalGross) (\(overPar > 0 ? "+" : "")\(overPar))
        - Putts per hole: \(String(format: "%.1f", pph))
        - Greens in Regulation: \(String(format: "%.0f", girPct))%
        - Fairways Hit: \(String(format: "%.0f", fwPct))%
        Format each tip as: [Category]: [Insight]
        Keep each tip under 2 sentences. Be specific about yardage ranges or situations.
        """

        let response = try await model.generateContent(prompt)
        let text = response.text ?? ""
        let tips = text.components(separatedBy: "\n").filter { !$0.isEmpty }

        return tips.prefix(3).map { tip in
            AICaddyAdvice(
                type: .postRoundInsight,
                title: "Post-Round Insight",
                message: tip,
                confidence: 0.7,
                timestamp: Date()
            )
        }
    }

    // MARK: - Helpers

    private func buildClubPrompt(context: ShotContext, clubs: [ClubData]) -> String {
        let clubList = clubs.map { "\($0.name): avg \($0.averageDistance)yds" }.joined(separator: ", ")
        return """
        Recommend the best golf club for this shot:
        Distance: \(context.distanceToPin) yards. Lie: \(context.lie.rawValue). \
        Elevation: \(context.elevation.rawValue). \
        Wind: \(context.windSpeed ?? 0) mph \(context.windDirection?.rawValue ?? "calm").
        Available clubs with average distances: \(clubList).
        Give a single club recommendation with brief reasoning (2 sentences max).
        """
    }

    private func suggestClubFallback(distance: Int, clubs: [ClubData]) -> String {
        let sorted = clubs.sorted { abs($0.averageDistance - distance) < abs($1.averageDistance - distance) }
        return sorted.first?.name ?? "7-iron"
    }
}
