//
//  TechnicianDetailsController.swift
//  TrackMyCafe Prod
//
//  Created by Леонід Квіт on 15.06.2024.
//

import FirebaseAuth
import MessageUI
import SVProgressHUD
import UIKit

class TechnicianDetailsController: UIViewController {

  private var technician: Technician
  private var fromMod: Bool

  init(_ technician: Technician, fromMod: Bool) {
    self.technician = technician
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
    setupNotifications()
    buildForm()
  }

  private func setupNavigationBar() {
    navigationItem.rightBarButtonItems = [
      UIBarButtonItem(
        image: UIImage(named: "edit"), style: .plain, target: self,
        action: #selector(editTechnician)),
      UIBarButtonItem(
        image: UIImage(named: "delete"), style: .plain, target: self,
        action: #selector(deleteTechnician)),
    ]
  }

  private func setupNotifications() {
    NotificationCenter.default.addObserver(
      self, selector: #selector(updateForm), name: .techniciansInfoReload, object: nil)
  }

  @objc private func updateForm() {
    if let updatedItem = RequestManager.shared.technicians.first(where: {
      $0.firebaseRef == technician.firebaseRef
    }) {
      technician = updatedItem
      removeAllFormSections()
      buildForm()
      reloadForm()
    } else {
      navigationController?.popViewController(animated: true)
    }
  }

  private func removeAllFormSections() {
    // Implement logic to remove all sections from your form UI
  }

  private func reloadForm() {
    // Implement logic to reload your form UI
  }

  private func buildForm() {
    title = [technician.lastName, technician.firstName].compactMap { $0 }.joined(separator: " ")

    let canSendEmail =
      technician.email.isValid(regex: .email)
      && MFMailComposeViewController.canSendMail()

    buildHeaderSection()
    buildContactInfoSection(canSendEmail: canSendEmail)
    buildAllowCalculationSection()
    buildNoteSection()
    buildActionButtonsSection()
    buildResendInviteSection()
  }

  private func buildHeaderSection() {
    let privileges: String
    if self.fromMod {
      privileges =
        technician.role == .techMod
        ? "Has Technician Privilege" : "Does Not Have Technician Privilege"
    } else {
      privileges = technician.role == .techMod ? "Has Mod Privilege" : "Does Not Have Mod Privilege"
    }

    let headerView = UIView()
    headerView.backgroundColor = UIColor.Main.background
    headerView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(headerView)

    let imageView = UIImageView()
    imageView.image = UIImage(named: "avatarPlaceholder")
    imageView.translatesAutoresizingMaskIntoConstraints = false
    headerView.addSubview(imageView)

    NSLayoutConstraint.activate([
      headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      headerView.heightAnchor.constraint(equalToConstant: 200),

      imageView.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
      imageView.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
      imageView.widthAnchor.constraint(equalToConstant: 100),
      imageView.heightAnchor.constraint(equalToConstant: 100),
    ])
  }

  private func buildContactInfoSection(canSendEmail: Bool) {
    let sectionView = UIView()
    sectionView.backgroundColor = UIColor.Main.background
    sectionView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(sectionView)

    let phoneLabel = UILabel()
    phoneLabel.text = R.string.global.phone()
    phoneLabel.translatesAutoresizingMaskIntoConstraints = false
    sectionView.addSubview(phoneLabel)

    let phoneField = UITextField()
    phoneField.placeholder = R.string.global.enterPhoneNumber()
    phoneField.translatesAutoresizingMaskIntoConstraints = false
    sectionView.addSubview(phoneField)

    NSLayoutConstraint.activate([
      sectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 220),
      sectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      sectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      sectionView.heightAnchor.constraint(equalToConstant: 100),

      phoneLabel.topAnchor.constraint(equalTo: sectionView.topAnchor, constant: 20),
      phoneLabel.leadingAnchor.constraint(equalTo: sectionView.leadingAnchor, constant: 20),

      phoneField.topAnchor.constraint(equalTo: phoneLabel.topAnchor, constant: 20),
      phoneField.leadingAnchor.constraint(equalTo: phoneLabel.leadingAnchor, constant: 20),
    ])
  }

  private func buildAllowCalculationSection() {
    guard
      technician.role == .technician || technician.role == .techMod
        || technician.role == .administrator
    else {
      return
    }

    let sectionView = UIView()
    sectionView.backgroundColor = UIColor.Main.background
    sectionView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(sectionView)

    let switchLabel = UILabel()
    switchLabel.text = R.string.global.allowCalculation()
    switchLabel.translatesAutoresizingMaskIntoConstraints = false
    sectionView.addSubview(switchLabel)

    let switchControl = UISwitch()
    switchControl.isOn = true
    switchControl.translatesAutoresizingMaskIntoConstraints = false
    sectionView.addSubview(switchControl)

    NSLayoutConstraint.activate([
      sectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 340),
      sectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      sectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      sectionView.heightAnchor.constraint(equalToConstant: 100),

      switchLabel.topAnchor.constraint(equalTo: sectionView.topAnchor, constant: 20),
      switchLabel.leadingAnchor.constraint(equalTo: sectionView.leadingAnchor, constant: 20),

      switchControl.centerYAnchor.constraint(equalTo: switchLabel.centerYAnchor),
      switchControl.trailingAnchor.constraint(equalTo: sectionView.trailingAnchor, constant: -20),
    ])
  }

  private func buildNoteSection() {
    let sectionView = UIView()
    sectionView.backgroundColor = UIColor.Main.background
    sectionView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(sectionView)

    let noteLabel = UILabel()
    noteLabel.text = R.string.global.note()
    noteLabel.translatesAutoresizingMaskIntoConstraints = false
    sectionView.addSubview(noteLabel)

    let noteTextView = UITextView()
    noteTextView.text = R.string.global.technicianNoteGoesHere()
    noteTextView.translatesAutoresizingMaskIntoConstraints = false
    sectionView.addSubview(noteTextView)

    NSLayoutConstraint.activate([
      sectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 460),
      sectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      sectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      sectionView.heightAnchor.constraint(equalToConstant: 200),

      noteLabel.topAnchor.constraint(equalTo: sectionView.topAnchor, constant: 20),
      noteLabel.leadingAnchor.constraint(equalTo: sectionView.leadingAnchor, constant: 20),

      noteTextView.topAnchor.constraint(equalTo: noteLabel.topAnchor, constant: 20),
      noteTextView.leadingAnchor.constraint(equalTo: noteLabel.leadingAnchor),
      noteTextView.trailingAnchor.constraint(equalTo: sectionView.trailingAnchor, constant: -20),
      noteTextView.bottomAnchor.constraint(equalTo: sectionView.bottomAnchor, constant: -20),
    ])
  }

