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
        setTitleColor(UIColor.Button.title.withAlphaComponent(0.5), for: .highlighted)
        backgroundColor      = UIColor.Button.background
        layer.cornerRadius   = 10
    }
}
