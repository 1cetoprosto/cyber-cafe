//
//  FirestoreDatabase.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 01.06.2022.
//

import FirebaseCore
import FirebaseFirestore
import FirebaseFirestoreSwift

class FIRFirestoreService: ObservableObject {
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    static let shared = FIRFirestoreService()
    
    // MARK: - Lifecycle
    private init() {}
}

extension FIRFirestoreService: FirestoreDB {
    
    func create<T: Encodable>(firModel: T, collection: String) -> String? {
        do {
            let ref = try db.collection(collection).addDocument(from: firModel)
            print("Add document succeded with id = \(ref.documentID)")
            return ref.documentID //saleGoodItem.id
        } catch let error {
            print("Add document failed: \(error.localizedDescription)")
            return nil
        }
    }
    
    func readDocument<T: Codable>(collection: String, documentId: String) -> T? {
        var result: T? = nil
        
        let docRef = db.collection(collection).document(documentId)
        
        docRef.getDocument { document, error in
            if let error = error as NSError? {
                self.errorMessage = "Error getting document: \(error.localizedDescription)"
            }
            else {
                if let document = document {
                    do {
                        result = try document.data(as: T.self)
                    }
                    catch let error {
                        self.errorMessage = error.localizedDescription
                    }
                }
            }
        }
        
        return result
    }
    
    func read<T: Codable>(collection: String, firModel: T.Type, completion: @escaping ([(documentId: String, T)]) -> Void) {
        var FIRModelArray: [(documentId: String, T)] = []

        FIRFirestoreService.shared.db.collection(collection).getDocuments { querySnapshot, error in
            if let error = error {
                self.errorMessage = error.localizedDescription
                print("Error getting documents: \(error.localizedDescription)")
            } else {
                for document in querySnapshot!.documents {
                    do {
                        
                        let data = try document.data(as: T.self)
                        FIRModelArray.append((document.documentID, data))
                    }
                    catch let error {
                        self.errorMessage = error.localizedDescription
                        print(error.localizedDescription)
                    }
                }
            }
            completion(FIRModelArray)
        }
    }
    
    func update<T: Encodable>(firModel: T, collection: String, documentId: String) -> Bool {
        var result: Bool = false
        
            let docRef = db.collection(collection).document(documentId)
            do {
                try docRef.setData(from: firModel)
                result = true
            }
            catch {
                print("Document setData error: \(error.localizedDescription)")
            }

        return result
    }
    
    func delete(collection: String, documentId: String) -> Bool {
        var result: Bool = true
        
        let docRef = db.collection(collection).document(documentId)
    
        docRef.delete { error in
            if let error = error {
                result = false
                print("Delete delete error: \(error.localizedDescription)")
            }
        }
        
        return result
    }
    
}
