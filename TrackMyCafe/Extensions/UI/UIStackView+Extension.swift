//
//  UIStackView.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 05.11.2021.
//

import UIKit

extension UIStackView {

    convenience init(arrangedSubviews: [UIView],
                     axis: NSLayoutConstraint.Axis,
                     spacing: CGFloat,
                     distribution: UIStackView.Distribution) {
        self.init(arrangedSubviews: arrangedSubviews)
        self.axis = axis
        self.spacing = spacing
        self.distribution = distribution
        self.translatesAutoresizingMaskIntoConstraints = false
    }

    static func VStack(_ views: [UIView] = [], spacing: CGFloat = 0) -> UIStackView {
        let stack = UIStackView(arrangedSubviews: views)
        stack.axis = .vertical
        stack.spacing = spacing
        return stack
    }
    
    static func HStack(_ views: [UIView] = [], spacing: CGFloat = 0) -> UIStackView {
        let stack = UIStackView(arrangedSubviews: views)
        stack.axis = .horizontal
        stack.spacing = spacing
        return stack
    }
}
