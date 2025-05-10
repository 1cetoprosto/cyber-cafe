//
//  SubscriptionButtonCell.swift
//  TrackMyCafe
//
//  Created by Леонід Квіт on 10.05.2025.
//

import UIKit

final class SubscriptionButtonCell: UITableViewCell {
    
    private lazy var button: SubscriptionLinkButton = {
        let button = SubscriptionLinkButton(title: "")
        contentView.addSubview(button)
        return button
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupCell() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none
    }
    
    func configure(title: String, 
                  alignment: ButtonAlignment = .center,
                  target: Any?,
                  action: Selector) {
        button.setTitle(title, for: .normal)
        button.addTarget(target, action: action, for: .touchUpInside)
        
        switch alignment {
        case .center:
            button.centerXToSuperview()
        case .left:
            button.leftToSuperview(offset: 20)
        }
        button.verticalToSuperview()
    }
    
    enum ButtonAlignment {
        case center
        case left
    }
}
