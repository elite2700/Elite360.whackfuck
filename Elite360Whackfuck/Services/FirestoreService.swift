import Foundation
import FirebaseFirestore

final class FirestoreService {
    static let shared = FirestoreService()
    private lazy var db: Firestore = {
        let firestore = Firestore.firestore()
        let settings = firestore.settings
        settings.isPersistenceEnabled = true
        settings.cacheSizeBytes = FirestoreCacheSizeUnlimited
        firestore.settings = settings
        return firestore
    }()

    private init() {}

    // MARK: - Generic CRUD

    func create<T: Codable>(_ object: T, in collection: String) async throws -> String {
        let ref = try db.collection(collection).addDocument(from: object)
        return ref.documentID
    }

    func setDocument<T: Codable>(_ object: T, in collection: String, documentID: String) async throws {
        try db.collection(collection).document(documentID).setData(from: object)
    }

    func getDocument<T: Codable>(from collection: String, documentID: String) async throws -> T {
        let snapshot = try await db.collection(collection).document(documentID).getDocument()
        return try snapshot.data(as: T.self)
    }

    func updateFields(in collection: String, documentID: String, fields: [String: Any]) async throws {
        try await db.collection(collection).document(documentID).updateData(fields)
    }

    func delete(from collection: String, documentID: String) async throws {
        try await db.collection(collection).document(documentID).delete()
    }

    func query<T: Codable>(
        collection: String,
        field: String,
        isEqualTo value: Any
    ) async throws -> [T] {
        let snapshot = try await db.collection(collection)
            .whereField(field, isEqualTo: value)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: T.self) }
    }

    func query<T: Codable>(
        collection: String,
        field: String,
        arrayContains value: Any
    ) async throws -> [T] {
        let snapshot = try await db.collection(collection)
            .whereField(field, arrayContains: value)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: T.self) }
    }

    // MARK: - Real-time Listeners

    func listen<T: Codable>(
        to collection: String,
        documentID: String,
        handler: @escaping (T?) -> Void
    ) -> ListenerRegistration {
        db.collection(collection).document(documentID)
            .addSnapshotListener { snapshot, _ in
                guard let snapshot else { handler(nil); return }
                handler(try? snapshot.data(as: T.self))
            }
    }

    func listenToQuery<T: Codable>(
        collection: String,
        field: String,
        isEqualTo value: Any,
        handler: @escaping ([T]) -> Void
    ) -> ListenerRegistration {
        db.collection(collection)
            .whereField(field, isEqualTo: value)
            .addSnapshotListener { snapshot, _ in
                let results = snapshot?.documents.compactMap { try? $0.data(as: T.self) } ?? []
                handler(results)
            }
    }

    // MARK: - Batch & Transactions

    func runTransaction<T>(_ block: @escaping (Transaction, inout T?) throws -> Void) async throws where T: Any {
        try await db.runTransaction { transaction, errorPointer in
            var result: T?
            do { try block(transaction, &result) }
            catch { errorPointer?.pointee = error as NSError }
            return result
        }
    }

    var batch: WriteBatch { db.batch() }

    func collectionRef(_ name: String) -> CollectionReference {
        db.collection(name)
    }
}
