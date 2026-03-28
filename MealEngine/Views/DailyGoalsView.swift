// DailyGoalsView.swift
// ====================
// Functional Requirement:- Display goal values
// Non-functional Requirement:- Provide Progress visualization

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Daily Goals screen
struct DailyGoalsView: View {
    @ObservedObject var vm: MealPlannerViewModel

    // Pop share options
    @State private var isShowingShareOptions = false

    // Map metric → themed color
    private let ringColor: [String: Color] = [
        "Calories": Theme.primary,
        "Protein":  Theme.success,
        "Fat":      Theme.warning,
        "Carbs":    Theme.accent
    ]

    // Number formatter reused by text fields
    private var numberFormatter: NumberFormatter {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        return f
    }

    // Macro calories
    private var proteinKcal: Double { max(0, vm.currentProtein) * 4 }
    private var carbsKcal:   Double { max(0, vm.currentCarbs)   * 4 }
    private var fatKcal:     Double { max(0, vm.currentFat)     * 9 }
    private var macroTotal:  Double {
        let t = proteinKcal + carbsKcal + fatKcal
        return t > 0 ? t : 0.0001
    }

    // Calories bar -ISSUE- a double value can be higher than a possible int value, avoid nuclear holocaust by using floats instead -FIXED-
    private var calGoal: Double { max(vm.goals.calories, 1) }
    private var calUsed: Double { min(max(vm.currentCalories, 0), calGoal) }
    private var calRemain: Double { max(calGoal - vm.currentCalories, 0) }

    // MARK: - Share content
    private var shareMessage: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let dateString = formatter.string(from: Date())

        let calPercent = Int(round(vm.currentCalories / max(vm.goals.calories, 1) * 100))
        let proteinPercent = Int(round(vm.currentProtein / max(vm.goals.protein, 1) * 100))
        let carbsPercent = Int(round(vm.currentCarbs / max(vm.goals.carbs, 1) * 100))
        let fatPercent = Int(round(vm.currentFat / max(vm.goals.fat, 1) * 100))

