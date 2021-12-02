//
//  AlertLanguage.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 02.12.2021.
//

import UIKit

extension UIViewController {
    
    func alertLanguage(label: UILabel, completionHandle: @escaping (String) -> Void) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let english = UIAlertAction(title: "English", style: .default) { _ in
            label.text = "English"
            let typeContact = "English"
            completionHandle(typeContact)
        }
        
        let russian = UIAlertAction(title: "Русский", style: .default) { _ in
            label.text = "Русский"
            let typeContact = "Русский"
            completionHandle(typeContact)
        }
        
        let ukrainian = UIAlertAction(title: "Українська", style: .default) { _ in
            label.text = "Українська"
            let typeContact = "Українська"
            completionHandle(typeContact)
        }
        
        let cansel = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(english)
        alert.addAction(russian)
        alert.addAction(ukrainian)
        alert.addAction(cansel)
        
        present(alert, animated: true)
        
    }
}
