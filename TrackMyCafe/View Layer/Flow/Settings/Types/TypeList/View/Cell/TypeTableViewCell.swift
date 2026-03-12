//
//  TypeTableViewCell.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 13.04.2022.
//

import TinyConstraints
import UIKit

final class TypeTableViewCell: BaseListTableViewCell {

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        selectionStyle = .default
        accessoryType = .disclosureIndicator
        textLabel?.applyDynamic(Typography.body)
    }

    required init?(coder: NSCoder) {
        return nil
    }

    func configure(type: TypeModel, indexPath: IndexPath) {
        textLabel?.text = type.name
    }
}
