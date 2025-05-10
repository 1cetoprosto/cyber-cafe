//
//  AppLogger.swift
//  TrackMyCafe
//
//  Created by Леонід Квіт on 10.02.2025.
//

import Foundation
import os.log

public protocol Loggable {
    var logger: AppLogger { get }
}

extension Loggable {
    var logger: AppLogger {
        AppLogger(category: String(describing: type(of: self)))
    }
    static var logger: AppLogger {
        AppLogger(category: String(describing: Self.self))
    }
}

public struct AppLogger {
    private let logger: Logger
    
    public init(category: String) {
        self.logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: category)
    }
    
    public static func forType(_ type: Any.Type) -> AppLogger {
        AppLogger(category: String(describing: type))
    }
    
    public func debug(_ message: String, privacy: OSLogPrivacy = .public) {
        logger.debug("\(message)")
    }
    
    public func info(_ message: String, privacy: OSLogPrivacy = .public) {
        logger.info("\(message)")
    }
    
    public func notice(_ message: String, privacy: OSLogPrivacy = .public) {
        logger.notice("\(message)")
    }
    
    public func error(_ message: String, privacy: OSLogPrivacy = .public) {
        logger.error("\(message)")
    }
}
