//
//  FirestoreDatabase.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 01.06.2022.
//

import FirebaseCore
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseAuth

class FIRFirestoreService {
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    static let shared = FIRFirestoreService()
    
    // MARK: - Lifecycle
    private init() {}
    
    // MARK: - User-specific Operations
    
    private func getUserCollection() -> CollectionReference? {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("No authenticated user found")
            return nil
        }
        return db.collection("users").document(userId).collection("userData")
    }
    
    // MARK: - CRUD Operations
    
    func create<T: Encodable>(firModel: T, collection: String) -> String? {
        guard let userCollection = getUserCollection() else {
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
        guard let userCollection = getUserCollection() else {
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
        guard let userCollection = getUserCollection() else {
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
        guard let userCollection = getUserCollection() else {
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
        guard let userCollection = getUserCollection() else {
            return false
        }
        var result: Bool = true
        
        let docRef = userCollection.document(documentId)
        
        docRef.delete { error in
            if let error = error {
                result = false
                print("Delete delete error: \(error.localizedDescription)")
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
        
        func createSale(sale: FIRSaleGoodModel) -> String? {
            return create(firModel: sale, collection: "sales")
        }
        
        func readSales(completion: @escaping ([(documentId: String, FIRSaleGoodModel)]) -> Void) {
            read(collection: "sales", firModel: FIRSaleGoodModel.self) { result in
                completion(result)
            }
        }
        
        // MARK: - CRUD Operations for Daily Sales
        
        func createDailySale(dailySale: FIRDailySalesModel) -> String? {
            return create(firModel: dailySale, collection: "dailySales")
        }
        
        func readDailySales(completion: @escaping ([(documentId: String, FIRDailySalesModel)]) -> Void) {
            read(collection: "dailySales", firModel: FIRDailySalesModel.self) { result in
                completion(result)
            }
        }

}

//class FIRFirestoreService: ObservableObject {
//    @Published var errorMessage: String?
//    
//    private let db = Firestore.firestore()
//    static let shared = FIRFirestoreService()
//    
//    // MARK: - Lifecycle
//    private init() {}
//}
//
//extension FIRFirestoreService: FirestoreDB {
//    
//    func create<T: Encodable>(firModel: T, collection: String) -> String? {
//        do {
//            let ref = try db.collection(collection).addDocument(from: firModel)
//            print("Add document succeded with id = \(ref.documentID)")
//            return ref.documentID //saleGoodItem.id
//        } catch let error {
//            print("Add document failed: \(error.localizedDescription)")
//            return nil
//        }
//    }
//    
//    func readDocument<T: Codable>(collection: String, documentId: String) -> T? {
//        var result: T? = nil
//        
//        let docRef = db.collection(collection).document(documentId)
//        
//        docRef.getDocument { document, error in
//            if let error = error as NSError? {
//                self.errorMessage = "Error getting document: \(error.localizedDescription)"
//            }
//            else {
//                if let document = document {
//                    do {
//                        result = try document.data(as: T.self)
//                    }
//                    catch let error {
//                        self.errorMessage = error.localizedDescription
//                    }
//                }
//            }
//        }
//        
//        return result
//    }
//    
//    func read<T: Codable>(collection: String, firModel: T.Type, completion: @escaping ([(documentId: String, T)]) -> Void) {
//        var FIRModelArray: [(documentId: String, T)] = []
//
//        FIRFirestoreService.shared.db.collection(collection).getDocuments { querySnapshot, error in
//            if let error = error {
//                self.errorMessage = error.localizedDescription
//                print("Error getting documents: \(error.localizedDescription)")
//            } else {
//                for document in querySnapshot!.documents {
//                    do {
//                        
//                        let data = try document.data(as: T.self)
//                        FIRModelArray.append((document.documentID, data))
//                    }
//                    catch let error {
//                        self.errorMessage = error.localizedDescription
//                        print(error.localizedDescription)
//                    }
//                }
//            }
//            completion(FIRModelArray)
//        }
//    }
//    
//    func update<T: Encodable>(firModel: T, collection: String, documentId: String) -> Bool {
//        var result: Bool = false
//        
//            let docRef = db.collection(collection).document(documentId)
//            do {
//                try docRef.setData(from: firModel)
//                result = true
//            }
//            catch {
//                print("Document setData error: \(error.localizedDescription)")
//            }
//
//        return result
//    }
//    
//    func delete(collection: String, documentId: String) -> Bool {
//        var result: Bool = true
//        
//        let docRef = db.collection(collection).document(documentId)
//    
//        docRef.delete { error in
//            if let error = error {
//                result = false
//                print("Delete delete error: \(error.localizedDescription)")
//            }
//        }
//        
//        return result
//    }
//    
//}
