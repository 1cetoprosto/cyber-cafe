//
//  TechnicianDetailsController.swift
//  TrackMyCafe Prod
//
//  Created by Леонід Квіт on 15.06.2024.
//

import MessageUI
import SVProgressHUD
import UIKit

final class TechnicianDetailsController: UIViewController,
    UITableViewDataSource, UITableViewDelegate, MFMailComposeViewControllerDelegate
{

    private let viewModel: StaffDetailsViewModel
    private let fromMod: Bool

    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.backgroundColor = UIColor.Main.background
        tableView.separatorStyle = .singleLine
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()

    init(_ employee: Employee, fromMod: Bool) {
        self.viewModel = StaffDetailsViewModel(employee: employee)
        self.fromMod = fromMod
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.Main.background

        setupNavigationBar()
        setupTableView()
        setupNotifications()
        updateTitle()
    }

    private func setupNavigationBar() {
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(
                image: R.image.edit(), style: .plain, target: self,
                action: #selector(editTechnician)),
            UIBarButtonItem(
                image: R.image.delete(), style: .plain, target: self,
                action: #selector(deleteTechnician)),
        ]
    }

    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(reloadEmployee), name: .employeesInfoReload, object: nil)
    }

    @objc private func reloadEmployee() {
        if viewModel.reload() {
            updateTitle()
            tableView.reloadData()
        } else {
            navigationController?.popViewController(animated: true)
        }
    }

    private func updateTitle() {
        title = viewModel.shortName
    }

    // MARK: - UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1  // header
        case 1: return 3  // phone, email, address
        case 2: return 1  // note
        case 3: return 1  // resend invite
        default: return 0
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 1: return R.string.global.contactInfo()
        case 2: return R.string.global.note()
        default: return nil
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        configureCell(cell, at: indexPath)
        return cell
    }

    private func configureCell(_ cell: UITableViewCell, at indexPath: IndexPath) {
        // Reset cell state to avoid reuse artifacts
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        cell.contentConfiguration = nil
        cell.backgroundView = nil
        cell.backgroundColor = UIColor.TableView.cellBackground
        cell.accessoryType = .none
        cell.selectionStyle = .none

        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            configureHeaderCell(cell)
        case (1, 0):
            configureContactCell(
                cell, title: R.string.global.phone(),
                value: viewModel.phone,
                isClickable: viewModel.isPhoneClickable)
        case (1, 1):
            let canEmail = viewModel.isEmailClickable && MFMailComposeViewController.canSendMail()
            configureContactCell(
                cell, title: R.string.global.email(), value: viewModel.email,
                isClickable: canEmail)
        case (1, 2):
            configureContactCell(
                cell, title: R.string.global.address(),
                value: viewModel.address, isClickable: false)
        case (2, 0):
            configureNoteCell(cell)
        case (3, 0):
            configureResendCell(cell)
        default:
            break
        }
    }

    private func configureHeaderCell(_ cell: UITableViewCell) {
        let avatar = UIImageView()
        avatar.contentMode = .scaleAspectFill
        avatar.clipsToBounds = true
        avatar.layer.cornerRadius = 32
        avatar.translatesAutoresizingMaskIntoConstraints = false
        avatar.setImage(
            pathOrURL: viewModel.avatarUrl,
            placeholder: UIImage(named: AssetNames.avatarPlaceholder))

        let nameLabel = AppLabel(style: .headline)
        nameLabel.numberOfLines = 2
        nameLabel.text = viewModel.fullName

        let roleLabel = AppLabel(style: .callout)
        roleLabel.text = viewModel.roleName
        roleLabel.textColor = .secondaryLabel

        let labelsStack = UIStackView(arrangedSubviews: [nameLabel, roleLabel])
        labelsStack.axis = .vertical
        labelsStack.spacing = 4
        labelsStack.translatesAutoresizingMaskIntoConstraints = false

        cell.contentView.addSubview(avatar)
        cell.contentView.addSubview(labelsStack)

        NSLayoutConstraint.activate([
            avatar.leadingAnchor.constraint(
                equalTo: cell.contentView.leadingAnchor, constant: 16),
            avatar.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
            avatar.widthAnchor.constraint(equalToConstant: 64),
            avatar.heightAnchor.constraint(equalToConstant: 64),

            labelsStack.leadingAnchor.constraint(
                equalTo: avatar.trailingAnchor, constant: 16),
            labelsStack.trailingAnchor.constraint(
                lessThanOrEqualTo: cell.contentView.trailingAnchor, constant: -16),
            labelsStack.topAnchor.constraint(
                equalTo: cell.contentView.topAnchor, constant: 16),
            labelsStack.bottomAnchor.constraint(
                equalTo: cell.contentView.bottomAnchor, constant: -16),
        ])
    }

    private func configureContactCell(
        _ cell: UITableViewCell, title: String, value: String, isClickable: Bool
    ) {
        var content = cell.defaultContentConfiguration()
        content.text = title
        content.secondaryText = value
        content.secondaryTextProperties.color = .secondaryLabel
        content.secondaryTextProperties.numberOfLines = 0
        cell.contentConfiguration = content
        cell.accessoryType = isClickable ? .disclosureIndicator : .none
        cell.selectionStyle = isClickable ? .default : .none
    }

    private func configureNoteCell(_ cell: UITableViewCell) {
        var content = cell.defaultContentConfiguration()
        content.text = viewModel.note
        content.textProperties.numberOfLines = 0
        cell.contentConfiguration = content
    }

    private func configureResendCell(_ cell: UITableViewCell) {
        // Transparent background so the DefaultButton is the only visible element
        // (no white card from insetGrouped style)
        let clearView = UIView()
        clearView.backgroundColor = .clear
        cell.backgroundView = clearView
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear

        let button = DefaultButton()
        button.setTitle(R.string.global.resendInvite(), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(resendInvite), for: .touchUpInside)

        cell.contentView.addSubview(button)

        NSLayoutConstraint.activate([
            button.topAnchor.constraint(
                equalTo: cell.contentView.topAnchor, constant: 8),
            button.bottomAnchor.constraint(
                equalTo: cell.contentView.bottomAnchor, constant: -8),
            button.leadingAnchor.constraint(
                equalTo: cell.contentView.leadingAnchor, constant: 16),
            button.trailingAnchor.constraint(
                equalTo: cell.contentView.trailingAnchor, constant: -16),
            button.heightAnchor.constraint(equalToConstant: UIConstants.buttonHeight),
        ])

        cell.selectionStyle = .none
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch (indexPath.section, indexPath.row) {
        case (1, 0):
            callPhone()
        case (1, 1):
            sendMail()
        default:
            break
        }
    }

    // MARK: - Actions

    private func callPhone() {
        guard let phone = viewModel.rawPhone,
            viewModel.isPhoneClickable,
            let url = URL(string: "tel://\(phone)"),
            UIApplication.shared.canOpenURL(url)
        else { return }
        UIApplication.shared.open(url)
    }

    private func sendMail() {
        guard MFMailComposeViewController.canSendMail() else { return }
        let mail = MFMailComposeViewController()
        mail.mailComposeDelegate = self
        mail.setToRecipients([viewModel.email])
        present(mail, animated: true)
    }

    @objc private func editTechnician() {
        let controller = CreateEditTechnicianController(viewModel.employee, moderType: fromMod)
        navigationController?.pushViewController(controller, animated: true)
    }

    @objc private func deleteTechnician() {
        showWarning(
            body: R.string.global.areYouSureYouWantToDeleteThisItem(),
            buttonTitle: R.string.global.delete()
        ) { [weak self] in
            Task { [weak self] in
                guard let self else { return }
                let success = await self.viewModel.deleteEmployee()
                await MainActor.run {
                    if success {
                        self.viewModel.logDeletion()
                        self.navigationController?.popViewController(animated: true)
                    } else {
                        self.showAlert(
                            R.string.global.error(), body: R.string.global.somethingWentWrong())
                    }
                }
            }
        }
    }

    @objc private func resendInvite() {
        guard viewModel.isEmailClickable else {
            showAlert(R.string.global.error(), body: R.string.global.emailNotValid())
            return
        }

        SVProgressHUD.show()
        Task { [weak self] in
            guard let self else { return }
            do {
                try await self.viewModel.resendInvite()
                await MainActor.run {
                    SVProgressHUD.dismiss()
                    self.showAlert(
                        R.string.global.success(),
                        body: R.string.global.successSentEmployeeEmail(self.viewModel.email))
                }
            } catch {
                await MainActor.run {
                    SVProgressHUD.dismiss()
                    self.showAlert(
                        R.string.global.error(),
                        body: R.string.global.failedSentEmployeeEmail())
                }
            }
        }
    }

    // MARK: - MFMailComposeViewControllerDelegate

    func mailComposeController(
        _ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult,
        error: Error?
    ) {
        controller.dismiss(animated: true)
    }
}
