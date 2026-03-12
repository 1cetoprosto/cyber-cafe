//
//  ScheduleTableViewCell.swift
//
//
//  Created by Леонід Квіт on 05.11.2021.
//

import UIKit

final class OrdersTableViewCell: BaseListTableViewCell {
    static let identifier = CellIdentifiers.ordersCell

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .value1, reuseIdentifier: reuseIdentifier)

        accessoryType = .disclosureIndicator
        textLabel?.applyDynamic(Typography.body)
        detailTextLabel?.applyDynamic(Typography.body)
    }

    required init?(coder: NSCoder) {
        return nil
    }

    weak var viewModel: OrderListItemViewModelType? {
        didSet {
            applyConfiguration()
        }
    }

    private func applyConfiguration() {
        guard let viewModel else { return }

        textLabel?.text = viewModel.productsName
        detailTextLabel?.text = viewModel.ordersSum
    }
}
