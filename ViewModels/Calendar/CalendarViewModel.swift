// PURPOSE: Handles the logic for displaying historical nutrition data in a calendar format.
// FR: The system shall allow users to review historical nutrition progress.

import Foundation

final class CalendarViewModel: ObservableObject {
    @Published var days: [TrackedDay] = []

    func day(for date: Date) -> TrackedDay? {
        days.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }
}
