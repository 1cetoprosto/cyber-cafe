//
//  PersonTableViewCell.swift
//  TrackMyCafe Prod
//
//  Created by Леонід Квіт on 15.06.2024.
//

import TinyConstraints
import UIKit

class PersonTableViewCell: UITableViewCell {
    
    let backgroundViewCell: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.TableView.cellBackground
        view.layer.cornerRadius = 10
        view.translatesAutoresizingMaskIntoConstraints = false
        
        return view
    }()
    
    private lazy var profileImage: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.layer.cornerRadius = 20
        view.clipsToBounds = true
        return view
    }()
    
    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.TableView.cellLabel
        label.font = .systemFont(ofSize: 17)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var phoneLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = UIColor.Main.text
        return label
    }()
    
    private lazy var callButton: UIButton = {
        let button = UIButton()
        
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = .systemBlue
        config.baseForegroundColor = .white
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
        config.cornerStyle = .capsule
        button.configuration = config
        
        button.configurationUpdateHandler = { button in
            var config = button.configuration
            let image = R.image.call()
            if button.isHighlighted {
                config?.image = image?.tint(color: UIColor.white.alpha(0.5))
            } else {
                config?.image = image?.tint(color: .white)
            }
            button.configuration = config
        }
        
        button.addTarget(self, action: #selector(callAction(_:)), for: .touchUpInside)
        return button
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = UIColor.Main.background
        selectionStyle = .none
        callButton.isHidden = true
        setupLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupLayout() {
        
        contentView.addSubview(backgroundViewCell)
        NSLayoutConstraint.activate([
            backgroundViewCell.topAnchor.constraint(equalTo: self.topAnchor, constant: 0),
            backgroundViewCell.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 0),
            backgroundViewCell.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: 0),
            backgroundViewCell.bottomAnchor.constraint(
                equalTo: self.bottomAnchor, constant: -UIConstants.standardBorderWidth),
        ])
        
        let vStack = UIStackView(arrangedSubviews: [nameLabel, phoneLabel])
        vStack.axis = .vertical
        vStack.spacing = UIConstants.smallSpacing
        
        let hStack = UIStackView(arrangedSubviews: [profileImage, vStack, callButton])
        hStack.axis = .horizontal
        hStack.spacing = UIConstants.standardSpacing
        hStack.alignment = .center
        
        contentView.addSubview(hStack)
        
        // Constraints
        profileImage.height(40)
        profileImage.width(40)
        
        callButton.height(30)
        callButton.width(30)
        
        hStack.horizontalToSuperview(insets: .horizontal(UIConstants.standardPadding))
        hStack.centerYToSuperview()
    }
    
    func setup(_ model: PersonListModelProtocol) {
        nameLabel.text = model.name
        if let phone = model.phoneValue, !phone.isEmpty {
            phoneLabel.text = phone
        } else {
            phoneLabel.isHidden = true
            callButton.isHidden = true
        }
        
        if let imagePath = model.profileImagePath, !imagePath.isEmpty,
           let imageURL = URL(string: imagePath)
        {
            profileImage.setImage(imageURL, placeholder: UIImage(named: model.placeholderImage ?? ""))
        } else if let placeholderName = model.placeholderImage {
            profileImage.image = UIImage(named: placeholderName)
        } else {
            profileImage.isHidden = true
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        phoneLabel.isHidden = false
        callButton.isHidden = false
        profileImage.isHidden = false
        
        nameLabel.text = nil
        phoneLabel.text = nil
        profileImage.image = nil
    }
    
    // MARK: - Actions
    @objc private func callAction(_ sender: UIButton) {
        // TODO: розібратися як можна подзвонити, якщо дійсно потрібен такий функціонал
        //phoneLabel.text?.makeACall()
    }
    
}
