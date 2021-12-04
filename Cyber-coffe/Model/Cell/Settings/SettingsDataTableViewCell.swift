//
//  SettingsDataTableViewCell.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 02.12.2021.
//

import UIKit

class SettingsDataTableViewCell: UITableViewCell {
    static let identifier = "SettingsDataTableViewCell"
    
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
    
    let dataLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .right
        label.numberOfLines = 1
        label.textColor = UIColor.TableView.cellLabel
        
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        backgroundColor = UIColor.TableView.cellBackground
        contentView.addSubview(iconContainer)
        iconContainer.addSubview(iconImageView)
        contentView.addSubview(label)
        contentView.addSubview(dataLabel)
        contentView.clipsToBounds = true
        accessoryType = .disclosureIndicator
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
        
        label.frame = CGRect(x: 16 + iconContainer.frame.size.width,
                             y: 0,
                             width: (contentView.frame.size.width - 16 - iconContainer.frame.size.width - 10)/2,
                             height: contentView.frame.size.height)
        
        dataLabel.sizeToFit()
        dataLabel.frame = CGRect(x: 16 + iconContainer.frame.size.width + label.frame.size.width + 6,
                            y: 0,
                            width: (contentView.frame.size.width - 16 - iconContainer.frame.size.width - label.frame.size.width - 6 - 10),
                            height: contentView.frame.size.height)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        iconImageView.image = nil
        label.text = nil
        iconContainer.backgroundColor = nil
        dataLabel.text = nil
    }
    
    public func configure(with model: SettingsDataOption) {
        label.text = model.title
        iconImageView.image = model.icon
        iconContainer.backgroundColor = model.iconBackgroundColor
        dataLabel.text = model.data
    }
}
