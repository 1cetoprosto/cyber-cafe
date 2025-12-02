//
//  FirestoreDatabaseService.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 01.06.2022.
//

import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import FirebaseFirestoreSwift
import os.log

class FirestoreDatabaseService: FirestoreDB, Loggable {

  @Published var errorMessage: String?

  private let db = Firestore.firestore()
  static let shared = FirestoreDatabaseService()
  private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier!, category: "FirestoreDatabaseService")

  // MARK: - Lifecycle
  private init() {}

  // MARK: - User-specific Operations

  private func getUserCollection(collection: String) -> CollectionReference? {
    guard let userId = Auth.auth().currentUser?.uid else {
      logger.error("No authenticated user found")
      return nil
    }
    return db.collection(FirebaseCollections.users).document(userId).collection(
      collection)
  }

  // MARK: - Generic CRUD Operations

  func create<T: Encodable>(
    firModel: T, collection: String, completion: @escaping (Result<String, Error>) -> Void
  ) {
    guard let userCollection = getUserCollection(collection: collection) else {
      completion(
        .failure(
          NSError(
            domain: "NoUser", code: 0,
            userInfo: [NSLocalizedDescriptionKey: "No authenticated user found"])))
      return
    }
    do {
      let ref = try userCollection.addDocument(from: firModel)
      logger.info("Created document \(collection) with id - \(String(describing: ref.documentID))")
      completion(.success(ref.documentID))
    } catch {
      logger.error(
        "Failed to save document \(collection) to Firestore with error: \(error.localizedDescription)"
      )
      completion(.failure(error))
    }
  }

  func fetchObjectById<T: Decodable>(
    ofType: T.Type, collection: String, id: String, completion: @escaping (Result<T, Error>) -> Void
  ) {
    guard let userCollection = getUserCollection(collection: collection) else {
      completion(
        .failure(
          NSError(
            domain: "NoUser", code: 0,
            userInfo: [NSLocalizedDescriptionKey: "No authenticated user found"])))
      return
    }
    userCollection.document(id).getDocument { [self] document, error in
      if let error = error {
        self.logger.error("Error getting document: \(error.localizedDescription)")
        completion(.failure(error))
      } else if let document = document {
        do {
          let result = try document.data(as: T.self)
          completion(.success(result))
        } catch {
          self.logger.error("Error decoding document: \(error.localizedDescription)")
          completion(.failure(error))
        }
      } else {
        self.logger.error("No document found with ID \(id)")
        completion(
          .failure(
            NSError(
              domain: "NoDocument", code: 0,
              userInfo: [NSLocalizedDescriptionKey: "No document found"])))
      }
    }
  }

  func read<T: Decodable>(
    collection: String, firModel: T.Type,
    completion: @escaping (Result<[(documentId: String, T)], Error>) -> Void
  ) {
    guard let userCollection = getUserCollection(collection: collection) else {
      completion(
        .failure(
          NSError(
            domain: "NoUser", code: 0,
            userInfo: [NSLocalizedDescriptionKey: "No authenticated user found"])))
      return
    }

    userCollection.getDocuments { [self] querySnapshot, error in
      if let error = error {
        self.logger.error("Error getting documents: \(error.localizedDescription)")
        completion(.failure(error))
      } else {
        let result: [(documentId: String, T)] =
          querySnapshot?.documents.compactMap { document in
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
          } ?? []
        completion(.success(result))
      }
    }
  }

  func update<T: Encodable>(
    firModel: T, collection: String, documentId: String,
    completion: @escaping (Result<Void, Error>) -> Void
  ) {
    guard let userCollection = getUserCollection(collection: collection) else {
      completion(
        .failure(
          NSError(
            domain: "NoUser", code: 0,
            userInfo: [NSLocalizedDescriptionKey: "No authenticated user found"])))
      return
    }
    do {
      try userCollection.document(documentId).setData(from: firModel)
      logger.info("Document with ID \(documentId) updated successfully")
      completion(.success(()))
    } catch {
      logger.error("Error updating document: \(error.localizedDescription)")
      completion(.failure(error))
    }
  }

  func delete(
    collection: String, documentId: String, completion: @escaping (Result<Void, Error>) -> Void
  ) {
    guard let userCollection = getUserCollection(collection: collection) else {
      completion(
        .failure(
          NSError(
            domain: "NoUser", code: 0,
            userInfo: [NSLocalizedDescriptionKey: "No authenticated user found"])))
      return
    }
    userCollection.document(documentId).delete { [self] error in
      if let error = error {
        self.logger.error("Error deleting document: \(error.localizedDescription)")
        completion(.failure(error))
      } else {
        self.logger.info("Document with ID \(documentId) deleted successfully")
        completion(.success(()))
      }
    }
  }

  // MARK: - CRUD Operations for Products

  func createProduct(
    product: FIRProductsPriceModel, completion: @escaping (Result<Bool, Error>) -> Void
  ) {
    create(firModel: product, collection: FirebaseCollections.productsPrice) { result in
      switch result {
      case .success(_):
        completion(.success(true))
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }

  func readProducts(
    completion: @escaping (Result<[(documentId: String, FIRProductsPriceModel)], Error>) -> Void
  ) {
    read(
      collection: FirebaseCollections.productsPrice, firModel: FIRProductsPriceModel.self,
      completion: completion)
  }

  // MARK: - CRUD Operations for Types

  func createType(type: FIRTypeModel, completion: @escaping (Result<Bool, Error>) -> Void) {
    create(firModel: type, collection: FirebaseCollections.types) { result in
      switch result {
      case .success(_):
        completion(.success(true))
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }

  func readTypes(
    completion: @escaping (Result<[(documentId: String, FIRTypeModel)], Error>) -> Void
  ) {
    read(
      collection: FirebaseCollections.types, firModel: FIRTypeModel.self,
      completion: completion)
  }

  // MARK: - CRUD Operations for Costs

  func createCost(cost: FIRCostModel, completion: @escaping (Result<Bool, Error>) -> Void) {
    create(firModel: cost, collection: FirebaseCollections.costs) { result in
      switch result {
      case .success(_):
        completion(.success(true))
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }

  func readCosts(
    completion: @escaping (Result<[(documentId: String, FIRCostModel)], Error>) -> Void
  ) {
    read(
      collection: FirebaseCollections.costs, firModel: FIRCostModel.self,
      completion: completion)
  }

  // MARK: - CRUD Operations for Orders

  func createOrdersOfProducts(
    order: FIRProductModel, completion: @escaping (Result<Bool, Error>) -> Void
  ) {
    create(firModel: order, collection: FirebaseCollections.productOfOrders) { result in
      switch result {
      case .success(_):
        completion(.success(true))
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }

  func readOrdersOfProducts(
    completion: @escaping (Result<[(documentId: String, FIRProductModel)], Error>) -> Void
  ) {
    read(
      collection: FirebaseCollections.productOfOrders, firModel: FIRProductModel.self,
      completion: completion)
  }

  // MARK: - CRUD Operations for Orders

  func createOrder(order: FIROrderModel, completion: @escaping (Result<String, Error>) -> Void) {
    create(
      firModel: order, collection: FirebaseCollections.orders, completion: completion)
  }

  func readOrder(
    completion: @escaping (Result<[(documentId: String, FIROrderModel)], Error>) -> Void
  ) {
    read(
      collection: FirebaseCollections.orders, firModel: FIROrderModel.self,
      completion: completion)
  }

  // MARK: - Delete All Data

  func deleteAllData(completion: @escaping (Bool) -> Void) {
    let collections = [
      FirebaseCollections.productsPrice, FirebaseCollections.types,
      FirebaseCollections.costs, FirebaseCollections.orders,
      FirebaseCollections.productOfOrders,
    ]
    let dispatchGroup = DispatchGroup()

    for collection in collections {
      dispatchGroup.enter()
      self.logger.info("dispatchGroup.enter \(collection)")
      guard let userCollection = getUserCollection(collection: collection) else {
        logger.error("No authenticated user found or collection \(collection) does not exist")
        dispatchGroup.leave()
        logger.info("dispatchGroup.leave \(collection)")
        continue
      }
      userCollection.getDocuments { [self] querySnapshot, error in
        if let error = error {
          self.logger.error(
            "Error deleting documents from collection \(collection): \(error.localizedDescription)")
        } else {
          for document in querySnapshot!.documents {
            document.reference.delete()
          }
          self.logger.info("Documents deleted successfully from collection \(collection)")
        }
        dispatchGroup.leave()
        self.logger.info("dispatchGroup.leave \(collection)")
      }
    }

    dispatchGroup.notify(queue: .main) {
      self.logger.info("All data deleted successfully from Firestore")
      completion(true)
    }
  }

  static func getRoles(_ email: String, completion: @escaping ([RoleConfig]?) -> Void) {
    FirestoreDatabaseService.shared.db.collection(FirebaseCollections.roles)
      //db.collection("roles")
      .whereField(FirebaseFields.email, isEqualTo: email.trimmed.lowercased())
      .getDocuments { (querySnapshot, error) in
        if let error = error {
          self.logger.error("Error getting documents: \(error)")
          completion(nil)
          return
        }
        guard let documents = querySnapshot?.documents else {
          completion(nil)
          return
        }
        let roles = documents.compactMap { RoleConfig($0.data()) }
        completion(roles)
      }
  }

  static func getTechRoles(_ email: String, completion: @escaping ([RoleConfig]?) -> Void) {
    FirestoreDatabaseService.shared.db.collection(FirebaseCollections.roles)
      //db.collection("roles")
      .whereField(FirebaseFields.email, isEqualTo: email.trimmed.lowercased())
      .getDocuments { (querySnapshot, error) in
        if let error = error {
          self.logger.error("Error getting documents: \(error)")
          completion(nil)
          return
        }
        guard let documents = querySnapshot?.documents else {
          completion(nil)
          return
        }
        let roles = documents.compactMap { RoleConfig($0.data()) }
          .filter { $0.dataRef == UserSession.current.masterUserRef }
        completion(roles)
      }
  }

  func checkData(_ key: String?, completion: @escaping (Bool) -> Void) {
    guard let key = key else {
      completion(false)
      return
    }
    // Створюємо посилання на документ в Firestore
    FirestoreDatabaseService.shared.db.collection(FirebaseCollections.users).document(key)
      .getDocument {
        (document, error) in
        if let error = error {
          self.logger.error("Error getting document: \(error)")
          completion(false)
          return
        }
        // Перевіряємо, чи існує документ
        completion(document?.exists ?? false)
      }
  }

  func createNewCafe(
    _ id: String, _ email: String, _ completion: @escaping (RoleConfig?, Bool) -> Void
  ) {
    // Створення унікального ідентифікатора для користувача
    //let userKey = db.collection("users").document().documentID
    guard let userKey = Auth.auth().currentUser?.uid else {
      logger.error("No authenticated user found")
      completion(nil, false)
      return
    }

    // Створення даних користувача
    guard let userData = userData(userKey, id, email) else {
      completion(nil, false)
      return
    }

    // Створення даних ролі
    let roleKey = db.collection(FirebaseCollections.roles).document().documentID
    let role = RoleConfig(
      ref: roleKey, email: email, dataRef: userKey, userRef: userKey, role: Role.administrator,
      onlineVersion: true)

    let roles = [role]  // Створюємо масив з однією роллю

    // Використання транзакції для одночасного створення документів у колекціях `users` та `roles`
    let batch = db.batch()

    let userRef = db.collection(FirebaseCollections.users).document(userKey)
    batch.setData(userData, forDocument: userRef)

    // Додавання ролей до колекції `roles`
    roles.forEach { role in
      let roleRef = FirestoreDatabaseService.shared.db.collection(FirebaseCollections.roles)
        .document(
          role.firebaseRef)
      var roleData = role.forDatabase()
      roleData[FirebaseFields.userRef] = userKey
      batch.setData(roleData, forDocument: roleRef)
    }

    // Коміт транзакції
    batch.commit { error in
      completion(role, error == nil)
    }
  }

  func createNewUser(
    _ roles: [RoleConfig], _ id: String, _ email: String, _ completion: @escaping (Bool) -> Void
  ) {
    // Створення унікального ідентифікатора для користувача
    let userKey = FirestoreDatabaseService.shared.db.collection(FirebaseCollections.users)
      .document().documentID

    // Створення даних користувача
    guard let userData = userData(userKey, id, email) else {
      completion(false)
      return
    }

    // Використання транзакції для одночасного створення документів у колекціях `users` та `roles`
    let batch = FirestoreDatabaseService.shared.db.batch()

    // Додавання користувача до колекції `users`
    let userRef = FirestoreDatabaseService.shared.db.collection(FirebaseCollections.users).document(
      userKey)
    batch.setData(userData, forDocument: userRef)

    // Додавання ролей до колекції `roles`
    roles.forEach { role in
      let roleRef = FirestoreDatabaseService.shared.db.collection(FirebaseCollections.roles)
        .document(
          role.firebaseRef)
      var roleData = role.forDatabase()
      roleData[FirebaseFields.userRef] = userKey
      batch.setData(roleData, forDocument: roleRef)
    }

    // Коміт транзакції
    batch.commit { error in
      completion(error == nil)
    }
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

    let isUkrainian = Locale.current.languageCode == "uk"
    let defaultCurrencyName = isUkrainian ? DefaultValues.currencyName : DefaultValues.dollarName
    let defaultCurrencySymbol = isUkrainian ? DefaultValues.currencySymbol : DefaultValues.dollarSymbol
    userValue["Settings"] = Settings(
      currencyName: defaultCurrencyName, currencySymbol: defaultCurrencySymbol
    ).forDatabase()

    return userValue
  }

  static func updateAdmin(_ item: Admin, completion: @escaping (Bool) -> Void) {
    let db = Firestore.firestore()
    let adminRef = db.collection(FirebaseCollections.admins).document(item.firebaseRef)  // assuming `item.firebaseRef` is the document ID

    adminRef.updateData(item.forDatabase()) { error in
      completion(error == nil)
    }
  }

  static func deleteTechnician(_ item: Technician, completion: @escaping (Bool) -> Void) {
    getTechRoles(item.email.trimmed.lowercased()) { (roles) in
      var batch = Firestore.firestore().batch()

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

      batch.commit { error in
        completion(error == nil)
      }
    }
  }
}
