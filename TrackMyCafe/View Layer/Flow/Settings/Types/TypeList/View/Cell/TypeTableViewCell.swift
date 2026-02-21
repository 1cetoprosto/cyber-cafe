//
//  TypeTableViewCell.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 13.04.2022.
//

import TinyConstraints
import UIKit

class TypeTableViewCell: UITableViewCell {

    let typeLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.textColor = UIColor.TableView.cellLabel
        label.applyDynamic(Typography.body)

        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.backgroundColor = UIColor.TableView.cellBackground
        selectionStyle = .none

        setConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(type: TypeModel, indexPath: IndexPath) {
        typeLabel.text = type.name
    }

    func setConstraints() {
        contentView.addSubview(typeLabel)

        typeLabel.centerYToSuperview()
        typeLabel.leadingToSuperview(offset: 15)
        typeLabel.trailingToSuperview(offset: 15)
    }
}