  private func buildActionButtonsSection() {
    let sectionView = UIView()
    sectionView.backgroundColor = UIColor.Main.background
    sectionView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(sectionView)

    let ordersButton = UIButton()
    ordersButton.setTitle(R.string.global.orders(), for: .normal)
    ordersButton.backgroundColor = .blue
    ordersButton.translatesAutoresizingMaskIntoConstraints = false
    sectionView.addSubview(ordersButton)

    let allOrdersButton = UIButton()
    allOrdersButton.setTitle(R.string.global.allOrders(), for: .normal)
    allOrdersButton.backgroundColor = .blue
    allOrdersButton.translatesAutoresizingMaskIntoConstraints = false
    sectionView.addSubview(allOrdersButton)

    let pricesButton = UIButton()
    pricesButton.setTitle(R.string.global.prices(), for: .normal)
    pricesButton.backgroundColor = .blue
    pricesButton.translatesAutoresizingMaskIntoConstraints = false
    sectionView.addSubview(pricesButton)

    let printButton = UIButton()
    printButton.setTitle(R.string.global.printPrices(), for: .normal)
    printButton.backgroundColor = .blue
    printButton.translatesAutoresizingMaskIntoConstraints = false
    sectionView.addSubview(printButton)

    NSLayoutConstraint.activate([
      sectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 680),
      sectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      sectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      sectionView.heightAnchor.constraint(equalToConstant: 100),

      ordersButton.topAnchor.constraint(equalTo: sectionView.topAnchor, constant: 20),
      ordersButton.leadingAnchor.constraint(equalTo: sectionView.leadingAnchor, constant: 20),

      allOrdersButton.topAnchor.constraint(equalTo: sectionView.topAnchor, constant: 20),
      allOrdersButton.leadingAnchor.constraint(equalTo: ordersButton.trailingAnchor, constant: 20),

      pricesButton.topAnchor.constraint(equalTo: sectionView.topAnchor, constant: 20),
      pricesButton.leadingAnchor.constraint(equalTo: allOrdersButton.trailingAnchor, constant: 20),

      printButton.topAnchor.constraint(equalTo: sectionView.topAnchor, constant: 20),
      printButton.leadingAnchor.constraint(equalTo: pricesButton.trailingAnchor, constant: 20),
    ])
  }

  private func buildResendInviteSection() {
    let sectionView = UIView()
    sectionView.backgroundColor = UIColor.Main.background
    sectionView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(sectionView)

    let resendButton = UIButton()
    resendButton.setTitle(R.string.global.resendInvite(), for: .normal)
    resendButton.backgroundColor = .blue
    resendButton.translatesAutoresizingMaskIntoConstraints = false
    sectionView.addSubview(resendButton)

    NSLayoutConstraint.activate([
      sectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 800),
      sectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      sectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      sectionView.heightAnchor.constraint(equalToConstant: 50),

      resendButton.centerXAnchor.constraint(equalTo: sectionView.centerXAnchor),
      resendButton.centerYAnchor.constraint(equalTo: sectionView.centerYAnchor),
    ])
  }

  // MARK: - Button Actions

  @objc private func editTechnician() {
    let controller = CreateEditTechnicianController(technician, moderType: fromMod)
    navigationController?.pushViewController(controller, animated: true)
  }

  @objc private func deleteTechnician() {
    let deleteItem = self.technician
    showWarning(
      body: R.string.global.areYouSureYouWantToDeleteThisItem(),
      buttonTitle: R.string.global.delete()
    ) { [weak self] in
      FirestoreDatabaseService.deleteTechnician(deleteItem) { (success) in
        if success {
          RequestManager.shared.log(
            date: Date(), object: .technicians, action: .delete, description: deleteItem.description
          )
          self?.navigationController?.popViewController(animated: true)
        } else {
          self?.showAlert(R.string.global.error(), body: R.string.global.somethingWentWrong())
        }
      }
    }
  }

  @objc private func resendInvite() {
    // Implement logic to resend invite
  }

  // MARK: - Navigation

  private func showOrders() {
    //        let controller = TechnicianOrdersListController(technician.firebaseRef)
    //        navigationController?.pushViewController(controller, animated: true)
  }

  private func showAllOrders() {
    //        let controller = TechnicianAllOrdersListController(technician)
    //        navigationController?.pushViewController(controller, animated: true)
  }

  private func showPrices() {
    //        let controller = TechPriceCategoryController(technician.firebaseRef)
    //        navigationController?.pushViewController(controller, animated: true)
  }

  private func printPrices() {
    //        SVProgressHUD.show()
    //        PrintManager.shared.printTechnicianPrices(self.technician.firebaseRef) { [weak self] (pdfURL) in
    //            DispatchQueue.main.async {
    //                SVProgressHUD.dismiss()
    //                guard let url = pdfURL else {
    //                    self?.showAlert("Warning", body: "Something went wrong. Please try again.")
    //                    return
    //                }
    //                let controller = PDFViewController.create(url)
    //                self?.present(controller, animated: true)
    //            }
    //        }
  }
}

