import Foundation

@MainActor
final class GamesLibraryViewModel: ObservableObject {
    @Published var allGames: [GameFormat] = GameFormat.allCases.filter { $0 != .custom }
    @Published var customGames: [CustomGameDefinition] = []
    @Published var favoriteGameIDs: Set<String> = []
    @Published var selectedGames: [GameFormat] = []
    @Published var isLoading = false
    @Published var error: String?

    private let db = FirestoreService.shared

    func loadCustomGames(userID: String) async {
        isLoading = true
        do {
            customGames = try await db.query(
                collection: CustomGameDefinition.collectionName,
                field: "createdBy",
                isEqualTo: userID
            )
        } catch {
            self.error = error.localizedDescription
            customGames = []
        }
        isLoading = false
    }

    func saveCustomGame(_ game: CustomGameDefinition) async throws {
        _ = try await db.create(game, in: CustomGameDefinition.collectionName)
        if let uid = game.createdBy as String? {
            await loadCustomGames(userID: uid)
        }
    }

    func deleteCustomGame(_ game: CustomGameDefinition) async {
        guard let id = game.id else { return }
        try? await db.delete(from: CustomGameDefinition.collectionName, documentID: id)
        customGames.removeAll { $0.id == id }
    }

    func toggleFavorite(_ format: GameFormat) {
        if favoriteGameIDs.contains(format.rawValue) {
            favoriteGameIDs.remove(format.rawValue)
        } else {
            favoriteGameIDs.insert(format.rawValue)
        }
    }

    func toggleSelection(_ format: GameFormat) {
        if selectedGames.contains(format) {
            selectedGames.removeAll { $0 == format }
        } else {
            selectedGames.append(format)
        }
    }

    func availableGames(isPremium: Bool) -> [GameFormat] {
        if isPremium { return allGames }
        return allGames.filter { !$0.isPremiumOnly }
    }
}
