//
//  UIView+Extension.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 04.05.2024.
//

import TinyConstraints
import UIKit

extension UIView {

    func wrap(_ insets: UIEdgeInsets) -> UIView {
        let wrapper = UIView()
        wrapper.backgroundColor = .clear
        
        wrapper.addSubview(self)
        edgesToSuperview(insets: insets)
        return wrapper
    }
    
    func wrapV() -> UIView {
        let wrapper = UIView()
        wrapper.backgroundColor = .clear
        
        wrapper.addSubview(self)
        centerInSuperview()
        horizontalToSuperview()
        topToSuperview(relation: .equalOrGreater)
        bottomToSuperview(relation: .equalOrLess)
        return wrapper
    }
    
    func wrapVTop() -> UIView {
        let wrapper = UIView()
        wrapper.backgroundColor = .clear
        
        wrapper.addSubview(self)
        horizontalToSuperview()
        topToSuperview()
        bottomToSuperview(relation: .equalOrLess)
        return wrapper
    }
    
    func wrapH() -> UIView {
        let wrapper = UIView()
        wrapper.backgroundColor = .clear
        
        wrapper.addSubview(self)
        centerInSuperview()
        verticalToSuperview()
        leftToSuperview(relation: .equalOrGreater)
        rightToSuperview(relation: .equalOrLess)
        return wrapper
    }
}
