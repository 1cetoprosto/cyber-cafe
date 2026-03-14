//
//  DefaultButton.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 01.12.2022.
//

import UIKit

class DefaultButton: UIButton {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupButton()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupButton()
    }
    
    func setupButton() {
        translatesAutoresizingMaskIntoConstraints = false
        setTitleColor(UIColor.Button.title, for: .normal)
        setTitleColor(
            UIColor.Button.title.withAlphaComponent(UIConstants.highlightedAlpha), for: .highlighted)
        backgroundColor = UIColor.Button.background
        layer.cornerRadius = UIConstants.largeCornerRadius
        titleLabel?.font = Typography.title3
        if #available(iOS 11.0, *) { titleLabel?.adjustsFontForContentSizeCategory = true }
    }
}

final class AppLabel: UILabel {
    enum Style {
        case title2DemiBold
        case footnote
        case kpiTitle
        case kpiValue
        case kpiFooter
        case balanceTitle
        case balanceValue
    }

    init(style: Style) {
        super.init(frame: .zero)
        apply(style)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        apply(.footnote)
    }

    func apply(_ style: Style) {
        adjustsFontForContentSizeCategory = true

        switch style {
        case .title2DemiBold:
            font = Typography.title2DemiBold
            numberOfLines = 1
            lineBreakMode = .byTruncatingTail
            textColor = UIColor.Main.text
            adjustsFontSizeToFitWidth = false

        case .footnote:
            font = Typography.footnote
            numberOfLines = 1
            lineBreakMode = .byTruncatingTail
            textColor = UIColor.Main.text
            adjustsFontSizeToFitWidth = false

        case .kpiTitle:
            font = Typography.footnote
            numberOfLines = 2
            lineBreakMode = .byWordWrapping
            textColor = UIColor.Main.text.alpha(0.7)
            adjustsFontSizeToFitWidth = false

        case .kpiValue:
            font = Typography.title2DemiBold
            numberOfLines = 1
            lineBreakMode = .byTruncatingTail
            textColor = UIColor.Main.text
            adjustsFontSizeToFitWidth = true
            minimumScaleFactor = 0.7

        case .kpiFooter:
            font = Typography.footnote
            numberOfLines = 1
            lineBreakMode = .byTruncatingTail
            textColor = UIColor.Main.text.alpha(0.7)
            adjustsFontSizeToFitWidth = true
            minimumScaleFactor = 0.85

        case .balanceTitle:
            font = Typography.footnote
            numberOfLines = 1
            lineBreakMode = .byTruncatingTail
            textColor = UIColor.Main.text.alpha(0.7)
            adjustsFontSizeToFitWidth = false

        case .balanceValue:
            font = Typography.title3DemiBold
            numberOfLines = 1
            lineBreakMode = .byTruncatingTail
            textColor = UIColor.Main.text
            adjustsFontSizeToFitWidth = true
            minimumScaleFactor = 0.7
        }
    }
}
