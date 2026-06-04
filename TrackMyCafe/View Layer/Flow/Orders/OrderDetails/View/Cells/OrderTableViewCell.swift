//
//  OrderTableViewCell.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 08.11.2021.
//

import UIKit

class OrderTableViewCell: UITableViewCell {

    let backgroundViewCell: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.TableView.cellBackground
        view.layer.cornerRadius = 10
        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }()

    private let separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.separator
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    let productLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor.TableView.cellLabel
        label.applyDynamic(Typography.body)
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail

        return label
    }()

    let quantityLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor.TableView.cellLabel
        label.applyDynamic(Typography.body)

        return label
    }()

    let productStepper: UIStepper = {
        let stepper = UIStepper()
        stepper.translatesAutoresizingMaskIntoConstraints = false

        return stepper
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.backgroundColor = UIColor.Main.background
        directionalLayoutMargins = .zero
        contentView.directionalLayoutMargins = .zero
        preservesSuperviewLayoutMargins = true
        contentView.preservesSuperviewLayoutMargins = true
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
        NSLayoutConstraint.activate([
            backgroundViewCell.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0),
            backgroundViewCell.leadingAnchor.constraint(
                equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            backgroundViewCell.trailingAnchor.constraint(
                equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            backgroundViewCell.bottomAnchor.constraint(
                equalTo: contentView.bottomAnchor, constant: -1),
        ])

        contentView.addSubview(productLabel)
        NSLayoutConstraint.activate([
            productLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            productLabel.leadingAnchor.constraint(
                equalTo: backgroundViewCell.leadingAnchor, constant: 12),
        ])

        contentView.addSubview(productStepper)
        NSLayoutConstraint.activate([
            productStepper.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            productStepper.trailingAnchor.constraint(
                equalTo: backgroundViewCell.trailingAnchor, constant: -12),
        ])

        contentView.addSubview(quantityLabel)
        NSLayoutConstraint.activate([
            quantityLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            quantityLabel.trailingAnchor.constraint(
                equalTo: productStepper.leadingAnchor, constant: -12),
            productLabel.trailingAnchor.constraint(
                lessThanOrEqualTo: quantityLabel.leadingAnchor, constant: -8),
        ])

        backgroundViewCell.addSubview(separatorView)
        NSLayoutConstraint.activate([
            separatorView.leadingAnchor.constraint(
                equalTo: backgroundViewCell.leadingAnchor, constant: 12),
            separatorView.trailingAnchor.constraint(
                equalTo: backgroundViewCell.trailingAnchor, constant: -12),
            separatorView.bottomAnchor.constraint(equalTo: backgroundViewCell.bottomAnchor),
            separatorView.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale),
        ])

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
