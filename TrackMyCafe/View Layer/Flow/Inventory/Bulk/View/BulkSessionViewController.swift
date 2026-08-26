//
//  BulkSessionViewController.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 25.08.2026.
//

import TinyConstraints
import UIKit

final class BulkSessionViewController: UIViewController {

    // MARK: - Views

    private let summaryLabel: AppLabel = {
        let label = AppLabel(style: .footnote)
        label.textColor = UIColor.Main.secondaryText
        label.numberOfLines = 0
        return label
    }()

    private let noteTextField: UITextField = {
        let tf = UITextField()
        tf.borderStyle = .roundedRect
        tf.font = UIFont.preferredFont(forTextStyle: .body)
        tf.placeholder = R.string.global.inventoryBulkSessionNotePlaceholder()
        return tf
    }()

    private lazy var tableView: UITableView = {
        let tableView = UITableView.standardList()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()
        tableView.keyboardDismissMode = .onDrag
        return tableView
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        return indicator
    }()

    // MARK: - Properties

    private let viewModel: BulkSessionViewModelProtocol

    // MARK: - Init

    init(viewModel: BulkSessionViewModelProtocol) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
        viewModel.startSession()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = UIColor.Main.background
        title = viewModel.titleText

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: R.string.global.cancel(),
            style: .plain,
            target: self,
            action: #selector(handleCancel)
        )

        let commitTitle = R.string.global.inventoryBulkCommit()
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: commitTitle,
            style: .done,
            target: self,
            action: #selector(handleCommit)
        )

        let rootStack = UIStackView(arrangedSubviews: [summaryLabel, noteTextField, tableView])
        rootStack.axis = .vertical
        rootStack.spacing = UIConstants.standardSpacing
        rootStack.alignment = .fill

        view.addSubview(rootStack)
        view.addSubview(activityIndicator)

        rootStack.topToSuperview(offset: 16, usingSafeArea: true)
        rootStack.leadingToSuperview(offset: UIConstants.standardPadding)
        rootStack.trailingToSuperview(offset: -UIConstants.standardPadding)
        rootStack.bottomToSuperview()

        noteTextField.height(44)

        activityIndicator.centerInSuperview()

        tableView.register(
            BulkSessionCell.self, forCellReuseIdentifier: "BulkSessionCell"
        )

        noteTextField.addTarget(
            self, action: #selector(noteDidChange), for: .editingChanged
        )
    }

    private func bindViewModel() {
        var vm = viewModel

        vm.onDataUpdated = { [weak self] in
            DispatchQueue.main.async {
                guard let self else { return }
                self.summaryLabel.text = self.viewModel.summaryText
                self.navigationItem.rightBarButtonItem?.isEnabled = self.viewModel.canCommit
                self.tableView.reloadData()
            }
        }

        vm.isLoading = { [weak self] isLoading in
            DispatchQueue.main.async {
                if isLoading {
                    self?.activityIndicator.startAnimating()
                } else {
                    self?.activityIndicator.stopAnimating()
                }
            }
        }

        vm.onError = { [weak self] message in
            DispatchQueue.main.async {
                PopupFactory.showPopup(
                    title: R.string.global.error(),
                    description: message,
                    buttonAction: nil
                )
            }
        }

        vm.onFinished = { [weak self] in
            DispatchQueue.main.async {
                self?.dismiss(animated: true)
            }
        }
    }

    // MARK: - Actions

    @objc private func handleCancel() {
        viewModel.cancelSession()
    }

    @objc private func handleCommit() {
        view.endEditing(true)
        viewModel.commitSession()
    }

    @objc private func noteDidChange() {
        viewModel.sessionNote = noteTextField.text ?? ""
    }
}

// MARK: - UITableViewDataSource & Delegate

