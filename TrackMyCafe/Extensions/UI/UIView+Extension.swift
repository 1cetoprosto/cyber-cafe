//
//  UIView+Extension.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 04.05.2024.
//

import TinyConstraints
import UIKit

extension UIView {

    // MARK: - Cafe card surface (single app-wide style)

    /// Elevated content card: white surface, hairline stroke, soft drop shadow.
    /// Use for standalone / scroll-stack cards (Home KPIs, Reports hero, P&L big/detail).
    func applyCafeSoftCardStyle(
        cornerRadius: CGFloat = UIConstants.cardCornerRadius,
        elevated: Bool = true
    ) {
        backgroundColor = backgroundColor ?? UIColor.TableView.cellBackground
        layer.cornerRadius = cornerRadius
        layer.masksToBounds = false
        clipsToBounds = false
        layer.borderWidth = UIConstants.standardBorderWidth
        layer.borderColor = UIColor.Semantic.cardStroke.cgColor
        if elevated {
            layer.shadowColor = UIColor.black.cgColor
            layer.shadowOpacity = 0.06
            layer.shadowOffset = CGSize(width: 0, height: 2)
            layer.shadowRadius = 8
        } else {
            clearCafeCardShadow()
        }
    }

    /// Same surface/border/radius as soft cards, without drop shadow.
    /// Required for UITableView rows — the table clips shadows into muddy side bars.
    func applyCafeListCardStyle(cornerRadius: CGFloat = UIConstants.cardCornerRadius) {
        applyCafeSoftCardStyle(cornerRadius: cornerRadius, elevated: false)
    }

    func updateCafeSoftCardShadowPath(cornerRadius: CGFloat = UIConstants.cardCornerRadius) {
        guard layer.shadowOpacity > 0 else {
            layer.shadowPath = nil
            return
        }
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius).cgPath
    }

    private func clearCafeCardShadow() {
        layer.shadowOpacity = 0
        layer.shadowRadius = 0
        layer.shadowOffset = .zero
        layer.shadowPath = nil
    }

    // MARK: - Layout helpers

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
