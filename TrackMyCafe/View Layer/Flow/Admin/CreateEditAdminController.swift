//
//  CreateEditAdminController.swift
//  TrackMyCafe
//
//  Created by Леонід Квіт on 01.07.2024.
//

import UIKit
import FirebaseDatabase
import SVProgressHUD
import Kingfisher

class CreateEditAdminController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UITextViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    let tableView: UITableView = {
        let tableView = UITableView()
        
        //tableView.register(OrdersTableViewCell.self, forCellReuseIdentifier: OrdersTableViewCell.identifier)
        tableView.backgroundColor = UIColor.Main.background
        tableView.separatorStyle = .none
        tableView.translatesAutoresizingMaskIntoConstraints = false

        return tableView
    }()
    
    private var newImage: UIImage?
    private var imageView: UIImageView!
    
    private let admin: Admin
    
    init() {
        admin = RequestManager.shared.admin.copy()
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.Main.background
        title = R.string.global.edit()
        
        //tableView = UITableView(frame: view.bounds, style: .grouped)
        tableView.dataSource = self
        tableView.delegate = self
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveTechnician))
        
        setConstraints()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return 3
        case 2:
            return 2
        case 3:
            return 1
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 1:
            return R.string.global.names()
        case 2:
            return R.string.global.contactInfo()
        case 3:
            return R.string.global.note()
        default:
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            return 150.0
        case (2, 1), (3, 0):
            return 70.0
        default:
            return 44.0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            cell.backgroundColor = UIColor.Main.background
            imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 150))
            imageView.contentMode = .scaleAspectFit
            if let url = admin.avatarThumbnailUrl?.url {
                        imageView.kf.setImage(with: url, placeholder: R.image.profilePlaceholder())
                    } else {
                        imageView.image = R.image.profilePlaceholder()
                    }
            imageView.isUserInteractionEnabled = true
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(changeImage))
            imageView.addGestureRecognizer(tapGesture)
            cell.contentView.addSubview(imageView)
            return cell
        case (1, 0):
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            cell.backgroundColor = UIColor.TableView.cellBackground
            cell.layer.cornerRadius = 10
            let textField = createTextField(placeholder: R.string.global.lastName(), text: admin.lastName)
            textField.tag = 1
            cell.contentView.addSubview(textField)
            return cell
        case (1, 1):
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            cell.backgroundColor = UIColor.TableView.cellBackground
            cell.layer.cornerRadius = 10
            let textField = createTextField(placeholder: R.string.global.firstName(), text: admin.firstName)
            textField.tag = 2
            cell.contentView.addSubview(textField)
            return cell
        case (1, 2):
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            cell.backgroundColor = UIColor.TableView.cellBackground
            cell.layer.cornerRadius = 10
            let textField = createTextField(placeholder: R.string.global.middleName(), text: admin.middleName)
            textField.tag = 3
            cell.contentView.addSubview(textField)
            return cell
        case (2, 0):
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            cell.backgroundColor = UIColor.TableView.cellBackground
            cell.layer.cornerRadius = 10
            let textField = createTextField(placeholder: R.string.global.phone(), text: admin.phone)
            textField.keyboardType = .phonePad
            textField.tag = 4
            cell.contentView.addSubview(textField)
            return cell
        case (2, 1):
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            cell.backgroundColor = UIColor.TableView.cellBackground
            cell.layer.cornerRadius = 10
            let textView = createTextView(placeholder: R.string.global.address(), text: admin.address)
            textView.tag = 5
            cell.contentView.addSubview(textView)
            return cell
        case (3, 0):
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            cell.backgroundColor = UIColor.TableView.cellBackground
            cell.layer.cornerRadius = 10
            let textView = createTextView(placeholder: R.string.global.note(), text: admin.comment)
            textView.tag = 6
            cell.contentView.addSubview(textView)
            return cell
        default:
            return UITableViewCell()
        }
    }
    
    private func createTextField(placeholder: String, text: String?) -> UITextField {
        let textField = UITextField(frame: CGRect(x: 15, y: 0, width: view.bounds.width - 30, height: 44))
        textField.placeholder = placeholder
        textField.text = text
        textField.font = UIFont.systemFont(ofSize: 16)
        textField.textColor = UIColor.Main.text
        textField.delegate = self
        return textField
    }
    
    private func createTextView(placeholder: String, text: String?) -> UITextView {
        let textView = UITextView(frame: CGRect(x: 10, y: 0, width: view.bounds.width - 40, height: 70))
        textView.backgroundColor = UIColor.TableView.cellBackground
        textView.text = text ?? placeholder
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.textColor = text == nil ? UIColor.lightGray : UIColor.Main.text
        textView.delegate = self
        return textView
    }
    
    @objc private func changeImage() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true)
    }
    
    @objc private func saveTechnician() {
        view.endEditing(true)
        guard validate() else { return }
        SVProgressHUD.show()
        
        if let image = newImage {
            let fileName = [admin.firstName, admin.lastName, Date().interval.string].compactMap { $0 }.joined(separator: "_")
            StorageService.uploadAvatar(image, name: fileName) {[weak self] (success, filePath, thumbnailPath) in
                guard let self = self else { return }
                if success {
                    self.newImage = nil
                    self.admin.avatarUrl = filePath
                    self.admin.avatarThumbnailUrl = thumbnailPath
                    RequestManager.shared.log(date: Date(),
                                              object: .technicians,
                                              action: .add,
                                              description: "Uploaded new technician image at \(filePath.emptyIfNil)")
                    self.saveTechnicianToDatabase()
                } else {
                    SVProgressHUD.dismiss()
                    self.showAlert(R.string.global.error(),
                                   body: R.string.global.wentWrong())
                }
            }
        } else {
            saveTechnicianToDatabase()
        }
    }
    
    private func saveTechnicianToDatabase() {
        FirestoreDatabaseService.updateAdmin(admin) {[weak self] (success) in
            guard let self = self else { return }
            if success {
                self.log()
                SVProgressHUD.dismiss()
                self.navigationController?.popViewController(animated: true)
            } else {
                SVProgressHUD.dismiss()
                self.showAlert(R.string.global.error(),
                               body: R.string.global.wentWrong())
            }
        }
    }
    
    private func log() {
        RequestManager.shared.log(date: Date(),
                                  object: .technicians,
                                  action: .update,
                                  description: self.admin.description)
    }
    
    private func validate() -> Bool {
        if admin.firstName.isEmpty {
            showAlert(R.string.global.error(),
                      body: R.string.global.firstNameRequired())
            return false
        }
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        switch textField.tag {
        case 1:
            admin.lastName = textField.text ?? ""
        case 2:
            admin.firstName = textField.text ?? ""
        case 3:
            admin.middleName = textField.text ?? ""
        case 4:
            admin.phone = textField.text ?? ""
        default:
            break
        }
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        switch textView.tag {
        case 5, 6:
            textView.text = nil
            textView.textColor = UIColor.Main.text
        default:
            break
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        switch textView.tag {
        case 5:
            admin.address = textView.text
            if textView.text.isEmpty {
                textView.text = R.string.global.address()
                textView.textColor = UIColor.lightGray
            }
        case 6:
            admin.comment = textView.text
            if textView.text.isEmpty {
                textView.text = R.string.global.note()
                textView.textColor = UIColor.lightGray
            }
        default:
            break
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        if let image = info[.originalImage] as? UIImage {
            newImage = image
            imageView.image = image
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

// MARK: Constraints
extension CreateEditAdminController {
    func setConstraints() {

        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0)
        ])
    }
}
