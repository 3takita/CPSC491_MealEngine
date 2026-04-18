// Purpose: Displays historical tracking data, allowing the user to review previous.
// HLFR: The system shall allow users to review past nutrition history 

import SwiftUI

struct HistoryView: View {
    @ObservedObject var vm: MealPlannerViewModel

    @State private var monthAnchor = Date()
    @State private var selectedDay: Date? = nil
    @State private var showDetail = false

    private let cols = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.bottom, 8)
            
            weekdayRow
                .padding(.bottom, 4)

            LazyVGrid(columns: cols, spacing: 8) {
                ForEach(daysGrid(for: monthAnchor), id: \.self) { date in
                    if let date {
                        Button {
                            selectedDay = date
                            showDetail = true
                        } label: {
                            GoalCalendarDayCell(
                                date: date,
                                progress: progress(for: date)
                            )
                        }
                        .buttonStyle(.plain)
                    } else {
                        Color.clear.frame(width: 44, height: 44)
                    }
                }
            }
            .padding(.horizontal, 6)
            .padding(.bottom, 8)

            // Summary stats for selected month
            monthSummary
                .padding(.top, 4)

            Spacer()
        }
        .padding(.top, 0)
        .background(Theme.surface.ignoresSafeArea())
        .sheet(isPresented: $showDetail) {
            if let day = selectedDay {
                DayDetailView(vm: vm, date: day, progress: progress(for: day))
                    .presentationDetents([.height(360), .medium, .large])
            }
        }
        .navigationTitle("History")
    }

    // MARK: - Header & Weekdays

    private var header: some View {
        HStack {
            Button(action: {
                monthAnchor = Calendar.current.date(byAdding: .month, value: -1, to: monthAnchor)!
            }) {
                Image(systemName: "chevron.left")
            }

            Spacer()

            Text(monthAnchor, format: .dateTime.year().month(.wide))
                .font(.headline)
                .foregroundColor(Theme.textPrimary)

            Spacer()

            Button(action: {
                monthAnchor = Calendar.current.date(byAdding: .month, value: 1, to: monthAnchor)!
            }) {
                Image(systemName: "chevron.right")
            }
        }
        .foregroundColor(Theme.textPrimary)
        .padding(.horizontal)
    }

    private var weekdayRow: some View {
        let symbols = Calendar.current.shortWeekdaySymbols
        return HStack {
            ForEach(symbols, id: \.self) { s in
                Text(s.prefix(2))
                    .font(.caption).bold()
                    .foregroundColor(Theme.textSecondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 8)
    }

    // MARK: - Month Summary

    private var monthSummary: some View {
        let stats = calculateMonthStats()
        
        return VStack(spacing: 12) {
            Divider()
                .padding(.vertical, 8)
            
            Text("This Month")
                .font(.headline)
                .foregroundColor(Theme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            
            HStack(spacing: 16) {
                statCard(
                    title: "Days Tracked",
                    value: "\(stats.daysTracked)",
                    icon: "calendar.circle.fill",
                    color: Theme.primary
                )
                
                statCard(
                    title: "Avg. Progress",
                    value: "\(Int(stats.avgProgress * 100))%",
                    icon: "chart.line.uptrend.xyaxis.circle.fill",
                    color: Theme.success
                )
            }
            .padding(.horizontal)
            
            HStack(spacing: 16) {
                statCard(
                    title: "Goal Days",
                    value: "\(stats.goalDays)",
                    icon: "star.circle.fill",
                    color: Theme.warning
                )
                
                statCard(
                    title: "Streak",
                    value: "\(stats.streak)",
                    icon: "flame.circle.fill",
                    color: Theme.accent
                )
            }
            .padding(.horizontal)
        }
    }

    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .bold()
                .foregroundColor(Theme.textPrimary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Theme.surface)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Data hooks

    private func progress(for date: Date) -> Double {
        // For today, use current progress
        if Calendar.current.isDateInToday(date) {
            let goal = max(vm.goals.calories, 1)
            return min(vm.currentCalories / goal, 1)
        }
        
        // For past days, look up tracked data
        if let trackedDay = vm.getTrackedDay(for: date) {
            return trackedDay.progress
        }
        
        return 0
    }

    private func daysGrid(for anchor: Date) -> [Date?] {
        let cal = Calendar.current
        let start = cal.date(from: cal.dateComponents([.year, .month], from: anchor))!
        let range = cal.range(of: .day, in: .month, for: start)!
        let firstWeekday = cal.component(.weekday, from: start)
        let leading = (firstWeekday - cal.firstWeekday + 7) % 7

        var cells: [Date?] = Array(repeating: nil, count: leading)
        for day in range {
            cells.append(cal.date(byAdding: .day, value: day - 1, to: start)!)
        }
        while cells.count % 7 != 0 { cells.append(nil) }
        return cells
    }

    // MARK: - Statistics Calculation

    private func calculateMonthStats() -> MonthStats {
        let cal = Calendar.current
        let start = cal.date(from: cal.dateComponents([.year, .month], from: monthAnchor))!
        let range = cal.range(of: .day, in: .month, for: start)!
        
        var daysTracked = 0
        var totalProgress = 0.0
        var goalDays = 0
        var currentStreak = 0
        var maxStreak = 0
        
        for day in range {
            guard let date = cal.date(byAdding: .day, value: day - 1, to: start),
                  date <= Date() else { continue }
            
            if let trackedDay = vm.getTrackedDay(for: date) {
                daysTracked += 1
                totalProgress += trackedDay.progress
                
                if trackedDay.progress >= 0.9 {
                    goalDays += 1
                    currentStreak += 1
                    maxStreak = max(maxStreak, currentStreak)
                } else {
                    currentStreak = 0
                }
            } else {
                currentStreak = 0
            }
        }
        
        let avgProgress = daysTracked > 0 ? totalProgress / Double(daysTracked) : 0
        
        return MonthStats(
            daysTracked: daysTracked,
            avgProgress: avgProgress,
            goalDays: goalDays,
            streak: maxStreak
        )
    }
}

// MARK: - Supporting Types

private struct MonthStats {
    let daysTracked: Int
    let avgProgress: Double
    let goalDays: Int
    let streak: Int
}

#Preview {
    NavigationStack {
        HistoryView(vm: MealPlannerViewModel())
            .preferredColorScheme(.light)
    }
}
