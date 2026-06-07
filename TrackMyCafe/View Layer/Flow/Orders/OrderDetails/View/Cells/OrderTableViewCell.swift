//
//  OrderTableViewCell.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 08.11.2021.
//

import TinyConstraints
import UIKit

class OrderTableViewCell: UITableViewCell {

    let backgroundViewCell: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.TableView.cellBackground
        view.layer.cornerRadius = 10

        return view
    }()

    private let separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.separator
        return view
    }()

    let productLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.textColor = UIColor.TableView.cellLabel
        label.applyDynamic(Typography.body)
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail

        return label
    }()

    let quantityLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.textColor = UIColor.TableView.cellLabel
        label.applyDynamic(Typography.body)

        return label
    }()

    let productStepper: UIStepper = {
        let stepper = UIStepper()

        return stepper
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.backgroundColor = UIColor.Main.background
        setConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    weak var viewModel: ProductListItemViewModelType? {
        willSet(viewModel) {
            guard let viewModel = viewModel else { return }
            productLabel.text = viewModel.productLabel
            quantityLabel.text = viewModel.quantityLabel
            productStepper.value = viewModel.productStepperValue
            productStepper.tag = viewModel.productStepperTag
        }
    }

    func setConstraints() {

        contentView.addSubview(backgroundViewCell)
        backgroundViewCell.topToSuperview(offset: 0)
        backgroundViewCell.leftToSuperview(offset: 0)
        backgroundViewCell.rightToSuperview(offset: 0)
        backgroundViewCell.bottomToSuperview(offset: -1)

        contentView.addSubview(productLabel)
        productLabel.centerYToSuperview()
        productLabel.leftToSuperview(offset: 12, usingSafeArea: false)

        contentView.addSubview(productStepper)
        productStepper.centerYToSuperview()
        productStepper.rightToSuperview(offset: -12, usingSafeArea: false)

        contentView.addSubview(quantityLabel)
        quantityLabel.centerYToSuperview()
        quantityLabel.rightToLeft(of: productStepper, offset: -12)
        productLabel.rightToLeft(of: quantityLabel, offset: -8, relation: .equalOrLess)

        backgroundViewCell.addSubview(separatorView)
        separatorView.leftToSuperview(offset: 12)
        separatorView.rightToSuperview(offset: -12)
        separatorView.bottomToSuperview()
        separatorView.height(1 / UIScreen.main.scale)

        productLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        quantityLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        quantityLabel.setContentHuggingPriority(.required, for: .horizontal)
        productStepper.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    func applyListStyle(row: Int, totalRows: Int) {
        let radius: CGFloat = 12
        backgroundViewCell.layer.masksToBounds = true

        if totalRows <= 1 {
            backgroundViewCell.layer.cornerRadius = radius
            backgroundViewCell.layer.maskedCorners = [
                .layerMinXMinYCorner, .layerMaxXMinYCorner,
                .layerMinXMaxYCorner, .layerMaxXMaxYCorner,
            ]
            separatorView.isHidden = true
            return
        }

        let isFirst = row == 0
        let isLast = row == totalRows - 1

        if isFirst {
            backgroundViewCell.layer.cornerRadius = radius
            backgroundViewCell.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
            separatorView.isHidden = false
        } else if isLast {
            backgroundViewCell.layer.cornerRadius = radius
            backgroundViewCell.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
            separatorView.isHidden = true
        } else {
            backgroundViewCell.layer.cornerRadius = 0
            backgroundViewCell.layer.maskedCorners = [
                .layerMinXMinYCorner, .layerMaxXMinYCorner,
                .layerMinXMaxYCorner, .layerMaxXMaxYCorner,
            ]
            separatorView.isHidden = false
        }
    }
}
