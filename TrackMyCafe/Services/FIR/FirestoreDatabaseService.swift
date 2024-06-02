//
//  FirestoreDatabaseService.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 01.06.2022.
//

import FirebaseCore
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseAuth

class FirestoreDatabaseService: FirestoreDB {
    
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    static let shared = FirestoreDatabaseService()
    
    // MARK: - Lifecycle
    private init() {}
    
    // MARK: - User-specific Operations
    
    private func getUserCollection(collection: String) -> CollectionReference? {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("No authenticated user found")
            return nil
        }
        return db.collection("users").document(userId).collection(collection)
    }
    
    // MARK: - CRUD Operations
    
    func create<T: Encodable>(firModel: T, collection: String) -> String? {
        guard let userCollection = getUserCollection(collection: collection) else {
            return nil
        }
        do {
            let ref = try userCollection.addDocument(from: firModel)
            print("Add document succeeded with id = \(ref.documentID)")
            return ref.documentID
        } catch let error {
            print("Add document failed: \(error.localizedDescription)")
            return nil
        }
    }
    
    func fetchObjectById<T: Codable>(ofType: T.Type, collection: String, id: String, completion: @escaping (T?) -> Void) {
        guard let userCollection = getUserCollection(collection: collection) else {
            completion(nil)
            return
        }

        let docRef = userCollection.document(id)
        docRef.getDocument { document, error in
            if let error = error as NSError? {
                self.errorMessage = "Error getting document: \(error.localizedDescription)"
                completion(nil)
            } else {
                if let document = document {
                    do {
                        let result = try document.data(as: T.self)
                        completion(result)
                    } catch let error {
                        self.errorMessage = error.localizedDescription
                        completion(nil)
                    }
                } else {
                    completion(nil)
                }
            }
        }
    }
    
    func read<T: Codable>(collection: String, firModel: T.Type, completion: @escaping ([(documentId: String, T)]) -> Void) {
        guard let userCollection = getUserCollection(collection: collection) else {
            return
        }
        var FIRModelArray: [(documentId: String, T)] = []
        
        userCollection.getDocuments { querySnapshot, error in
            if let error = error {
                self.errorMessage = error.localizedDescription
                print("Error getting documents: \(error.localizedDescription)")
            } else {
                for document in querySnapshot!.documents {
                    do {
                        let data = try document.data(as: T.self)
                        FIRModelArray.append((document.documentID, data))
                    } catch let error {
                        self.errorMessage = error.localizedDescription
                        print("Помилка читання колекції \(collection): \(error.localizedDescription)")
                    }
                }
            }
            completion(FIRModelArray)
        }
    }
    
    func update<T: Encodable>(firModel: T, collection: String, documentId: String) -> Bool {
        guard let userCollection = getUserCollection(collection: collection) else {
            return false
        }
        var result: Bool = false
        
        let docRef = userCollection.document(documentId)
        do {
            try docRef.setData(from: firModel)
            result = true
        } catch {
            print("Document setData error: \(error.localizedDescription)")
        }
        
        return result
    }
    
    func delete(collection: String, documentId: String) -> Bool {
        guard let userCollection = getUserCollection(collection: collection) else {
            return false
        }
        var result: Bool = true
        
        let docRef = userCollection.document(documentId)
        
        docRef.delete { error in
            if let error = error {
                result = false
                print("Delete error: \(error.localizedDescription)")
            }
        }
        
        return result
    }
    
    // MARK: - CRUD Operations for Products
    
    func createProduct(product: FIRProductsPriceModel, completion: @escaping (Bool) -> Void) {
        let documentId =  create(firModel: product, collection: "productsPrice")
        completion(documentId != nil)
    }
    
    func readProducts(completion: @escaping ([(documentId: String, FIRProductsPriceModel)]) -> Void) {
        read(collection: "productsPrice", firModel: FIRProductsPriceModel.self) { result in
            completion(result)
        }
    }
    
    // MARK: - CRUD Operations for Types
    
    func createType(type: FIRTypeModel, completion: @escaping (Bool) -> Void) {
        let documentId = create(firModel: type, collection: "types")
        completion(documentId != nil)
    }
    
    func readTypes(completion: @escaping ([(documentId: String, FIRTypeModel)]) -> Void) {
        read(collection: "types", firModel: FIRTypeModel.self) { result in
            completion(result)
        }
    }
    
    // MARK: - CRUD Operations for Costs
    
    func createCost(cost: FIRCostModel, completion: @escaping (Bool) -> Void) {
        let documentId =  create(firModel: cost, collection: "costs")
        completion(documentId != nil)
    }
    
    func readCosts(completion: @escaping ([(documentId: String, FIRCostModel)]) -> Void) {
        read(collection: "costs", firModel: FIRCostModel.self) { result in
            completion(result)
        }
    }
    
    // MARK: - CRUD Operations for Orders
    
    func createOrdersOfProducts(order: FIRProductModel, completion: @escaping (Bool) -> Void) {
        let documentId = create(firModel: order, collection: "orders")
        completion(documentId != nil)
    }
    
    func readOrdersOfProducts(completion: @escaping ([(documentId: String, FIRProductModel)]) -> Void) {
        read(collection: "orders", firModel: FIRProductModel.self) { result in
            completion(result)
        }
    }
    
    // MARK: - CRUD Operations for Orders
    
    func createOrder(order: FIROrderModel, completion: @escaping (String?) -> Void) {
        let documentId = create(firModel: order, collection: "orders")
        completion(documentId)
    }
    
    func readOrder(completion: @escaping ([(documentId: String, FIROrderModel)]) -> Void) {
        read(collection: "orders", firModel: FIROrderModel.self) { result in
            completion(result)
        }
    }
    
    func deleteAllData(completion: @escaping () -> Void) {
        // Масив назв колекцій, з яких потрібно видалити дані
        let collections = ["productsPrice", "types", "costs", "orders", "products"]
        
        // Створюємо диспетчерну групу для відслідковування завершення всіх видалень
        let dispatchGroup = DispatchGroup()
        
        // Для кожної колекції виконуємо видалення
        for collection in collections {
            // Входимо до диспетчерної групи
            dispatchGroup.enter()
            
            // Отримуємо посилання на колекцію
            guard let userCollection = getUserCollection(collection: collection) else {
                print("No authenticated user found or collection does not exist")
                dispatchGroup.leave()
                continue
            }
            
            // Отримуємо всі документи з колекції та видаляємо їх
            userCollection.getDocuments { querySnapshot, error in
                if let error = error {
                    print("Error deleting documents from collection \(collection): \(error.localizedDescription)")
                } else {
                    for document in querySnapshot!.documents {
                        document.reference.delete()
                    }
                    print("Documents deleted successfully from collection \(collection)")
                }
                
                // Поки що документи видаляються асинхронно, тому виходимо з диспетчерної групи тільки після видалення всіх документів з усіх колекцій
                dispatchGroup.leave()
            }
        }
        
        // Викликаємо completion handler після завершення всіх операцій видалення
        dispatchGroup.notify(queue: .main) {
            print("All data deleted successfully from Firestore")
            completion()
        }
    }
}
