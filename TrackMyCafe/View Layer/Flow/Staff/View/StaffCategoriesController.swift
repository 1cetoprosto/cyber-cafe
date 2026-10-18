//
//  StaffCategoriesController.swift
//  TrackMyCafe Prod
//
//  Created by Леонід Квіт on 15.06.2024.
//

import UIKit

class StaffCategoriesController: UITableViewController {

    private let viewModel = StaffCategoriesViewModel()

    enum Category: CaseIterable {
        case waiter
        case seniorWaiter

        var name: String {
            switch self {
            case .waiter: return R.string.global.staff_sectionWaiter()
            case .seniorWaiter: return R.string.global.staff_sectionSeniorWaiter()
            }
        }

        var icon: UIImage? {
            switch self {
            case .waiter: return UIImage(systemName: SystemImages.person2Fill)
            case .seniorWaiter: return UIImage(systemName: "person.3.fill")
            }
        }

        var iconBackgroundColor: UIColor {
            switch self {
            case .waiter: return .systemBlue
            case .seniorWaiter: return .systemOrange
            }
        }
    }

    override init(style: UITableView.Style) {
        super.init(style: .insetGrouped)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = R.string.global.menuStaff()

        tableView.applyStandardListAppearance()
        tableView.register(
            SettingsStaticTableViewCell.self,
            forCellReuseIdentifier: SettingsStaticTableViewCell.identifier
        )
        tableView.tableFooterView = UIView()

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add, target: self, action: #selector(addEmployee(_:)))
    }

    @objc private func addEmployee(_ sender: UIBarButtonItem) {
        let controller = CreateEditTechnicianController(moderType: false)
        navigationController?.pushViewController(controller, animated: true)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Category.allCases.count + 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath)
        -> UITableViewCell
    {
        guard
            let cell = tableView.dequeueReusableCell(
                withIdentifier: SettingsStaticTableViewCell.identifier,
                for: indexPath
            ) as? SettingsStaticTableViewCell
        else {
            return UITableViewCell()
        }

        var option: SettingsStaticOption

        if indexPath.row == 0 {
            option = SettingsStaticOption(
                title: viewModel.ownerDisplayName,
                icon: UIImage(systemName: "person.crop.circle.fill"),
                iconBackgroundColor: .systemIndigo
            ) {}
            option.infoHandler = { [weak self] in
                self?.showInfo(
                    title: R.string.global.staff_infoOwnerTitle(),
                    message: R.string.global.staff_infoOwnerMessage()
                )
            }
        } else {
            let category = Category.allCases[indexPath.row - 1]
            option = SettingsStaticOption(
                title: category.name,
                icon: category.icon,
                iconBackgroundColor: category.iconBackgroundColor
            ) {}
            switch category {
            case .waiter:
                option.infoHandler = { [weak self] in
                    self?.showInfo(
                        title: R.string.global.staff_infoWaiterTitle(),
                        message: R.string.global.staff_infoWaiterMessage()
                    )
                }
            case .seniorWaiter:
                option.infoHandler = { [weak self] in
                    self?.showInfo(
                        title: R.string.global.staff_infoSeniorWaiterTitle(),
                        message: R.string.global.staff_infoSeniorWaiterMessage()
                    )
                }
            }
        }

        cell.configure(with: option)
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if indexPath.row == 0 {
            let controller = AdminDetailsController()
            navigationController?.pushViewController(controller, animated: true)
            return
        }

        switch Category.allCases[indexPath.row - 1] {
        case .waiter:
            let controller = TechniciansListController()
            navigationController?.pushViewController(controller, animated: true)
        case .seniorWaiter:
            let controller = ModeratorListController()
            navigationController?.pushViewController(controller, animated: true)
        }
    }

    // MARK: - Info

    private func showInfo(title: String, message: String) {
        showAlert(title, body: message)
    }
}
