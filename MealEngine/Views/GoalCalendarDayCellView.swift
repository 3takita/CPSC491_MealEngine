//  ContentView.swift
//  NutriPlanner -- Meals optimized for your goals
//  Features: knapsack algorithm, Nutrionix API
//  Required: 3 data types (string, double, bool. Food), 3 screens, 3 colors, 3 GUI objects (8-9 core UI elements)
//  ...and persistent data storage
//  ==================
//  Group Members: 
//  ------------------
//  1.	Stephen Anaba as Code Keeper
//  2.	Liam Knight as Presenter
//  3.  Jane Lin as API Lead
//  4.  Curtis Quan-Tran as Data Lead
//  5.  Angel Orduna as GUI Lead 
//  ====================

import SwiftUI

struct GoalCalendarDayCell: View {
    let date: Date
    let progress: Double   // 0...1 for the day
    private var percent: Int { Int(round(progress * 100)) }

    private var ringColor: Color {
        switch progress {
        case ..<0.60: return Theme.textSecondary
        case ..<1.00: return Theme.primary
        default:      return Theme.success
        }
    }

    var body: some View {
        ZStack {
            Circle().stroke(Theme.textSecondary.opacity(0.15), lineWidth: 6)
            Circle()
                .trim(from: 0, to: CGFloat(min(progress, 1)))
                .stroke(ringColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))

            Text("\(percent)%")
                .font(.caption).bold()
                .monospacedDigit()
                .foregroundColor(Theme.textPrimary)
                .lineLimit(1).minimumScaleFactor(0.7)
        }
        .frame(width: 44, height: 44)
        .contentShape(Circle())
    }
}

#Preview {
    GoalCalendarDayCell(date: .now, progress: 0.72)
        .padding()
        .background(Theme.surface)
        .preferredColorScheme(.dark)
}
