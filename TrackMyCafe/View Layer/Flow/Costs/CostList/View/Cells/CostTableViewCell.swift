//
//  CostsTableViewCell.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 04.12.2021.
//

import UIKit

final class CostsTableViewCell: BaseListTableViewCell {

    static let identifier = CellIdentifiers.costsCell
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .value1, reuseIdentifier: reuseIdentifier)
        accessoryType = .disclosureIndicator
    }

    required init?(coder: NSCoder) {
        return nil
    }

    weak var viewModel: CostListItemViewModelType? {
        didSet {
            guard let viewModel else { return }
            textLabel?.applyDynamic(Typography.body)
            detailTextLabel?.applyDynamic(Typography.body)
            detailTextLabel?.adjustsFontSizeToFitWidth = true
            detailTextLabel?.minimumScaleFactor = 0.7
            detailTextLabel?.lineBreakMode = .byTruncatingTail
            textLabel?.text = viewModel.costName
            detailTextLabel?.text = viewModel.costSum
        }
    }
}
