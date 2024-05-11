//
//  Bundle+Extension.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 06.05.2024.
//

import Foundation

extension Bundle {
    
    static var displayName: String {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as! String
    }
    
    static var documentDirectoryURL: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    static var documentDirectory: String {
        return documentDirectoryURL.absoluteString
    }
}

