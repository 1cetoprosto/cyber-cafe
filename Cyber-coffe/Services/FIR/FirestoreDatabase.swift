//
//  FirestoreDatabase.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 01.06.2022.
//

import FirebaseCore
import FirebaseFirestore
import FirebaseFirestoreSwift

class FirestoreDatabase: ObservableObject {
    @Published var saleGood: FIRSaleGoodModel = .empty
    @Published var errorMessage: String?
    
    private let firebaseDb = Firestore.firestore()
    static let shared = FirestoreDatabase()
    
    // MARK: - Lifecycle
    private init() {}
}

extension FirestoreDatabase: FirestoreDB {
  
    func create<T: Encodable>(firModel: T, collection: String) -> String? {
        do {
            let ref = try firebaseDb.collection(collection).addDocument(from: firModel)
            print("Add document succeded with id = \(ref.documentID)")
            return ref.documentID //saleGoodItem.id
        } catch let error {
            print("Add document failed: \(error.localizedDescription)")
            return nil
        }
    }
    
//    func readSaleGood(collection: String, documentId: String) -> FIRSaleGood? {
//        let docRef = firebaseDb.collection(collection).document(documentId)
//        
//        docRef.getDocument(as: FIRSaleGood.self) { result in
//            switch result {
//            case .success(let saleGood):
//                // A Book value was successfully initialized from the DocumentSnapshot.
//                self.saleGood = saleGood
//                self.errorMessage = nil
//            case .failure(let error):
//                // A Book value could not be initialized from the DocumentSnapshot.
//                switch error {
//                case DecodingError.typeMismatch(_, let context):
//                    self.errorMessage = "\(error.localizedDescription): \(context.debugDescription)"
//                case DecodingError.valueNotFound(_, let context):
//                    self.errorMessage = "\(error.localizedDescription): \(context.debugDescription)"
//                case DecodingError.keyNotFound(_, let context):
//                    self.errorMessage = "\(error.localizedDescription): \(context.debugDescription)"
//                case DecodingError.dataCorrupted(let key):
//                    self.errorMessage = "\(error.localizedDescription): \(key)"
//                default:
//                    self.errorMessage = "Error decoding document: \(error.localizedDescription)"
//                }
//            }
//        }
//        return saleGood
//    }
    
    func update<T: Encodable>(firModel: T, collection: String, documentId: String) -> Bool {
        
        var result: Bool = false
        
        //if let id = firModel.id {
            let docRef = firebaseDb.collection(collection).document(documentId)
            do {
                try docRef.setData(from: firModel)
                result = true
            }
            catch {
                print("Document setData error: \(error.localizedDescription)")
            }
        //}
        return result
    }
    
    func delete(collection: String, documentId: String) -> Bool {
        
        var result: Bool = true
        
        let docRef = firebaseDb.collection(collection).document(documentId)
    
        docRef.delete { error in
            if let error = error {
                result = false
                print("Delete delete error: \(error.localizedDescription)")
            }
        }
        
        return result
    }
    
    
}
