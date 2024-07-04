//
//  BaseReusableView.swift
//  TrackMyCafe Prod
//
//  Created by Леонід Квіт on 15.06.2024.
//

import UIKit

protocol BaseReusableView {
    static var identifier: String { get }
    static var nib: UINib? { get }
}

extension BaseReusableView {
    
    static var identifier: String {
        return String(describing: self)
    }
    
    static var nib: UINib? {
        let nibName = String(describing: self)
        guard Bundle.main.path(forResource: nibName, ofType: "nib") != nil else {
            return nil
        }
        return UINib(nibName: nibName, bundle: nil)
    }
}

extension UITableViewCell: BaseReusableView {
    
}

extension UITableViewHeaderFooterView: BaseReusableView {
    
}

extension UICollectionReusableView: BaseReusableView {
    
}