extension BulkSessionViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let cell = tableView.dequeueReusableCell(
                withIdentifier: "BulkSessionCell", for: indexPath
            ) as? BulkSessionCell
        else {
            return UITableViewCell()
        }
        let item = viewModel.items[indexPath.row]
        cell.configure(with: item)
        cell.onCountedTextChanged = { [weak self] text in
            self?.viewModel.updateCounted(forRowAt: indexPath.row, countedText: text)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        false
    }
}

// MARK: - Cell

final class BulkSessionCell: BaseListTableViewCell, UITextFieldDelegate {

    // MARK: - Hooks

    var onCountedTextChanged: ((String?) -> Void)?

    // MARK: - Views

    private let nameLabel: AppLabel = {
        let label = AppLabel(style: .bodyMultiline)
        label.textColor = UIColor.TableView.cellLabel
        label.numberOfLines = 2
        return label
    }()

    private let expectedLabel: AppLabel = {
        let label = AppLabel(style: .footnoteValue)
        label.textColor = UIColor.Main.secondaryText
        label.textAlignment = .left
        return label
    }()

    private let countedTextField: UITextField = {
        let tf = UITextField()
        tf.borderStyle = .roundedRect
        tf.keyboardType = .decimalPad
        tf.textAlignment = .right
        tf.font = Typography.body
        tf.placeholder = "0"
        tf.enableNumericInput(maxFractionDigits: 3)
        return tf
    }()

    private let deltaLabel: AppLabel = {
        let label = AppLabel(style: .footnoteValue)
        label.textAlignment = .right
        return label
    }()

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        setupUI()
        countedTextField.delegate = self
        countedTextField.addTarget(
            self, action: #selector(textFieldDidChange), for: .editingChanged
        )
    }

    required init?(coder: NSCoder) {
        return nil
    }

    // MARK: - Setup

    private func setupUI() {
        selectionStyle = .none

        let leftStack = UIStackView(arrangedSubviews: [nameLabel, expectedLabel])
        leftStack.axis = .vertical
        leftStack.spacing = UIConstants.smallSpacing

        let rightStack = UIStackView(arrangedSubviews: [countedTextField, deltaLabel])
        rightStack.axis = .vertical
        rightStack.spacing = UIConstants.smallSpacing
        rightStack.alignment = .fill

        rightStack.setContentHuggingPriority(.required, for: .horizontal)
        rightStack.setContentCompressionResistancePriority(.required, for: .horizontal)
        leftStack.setContentHuggingPriority(.defaultLow, for: .horizontal)
        leftStack.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let rootStack = UIStackView(arrangedSubviews: [leftStack, rightStack])
        rootStack.axis = .horizontal
        rootStack.alignment = .top
        rootStack.distribution = .fill
        rootStack.spacing = UIConstants.standardSpacing

        contentView.addSubview(rootStack)
        rootStack.edgesToSuperview(
            insets: .init(
                top: UIConstants.smallSpacing,
                left: UIConstants.standardPadding,
                bottom: UIConstants.smallSpacing,
                right: UIConstants.standardPadding
            )
        )

        countedTextField.width(120)
    }

    func configure(with vm: BulkSessionRowViewModel) {
        nameLabel.text = "\(vm.name), \(vm.unitText)"
        expectedLabel.text = String(
            format: R.string.global.inventoryBulkExpected(vm.expectedText), vm.expectedText
        )
        countedTextField.text = vm.countedText
        if let deltaText = vm.deltaText {
            deltaLabel.isHidden = false
            deltaLabel.text = deltaText
            switch vm.deltaIsPositive {
            case .some(true):
                deltaLabel.textColor = .systemGreen
            case .some(false):
                deltaLabel.textColor = .systemRed
            case .none:
                deltaLabel.textColor = UIColor.Main.secondaryText
            }
        } else {
            deltaLabel.isHidden = true
        }
    }

    // MARK: - TextField

    @objc private func textFieldDidChange() {
        onCountedTextChanged?(countedTextField.text)
    }
}
