//
//  SettingsSwitchTableViewCell.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 24.11.2021.
//

import UIKit

class SettingsSwitchTableViewCell: UITableViewCell {
    static let identifier = "SettingsSwitchStaticTableViewCell"
    
    private let iconContainer: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        view.layer.cornerRadius = 6
        view.layer.masksToBounds = true
        
        return view
    }()
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        
        return imageView
    }()
    
    private let label: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.textColor = UIColor.TableView.cellLabel
        
        return label
    }()
    
    private let settingSwitch: UISwitch = {
        let settingSwitch = UISwitch()
        settingSwitch.onTintColor = UIColor.Button.background
        settingSwitch.tintColor = .red
        settingSwitch.thumbTintColor = UIColor.NavBar.text
        
        return settingSwitch
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        backgroundColor = UIColor.TableView.cellBackground
        contentView.addSubview(iconContainer)
        iconContainer.addSubview(iconImageView)
        contentView.addSubview(label)
        contentView.addSubview(settingSwitch)
        contentView.clipsToBounds = true
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let size: CGFloat = contentView.frame.size.height - 12
        iconContainer.frame = CGRect(x: 10, y: 6, width: size, height: size)

        let imageSize: CGFloat = size/1.5
        iconImageView.frame = CGRect(x: (size - imageSize)/2, y: (size - imageSize)/2, width: imageSize, height: imageSize)
        
        settingSwitch.sizeToFit()
        settingSwitch.frame = CGRect(x: contentView.frame.size.width - settingSwitch.frame.size.width - 20,
                                     y: (contentView.frame.size.height - settingSwitch.frame.size.height) / 2,
                                     width: settingSwitch.frame.size.width,
                                     height: settingSwitch.frame.size.height)
        
        label.frame = CGRect(x: 16 + iconContainer.frame.size.width,
                             y: 0,
                             width: contentView.frame.size.width - 16 - iconContainer.frame.size.width - 10,
                             height: contentView.frame.size.height)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        iconImageView.image = nil
        label.text = nil
        iconContainer.backgroundColor = nil
        settingSwitch.isOn = false
    }
    
    public func configure(with model: SettingsSwitchOption) {
        label.text = model.title
        iconImageView.image = model.icon
        iconContainer.backgroundColor = model.iconBackgroundColor
        settingSwitch.isOn = model.isOn
    }
}
 
