//
//  SaleViewController.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 08.11.2021.
//

import UIKit
import RealmSwift

struct SaleGood {
    let date: Date
    let good: String
    var qty: Int
    var sum: Double
}
//
//struct SaleDate {
//    let date: Date
//    let cash: Double
//    let sum: Double
//}

class SaleViewController: UIViewController {
    
    var forDate = NSDate() as Date
    
    //var salesGoods = [SaleGood]()
    //let cashforDate: Cash
    
    private var salesGoodsModel = SaleGoodModel()
    private var salesDateModel = SalesModel()
    private var salesGoodsArray = [SaleGood]()
    
    let localRealm = try! Realm()
    var saleGood: Results<SaleGoodModel>!
    var saleForDate: Results<SalesModel>!
    
    
    let datePiker: UIDatePicker = {
        let datePiker = UIDatePicker(frame: CGRect(x: 0, y: 70, width: 100, height: 50))
        //datePiker.backgroundColor = .red
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
        //label.backgroundColor = .red
        label.font = UIFont.systemFont(ofSize: 20)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        return label
    }()
    
    let moneyTextfield: UITextField = {
        let textField = UITextField()
        textField.textAlignment = .left
        textField.placeholder = "0"
        //textField.layer.borderWidth = 1
        //textField.text = "0"
        //textField.backgroundColor = .orange
        textField.font = UIFont.systemFont(ofSize: 28)
        textField.translatesAutoresizingMaskIntoConstraints = false
        
        return textField
    }()
    
    let saleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .right
        label.text = "0"
        label.textColor = UIColor.Main.text
        //label.backgroundColor = .green
        label.font = UIFont.systemFont(ofSize: 28)
        label.translatesAutoresizingMaskIntoConstraints = false
        //label.sizeToFit()//If required
        
        return label
    }()
    
    let saveButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Save", for: .normal)
        button.setTitleColor(UIColor.Button.title, for: .normal) 
        button.backgroundColor = UIColor.Button.background
        button.layer.cornerRadius = 10

        button.addTarget(self, action: #selector(saveAction(param:)), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Sale for:"
        view.backgroundColor = UIColor.Main.background
        navigationController?.view.backgroundColor = UIColor.NavBar.background
        
        configure(date: forDate)
        
        setConstraints()
        
    }
    
    func setConstraints() {
        
        let cashStackView = UIStackView(arrangedSubviews: [moneyLabel, moneyTextfield], axis: .horizontal, spacing: 5, distribution: .fillEqually)
        view.addSubview(cashStackView)
        
//        NSLayoutConstraint.activate([
//            cashStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
//            cashStackView.widthAnchor.constraint(equalToConstant: view.frame.width/2),
//            cashStackView.heightAnchor.constraint(equalToConstant: 44),
//        ])
        
        let moneyStackView = UIStackView(arrangedSubviews: [cashStackView, saleLabel], axis: .horizontal, spacing: 10, distribution: .fillEqually)
        view.addSubview(moneyStackView)
        
//        NSLayoutConstraint.activate([
//            moneyStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
//            moneyStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 20),
//            moneyStackView.heightAnchor.constraint(equalToConstant: 44),
//        ])
        
        NSLayoutConstraint.activate([
            saveButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        let mainStackView = UIStackView(arrangedSubviews: [datePiker, tableView, moneyStackView, saveButton], axis: .vertical, spacing: 10, distribution: .fill)
        view.addSubview(mainStackView)
        
        NSLayoutConstraint.activate([
            mainStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            mainStackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            mainStackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            mainStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
        ])
    }
    
    func configure(date: Date) {
        
        datePiker.date = date
        salesGoodsArray = [SaleGood]()
        
        //заполнить продажами за этот день
        let dateStart = Calendar.current.startOfDay(for: date)
        let dateEnd: Date = {
            let components = DateComponents(day: 1, second: -1)
            return Calendar.current.date(byAdding: components, to: dateStart)!
        }()
        
        var predicateDate = NSPredicate(format: "saleDate BETWEEN %@", [dateStart, dateEnd])
        saleGood = localRealm.objects(SaleGoodModel.self).filter(predicateDate).sorted(byKeyPath: "saleGood")
        
        //если данных за этот день нет, значит это новый день,
        //заполнить товарами по-умолчанию
        if saleGood.count == 0 {
            let goodsPrice = localRealm.objects(GoodsPriceModel.self).sorted(byKeyPath: "good")
            for goodPrice in goodsPrice {
                salesGoodsArray.append(SaleGood(date: forDate, good: goodPrice.good, qty: 0, sum: 0.0))
            }
        } else {
            
            for sale in saleGood {
                salesGoodsArray.append(SaleGood(date: sale.saleDate, good: sale.saleGood, qty: sale.saleQty, sum: sale.saleSum))
            }
            
            //
            predicateDate = NSPredicate(format: "salesDate BETWEEN %@", [dateStart, dateEnd])
            saleForDate = localRealm.objects(SalesModel.self).filter(predicateDate)
            
            //также получаем значение "Кеш"
            moneyTextfield.text = String(Int(saleForDate.first?.salesCash ?? 0.0))
            saleLabel.text = String(Int(saleForDate.first?.salesSum ?? 0.0))
        }
        
        tableView.reloadData()
    }
    
    //MARK: - Method
    @objc func saveAction(param: UIButton) {
        //в цикле по таблице нужно записать значения продаж по каждому товару
        for sale in salesGoodsArray {
            salesGoodsModel.saleGood = sale.good
            salesGoodsModel.saleDate = datePiker.date
            salesGoodsModel.saleQty = sale.qty
            salesGoodsModel.saleSum = sale.sum
            
            RealmManager.shared.saveSalesGoodModel(model: salesGoodsModel)
            salesGoodsModel = SaleGoodModel()
        }
        
        //запишем продажи и поступление денег за день
        salesDateModel.salesDate = datePiker.date
        salesDateModel.salesSum = Double(saleLabel.text ?? "0") ?? 0
        salesDateModel.salesCash = Double(moneyTextfield.text ?? "0") ?? 0
        
        RealmManager.shared.saveSalesModel(model: salesDateModel)
        salesDateModel = SalesModel()
        
        navigationController?.popToRootViewController(animated: true)
        
    }
    
    @objc func cancelAction(param: UIButton) {
        navigationController?.popToRootViewController(animated: true)
    }
}

//MARK: - UITableViewDelegate, UITableViewDataSource
extension SaleViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return salesGoodsArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: idSaleCell, for: indexPath) as! SaleTableViewCell
        //cell.configure(sale: salesGoodsArray[indexPath.row])
        
        let stepperValue = salesGoodsArray[indexPath.row]
        cell.goodLabel.text = stepperValue.good
        cell.quantityLabel.text = String(stepperValue.qty)
        cell.goodStepper.value = Double(stepperValue.qty)
        cell.goodStepper.tag = indexPath.row
        cell.goodStepper.addTarget(self, action: #selector(self.stepperValueChanged(_:)), for: .valueChanged)
        
        return cell
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
            salesGoodsArray[stepperTag].qty = stepperValue
            salesGoodsArray[stepperTag].sum = Double(salesGoodsArray[stepperTag].qty * 10)
            recalcSTotalSum()
        }
    }
    
    func recalcSTotalSum() {
        var totalSum: Double = 0.0
        
        for good in salesGoodsArray {
            totalSum = totalSum + good.sum
        }
        
        saleLabel.text = String(totalSum)
    }
}
