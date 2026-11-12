import Foundation

enum DashboardPeriod: Int {
    case day = 0
    case week = 1
    case month = 2
}

extension DashboardPeriod {

    /// Reference date shifted one period back (yesterday / previous week / previous month).
    func previousReferenceDate(
        from referenceDate: Date,
        calendar: Calendar = .current
    ) -> Date? {
        switch self {
        case .day:
            return calendar.date(byAdding: .day, value: -1, to: referenceDate)
        case .week:
            return calendar.date(byAdding: .weekOfYear, value: -1, to: referenceDate)
        case .month:
            return calendar.date(byAdding: .month, value: -1, to: referenceDate)
        }
    }

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

    /// Same-length windows for Home delta % (avoids MTD vs full previous month).
    /// Returns exclusive ends (`[start, end)`) suitable for aggregation filters.
    func comparisonIntervals(
        for referenceDate: Date,
        calendar: Calendar = .current
    ) -> (currentStart: Date, currentEnd: Date, previousStart: Date, previousEnd: Date)? {
        let refDay = calendar.startOfDay(for: referenceDate)
        switch self {
        case .day:
            let previousStart = calendar.startOfDay(
                for: previousReferenceDate(from: referenceDate, calendar: calendar) ?? referenceDate
            )
            guard let currentEnd = calendar.date(byAdding: .day, value: 1, to: refDay),
                previousReferenceDate(from: referenceDate, calendar: calendar) != nil,
                let previousEnd = calendar.date(byAdding: .day, value: 1, to: previousStart)
            else { return nil }
            return (refDay, currentEnd, previousStart, previousEnd)

        case .week:
            // Week-to-date vs same number of days in the previous week (not full prior week).
            let currentWeek = interval(for: referenceDate, calendar: calendar)
            guard let previousRef = previousReferenceDate(from: referenceDate, calendar: calendar),
                let currentEnd = calendar.date(byAdding: .day, value: 1, to: refDay)
            else { return nil }
            let previousWeek = interval(for: previousRef, calendar: calendar)
            let daysElapsed =
                (calendar.dateComponents([.day], from: currentWeek.start, to: refDay).day ?? 0) + 1
            guard
                let previousEndDay = calendar.date(
                    byAdding: .day, value: daysElapsed - 1, to: previousWeek.start),
                let previousEnd = calendar.date(byAdding: .day, value: 1, to: previousEndDay)
            else { return nil }
            return (currentWeek.start, currentEnd, previousWeek.start, previousEnd)

        case .month:
            let monthStartComponents = calendar.dateComponents([.year, .month], from: refDay)
            guard let currentStart = calendar.date(from: monthStartComponents),
                let currentEnd = calendar.date(byAdding: .day, value: 1, to: refDay),
                let previousMonthAnchor = calendar.date(byAdding: .month, value: -1, to: currentStart)
            else { return nil }

            let dayOfMonth = calendar.component(.day, from: refDay)
            let prevMonthDays =
                calendar.range(of: .day, in: .month, for: previousMonthAnchor)?.count ?? dayOfMonth
            let clampedDay = min(dayOfMonth, prevMonthDays)
            var prevEndComponents = calendar.dateComponents(
                [.year, .month], from: previousMonthAnchor)
            prevEndComponents.day = clampedDay
            guard let previousEndDay = calendar.date(from: prevEndComponents),
                let previousEnd = calendar.date(byAdding: .day, value: 1, to: previousEndDay)
            else { return nil }

            return (currentStart, currentEnd, previousMonthAnchor, previousEnd)
        }
    }
}
