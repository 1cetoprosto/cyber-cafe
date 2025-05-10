//
//  BaseDatabaseModel.swift
//  TrackMyCafe Prod
//
//  Created by Леонід Квіт on 15.06.2024.
//

import Foundation

protocol BaseDatabaseModel: AnyObject {
    var ref: Refs { get }
    
    var firebaseRef: String! { get set }
    
    func forDatabase() -> [String: Any]
}
