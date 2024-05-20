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
    
    func readDocument<T: Codable>(collection: String, documentId: String) -> T? {
        guard let userCollection = getUserCollection(collection: collection) else {
            return nil
        }
        var result: T? = nil
        
        let docRef = userCollection.document(documentId)
        
        docRef.getDocument { document, error in
            if let error = error as NSError? {
                self.errorMessage = "Error getting document: \(error.localizedDescription)"
            } else {
                if let document = document {
                    do {
                        result = try document.data(as: T.self)
                    } catch let error {
                        self.errorMessage = error.localizedDescription
                    }
                }
            }
        }
        
        return result
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
                        print(error.localizedDescription)
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
    
    func createProduct(product: FIRGoodsPriceModel) -> String? {
        return create(firModel: product, collection: "goodsPrice")
    }
    
    func readProducts(completion: @escaping ([(documentId: String, FIRGoodsPriceModel)]) -> Void) {
        read(collection: "goodsPrice", firModel: FIRGoodsPriceModel.self) { result in
            completion(result)
        }
    }
    
    // MARK: - CRUD Operations for Income Types
    
    func createIncomeType(incomeType: FIRIncomeTypeModel) -> String? {
        return create(firModel: incomeType, collection: "incomeTypes")
    }
    
    func readIncomeTypes(completion: @escaping ([(documentId: String, FIRIncomeTypeModel)]) -> Void) {
        read(collection: "incomeTypes", firModel: FIRIncomeTypeModel.self) { result in
            completion(result)
        }
    }
    
    // MARK: - CRUD Operations for Purchases
    
    func createPurchase(purchase: FIRPurchaseModel) -> String? {
        return create(firModel: purchase, collection: "purchases")
    }
    
    func readPurchases(completion: @escaping ([(documentId: String, FIRPurchaseModel)]) -> Void) {
        read(collection: "purchases", firModel: FIRPurchaseModel.self) { result in
            completion(result)
        }
    }
    
    // MARK: - CRUD Operations for Sales
    
    func createSale(sale: FIRSaleGoodModel, completion: @escaping (Bool) -> Void) {
        let documentId = create(firModel: sale, collection: "sales")
        completion(documentId != nil)
    }
    
    func readSales(completion: @escaping ([(documentId: String, FIRSaleGoodModel)]) -> Void) {
        read(collection: "sales", firModel: FIRSaleGoodModel.self) { result in
            completion(result)
        }
    }
    
    // MARK: - CRUD Operations for Daily Sales
    
    func createDailySale(dailySale: FIRDailySalesModel, completion: @escaping (Bool) -> Void) {
        let documentId = create(firModel: dailySale, collection: "dailySales")
        completion(documentId != nil)
    }
    
    func readDailySales(completion: @escaping ([(documentId: String, FIRDailySalesModel)]) -> Void) {
        read(collection: "dailySales", firModel: FIRDailySalesModel.self) { result in
            completion(result)
        }
    }
    
    
    
    func deleteAllData(completion: @escaping () -> Void) {
        // Масив назв колекцій, з яких потрібно видалити дані
        let collections = ["goodsPrice", "incomeTypes", "purchases", "sales", "dailySales"]
        
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
