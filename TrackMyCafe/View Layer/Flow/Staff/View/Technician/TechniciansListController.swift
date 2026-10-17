//
//  TechniciansListController.swift
//  TrackMyCafe Prod
//
//  Created by Леонід Квіт on 15.06.2024.
//

import UIKit

enum TechniciansListControllerState {
    case simple
    // case forCalculation
}

class TechniciansListController: PersonsListViewController<Employee> {

    let currentState: TechniciansListControllerState
    private let viewModel = StaffListViewModel(allowedRoles: [.waiter, .techMod])

    init(state: TechniciansListControllerState = .simple) {
        self.currentState = state
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var rightBarButtons: [UIBarButtonItem]? {
        switch currentState {
        case .simple:
            return [
                UIBarButtonItem(
                    barButtonSystemItem: .add, target: self, action: #selector(addTechnician(_:)))
            ]
        }
    }

    override var updateNotification: Notification.Name {
        return .employeesInfoReload
    }

    override var items: [Employee] {
        switch currentState {
        case .simple:
            return viewModel.allEmployees
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = R.string.global.staff_sectionWaiter()
        view.backgroundColor = UIColor.Main.background
    }

    @objc override func reload() {
        viewModel.reload()
        super.reload()
    }

    override func didSelect(item: Employee) {
        switch currentState {
        case .simple:
            let controller = TechnicianDetailsController(item, fromMod: false)
            show(controller, sender: self)
        }
    }

    // MARK: - Actions
    @objc func addTechnician(_ sender: UIBarButtonItem) {
        let controller = CreateEditTechnicianController(moderType: false)
        navigationController?.pushViewController(controller, animated: true)
    }
}
