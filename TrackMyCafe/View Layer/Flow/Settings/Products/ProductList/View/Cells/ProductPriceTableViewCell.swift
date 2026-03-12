//
//  ProductPriceTableViewCell.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 27.11.2021.
//

import UIKit

final class ProductPriceTableViewCell: BaseListTableViewCell {
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .value1, reuseIdentifier: reuseIdentifier)

        selectionStyle = .default
        accessoryType = .disclosureIndicator
        textLabel?.applyDynamic(Typography.body)
        detailTextLabel?.applyDynamic(Typography.body)
    }
    
    required init?(coder: NSCoder) {
        return nil
    }
    
    func configure(productPrice: ProductsPriceModel, indexPath: IndexPath) {
        textLabel?.text = productPrice.name
        detailTextLabel?.text = productPrice.price.currency
    }
}
