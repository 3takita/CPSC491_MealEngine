
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
