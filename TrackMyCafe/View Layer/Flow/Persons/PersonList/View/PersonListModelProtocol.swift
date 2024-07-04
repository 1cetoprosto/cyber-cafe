//
//  PersonListModelProtocol.swift
//  TrackMyCafe Prod
//
//  Created by Леонід Квіт on 15.06.2024.
//

import Foundation

protocol PersonListModelProtocol {
    var name: String { get }
    var phoneValue: String? { get }
    var profileImagePath: String? { get }
    var placeholderImage: String? { get }
}

extension PersonListModelProtocol {
    
    var placeholderImage: String? {
        return R.image.profilePlaceholder.name
    }
}
