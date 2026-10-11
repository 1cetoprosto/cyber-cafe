//
//  FirestoreDB.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 01.06.2022.
//

import Foundation

protocol FirestoreDB {
    func create<T: Encodable>(firModel: T, collection: String) async throws -> String
    func read<T: Decodable>(collection: String, firModel: T.Type) async throws -> [(documentId: String, T)]
    func update<T: Encodable>(firModel: T, collection: String, documentId: String) async throws
    func delete(collection: String, documentId: String) async throws
}
