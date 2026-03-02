//  CalendarViewModel.swift
//  MealEngine
//
//  Purpose:
//  Manages calendar-based nutrition tracking.
//  Responsible for creating, retrieving, and updating TrackedDay objects.
//
//  High-Level Functional Requirement (HLFR):
//  HLFR-03: The system shall provide a calendar-based history
//  of tracked nutrition and allow daily aggregation of meals.
//

import Foundation

final class CalendarViewModel: ObservableObject {
    @Published var days: [TrackedDay] = []

    func day(for date: Date) -> TrackedDay? {
        days.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }
}