extension TechnicianDetailsController: MFMailComposeViewControllerDelegate {

  func mailComposeController(
    _ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult,
    error: Error?
  ) {
    controller.dismiss(animated: true)
  }
}

// Helper Extensions and Functions

extension String {
  func isValid(regex: NSRegularExpression) -> Bool {
    let range = NSRange(location: 0, length: self.utf16.count)
    return regex.firstMatch(in: self, options: [], range: range) != nil
  }
}

extension Optional where Wrapped == String {
  func nilIfEmpty() -> String? {
    return self?.isEmpty ?? true ? nil : self
  }
}

func showAlert(_ title: String, body: String) {
  let alertController = UIAlertController(title: title, message: body, preferredStyle: .alert)
  alertController.addAction(
    UIAlertAction(title: R.string.global.actionOk(), style: .default, handler: nil))
  UIApplication.shared.keyWindow?.rootViewController?.present(
    alertController, animated: true, completion: nil)
}

func showWarning(body: String, buttonTitle: String, action: @escaping () -> Void) {
  let alertController = UIAlertController(
    title: R.string.global.warning(), message: body, preferredStyle: .alert)
  alertController.addAction(
    UIAlertAction(title: R.string.global.cancel(), style: .cancel, handler: nil))
  alertController.addAction(
    UIAlertAction(
      title: buttonTitle, style: .destructive,
      handler: { _ in
        action()
      }))
  UIApplication.shared.keyWindow?.rootViewController?.present(
    alertController, animated: true, completion: nil)
}
