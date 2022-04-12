//
//  SaleDetailsViewController.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 08.11.2021.
//

import UIKit
//import RealmSwift
//
//struct SaleGood {
//    let date: Date
//    let good: String
//    var qty: Int
//    let price: Double
//    var sum: Double
//    let model: SaleGoodModel
//}

class SaleDetailsViewController: UIViewController, UITextFieldDelegate {
    
    var viewModel: SaleDetailsViewModelType?
    var tableViewModel: SaleGoodListViewModelType?
    
    let datePiker: UIDatePicker = {
        let datePiker = UIDatePicker(frame: CGRect(x: 0, y: 70, width: 100, height: 50))
        datePiker.datePickerMode = .date
        datePiker.contentHorizontalAlignment = .center
        datePiker.preferredDatePickerStyle = .automatic

        return datePiker
    }()

    let idSaleCell = "idSaleCell"
    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(SaleTableViewCell.self, forCellReuseIdentifier: idSaleCell)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = UIColor.Main.background
        tableView.separatorStyle = .none
        
        return tableView
    }()
    
    let moneyLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.text = "Money:"
        label.textColor = UIColor.Main.text
        label.font = UIFont.systemFont(ofSize: 20)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        return label
    }()
    
    let moneyTextfield: UITextField = {
        let textField = UITextField()
        textField.textAlignment = .left
        textField.placeholder = "0"
        textField.font = UIFont.systemFont(ofSize: 28)
        textField.translatesAutoresizingMaskIntoConstraints = false
        
        return textField
    }()
    
    let saleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .right
        label.text = "0"
        label.textColor = UIColor.Main.text
        label.font = UIFont.systemFont(ofSize: 28)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        return label
    }()

    lazy var saveButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Save", for: .normal)
        button.setTitleColor(UIColor.Button.title, for: .normal) 
        button.backgroundColor = UIColor.Button.background
        button.layer.cornerRadius = 10

        button.addTarget(self, action: #selector(saveAction(param:)), for: .touchUpInside)
        return button
    }()
    
//    var forDate = NSDate() as Date
//
//    var salesGoodsModel = SaleGoodModel()
//    var salesDateModel = SalesModel()
//    var newModel: Bool = true
//    private var salesGoodsArray = [SaleGood]()
//
//    let localRealm = try! Realm()
//    var saleGood: Results<SaleGoodModel>!
//    var salesCash: Double = 0.0
//    var salesSum: Double = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Sale for:"
        view.backgroundColor = UIColor.Main.background
        navigationController?.view.backgroundColor = UIColor.NavBar.background

        self.moneyTextfield.delegate = self
        
        //configure(date: forDate)
        setData()
        
        setConstraints()

    }

