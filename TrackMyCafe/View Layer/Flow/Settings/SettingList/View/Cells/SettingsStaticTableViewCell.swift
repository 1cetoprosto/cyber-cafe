//
//  SettingsStaticTableViewCell.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 24.11.2021.
//

import UIKit

final class SettingsStaticTableViewCell: BaseSettingsCell {
    
    func configure(with option: SettingsStaticOption) {
        label.text = option.title
        iconImageView.image = option.icon
        iconContainer.backgroundColor = option.iconBackgroundColor
    }
}
