import OSLog

extension Logger {
    private static let subsystem = Bundle.main.bundleIdentifier!
    
    static func forClass(_ class: AnyClass) -> Logger {
        return Logger(subsystem: subsystem, category: String(describing: `class`))
    }
    
    static func forType<T>(_ type: T.Type) -> Logger {
        return Logger(subsystem: subsystem, category: String(describing: type))
    }
}