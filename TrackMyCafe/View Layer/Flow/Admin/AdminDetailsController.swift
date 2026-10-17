//
//  AdminDetailsController.swift
//  TrackMyCafe
//
//  Created by Леонід Квіт on 01.07.2024.
//

import MessageUI
import SVProgressHUD
import UIKit

final class AdminDetailsController: UIViewController,
    UITableViewDataSource, UITableViewDelegate, MFMailComposeViewControllerDelegate
{

    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.backgroundColor = UIColor.Main.background
        tableView.separatorStyle = .singleLine
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()

    private var admin: Admin?

    private let cellIdentifier = "AdminDetailCell"

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.Main.background

        setupNavigationBar()
        setupTableView()
        setupNotifications()

        loadAdminData { [weak self] in
            self?.tableView.reloadData()
        }
    }

    private func setupNavigationBar() {
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(
                image: R.image.edit(), style: .plain, target: self,
                action: #selector(editAdmin))
        ]
    }

    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.applyStandardListAppearance()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
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
            self, selector: #selector(updateForm), name: .adminInfoReload, object: nil)
    }

    private func loadAdminData(completion: @escaping () -> Void) {
        RequestManager.shared.listenToAdmin { [weak self] in
            self?.admin = RequestManager.shared.admin
            completion()
        }
    }

    @objc private func updateForm() {
        tableView.reloadData()
    }

    // MARK: - UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1  // header
        case 1: return 3  // phone, email, address
        case 2: return 1  // note
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
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
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

        guard let admin = admin else { return }

        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            configureHeaderCell(cell, admin: admin)
        case (1, 0):
            let canCall = admin.phone?.isValid(regex: .phone) == true
            configureContactCell(
                cell, title: R.string.global.phone(),
                value: admin.phone?.nilIfEmpty ?? R.string.global.noSpecified(),
                isClickable: canCall)
        case (1, 1):
            let canEmail =
                admin.email.isValid(regex: .email)
                && MFMailComposeViewController.canSendMail()
            configureContactCell(
                cell, title: R.string.global.email(), value: admin.email,
                isClickable: canEmail)
        case (1, 2):
            configureContactCell(
                cell, title: R.string.global.address(),
                value: admin.address?.nilIfEmpty ?? R.string.global.noSpecified(),
                isClickable: false)
        case (2, 0):
            configureNoteCell(cell, admin: admin)
        default:
            break
        }
    }

    private func configureHeaderCell(_ cell: UITableViewCell, admin: Admin) {
        let avatar = UIImageView()
        avatar.contentMode = .scaleAspectFill
        avatar.clipsToBounds = true
        avatar.layer.cornerRadius = 32
        avatar.translatesAutoresizingMaskIntoConstraints = false

        if let path = admin.avatarThumbnailUrl ?? admin.avatarUrl, let url = URL(string: path) {
            avatar.setImage(url, placeholder: R.image.profilePlaceholder())
        } else {
            avatar.image = R.image.profilePlaceholder()
        }

        let nameLabel = AppLabel(style: .headline)
        nameLabel.numberOfLines = 2
        nameLabel.text =
            admin.fullName.isEmpty
            ? R.string.global.roleAdmin()
            : admin.fullName

        let roleLabel = AppLabel(style: .callout)
        roleLabel.text = R.string.global.adminPrivilege()
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

    private func configureNoteCell(_ cell: UITableViewCell, admin: Admin) {
        var content = cell.defaultContentConfiguration()
        content.text = admin.comment?.nilIfEmpty ?? R.string.global.noSpecified()
        content.textProperties.numberOfLines = 0
        cell.contentConfiguration = content
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
        guard let phone = admin?.phone?.nilIfEmpty,
            phone.isValid(regex: .phone),
            let url = URL(string: "tel://\(phone)"),
            UIApplication.shared.canOpenURL(url)
        else { return }
        UIApplication.shared.open(url)
    }

    private func sendMail() {
        guard let admin = admin,
            MFMailComposeViewController.canSendMail()
        else { return }

        let mail = MFMailComposeViewController()
        mail.mailComposeDelegate = self
        mail.setToRecipients([admin.email])
        present(mail, animated: true)
    }

    @objc private func editAdmin() {
        let controller = CreateEditAdminController()
        navigationController?.pushViewController(controller, animated: true)
    }

    // MARK: - MFMailComposeViewControllerDelegate

    func mailComposeController(
        _ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult,
        error: Error?
    ) {
        controller.dismiss(animated: true)
    }
}