//    func configure(date: Date) {
//
//        datePiker.date = date
//        salesGoodsArray = [SaleGood]()
//
//        // если данных за этот день нет, значит это новый день,
//        // заполнить товарами по-умолчанию
//        if newModel {
//            let goodsPrice = localRealm.objects(GoodsPriceModel.self).sorted(byKeyPath: "good")
//            for goodPrice in goodsPrice {
//                salesGoodsArray.append(SaleGood(date: forDate,
//                                                good: goodPrice.good,
//                                                qty: 0,
//                                                price: goodPrice.price,
//                                                sum: 0.0,
//                                                model: SaleGoodModel()))
//            }
//        } else {
//            // заполнить продажами за этот день
//            let dateStart = Calendar.current.startOfDay(for: date)
//            let dateEnd: Date = {
//                let components = DateComponents(day: 1, second: -1)
//                return Calendar.current.date(byAdding: components, to: dateStart)!
//            }()
//
//            let predicateDate = NSPredicate(format: "saleDate BETWEEN %@", [dateStart, dateEnd])
//            saleGood = localRealm.objects(SaleGoodModel.self).filter(predicateDate).sorted(byKeyPath: "saleGood")
//
//            for sale in saleGood {
//                salesGoodsArray.append(SaleGood(date: sale.saleDate,
//                                                good: sale.saleGood,
//                                                qty: sale.saleQty,
//                                                price: sale.saleSum/Double(sale.saleQty),
//                                                sum: sale.saleSum,
//                                                model: sale))
//            }
//
//            // также получаем значение "Кеш"
//            moneyTextfield.text = String(salesCash)
//            saleLabel.text = String(salesSum)
//        }
//        tableView.reloadData()
//    }
    
    fileprivate func setData() {
        if viewModel == nil {
            viewModel = SaleDetailsViewModel(sale: SalesModel(), newModel: true)
        }
        
        guard let viewModel = viewModel else { return }
        
        if tableViewModel == nil {
            tableViewModel = SaleGoodListViewModel()
            tableViewModel?.getSaleGoods(date: datePiker.date) {
                self.tableView.reloadData()
            }
        }
        
        if viewModel.salesCash != 0 {
            moneyTextfield.text = viewModel.salesCash.description
        }
        if viewModel.salesSum != 0 {
            saleLabel.text = viewModel.salesSum.description
        }
        
        datePiker.date = viewModel.date
    }

    // MARK: - Method
    @objc func saveAction(param: UIButton) {
        guard let viewModel = self.viewModel else { return }

        if viewModel.newModel {
//            // в цикле по таблице нужно записать значения продаж по каждому товару
//            for sale in salesGoodsArray {
//                salesGoodsModel.saleGood = sale.good
//                salesGoodsModel.saleDate = datePiker.date
//                salesGoodsModel.saleQty = sale.qty
//                salesGoodsModel.saleSum = sale.sum
//
//                DatabaseManager.shared.saveSalesGoodModel(model: salesGoodsModel)
//                salesGoodsModel = SaleGoodModel()
//            }
            guard let tableViewModel = self.tableViewModel else { return }
            //for sale in tableViewModel.saleGoods {
            tableViewModel.saveSalesGood()
            //}

            // запишем продажи и поступление денег за день
            viewModel.saveSales(date: datePiker.date, salesCash: moneyTextfield.text, salesSum: saleLabel.text)
//            salesDateModel.salesDate = datePiker.date
//            salesDateModel.salesSum = salesSum
//            salesDateModel.salesCash = salesCash

            //DatabaseManager.shared.saveSalesModel(model: salesDateModel)
            //salesDateModel = SalesModel()
        } else {
//            for sale in salesGoodsArray {
//                DatabaseManager.shared.updateSaleGoodModel(model: sale.model,
//                                                        saleDate: datePiker.date,
//                                                        saleGood: sale.good,
//                                                        saleQty: sale.qty,
//                                                        saleSum: sale.sum)
//            }
            viewModel.updateSales(date: datePiker.date,
                                   salesCash: moneyTextfield.text,
                                   salesSum: saleLabel.text)
//            DatabaseManager.shared.updateSalesModel(model: salesDateModel,
//                                                 salesDate: date,
//                                                 salesSum: salesSum,
//                                                 salesCash: salesCash)
        }
        navigationController?.popToRootViewController(animated: true)
    }

    @objc func cancelAction(param: UIButton) {
        navigationController?.popToRootViewController(animated: true)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension SaleDetailsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let tableViewModel = tableViewModel else { return 0 }
        return tableViewModel.numberOfRowInSection(for: section)//salesGoodsArray.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: idSaleCell, for: indexPath) as? SaleTableViewCell

//
//        cell.goodLabel.text = stepperValue.good
//        cell.quantityLabel.text = String(stepperValue.qty)
        
//
//        return cell
        
        guard let tableViewCell = cell,
        let tableViewModel = tableViewModel else { return UITableViewCell() }
        
        let cellViewModel = tableViewModel.cellViewModel(for: indexPath)

        tableViewCell.viewModel = cellViewModel
        
        //let stepperValue = tableViewModel.getQuantity()
//        tableViewCell.goodStepper.value = cellViewModel?.goodStepperValue ?? 0.0 //stepperValue
//        tableViewCell.goodStepper.tag = cellViewModel?.goodStepperTag ?? 0 //indexPath.row
        tableViewCell.goodStepper.addTarget(self, action: #selector(self.stepperValueChanged(_:)), for: .valueChanged)
        
        return tableViewCell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }

    // handle stepper value change action
    @objc func stepperValueChanged(_ stepper: UIStepper) {

        let stepperValue = Int(stepper.value)
        let stepperTag = Int(stepper.tag)

        let indexPath = IndexPath(row: stepperTag, section: 0)
        if let cell = tableView.cellForRow(at: indexPath) as? SaleTableViewCell {
            cell.quantityLabel.text = String(stepperValue)
//            salesGoodsArray[stepperTag].qty = stepperValue
//            salesGoodsArray[stepperTag].sum = Double(salesGoodsArray[stepperTag].qty)*salesGoodsArray[stepperTag].price
            tableViewModel?.setQuantity(tag: stepperTag, quantity: stepperValue)
            //recalcsTotalSum()
        }
        saleLabel.text = tableViewModel?.totalSum()
    }

//    func recalcsTotalSum() {
//        var totalSum: Double = 0.0
//
//        for good in tableViewModel. {
//            totalSum += good.sum
//        }
//
//        saleLabel.text = String(totalSum)
//    }
}

// MARK: - Constraints
extension SaleDetailsViewController {
    func setConstraints() {

        let cashStackView = UIStackView(arrangedSubviews: [moneyLabel, moneyTextfield],
                                        axis: .horizontal,
                                        spacing: 5,
                                        distribution: .fillEqually)
        view.addSubview(cashStackView)

        let moneyStackView = UIStackView(arrangedSubviews: [cashStackView, saleLabel],
                                         axis: .horizontal,
                                         spacing: 10,
                                         distribution: .fillEqually)
        view.addSubview(moneyStackView)

        NSLayoutConstraint.activate([
            saveButton.heightAnchor.constraint(equalToConstant: 50)
        ])

        let mainStackView = UIStackView(arrangedSubviews: [datePiker, tableView, moneyStackView, saveButton],
                                        axis: .vertical,
                                        spacing: 10,
                                        distribution: .fill)
        view.addSubview(mainStackView)

        NSLayoutConstraint.activate([
            mainStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            mainStackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            mainStackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            mainStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }
}
