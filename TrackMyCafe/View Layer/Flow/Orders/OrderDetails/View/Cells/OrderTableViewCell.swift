//
//  OrderTableViewCell.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 08.11.2021.
//

import TinyConstraints
import UIKit

class OrderTableViewCell: UITableViewCell {

    /// Matches system `insetGrouped` section corner radius.
    private static let groupedCornerRadius: CGFloat = 10

    let backgroundViewCell: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.TableView.cellBackground
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.TableView.separator
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    let productLabel: UILabel = {
        let label = AppLabel(style: .body)
        label.text = ""
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor.TableView.cellLabel
        label.apply(.body)
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    let quantityLabel: UILabel = {
        let label = AppLabel(style: .footnote)
        label.text = ""
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor.TableView.cellLabel
        label.apply(.body)
        return label
    }()

    let productStepper: UIStepper = {
        let stepper = UIStepper()
        stepper.translatesAutoresizingMaskIntoConstraints = false
        return stepper
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none
        directionalLayoutMargins = .zero
        contentView.directionalLayoutMargins = .zero
        preservesSuperviewLayoutMargins = false
        contentView.preservesSuperviewLayoutMargins = false
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
        backgroundViewCell.topToSuperview()
        backgroundViewCell.bottomToSuperview()
        backgroundViewCell.leftToSuperview(offset: UIConstants.standardPadding)
        backgroundViewCell.rightToSuperview(offset: -UIConstants.standardPadding)

        backgroundViewCell.addSubview(productLabel)
        backgroundViewCell.addSubview(quantityLabel)
        backgroundViewCell.addSubview(productStepper)
        backgroundViewCell.addSubview(separatorView)

        productLabel.centerYToSuperview()
        productLabel.leftToSuperview(offset: UIConstants.standardPadding)

        productStepper.centerYToSuperview()
        productStepper.rightToSuperview(offset: -UIConstants.standardPadding)

        quantityLabel.centerYToSuperview()
        quantityLabel.rightToLeft(of: productStepper, offset: -UIConstants.mediumSpacing)
        productLabel.rightToLeft(of: quantityLabel, offset: -UIConstants.smallSpacing, relation: .equalOrLess)

        separatorView.leftToSuperview(offset: UIConstants.standardPadding)
        separatorView.rightToSuperview()
        separatorView.bottomToSuperview()
        separatorView.height(1 / UIScreen.main.scale)

        productLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        quantityLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        quantityLabel.setContentHuggingPriority(.required, for: .horizontal)
        productStepper.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    /// Settings-like insetGrouped section: one white block with rounded ends + hairline separators.
    func applyListStyle(row: Int, totalRows: Int) {
        let radius = Self.groupedCornerRadius
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
