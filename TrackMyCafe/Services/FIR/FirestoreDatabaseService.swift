//
//  FirestoreDatabaseService.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 01.06.2022.
//

import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import FirebaseFirestore
import os.log

class FirestoreDatabaseService: FirestoreDB, Loggable {

    @Published var errorMessage: String?

    private let db = Firestore.firestore()
    static let shared = FirestoreDatabaseService()
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!, category: "FirestoreDatabaseService")

    // MARK: - Lifecycle
    private init() {
        // Firestore settings (cache, etc.) are configured once in
        // `AppDelegate.configureFirebase()` right after `FirebaseApp.configure()`.
        // Assigning `db.settings` here would crash with `FIRIllegalState` if the
        // default Firestore instance has already been used by listeners/services.
    }

    // MARK: - User-specific Operations

    private func getUserCollection(collection: String) -> CollectionReference? {
        guard let userId = Auth.auth().currentUser?.uid else {
            logger.error("No authenticated user found")
            return nil
        }
        return db.collection(FirebaseCollections.users).document(userId).collection(
            collection)
    }

    // MARK: - Generic CRUD Operations (async)

    func create<T: Encodable>(firModel: T, collection: String) async throws -> String {
        guard let userCollection = getUserCollection(collection: collection) else {
            throw NSError(
                domain: "NoUser", code: 0,
                userInfo: [NSLocalizedDescriptionKey: "No authenticated user found"])
        }
        let ref = try userCollection.addDocument(from: firModel)
        logger.info(
            "Created document \(collection) with id - \(String(describing: ref.documentID))")
        return ref.documentID
    }

    func fetchObjectById<T: Decodable>(
        ofType: T.Type, collection: String, id: String
    ) async throws -> T {
        guard let userCollection = getUserCollection(collection: collection) else {
            throw NSError(
                domain: "NoUser", code: 0,
                userInfo: [NSLocalizedDescriptionKey: "No authenticated user found"])
        }

        guard !id.isEmpty else {
            logger.error("fetchObjectById called with empty ID for collection: \(collection)")
            throw NSError(
                domain: "InvalidID", code: 0,
                userInfo: [NSLocalizedDescriptionKey: "Document ID cannot be empty"])
        }

        let document = try await userCollection.document(id).getDocument()
        do {
            return try document.data(as: T.self)
        } catch {
            logger.error("Error decoding document: \(error.localizedDescription)")
            throw error
        }
    }

    func read<T: Decodable>(
        collection: String, firModel: T.Type
    ) async throws -> [(documentId: String, T)] {
        guard let userCollection = getUserCollection(collection: collection) else {
            throw NSError(
                domain: "NoUser", code: 0,
                userInfo: [NSLocalizedDescriptionKey: "No authenticated user found"])
        }

        let querySnapshot = try await userCollection.getDocuments()
        return querySnapshot.documents.compactMap { document in
            do {
                let data = try document.data(as: T.self)
                return (document.documentID, data)
            } catch {
                self.errorMessage = error.localizedDescription
                self.logger.error(
                    "Error decoding document in collection \(collection): \(error.localizedDescription)"
                )
                return nil
            }
        }
    }

    func readWhere<T: Decodable>(
        collection: String,
        firModel: T.Type,
        equalTo filters: [String: Any] = [:],
        orderedBy orderField: String? = nil,
        startAt startDate: Date? = nil,
        endAt endDate: Date? = nil
    ) async throws -> [(documentId: String, T)] {
        guard let userCollection = getUserCollection(collection: collection) else {
            throw NSError(
                domain: "NoUser", code: 0,
                userInfo: [NSLocalizedDescriptionKey: "No authenticated user found"])
        }

        var query: Query = userCollection

        for (field, value) in filters {
            query = query.whereField(field, isEqualTo: value)
        }

        if let orderField {
            query = query.order(by: orderField)
        }

        if let startDate, let orderField {
            query = query.whereField(orderField, isGreaterThanOrEqualTo: startDate)
        }

        if let endDate, let orderField {
            query = query.whereField(orderField, isLessThanOrEqualTo: endDate)
        }

        let querySnapshot = try await query.getDocuments()
        return querySnapshot.documents.compactMap { document in
            do {
                let data = try document.data(as: T.self)
                return (document.documentID, data)
            } catch {
                self.errorMessage = error.localizedDescription
                self.logger.error(
                    "Error decoding filtered document in collection \(collection): \(error.localizedDescription)"
                )
                return nil
            }
        }
    }

    func readDocumentIdRange<T: Decodable>(
        collection: String, firModel: T.Type, startId: String, endId: String
    ) async throws -> [(documentId: String, T)] {
        guard let userCollection = getUserCollection(collection: collection) else {
            throw NSError(
                domain: "NoUser", code: 0,
                userInfo: [NSLocalizedDescriptionKey: "No authenticated user found"])
        }

        let lowerBound = min(startId, endId)
        let upperBound = max(startId, endId)

        let query =
            userCollection
            .order(by: FieldPath.documentID())
            .start(at: [lowerBound])
            .end(at: [upperBound])

        let querySnapshot = try await query.getDocuments()
        return querySnapshot.documents.compactMap { document in
            do {
                let data = try document.data(as: T.self)
                return (document.documentID, data)
            } catch {
                self.errorMessage = error.localizedDescription
                self.logger.error(
                    "Error decoding documentId range document in collection \(collection): \(error.localizedDescription)"
                )
                return nil
            }
        }
    }

    func update<T: Encodable>(
        firModel: T, collection: String, documentId: String
    ) async throws {
        guard let userCollection = getUserCollection(collection: collection) else {
            throw NSError(
                domain: "NoUser", code: 0,
                userInfo: [NSLocalizedDescriptionKey: "No authenticated user found"])
        }
        try userCollection.document(documentId).setData(from: firModel)
        logger.info("Document with ID \(documentId) updated successfully")
    }

    func delete(collection: String, documentId: String) async throws {
        guard let userCollection = getUserCollection(collection: collection) else {
            throw NSError(
                domain: "NoUser", code: 0,
                userInfo: [NSLocalizedDescriptionKey: "No authenticated user found"])
        }
        try await userCollection.document(documentId).delete()
        logger.info("Document with ID \(documentId) deleted successfully")
    }

    func deleteDocuments(collection: String, ids: [String]) async throws {
        guard let userCollection = getUserCollection(collection: collection) else {
            throw NSError(
                domain: "NoUser", code: 0,
                userInfo: [NSLocalizedDescriptionKey: "No authenticated user found"])
        }

        guard !ids.isEmpty else { return }

        let batchSize = 500
        let chunks = ids.chunked(into: batchSize)

        for chunk in chunks {
            let batch = db.batch()
            for id in chunk {
                let ref = userCollection.document(id)
                batch.deleteDocument(ref)
            }
            try await batch.commit()
        }
    }

    // MARK: - Collection-specific Operations (async)

    func createProduct(product: FIRProductsPriceModel) async throws -> Bool {
        _ = try await create(firModel: product, collection: FirebaseCollections.productsPrice)
        return true
    }

    func readProducts() async throws -> [(documentId: String, FIRProductsPriceModel)] {
        try await read(
            collection: FirebaseCollections.productsPrice,
            firModel: FIRProductsPriceModel.self)
    }

    func createType(type: FIRTypeModel) async throws -> Bool {
        _ = try await create(firModel: type, collection: FirebaseCollections.types)
        return true
    }

    func readTypes() async throws -> [(documentId: String, FIRTypeModel)] {
        try await read(collection: FirebaseCollections.types, firModel: FIRTypeModel.self)
    }

    func createOrdersOfProducts(order: FIRProductModel) async throws -> Bool {
        _ = try await create(firModel: order, collection: FirebaseCollections.productOfOrders)
        return true
    }

    func readOrdersOfProducts() async throws -> [(documentId: String, FIRProductModel)] {
        try await read(
            collection: FirebaseCollections.productOfOrders, firModel: FIRProductModel.self)
    }

    func createOrder(order: FIROrderModel) async throws -> String {
        try await create(firModel: order, collection: FirebaseCollections.orders)
    }

    func readOrder() async throws -> [(documentId: String, FIROrderModel)] {
        try await read(collection: FirebaseCollections.orders, firModel: FIROrderModel.self)
    }

    // MARK: - Delete All Data

    private func deleteCollection(collection: String, batchSize: Int = 400) async throws {
        guard let userCollection = getUserCollection(collection: collection) else {
            return
        }

        while true {
            let querySnapshot = try await userCollection.limit(to: batchSize).getDocuments()
            let documents = querySnapshot.documents

            guard !documents.isEmpty else { break }

            let batch = db.batch()
            for document in documents {
                batch.deleteDocument(document.reference)
            }
            try await batch.commit()
        }
    }

    func deleteAllData() async -> Bool {
        let collections = [
            FirebaseCollections.productsPrice,
            FirebaseCollections.types,
            FirebaseCollections.orders,
            FirebaseCollections.productOfOrders,
            FirebaseCollections.journalEntries,
            FirebaseCollections.dailyBalances,
            FirebaseCollections.inventoryAdjustments,
            FirebaseCollections.opexExpenses,
            FirebaseCollections.ingredients,
            FirebaseCollections.purchases,
            FirebaseCollections.productCategories,
            FirebaseCollections.costs,
            FirebaseCollections.technicians,
            FirebaseCollections.admins,
        ]

        var overallSuccess = true

        for collection in collections {
            do {
                try await deleteCollection(collection: collection)
                logger.info("Documents deleted successfully from collection \(collection)")
            } catch {
                logger.error(
                    "Error deleting documents from collection \(collection): \(error.localizedDescription)"
                )
                overallSuccess = false
            }
        }

        logger.info("All data deletion completed from Firestore")
        return overallSuccess
    }

    func deleteUserAndRoles() async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(
                domain: "NoUser", code: 0,
                userInfo: [NSLocalizedDescriptionKey: "No authenticated user found"])
        }

        let success = await deleteAllData()
        guard success else {
            throw NSError(
                domain: "DeleteDataError", code: 0,
                userInfo: [NSLocalizedDescriptionKey: "Failed to delete user data"])
        }

        try await deleteRoles(userId: userId)

        try await db.collection(FirebaseCollections.users).document(userId).delete()
    }

    private func deleteRoles(userId: String) async throws {
        let snapshot = try await db.collection(FirebaseCollections.roles).whereField(
            FirebaseFields.userRef, isEqualTo: userId
        ).getDocuments()

        let batch = db.batch()
        snapshot.documents.forEach { batch.deleteDocument($0.reference) }
        try await batch.commit()
    }

    static func getRoles(_ email: String) async -> [RoleConfig]? {
        do {
            let querySnapshot = try await FirestoreDatabaseService.shared.db
                .collection(FirebaseCollections.roles)
                .whereField(FirebaseFields.email, isEqualTo: email.trimmed.lowercased())
                .getDocuments()
            return querySnapshot.documents.compactMap { RoleConfig($0.data()) }
        } catch {
            Self.shared.logger.error("Error getting roles: \(error.localizedDescription)")
            return nil
        }
    }

    static func getEmployeeRoles(_ email: String) async -> [RoleConfig]? {
        do {
            let querySnapshot = try await FirestoreDatabaseService.shared.db
                .collection(FirebaseCollections.roles)
                .whereField(FirebaseFields.email, isEqualTo: email.trimmed.lowercased())
                .getDocuments()
            return querySnapshot.documents.compactMap { RoleConfig($0.data()) }
                .filter { $0.dataRef == UserSession.current.masterUserRef }
        } catch {
            Self.shared.logger.error("Error getting tech roles: \(error.localizedDescription)")
            return nil
        }
    }

    func checkData(_ key: String?) async -> Bool {
        guard let key = key else { return false }
        do {
            let document = try await FirestoreDatabaseService.shared.db
                .collection(FirebaseCollections.users).document(key).getDocument()
            return document.exists
        } catch {
            logger.error("Error checking data: \(error.localizedDescription)")
            return false
        }
    }

    func createNewCafe(_ id: String, _ email: String) async throws -> RoleConfig {
        guard let userKey = Auth.auth().currentUser?.uid else {
            let error = NSError(
                domain: "Auth", code: 401,
                userInfo: [NSLocalizedDescriptionKey: "No authenticated user found"])
            logger.error("\(error.localizedDescription)")
            throw error
        }

        guard let userData = userData(userKey, id, email) else {
            throw NSError(
                domain: "UserData", code: 500,
                userInfo: [NSLocalizedDescriptionKey: "Failed to generate user data"])
        }

        let roleKey = db.collection(FirebaseCollections.roles).document().documentID
        let role = RoleConfig(
            ref: roleKey, email: email, dataRef: userKey, userRef: userKey,
            role: Role.administrator,
            onlineVersion: true)

        let roles = [role]

        let batch = db.batch()

        let userRef = db.collection(FirebaseCollections.users).document(userKey)
        batch.setData(userData, forDocument: userRef)

        roles.forEach { role in
            let roleRef = FirestoreDatabaseService.shared.db.collection(FirebaseCollections.roles)
                .document(
                    role.firebaseRef)
            var roleData = role.forDatabase()
            roleData[FirebaseFields.userRef] = userKey
            batch.setData(roleData, forDocument: roleRef)
        }

        try await batch.commit()
        return role
    }

    func createNewUser(_ roles: [RoleConfig], _ id: String, _ email: String) async throws {
        let userKey = FirestoreDatabaseService.shared.db.collection(FirebaseCollections.users)
            .document().documentID

        guard let userData = userData(userKey, id, email) else {
            throw NSError(
                domain: "UserData", code: 500,
                userInfo: [NSLocalizedDescriptionKey: "Failed to generate user data"])
        }

        let batch = FirestoreDatabaseService.shared.db.batch()

        let userRef = FirestoreDatabaseService.shared.db.collection(FirebaseCollections.users)
            .document(
                userKey)
        batch.setData(userData, forDocument: userRef)

        roles.forEach { role in
            let roleRef = FirestoreDatabaseService.shared.db.collection(FirebaseCollections.roles)
                .document(
                    role.firebaseRef)
            var roleData = role.forDatabase()
            roleData[FirebaseFields.userRef] = userKey
            batch.setData(roleData, forDocument: roleRef)
        }

        try await batch.commit()
    }

    private func userData(_ userKey: String, _ id: String, _ email: String) -> [String: Any]? {

        var userValue: [String: Any] = [
            FirebaseFields.uid: id,
            FirebaseFields.firebaseRef: userKey,
            FirebaseFields.createdDate: Date().interval,
            FirebaseFields.updatedDate: Date().interval,
            FirebaseFields.firstName: DefaultValues.adminFirstName,
            FirebaseFields.middleName: "",
            FirebaseFields.lastName: "",
            FirebaseFields.email: email.trimmed.lowercased(),
            FirebaseFields.phone: "",
            FirebaseFields.address: "",
            FirebaseFields.comment: "",
            FirebaseFields.avatarUrl: "",
            FirebaseFields.avatarThumbnailUrl: "",
        ]

        let isUkrainian: Bool
        if #available(iOS 16.0, *) {
            isUkrainian = Locale.current.language.languageCode?.identifier == "uk"
        } else {
            isUkrainian = Locale.current.languageCode == "uk"
        }
        let defaultCurrencyName =
            isUkrainian ? DefaultValues.currencyName : DefaultValues.dollarName
        let defaultCurrencySymbol =
            isUkrainian ? DefaultValues.currencySymbol : DefaultValues.dollarSymbol
        userValue["Settings"] = Settings(
            currencyName: defaultCurrencyName, currencySymbol: defaultCurrencySymbol
        ).forDatabase()

        return userValue
    }

    static func updateAdmin(_ item: Admin) async -> Bool {
        guard let masterRef = UserSession.current.masterUserRef else {
            logger.error("updateAdmin: masterUserRef is nil")
            return false
        }

        let db = Firestore.firestore()
        let mainRef = db.collection(Refs.users.rawValue).document(masterRef)

        // Admin fields are stored as subcollections under Users/{masterRef}/{field}
        // each containing a single document with a "value" field.
        let fields: [String: String] = [
            FirebaseFields.email: item.email,
            FirebaseFields.firstName: item.firstName,
            FirebaseFields.lastName: item.lastName ?? "",
            FirebaseFields.middleName: item.middleName ?? "",
            FirebaseFields.phone: item.phone ?? "",
            FirebaseFields.address: item.address ?? "",
            FirebaseFields.comment: item.comment ?? "",
            FirebaseFields.avatarUrl: item.avatarUrl ?? "",
            FirebaseFields.avatarThumbnailUrl: item.avatarThumbnailUrl ?? "",
        ]

        let batch = db.batch()

        for (field, value) in fields {
            let collectionRef = mainRef.collection(field)
            do {
                let snapshot = try await collectionRef.getDocuments()
                if let doc = snapshot.documents.first {
                    batch.updateData(
                        [FirebaseFields.value: value], forDocument: doc.reference)
                } else {
                    batch.setData(
                        [FirebaseFields.value: value],
                        forDocument: collectionRef.document())
                }
            } catch {
                logger.error("updateAdmin: failed to read \(field): \(error.localizedDescription)")
                return false
            }
        }

        do {
            try await batch.commit()
            return true
        } catch {
            logger.error("updateAdmin: batch commit failed: \(error.localizedDescription)")
            return false
        }
    }

    static func deleteEmployee(_ item: Employee) async -> Bool {
        let roles = await getEmployeeRoles(item.email.trimmed.lowercased())
        let batch = Firestore.firestore().batch()

        roles?.forEach { role in
            let roleRef = Firestore.firestore().collection(FirebaseCollections.roles).document(
                role.firebaseRef)
            batch.deleteDocument(roleRef)
        }

        let userRef = Firestore.firestore().collection(FirebaseCollections.users)
            .document(UserSession.current.masterUserRef)
            .collection(item.ref.rawValue)
            .document(item.firebaseRef)

        batch.updateData([FirebaseFields.enabled: false], forDocument: userRef)

        do {
            try await batch.commit()
            return true
        } catch {
            return false
        }
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
