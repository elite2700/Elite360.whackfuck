import Foundation

/// Client for the GolfCourseAPI (https://api.golfcourseapi.com)
final class GolfCourseAPIService {
    static let shared = GolfCourseAPIService()

    private let baseURL = "https://api.golfcourseapi.com/v1"
    private var apiKey: String? { SecretsManager.golfCourseAPIKey }

    private init() {}

    // MARK: - Search

    func searchCourses(query: String) async throws -> [GolfCourse] {
        guard let apiKey, !apiKey.isEmpty, !apiKey.starts(with: "YOUR_") else {
            print("⚠️ GOLF_COURSE_API_KEY not configured in Secrets.plist")
            return []
        }

        guard var components = URLComponents(string: "\(baseURL)/search") else { return [] }
        components.queryItems = [URLQueryItem(name: "search_query", value: query)]

        guard let url = components.url else { return [] }

        var request = URLRequest(url: url)
        request.setValue("Key \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 10

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            return []
        }

        let decoded = try JSONDecoder().decode(APISearchResponse.self, from: data)
        return decoded.courses.compactMap { mapToCourse($0) }
    }

    // MARK: - Get Course Detail

    func getCourse(id: Int) async throws -> GolfCourse? {
        guard let apiKey, !apiKey.isEmpty, !apiKey.starts(with: "YOUR_") else { return nil }

        guard let url = URL(string: "\(baseURL)/courses/\(id)") else { return nil }

        var request = URLRequest(url: url)
        request.setValue("Key \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 10

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            return nil
        }

        let decoded = try JSONDecoder().decode(APICourse.self, from: data)
        return mapToCourse(decoded)
    }

    // MARK: - Mapping

    private func mapToCourse(_ api: APICourse) -> GolfCourse? {
        // Pick the first male tee box for default ratings, or fall back
        let teeBox = api.tees?.male?.first ?? api.tees?.female?.first

        let courseRating = teeBox?.courseRating ?? 72.0
        let slopeRating = teeBox?.slopeRating ?? 113
        let par = teeBox?.parTotal ?? 72
        let numberOfHoles = teeBox?.numberOfHoles ?? 18

        let holes: [HoleInfo]
        if let apiHoles = teeBox?.holes, !apiHoles.isEmpty {
            holes = apiHoles.enumerated().map { index, h in
                HoleInfo(
                    number: index + 1,
                    par: h.par ?? 4,
                    yardage: h.yardage ?? 0,
                    handicapRank: h.handicap ?? (index + 1)
                )
            }
        } else {
            // Generate default holes
            let basePar = par / numberOfHoles
            let remainder = par % numberOfHoles
            holes = (1...numberOfHoles).map { num in
                HoleInfo(
                    number: num,
                    par: basePar + (num <= remainder ? 1 : 0),
                    yardage: 0,
                    handicapRank: num
                )
            }
        }

        let displayName: String
        if let courseName = api.courseName, !courseName.isEmpty,
           let clubName = api.clubName, !clubName.isEmpty,
           courseName != clubName {
            displayName = "\(clubName) - \(courseName)"
        } else {
            displayName = api.clubName ?? api.courseName ?? "Unknown Course"
        }

        return GolfCourse(
            id: api.id != nil ? String(api.id!) : nil,
            name: displayName,
            nameLowercase: displayName.lowercased(),
            city: api.location?.city ?? "",
            state: api.location?.state ?? "",
            country: api.location?.country ?? "US",
            latitude: api.location?.latitude ?? 0,
            longitude: api.location?.longitude ?? 0,
            courseRating: courseRating,
            slopeRating: slopeRating,
            par: par,
            holes: holes
        )
    }
}

// MARK: - API Response Models

private struct APISearchResponse: Decodable {
    let courses: [APICourse]
}

private struct APICourse: Decodable {
    let id: Int?
    let clubName: String?
    let courseName: String?
    let location: APILocation?
    let tees: APITees?

    enum CodingKeys: String, CodingKey {
        case id
        case clubName = "club_name"
        case courseName = "course_name"
        case location
        case tees
    }
}

private struct APILocation: Decodable {
    let address: String?
    let city: String?
    let state: String?
    let country: String?
    let latitude: Double?
    let longitude: Double?
}

private struct APITees: Decodable {
    let female: [APITeeBox]?
    let male: [APITeeBox]?
}

private struct APITeeBox: Decodable {
    let teeName: String?
    let courseRating: Double?
    let slopeRating: Int?
    let bogeyRating: Double?
    let totalYards: Int?
    let numberOfHoles: Int?
    let parTotal: Int?
    let holes: [APIHole]?

    enum CodingKeys: String, CodingKey {
        case teeName = "tee_name"
        case courseRating = "course_rating"
        case slopeRating = "slope_rating"
        case bogeyRating = "bogey_rating"
        case totalYards = "total_yards"
        case numberOfHoles = "number_of_holes"
        case parTotal = "par_total"
        case holes
    }
}

private struct APIHole: Decodable {
    let par: Int?
    let yardage: Int?
    let handicap: Int?
}