        return """
        🥗 OptiMeal – Daily Goals (\(dateString))

        Calories: \(Int(vm.currentCalories)) / \(Int(vm.goals.calories)) kcal (\(calPercent)%)
        Protein:  \(Int(vm.currentProtein))g / \(Int(vm.goals.protein))g (\(proteinPercent)%)
        Carbs:    \(Int(vm.currentCarbs))g / \(Int(vm.goals.carbs))g (\(carbsPercent)%)
        Fat:      \(Int(vm.currentFat))g / \(Int(vm.goals.fat))g (\(fatPercent)%)

        Join me and track your daily goals too! 💪
        """
    }

    // Share link
    private var shareLinkString: String {
        "https://optimeal.app/share/today" // TODO: if we have our own link, we can switch it
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Today’s Goals")
                    .font(.title).fontWeight(.bold)
                    .padding(.top, 8)
                    .foregroundColor(Theme.textPrimary)
                    .background(Theme.surface.ignoresSafeArea())

                // Metric rings (2 columns)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ringCard(title: "Calories", value: $vm.currentCalories, goal: vm.goals.calories, unit: "kcal", color: ringColor["Calories"]!)
                    ringCard(title: "Protein",  value: $vm.currentProtein,  goal: vm.goals.protein,  unit: "g",    color: ringColor["Protein"]!)
                    ringCard(title: "Fat",      value: $vm.currentFat,      goal: vm.goals.fat,      unit: "g",    color: ringColor["Fat"]!)
                    ringCard(title: "Carbs",    value: $vm.currentCarbs,    goal: vm.goals.carbs,    unit: "g",    color: ringColor["Carbs"]!)
                }
                .padding(.horizontal, 4)

                // Macro donut (calorie split)
                VStack(alignment: .leading, spacing: 12) {
                    Text("Macro Split (kcal)")
                        .font(.headline)
                        .foregroundColor(Theme.textPrimary)

                    MacroDonut(proteinKcal: proteinKcal, carbsKcal: carbsKcal, fatKcal: fatKcal)
                        .frame(height: 160)

                    HStack(spacing: 16) {
                        legend(color: Theme.success, text: "Protein \(doubleToInt(dub: proteinKcal))")
                        legend(color: Theme.primary, text: "Carbs \(doubleToInt(dub: carbsKcal))")
                        legend(color: Theme.warning, text: "Fat \(doubleToInt(dub: fatKcal))")
                    }
                    .font(.caption)
                }
                .cardBackground()

                // Calories progress bar
                VStack(alignment: .leading, spacing: 10) {
                    Text("Calories Progress")
                        .font(.headline)
                        .foregroundColor(Theme.textPrimary)

                    CaloriesBar(used: calUsed, total: calGoal)
                        .frame(height: 18)
                        .clipShape(Capsule())

                    HStack {
                        Text("Eaten: \(doubleToInt(dub: vm.currentCalories)) kcal")
                            .foregroundColor(Theme.textPrimary)
                        Spacer()
                        Text("Remaining: \(doubleToInt(dub: calRemain)) kcal")
                            .foregroundColor(calRemain > 0 ? Theme.textSecondary : Theme.accent)
                    }
                    .font(.subheadline)
                }
                .cardBackground()

                // Quick edits
                VStack(alignment: .leading, spacing: 12) {
                    Text("Quick Edit")
                        .font(.headline)
                        .foregroundColor(Theme.textPrimary)
                    trackingRow(title: "Calories", value: $vm.currentCalories, goal: vm.goals.calories, unit: "kcal")
                    trackingRow(title: "Protein",  value: $vm.currentProtein,  goal: vm.goals.protein,  unit: "g")
                    trackingRow(title: "Fat",      value: $vm.currentFat,      goal: vm.goals.fat,      unit: "g")
                    trackingRow(title: "Carbs",    value: $vm.currentCarbs,    goal: vm.goals.carbs,    unit: "g")
                }
                .cardBackground()

                // Goal editing
                VStack(alignment: .leading, spacing: 12) {
                    Text("Adjust Goals")
                        .font(.headline)
                        .foregroundColor(Theme.textPrimary)
                    goalField(title: "Calories", value: $vm.goals.calories)
                    goalField(title: "Protein",  value: $vm.goals.protein)
                    goalField(title: "Fat",      value: $vm.goals.fat)
                    goalField(title: "Carbs",    value: $vm.goals.carbs)
                }
                .cardBackground()

                // MARK: Sharecard button
                shareCTASection

                Spacer(minLength: 8)
            }
            .padding()
            .background(Theme.surface.ignoresSafeArea())
        }
        .navigationTitle("Daily Goals")
        .background(Theme.surface.ignoresSafeArea())
        .toolbar {
        // Share toolbarItem
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: quickShare) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(Theme.primary)
                }
            }
        }
        .confirmationDialog(
            "Share today's progress",
            isPresented: $isShowingShareOptions,
            titleVisibility: .visible
        ) {
            Button("Share to apps & contacts") {
                quickShare()
            }
            Button("Copy share link") {
                copyShareLink()
            }
            Button("Cancel", role: .cancel) {}
        }
        .onTapGesture { hideKeyboard() }
    }
    // MARK: - Share CTA Section
    private var shareCTASection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Share your day 🥗")
                .font(.headline)
                .foregroundColor(Theme.textPrimary)

            Text("Stay accountable by sharing today's goals with a friend or on social media.")
                .font(.caption)
                .foregroundColor(Theme.textSecondary)

            Button {
                isShowingShareOptions = true
            } label: {
                HStack {
                    Image(systemName: "leaf.fill")
                        .imageScale(.medium)
                    Text("Share today’s progress")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Image(systemName: "chevron.up")
                        .font(.footnote.weight(.bold))
                        .opacity(0.9)
                }
                .foregroundColor(.white)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(
                    LinearGradient(
                        colors: [Theme.primary, Theme.accent],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: Theme.primary.opacity(0.35), radius: 8, y: 4)
            }
        }
        .cardBackground()
    }

    // MARK: - Share Functions

    /// System share to contacts, social media or different apps
    private func quickShare() {
        let text = shareMessage

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootVC = window.rootViewController else {
            return
        }

        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            topVC = presented
        }

        let activityVC = UIActivityViewController(
            activityItems: [text],
            applicationActivities: nil
        )

        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = topVC.view
            popover.sourceRect = topVC.view.bounds
        }

        topVC.present(activityVC, animated: true)
    }

    /// Copy link
    private func copyShareLink() {
        #if canImport(UIKit)
        UIPasteboard.general.string = shareLinkString

        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        #endif
    }

    // MARK: - Reused pieces

    private func ringCard(
        title: String,
        value: Binding<Double>,
        goal: Double,
        unit: String,
        color: Color
    ) -> some View {
        let safeGoal = max(goal, 1)
        let progress = max(0, min(value.wrappedValue / safeGoal, 1))

        return VStack(spacing: 10) {
            RingProgress(progress: progress, color: color) {
                VStack(spacing: 2) {
                    Text("\(Int(min(value.wrappedValue, safeGoal))) / \(Int(safeGoal))")
                        .font(.subheadline).bold()
                        .foregroundColor(Theme.textPrimary)
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                }
            }
            .frame(height: 120)

            Text(title)
                .font(.headline)
                .foregroundColor(Theme.textPrimary)

            HStack(spacing: 8) {
                TextField("0", value: value, formatter: numberFormatter)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.decimalPad)
                    .frame(width: 90)
                Text(unit)
                    .foregroundColor(Theme.textSecondary)
                Spacer()
            }
        }
        .cardBackground()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title) progress")
        .accessibilityValue("\(Int(round(progress * 100))) percent")
    }

    private func trackingRow(title: String, value: Binding<Double>, goal: Double, unit: String) -> some View {
        let safeGoal = max(goal, 1)
        let p = max(0, min(value.wrappedValue / safeGoal, 1))
        let tint = ringColor[title] ?? Theme.primary

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(title):")
                    .foregroundColor(Theme.textPrimary)
                TextField("0", value: value, formatter: numberFormatter)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.decimalPad)
                    .frame(width: 90)
                Text("/ \(Int(safeGoal)) \(unit)")
                    .foregroundColor(Theme.textSecondary)
                Spacer()
                Text("\(Int(round(p * 100)))%")
                    .foregroundColor(Theme.textSecondary)
                    .font(.subheadline)
            }
            ProgressView(value: p)
                .tint(tint)
        }
    }

    private func goalField(title: String, value: Binding<Double>) -> some View {
        HStack {
            Text("\(title):")
                .foregroundColor(Theme.textPrimary)
            TextField("Enter", value: value, formatter: numberFormatter)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.decimalPad)
        }
    }

    private func legend(color: Color, text: String) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 10, height: 10)
            Text(text).foregroundColor(Theme.textPrimary)
        }
    }
}

