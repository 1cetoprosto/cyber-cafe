//
//  AdminDetailsController.swift
//  TrackMyCafe
//
//  Created by Леонід Квіт on 01.07.2024.
//

import UIKit
import MessageUI
import SVProgressHUD

class AdminDetailsController: UIViewController, UITableViewDataSource, UITableViewDelegate, MFMailComposeViewControllerDelegate {
    
    private var tableView: UITableView!
    private var admin: Admin {
        return RequestManager.shared.admin
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavigationBar()
        setupTableView()
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateForm), name: .adminInfoReload, object: nil)
        
        updateForm()
    }
    
    private func setupNavigationBar() {
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(image: R.image.edit()!, style: .plain, target: self, action: #selector(editTechnician)),
        ]
    }
    
    private func setupTableView() {
        tableView = UITableView(frame: view.bounds, style: .grouped)
        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)
    }
    
    @objc private func updateForm() {
        tableView.reloadData()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return 3
        case 2:
            return 1
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return nil
        case 1:
            return R.string.global.contactInfo()
        case 2:
            return R.string.global.note()
        default:
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case 2:
            return nil
        default:
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
            cell.textLabel?.text = admin.fullName
            cell.detailTextLabel?.text = R.string.global.adminPrivilege()
            // Load image from admin.avatarThumbnailUrl if needed
            return cell
        case (1, 0):
            let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
            cell.textLabel?.text = R.string.global.phone()
            cell.detailTextLabel?.text = admin.phone ?? R.string.global.noSpecified()
            if let phone = admin.phone, !phone.isEmpty {
                cell.accessoryView = UIImageView(image: R.image.call())
                cell.selectionStyle = .default
            } else {
                cell.selectionStyle = .none
            }
            return cell
        case (1, 1):
            let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
            cell.textLabel?.text = R.string.global.email()
            cell.detailTextLabel?.text = admin.email
            if admin.email.isValid(regex: .email) && MFMailComposeViewController.canSendMail() {
                cell.accessoryView = UIImageView(image: R.image.mail())
                cell.selectionStyle = .default
            } else {
                cell.selectionStyle = .none
            }
            return cell
        case (1, 2):
            let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
            cell.textLabel?.text = R.string.global.address()
            cell.detailTextLabel?.text = admin.address?.nilIfEmpty ?? R.string.global.noSpecified()
            cell.selectionStyle = .none
            return cell
        case (2, 0):
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            cell.textLabel?.text = admin.comment?.nilIfEmpty ?? R.string.global.noSpecified()
            cell.selectionStyle = .none
            return cell
        default:
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch (indexPath.section, indexPath.row) {
        case (1, 0):
            call()
        case (1, 1):
            sendMail()
        default:
            break
        }
    }
    
    func call() {
        // TODO: розібратись як реалізувати дзвінок, якщо це потрібно
        //admin.phone?.makeACall()
    }
    
    func sendMail() {
        let mail = MFMailComposeViewController()
        mail.mailComposeDelegate = self
        mail.setToRecipients([admin.email])
        present(mail, animated: true)
    }
    
    @objc private func editTechnician() {
        let controller = CreateEditAdminController()
        navigationController?.pushViewController(controller, animated: true)
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
}
