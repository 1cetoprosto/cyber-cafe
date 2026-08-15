import Foundation

enum DashboardPeriod: Int {
    case day = 0
    case week = 1
    case month = 2
}

extension DashboardPeriod {

    func interval(for referenceDate: Date, calendar: Calendar = .current) -> DateInterval {
        switch self {
        case .day:
            let start = calendar.startOfDay(for: referenceDate)
            guard
                let nextDay = calendar.date(byAdding: .day, value: 1, to: start),
                let end = calendar.date(byAdding: .second, value: -1, to: nextDay)
            else { return DateInterval(start: start, end: start) }
            return DateInterval(start: start, end: end)
        case .week:
            var startComponents = calendar.dateComponents(
                [.yearForWeekOfYear, .weekOfYear], from: referenceDate)
            startComponents.weekday = calendar.firstWeekday
            guard
                let start = calendar.date(from: startComponents),
                let nextWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: start),
                let end = calendar.date(byAdding: .second, value: -1, to: nextWeek)
            else { return DateInterval(start: referenceDate, end: referenceDate) }
            return DateInterval(start: start, end: end)
        case .month:
            let components = calendar.dateComponents([.year, .month], from: referenceDate)
            guard
                let start = calendar.date(from: components),
                let nextMonth = calendar.date(byAdding: .month, value: 1, to: start),
                let end = calendar.date(byAdding: .second, value: -1, to: nextMonth)
            else { return DateInterval(start: referenceDate, end: referenceDate) }
            return DateInterval(start: start, end: end)
        }
    }
}
