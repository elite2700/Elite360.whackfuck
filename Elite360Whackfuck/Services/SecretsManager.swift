import Foundation

/// Loads API keys from Secrets.plist (which is .gitignored and never committed).
enum SecretsManager {
    private static let secrets: [String: Any] = {
        guard let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
        else {
            print("⚠️ Secrets.plist not found in bundle. API keys will not be available.")
            return [:]
        }
        return dict
    }()

    static var geminiAPIKey: String? {
        secrets["GEMINI_API_KEY"] as? String
    }

    static var revenueCatAPIKey: String? {
        secrets["REVENUECAT_API_KEY"] as? String
    }

    static var golfCourseAPIKey: String? {
        secrets["GOLF_COURSE_API_KEY"] as? String
    }
}
