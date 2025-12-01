//
//  AnimatedTextInputStyleLogin.swift
//  DTLab
//
//  Created by Alexander Momotiuk on 24.07.2020.
//  Copyright © 2020 DTLab. All rights reserved.
//

import UIKit
import AnimatedTextInput

public struct AnimatedTextInputStyleLogin: AnimatedTextInputStyle {
    //UIColor.gray замінив на UIColor.Main.text
    public let activeColor = UIColor.Main.text
    public let placeholderInactiveColor = UIColor.Main.text.withAlphaComponent(0.5)
    public let inactiveColor = UIColor.Main.text.withAlphaComponent(0.5)
    public let lineInactiveColor = UIColor.Main.text.withAlphaComponent(0.2)
    public let lineActiveColor = UIColor.Main.text
    public let lineHeight: CGFloat = 1.0 / UIScreen.main.scale
    public let errorColor = UIColor.red
    public let textInputFont = Typography.body
    public let textInputFontColor = UIColor.Main.text
    public let placeholderMinFontSize: CGFloat = 14
    public let counterLabelFont: UIFont? = UIFont.systemFont(ofSize: 9)
    public let leftMargin: CGFloat = 0
    public let topMargin: CGFloat = 20
    public let rightMargin: CGFloat = 0
    public let bottomMargin: CGFloat = 6
    public let yHintPositionOffset: CGFloat = 0
    public let yPlaceholderPositionOffset: CGFloat = 0
    //Text attributes will override properties like textInputFont, textInputFontColor...
    public let textAttributes: [String: Any]? = nil
    
    public init() { }
}
