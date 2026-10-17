//
//  PersonTableViewCell.swift
//  TrackMyCafe Prod
//
//  Created by Леонід Квіт on 15.06.2024.
//

import TinyConstraints
import UIKit

class PersonTableViewCell: UITableViewCell {

    private lazy var profileImage: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.layer.cornerRadius = 20
        view.clipsToBounds = true
        return view
    }()

    private lazy var nameLabel: UILabel = {
        let label = AppLabel(style: .body)
        label.textColor = UIColor.Main.text
        label.font = .systemFont(ofSize: 17)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var phoneLabel: UILabel = {
        let label = AppLabel(style: .footnote)
        label.font = .systemFont(ofSize: 14)
        label.textColor = UIColor.Main.secondaryText
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = UIColor.TableView.cellBackground
        self.contentView.backgroundColor = UIColor.TableView.cellBackground
        selectionStyle = .none
        accessoryType = .disclosureIndicator
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        let vStack = UIStackView(arrangedSubviews: [nameLabel, phoneLabel])
        vStack.axis = .vertical
        vStack.spacing = UIConstants.smallSpacing

        let hStack = UIStackView(arrangedSubviews: [profileImage, vStack])
        hStack.axis = .horizontal
        hStack.spacing = UIConstants.standardSpacing
        hStack.alignment = .center

        contentView.addSubview(hStack)

        // Constraints
        profileImage.height(40)
        profileImage.width(40)

        hStack.horizontalToSuperview(insets: .horizontal(UIConstants.standardPadding))
        hStack.centerYToSuperview()
    }

    func setup(_ model: PersonListModelProtocol) {
        nameLabel.text = model.name
        if let phone = model.phoneValue, !phone.isEmpty {
            phoneLabel.text = phone
        } else {
            phoneLabel.isHidden = true
        }

        if let imagePath = model.profileImagePath, !imagePath.isEmpty,
            let imageURL = URL(string: imagePath)
        {
            profileImage.setImage(
                imageURL, placeholder: UIImage(named: model.placeholderImage ?? ""))
        } else if let placeholderName = model.placeholderImage {
            profileImage.image = UIImage(named: placeholderName)
        } else {
            profileImage.isHidden = true
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        phoneLabel.isHidden = false
        profileImage.isHidden = false

        nameLabel.text = nil
        phoneLabel.text = nil
        profileImage.image = nil
    }
}
