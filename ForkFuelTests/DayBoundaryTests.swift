import XCTest
@testable import ForkFuel

final class DayBoundaryTests: XCTestCase {
    func testStartOfDayStableAcrossUSSpringForward() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York") ?? .gmt
        let before = calendar.date(from: DateComponents(year: 2026, month: 3, day: 8, hour: 1, minute: 30)) ?? Date()
        let after = calendar.date(from: DateComponents(year: 2026, month: 3, day: 8, hour: 4, minute: 15)) ?? Date()
        let keyBefore = DayKeyCalendar.key(for: before, calendar: calendar)
        let keyAfter = DayKeyCalendar.key(for: after, calendar: calendar)
        XCTAssertTrue(DayKeyCalendar.isSameDay(keyBefore, keyAfter, calendar: calendar))
        XCTAssertEqual(calendar.component(.hour, from: keyBefore), 0)
        XCTAssertEqual(calendar.component(.hour, from: keyAfter), 0)
        let next = DayKeyCalendar.addingDays(1, to: keyBefore, calendar: calendar)
        XCTAssertFalse(DayKeyCalendar.isSameDay(keyBefore, next, calendar: calendar))
    }
}