// MARK: - Ring progress
private struct RingProgress<Center: View>: View {
    let progress: Double   // 0...1
    let color: Color
    @ViewBuilder var center: () -> Center

    var body: some View {
        ZStack {
            Circle().stroke(Theme.textSecondary.opacity(0.25), lineWidth: 12)
            Circle()
                .trim(from: 0, to: CGFloat(max(0, min(progress, 1))))
                .stroke(color, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.35), value: progress)
            center()
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

// MARK: - Calories Bar
private struct CaloriesBar: View {
    let used: Double
    let total: Double

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let progress = max(0, min(used / max(total, 1), 1))
            let usedW = width * CGFloat(progress)

            ZStack(alignment: .leading) {
                Capsule().fill(Theme.textSecondary.opacity(0.12))
                Capsule().fill(Theme.primary.opacity(0.85))
                    .frame(width: usedW)
            }
        }
    }
}

// MARK: - Helpers

private extension View {
    @ViewBuilder
    func cardBackground() -> some View {
        self
            .padding()
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
}

extension View {
    func hideKeyboard() {
        #if canImport(UIKit)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
        #endif
    }
}

func doubleToInt(dub: Double) -> Int{
    if dub > Double(Int.max){
        return -1
    }
    return Int(dub)
}

#Preview {
    DailyGoalsView(vm: MealPlannerViewModel())
}
