//
//  ModeratorListController.swift
//  TrackMyCafe Prod
//
//  Created by Леонід Квіт on 15.06.2024.
//

import UIKit

class ModeratorListController: PersonsListViewController<Employee> {

    private let viewModel = StaffListViewModel(allowedRoles: [.moderator, .techMod])

    override var rightBarButtons: [UIBarButtonItem]? {
        return [
            UIBarButtonItem(
                barButtonSystemItem: .add, target: self, action: #selector(addTechnician(_:)))
        ]
    }

    override var updateNotification: Notification.Name {
        return .employeesInfoReload
    }

    override var items: [Employee] {
        return viewModel.allEmployees
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = R.string.global.staff_sectionSeniorWaiter()
        view.backgroundColor = UIColor.Main.background
    }

    @objc override func reload() {
        viewModel.reload()
        super.reload()
    }

    override func didSelect(item: Employee) {
        let controller = TechnicianDetailsController(item, fromMod: true)
        show(controller, sender: self)
    }

    // MARK: - Actions
    @objc func addTechnician(_ sender: UIBarButtonItem) {
        let controller = CreateEditTechnicianController(moderType: true)
        navigationController?.pushViewController(controller, animated: true)
    }
}
