import SwiftUI

struct MacroDonut: View {
    let proteinKcal: Double
    let carbsKcal: Double
    let fatKcal: Double

    // Optional: customize colors if you want
    var proteinColor: Color = Theme.success
    var carbsColor: Color   = Theme.primary
    var fatColor: Color     = Theme.warning

    private var total: Double {
        let t = proteinKcal + carbsKcal + fatKcal
        return t > 0 ? t : 0.0001
    }

    var body: some View {
        GeometryReader { geo in
            let size   = min(geo.size.width, geo.size.height)
            let radius = size / 2
            let line: CGFloat = 18
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)

            let a0 = -90.0
            let a1 = a0 + (proteinKcal / total) * 360
            let a2 = a1 + (carbsKcal   / total) * 360
            let a3 = 270.0 // completes the circle

            ZStack {
                DonutArc(center: center, radius: radius, startDeg: a0, endDeg: a1)
                    .stroke(proteinColor, lineWidth: line)
                DonutArc(center: center, radius: radius, startDeg: a1, endDeg: a2)
                    .stroke(carbsColor,   lineWidth: line)
                DonutArc(center: center, radius: radius, startDeg: a2, endDeg: a3)
                    .stroke(fatColor,     lineWidth: line)
            }
            .frame(width: size, height: size)
        }
    }
}

private struct DonutArc: Shape {
    let center: CGPoint
    let radius: CGFloat
    let startDeg: Double
    let endDeg: Double

    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.addArc(center: center,
                 radius: radius,
                 startAngle: .degrees(startDeg),
                 endAngle: .degrees(endDeg),
                 clockwise: false)
        return p
    }
}
