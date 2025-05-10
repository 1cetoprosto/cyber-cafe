//
//  Log.swift
//  TrackMyCafe Prod
//
//  Created by Леонід Квіт on 15.06.2024.
//

import Foundation

enum ActionType: String {
    case add = "Add New"
    case update = "Update"
    case delete = "Delete"
    case system = "System action"
    case none = "No action"
}

class Log {
    
    var timestamp: Date
    var firebaseRef: String?
    var description: String
    var object: Refs // doctor, caster, etc
    var objectRef: String? // ref to object
    var action: ActionType
    
    init(date: Date, object: Refs, action: ActionType, description: String) {
        self.timestamp = date
        self.object = object
        self.action = action
        self.description = description
        self.objectRef = ""
        self.firebaseRef = ""
    }
}

extension Log {
    func logEntry() -> String {
        let additionalInfo = ", (object Id: \(objectRef!), log Id: \(firebaseRef!).\n\n"
        return "Date: " + timestamp.asString(showTime: true) + ", action: " + action.rawValue + ", for object: " + object.rawValue + ", description: " + description + additionalInfo
    }
}

