//
//  UIStackView.swift
//  Schedule
//
//  Created by Леонід Квіт on 05.11.2021.
//

import UIKit

extension UIStackView {

    convenience init(arrangedSubviews: [UIView], axis: NSLayoutConstraint.Axis, spacing: CGFloat, distribution: UIStackView.Distribution) {
        self.init(arrangedSubviews: arrangedSubviews)
        self.axis = axis
        self.spacing = spacing
        self.distribution = distribution
        self.translatesAutoresizingMaskIntoConstraints = false
    }

}
