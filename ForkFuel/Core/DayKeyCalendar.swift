import Foundation

/// Day keys are `Calendar.startOfDay` in the user's current time zone.
enum DayKeyCalendar {
    static func key(for date: Date, calendar: Calendar = .current) -> Date {
        calendar.startOfDay(for: date)
    }

    static func isSameDay(_ lhs: Date, _ rhs: Date, calendar: Calendar = .current) -> Bool {
        calendar.isDate(lhs, inSameDayAs: rhs)
    }

    static func addingDays(_ days: Int, to dayKey: Date, calendar: Calendar = .current) -> Date {
        let shifted = calendar.date(byAdding: .day, value: days, to: dayKey) ?? dayKey
        return calendar.startOfDay(for: shifted)
    }
}
