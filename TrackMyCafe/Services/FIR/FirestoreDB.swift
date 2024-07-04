//
//  FirestoreDB.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 01.06.2022.
//

import Foundation

protocol FirestoreDB {
    func create<T: Encodable>(firModel: T, collection: String, completion: @escaping (Result<String, Error>) -> Void)
    func read<T: Codable>(collection: String, firModel: T.Type, completion: @escaping (Result<[(documentId: String, T)], Error>) -> Void)
    func update<T: Encodable>(firModel: T, collection: String, documentId: String, completion: @escaping (Result<Void, Error>) -> Void)
    func delete(collection: String, documentId: String, completion: @escaping (Result<Void, Error>) -> Void)
}

