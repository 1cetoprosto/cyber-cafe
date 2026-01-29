//
//  RememberMeButton.swift
//  DTLab
//
//  Created by Alexander Momotiuk on 24.07.2020.
//  Copyright © 2020 DTLab. All rights reserved.
//

import Foundation
import UIKit

class RememberMeButton: UIControl {
    
    var isCheck = false {
        didSet {
            checkImageView.image = isCheck ? R.image.icon_checkmark() : nil
        }
    }
    
    private lazy var boxView: UIView = {
        let view = UIView()
        view.layer.borderColor = UIColor.TabBar.tint.cgColor
        view.layer.borderWidth = UIConstants.thickBorderWidth
        view.layer.cornerRadius = UIConstants.smallCornerRadius
        view.size(.init(width: 16, height: 16))
        view.isUserInteractionEnabled = false
        return view
    }()
    
    private lazy var checkImageView: UIImageView = {
        let view = UIImageView()
        view.tintColor = UIColor.TabBar.tint
        view.contentMode = .scaleAspectFit
        view.isUserInteractionEnabled = false
        return view
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = Typography.footnote
        label.text = R.string.auth.rememberMe()
        label.textColor = UIColor.Main.text
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        
        addTarget(self, action: #selector(changeValue(_:)), for: .touchUpInside)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(boxView)
        boxView.leftToSuperview()
        boxView.centerYToSuperview()
        
        boxView.addSubview(checkImageView)
        checkImageView.edgesToSuperview(insets: .init(top: 3, left: 3, bottom: 3, right: 3))
        
        addSubview(titleLabel)
        titleLabel.leftToRight(of: boxView, offset: 6)
        titleLabel.verticalToSuperview(insets: .vertical(2))
        titleLabel.rightToSuperview()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        boxView.layer.borderColor = UIColor.NavBar.text.cgColor
    }
    
    // MARK: - Actions
    @objc private func changeValue(_ sender: UIControl) {
        isCheck = !isCheck
    }
}
