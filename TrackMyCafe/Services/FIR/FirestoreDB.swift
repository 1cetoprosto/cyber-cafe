//
//  FirestoreDB.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 01.06.2022.
//

import Foundation

protocol FirestoreDB {
    func create<T: Encodable>(firModel: T, collection: String) -> String?
    func read<T: Codable>(collection: String, firModel: T.Type, completion: @escaping ([(documentId: String, T)]) -> Void)
    func update<T: Encodable>(firModel: T, collection: String, documentId: String) -> Bool
    func delete(collection: String, documentId: String) -> Bool
}

