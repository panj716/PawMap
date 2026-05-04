import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

/// Base Firebase service class providing common functionality
class FirebaseService: ObservableObject {
    static let shared = FirebaseService()
    
    let db = Firestore.firestore()
    let auth = Auth.auth()
    
    private init() {
        // Configure Firestore settings
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        settings.cacheSizeBytes = FirestoreCacheSizeUnlimited
        db.settings = settings
    }
    
    // MARK: - Generic CRUD Operations
    
    /// Create a document in a collection
    func createDocument<T: Codable>(_ data: T, in collection: String, withId id: String? = nil) -> AnyPublisher<String, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(FirebaseError.serviceUnavailable))
                return
            }
            
            do {
                let documentData = try Firestore.Encoder().encode(data)
                let documentId = id ?? UUID().uuidString
                
                self.db.collection(collection).document(documentId).setData(documentData) { error in
                    if let error = error {
                        promise(.failure(error))
                    } else {
                        promise(.success(documentId))
                    }
                }
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// Read a document from a collection
    func readDocument<T: Codable>(_ type: T.Type, from collection: String, withId id: String) -> AnyPublisher<T?, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(FirebaseError.serviceUnavailable))
                return
            }
            
            self.db.collection(collection).document(id).getDocument { document, error in
                if let error = error {
                    promise(.failure(error))
                    return
                }
                
                guard let document = document, document.exists else {
                    promise(.success(nil))
                    return
                }
                
                do {
                    let data = try Firestore.Decoder().decode(type, from: document.data() ?? [:])
                    promise(.success(data))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// Update a document in a collection
    func updateDocument<T: Codable>(_ data: T, in collection: String, withId id: String) -> AnyPublisher<Void, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(FirebaseError.serviceUnavailable))
                return
            }
            
            do {
                let documentData = try Firestore.Encoder().encode(data)
                self.db.collection(collection).document(id).setData(documentData, merge: true) { error in
                    if let error = error {
                        promise(.failure(error))
                    } else {
                        promise(.success(()))
                    }
                }
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// Delete a document from a collection
    func deleteDocument(from collection: String, withId id: String) -> AnyPublisher<Void, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(FirebaseError.serviceUnavailable))
                return
            }
            
            self.db.collection(collection).document(id).delete { error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success(()))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// Listen to real-time updates for a collection.
    /// Uses a long-lived publisher (not `Future`) so every snapshot update reaches subscribers.
    func listenToCollection<T: Codable>(_ type: T.Type, from collection: String, where field: String? = nil, isEqualTo value: Any? = nil) -> AnyPublisher<[T], Error> {
        Deferred { [weak self] () -> AnyPublisher<[T], Error> in
            guard let self = self else {
                return Fail(error: FirebaseError.serviceUnavailable).eraseToAnyPublisher()
            }
            
            var query: Query = self.db.collection(collection)
            if let field = field, let value = value {
                query = query.whereField(field, isEqualTo: value)
            }
            
            let subject = PassthroughSubject<[T], Error>()
            let listener = query.addSnapshotListener { snapshot, error in
                if let error = error {
                    subject.send(completion: .failure(error))
                    return
                }
                guard let documents = snapshot?.documents else {
                    subject.send([])
                    return
                }
                let results: [T] = documents.compactMap { document in
                    var data = document.data()
                    if data["id"] == nil {
                        data["id"] = document.documentID
                    }
                    return try? Firestore.Decoder().decode(type, from: data)
                }
                subject.send(results)
            }
            return subject
                .handleEvents(receiveCancel: {
                    listener.remove()
                })
                .eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }
    
    /// Listen to real-time updates for a single document (multi-emission, not `Future`).
    func listenToDocument<T: Codable>(_ type: T.Type, from collection: String, withId id: String) -> AnyPublisher<T?, Error> {
        Deferred { [weak self] () -> AnyPublisher<T?, Error> in
            guard let self = self else {
                return Fail(error: FirebaseError.serviceUnavailable).eraseToAnyPublisher()
            }
            let subject = PassthroughSubject<T?, Error>()
            let listener = self.db.collection(collection).document(id).addSnapshotListener { document, error in
                if let error = error {
                    subject.send(completion: .failure(error))
                    return
                }
                guard let document = document, document.exists else {
                    subject.send(nil)
                    return
                }
                do {
                    var data = document.data() ?? [:]
                    if data["id"] == nil {
                        data["id"] = document.documentID
                    }
                    let decoded = try Firestore.Decoder().decode(type, from: data)
                    subject.send(decoded)
                } catch {
                    subject.send(completion: .failure(error))
                }
            }
            return subject
                .handleEvents(receiveCancel: {
                    listener.remove()
                })
                .eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }
    
    /// Query documents with multiple conditions
    func queryDocuments<T: Codable>(_ type: T.Type, from collection: String, where conditions: [(field: String, operator: QueryOperator, value: Any)]) -> AnyPublisher<[T], Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(FirebaseError.serviceUnavailable))
                return
            }
            
            var query: Query = self.db.collection(collection)
            
            for condition in conditions {
                switch condition.operator {
                case .isEqualTo:
                    query = query.whereField(condition.field, isEqualTo: condition.value)
                case .isGreaterThan:
                    query = query.whereField(condition.field, isGreaterThan: condition.value)
                case .isLessThan:
                    query = query.whereField(condition.field, isLessThan: condition.value)
                case .arrayContains:
                    query = query.whereField(condition.field, arrayContains: condition.value)
                case .in:
                    query = query.whereField(condition.field, in: condition.value as! [Any])
                }
            }
            
            query.getDocuments { snapshot, error in
                if let error = error {
                    promise(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    promise(.success([]))
                    return
                }
                
                let results = documents.compactMap { document in
                    try? Firestore.Decoder().decode(type, from: document.data())
                }
                
                promise(.success(results))
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// Fetch multiple documents by their IDs
    func fetchDocumentsByIds<T: Codable>(_ type: T.Type, from collection: String, ids: [String]) -> AnyPublisher<[T], Error> {
        guard !ids.isEmpty else {
            return Future { promise in
                promise(.success([]))
            }
            .eraseToAnyPublisher()
        }
        
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(FirebaseError.serviceUnavailable))
                return
            }
            
            // Fetch documents directly by their IDs (more efficient than querying)
            let resultsQueue = DispatchQueue(label: "com.pawmap.fetchResults")
            var allResults: [T] = []
            let dispatchGroup = DispatchGroup()
            
            for id in ids {
                dispatchGroup.enter()
                self.db.collection(collection).document(id).getDocument { document, error in
                    defer { dispatchGroup.leave() }
                    
                    // Skip documents that don't exist or have errors
                    guard error == nil, let document = document, document.exists else {
                        return
                    }
                    
                    do {
                        var data = document.data() ?? [:]
                        data["id"] = document.documentID
                        let decoded = try Firestore.Decoder().decode(type, from: data)
                        resultsQueue.sync {
                            allResults.append(decoded)
                        }
                    } catch {
                        // Skip documents that can't be decoded
                    }
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                // Return results (partial success is acceptable)
                promise(.success(allResults))
            }
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - Supporting Types

enum QueryOperator {
    case isEqualTo
    case isGreaterThan
    case isLessThan
    case arrayContains
    case `in`
}

enum FirebaseError: LocalizedError {
    case serviceUnavailable
    case authenticationRequired
    case invalidData
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .serviceUnavailable:
            return "Firebase service is unavailable"
        case .authenticationRequired:
            return "Authentication is required"
        case .invalidData:
            return "Invalid data format"
        case .networkError:
            return "Network error occurred"
        }
    }
}
