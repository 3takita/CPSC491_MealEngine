// PURPOSE: Calculates TDEE from user stats and sets macro goals based on bulk / cut / maintain mode.
// HLFR: The system shall allow users to auto-generate daily nutrition goals from personal data.

import SwiftUI

// Enumerations for defining what values are allowed for each user input field, along with any related helper properties (e.g. activity multiplier, goal calorie adjustment, etc)

enum BiologicalSex: String, CaseIterable, Identifiable {
    case male = "Male"
    case female = "Female"
    var id: String { rawValue }
}

enum ActivityLevel: String, CaseIterable, Identifiable {
    case sedentary    = "Sedentary"
    case light        = "Lightly Active"
    case moderate     = "Moderately Active"
    case active       = "Very Active"
    case extraActive  = "Extra Active"

    var id: String { rawValue }


    /// Multiplier for TDEE calculation for activity level 
    var multiplier: Double {
        switch self {
        case .sedentary:   return 1.2
        case .light:       return 1.375
        case .moderate:    return 1.55
        case .active:      return 1.725
        case .extraActive: return 1.9
        }
    }

    var description: String {
        switch self {
        case .sedentary:   return "Little/no exercise"
        case .light:       return "Light exercise 1–3 days/week"
        case .moderate:    return "Moderate exercise 3–5 days/week"
        case .active:      return "Hard exercise 6–7 days/week"
        case .extraActive: return "Physical job + hard training"
        }
    }
}

enum PhysiqGoal: String, CaseIterable, Identifiable {
    case cutting     = "Cut"
    case maintaining = "Maintain"
    case bulking     = "Bulk"

    var id: String { rawValue }

    /// Calorie adjustment relative to TDEE
    var calorieAdjustment: Double {
        switch self {
        case .cutting:     return -500
        case .maintaining: return 0
        case .bulking:     return +300
        }
    }

    var emoji: String {
        switch self {
        case .cutting:     return "🔥"
        case .maintaining: return "⚖️"
        case .bulking:     return "💪"
        }
    }

    var description: String {
        switch self {
        case .cutting:     return "Lose ~0.5 kg/week"
        case .maintaining: return "Hold current weight"
        case .bulking:     return "Gain ~0.3 kg/week"
        }
    }

    var color: Color {
        switch self {
        case .cutting:     return Theme.warning
        case .maintaining: return Theme.primary
        case .bulking:     return Theme.success
        }
    }
}

enum WeightUnit: String, CaseIterable, Identifiable {
    case kg = "kg"
    case lbs = "lbs"
    var id: String { rawValue }
}

enum HeightUnit: String, CaseIterable, Identifiable {
    case cm = "cm"
    case ft = "ft/in"
    var id: String { rawValue }
}

// MARK: - Main View

struct TDEECalculatorView: View {

    @ObservedObject var vm: MealPlannerViewModel
    @Environment(\.dismiss) private var dismiss

    // User inputs
    @State private var age: String = ""
    @State private var weightValue: String = ""
    @State private var heightCm: String = ""
    @State private var heightFt: String = ""
    @State private var heightIn: String = ""
    @State private var sex: BiologicalSex = .male
    @State private var activityLevel: ActivityLevel = .moderate
    @State private var physiqGoal: PhysiqGoal = .maintaining
    @State private var weightUnit: WeightUnit = .kg
    @State private var heightUnit: HeightUnit = .cm

    // Result state
    @State private var result: TDEEResult? = nil
    @State private var showResult = false
    @State private var showApplyConfirm = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {

                    // MARK: Header banner
                    headerBanner

                    // MARK: Personal info
                    inputSection("Personal Info", icon: "person.fill") {
                        sexPicker
                        agePicker
                    }

                    // MARK: Body measurements
                    inputSection("Body Measurements", icon: "ruler.fill") {
                        weightRow
                        heightRow
                    }

                    // MARK: Activity level
                    inputSection("Activity Level", icon: "figure.run") {
                        activityPicker
                    }

                    // MARK: Goal
                    inputSection("Your Goal", icon: "target") {
                        goalPicker
                    }

                    // MARK: Calculate button
                    calculateButton

                    // MARK: Result card
                    if showResult, let res = result {
                        resultCard(res)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }

                    Spacer(minLength: 20)
                }
                .padding()
            }
            .background(Theme.surface.ignoresSafeArea())
            .navigationTitle("Goal Calculator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundColor(Theme.primary)
                }
            }
            .alert("Apply these goals?", isPresented: $showApplyConfirm) {
                Button("Apply", role: .none) {
                    if let res = result { applyGoals(res) }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                if let res = result {
                    Text("This will update your daily targets to \(Int(res.targetCalories)) kcal and set your macro splits.")
                }
            }
        }
    }

    // MARK: - Header

    private var headerBanner: some View {
        HStack(spacing: 14) {
            Image(systemName: "bolt.heart.fill")
                .font(.largeTitle)
                .foregroundColor(Theme.primary)

            VStack(alignment: .leading, spacing: 4) {
                Text("TDEE Calculator")
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
                Text("Get personalised calorie & macro targets based on your stats and goal.")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.primary.opacity(0.08))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Theme.primary.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Section wrapper

    private func inputSection<Content: View>(
        _ title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(Theme.primary)
                Text(title)
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
            }
            content()
        }
        .padding()
        .background(Theme.surface)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Theme.textSecondary.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.04), radius: 6, y: 3)
    }

    // MARK: - Input fields

    private var sexPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Biological Sex")
                .font(.subheadline)
                .foregroundColor(Theme.textSecondary)
            Picker("Sex", selection: $sex) {
                ForEach(BiologicalSex.allCases) { s in
                    Text(s.rawValue).tag(s)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var agePicker: some View {
        HStack {
            Text("Age")
                .foregroundColor(Theme.textPrimary)
            Spacer()
            TextField("e.g. 25", text: $age)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .foregroundColor(Theme.textPrimary)
                .frame(width: 80)
                .padding(8)
                .background(Theme.primary.opacity(0.06))
                .cornerRadius(8)
            Text("yrs")
                .foregroundColor(Theme.textSecondary)
                .font(.caption)
        }
    }

    private var weightRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Weight")
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                Picker("Unit", selection: $weightUnit) {
                    ForEach(WeightUnit.allCases) { u in Text(u.rawValue).tag(u) }
                }
                .pickerStyle(.segmented)
                .frame(width: 110)
            }

            HStack {
                TextField(weightUnit == .kg ? "e.g. 75" : "e.g. 165", text: $weightValue)
                    .keyboardType(.decimalPad)
                    .foregroundColor(Theme.textPrimary)
                    .padding(8)
                    .background(Theme.primary.opacity(0.06))
                    .cornerRadius(8)
                Text(weightUnit.rawValue)
                    .foregroundColor(Theme.textSecondary)
                    .font(.caption)
            }
        }
    }

    private var heightRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Height")
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                Picker("Unit", selection: $heightUnit) {
                    ForEach(HeightUnit.allCases) { u in Text(u.rawValue).tag(u) }
                }
                .pickerStyle(.segmented)
                .frame(width: 110)
            }

            if heightUnit == .cm {
                HStack {
                    TextField("e.g. 175", text: $heightCm)
                        .keyboardType(.decimalPad)
                        .foregroundColor(Theme.textPrimary)
                        .padding(8)
                        .background(Theme.primary.opacity(0.06))
                        .cornerRadius(8)
                    Text("cm")
                        .foregroundColor(Theme.textSecondary)
                        .font(.caption)
                }
            } else {
                HStack(spacing: 10) {
                    HStack {
                        TextField("5", text: $heightFt)
                            .keyboardType(.numberPad)
                            .foregroundColor(Theme.textPrimary)
                            .padding(8)
                            .background(Theme.primary.opacity(0.06))
                            .cornerRadius(8)
                        Text("ft")
                            .foregroundColor(Theme.textSecondary)
                            .font(.caption)
                    }
                    HStack {
                        TextField("10", text: $heightIn)
                            .keyboardType(.numberPad)
                            .foregroundColor(Theme.textPrimary)
                            .padding(8)
                            .background(Theme.primary.opacity(0.06))
                            .cornerRadius(8)
                        Text("in")
                            .foregroundColor(Theme.textSecondary)
                            .font(.caption)
                    }
                }
            }
        }
    }

    private var activityPicker: some View {
        VStack(spacing: 10) {
            ForEach(ActivityLevel.allCases) { level in
                Button {
                    activityLevel = level
                } label: {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(activityLevel == level ? Theme.primary : Theme.textSecondary.opacity(0.2))
                            .frame(width: 12, height: 12)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(level.rawValue)
                                .font(.subheadline).bold()
                                .foregroundColor(Theme.textPrimary)
                            Text(level.description)
                                .font(.caption)
                                .foregroundColor(Theme.textSecondary)
                        }
                        Spacer()

                        if activityLevel == level {
                            Image(systemName: "checkmark")
                                .font(.caption.bold())
                                .foregroundColor(Theme.primary)
                        }
                    }
                    .padding(12)
                    .background(activityLevel == level ? Theme.primary.opacity(0.06) : Color.clear)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(activityLevel == level ? Theme.primary.opacity(0.3) : Theme.textSecondary.opacity(0.15), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .animation(.easeInOut(duration: 0.15), value: activityLevel)
            }
        }
    }

    private var goalPicker: some View {
        HStack(spacing: 10) {
            ForEach(PhysiqGoal.allCases) { goal in
                Button {
                    physiqGoal = goal
                } label: {
                    VStack(spacing: 6) {
                        Text(goal.emoji)
                            .font(.title2)
                        Text(goal.rawValue)
                            .font(.subheadline).bold()
                            .foregroundColor(physiqGoal == goal ? .white : Theme.textPrimary)
                        Text(goal.description)
                            .font(.caption2)
                            .foregroundColor(physiqGoal == goal ? .white.opacity(0.8) : Theme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(physiqGoal == goal ? goal.color : goal.color.opacity(0.08))
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(goal.color.opacity(physiqGoal == goal ? 0 : 0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .animation(.easeInOut(duration: 0.15), value: physiqGoal)
            }
        }
    }

    // MARK: - Calculate button

    private var calculateButton: some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                result = calculate()
                showResult = result != nil
            }
        } label: {
            HStack {
                Image(systemName: "function")
                Text("Calculate My Goals")
                    .bold()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isFormValid ? Theme.primary : Theme.textSecondary.opacity(0.3))
            .foregroundColor(.white)
            .cornerRadius(14)
        }
        .disabled(!isFormValid)
    }

    // MARK: - Result card

    private func resultCard(_ res: TDEEResult) -> some View {
        VStack(spacing: 16) {

            // Title row
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Results")
                        .font(.headline)
                        .foregroundColor(Theme.textPrimary)
                    Text(physiqGoal.rawValue + " · " + activityLevel.rawValue)
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                }
                Spacer()
                Text(physiqGoal.emoji)
                    .font(.largeTitle)
            }

            Divider()

            // TDEE vs Target
            HStack(spacing: 0) {
                tdeeStatBlock(
                    title: "TDEE",
                    subtitle: "Maintenance",
                    value: "\(Int(res.tdee))",
                    unit: "kcal",
                    color: Theme.primary
                )
                Divider().frame(height: 60)
                tdeeStatBlock(
                    title: "Target",
                    subtitle: physiqGoal.rawValue,
                    value: "\(Int(res.targetCalories))",
                    unit: "kcal",
                    color: physiqGoal.color
                )
                Divider().frame(height: 60)
                tdeeStatBlock(
                    title: "Adjust",
                    subtitle: res.adjustmentLabel,
                    value: res.adjustmentDisplay,
                    unit: "kcal/day",
                    color: res.adjustmentCalories == 0 ? Theme.textSecondary : (res.adjustmentCalories > 0 ? Theme.success : Theme.warning)
                )
            }

            Divider()

            // Macro breakdown
            Text("Macro Targets")
                .font(.subheadline).bold()
                .foregroundColor(Theme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 12) {
                macroPill("Protein", "\(Int(res.protein))g", color: Theme.success)
                macroPill("Carbs",   "\(Int(res.carbs))g",   color: Theme.primary)
                macroPill("Fat",     "\(Int(res.fat))g",     color: Theme.warning)
            }

            // Macro % breakdown bar
            macroBar(res)

            // Explanation note
            Text(physiqGoal.explanation)
                .font(.caption)
                .foregroundColor(Theme.textSecondary)
                .padding(10)
                .background(physiqGoal.color.opacity(0.07))
                .cornerRadius(10)

            // Apply button
            Button {
                showApplyConfirm = true
            } label: {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Apply These Goals")
                        .bold()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(physiqGoal.color)
                .foregroundColor(.white)
                .cornerRadius(14)
            }
        }
        .padding()
        .background(Theme.surface)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(physiqGoal.color.opacity(0.3), lineWidth: 1.5)
        )
        .shadow(color: physiqGoal.color.opacity(0.1), radius: 12, y: 6)
    }

    private func tdeeStatBlock(title: String, subtitle: String, value: String, unit: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption).bold()
                .foregroundColor(Theme.textSecondary)
            Text(value)
                .font(.title3).bold()
                .foregroundColor(color)
                .monospacedDigit()
            Text(unit)
                .font(.caption2)
                .foregroundColor(Theme.textSecondary)
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func macroPill(_ title: String, _ value: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(value)
                .font(.subheadline).bold()
                .foregroundColor(Theme.textPrimary)
            Text(title)
                .font(.caption2)
                .foregroundColor(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.08))
        .cornerRadius(12)
    }

    private func macroBar(_ res: TDEEResult) -> some View {
        let total = res.protein * 4 + res.carbs * 4 + res.fat * 9
        let pPct = total > 0 ? (res.protein * 4) / total : 0
        let cPct = total > 0 ? (res.carbs * 4) / total : 0
        let fPct = total > 0 ? (res.fat * 9) / total : 0

        return GeometryReader { geo in
            HStack(spacing: 2) {
                Capsule().fill(Theme.success)
                    .frame(width: geo.size.width * CGFloat(pPct))
                Capsule().fill(Theme.primary)
                    .frame(width: geo.size.width * CGFloat(cPct))
                Capsule().fill(Theme.warning)
                    .frame(width: geo.size.width * CGFloat(fPct))
            }
        }
        .frame(height: 10)
        .clipShape(Capsule())
    }

    // Checking if user input is valid before enabling calculate button

    private var isFormValid: Bool {
        guard
            let a = Int(age), a > 0, a < 120,
            let w = Double(weightValue), w > 0
        else { return false }

        if heightUnit == .cm {
            guard let h = Double(heightCm), h > 0 else { return false }
        } else {
            guard let _ = Double(heightFt) else { return false }
        }
        return true
    }

    // Calculation logic based on Mifflin-St Jeor equation and goal adjustments
    // Everything below is math portion - no UI code, so can be tested independently if needed

    private func calculate() -> TDEEResult? {
        guard
            let ageVal = Double(age),
            let weightRaw = Double(weightValue)
        else { return nil }

        let weightKg = weightUnit == .kg ? weightRaw : weightRaw * 0.453592

        let heightCmVal: Double
        if heightUnit == .cm {
            guard let h = Double(heightCm) else { return nil }
            heightCmVal = h
        } else {
            let ft = Double(heightFt) ?? 0
            let inches = Double(heightIn) ?? 0
            heightCmVal = (ft * 12 + inches) * 2.54
        }

        guard heightCmVal > 0 else { return nil }

        // Mifflin-St Jeor BMR
        let bmr: Double
        switch sex {
        case .male:
            bmr = (10 * weightKg) + (6.25 * heightCmVal) - (5 * ageVal )+ 5
        case .female:
            bmr = (10 * weightKg) + (6.25 * heightCmVal) - (5 * ageVal ) - 161
        }

        let tdee = bmr * activityLevel.multiplier
        let targetCalories = max(1200, tdee + physiqGoal.calorieAdjustment)

        // Macro splits based on goal
        let proteinPerKg: Double
        let fatPct: Double

        switch physiqGoal {
        case .cutting:
            proteinPerKg = 2.4   // Higher protein to preserve muscle
            fatPct       = 0.25
        case .maintaining:
            proteinPerKg = 2.0
            fatPct       = 0.30
        case .bulking:
            proteinPerKg = 2.2   // Slightly elevated for muscle growth
            fatPct       = 0.28
        }

        let protein = weightKg * proteinPerKg
        let fat     = (targetCalories * fatPct) / 9
        let carbCals = targetCalories - (protein * 4) - (fat * 9)
        let carbs   = max(carbCals / 4, 0)

        return TDEEResult(
            bmr: bmr,
            tdee: tdee,
            targetCalories: targetCalories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            adjustmentCalories: physiqGoal.calorieAdjustment
        )
    }

    // Apply the calculated goals to the view model and dismiss the calculator

    private func applyGoals(_ res: TDEEResult) {
        vm.goals.calories = res.targetCalories
        vm.goals.protein  = res.protein
        vm.goals.carbs    = res.carbs
        vm.goals.fat      = res.fat
        vm.savePreferences()
        dismiss()
    }
}

// Container to hold the calculated output

private struct TDEEResult {
    let bmr: Double
    let tdee: Double
    let targetCalories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let adjustmentCalories: Double

    var adjustmentDisplay: String {
        if adjustmentCalories == 0 { return "±0" }
        return adjustmentCalories > 0 ? "+\(Int(adjustmentCalories))" : "\(Int(adjustmentCalories))"
    }

    var adjustmentLabel: String {
        if adjustmentCalories == 0 { return "None" }
        return adjustmentCalories > 0 ? "Surplus" : "Deficit"
    }
}

// MARK: - PhysiqGoal explanation

private extension PhysiqGoal {
    var explanation: String {
        switch self {
        case .cutting:
            return "A 500 kcal daily deficit targets ~0.5 kg of fat loss per week. Protein is set high to preserve muscle mass while in a deficit."
        case .maintaining:
            return "Calories match your TDEE to sustain your current weight. Great for recomping or taking a diet break."
        case .bulking:
            return "A 300 kcal surplus supports muscle growth while minimising fat gain. Pair with progressive resistance training."
        }
    }
}

// MARK: - Preview

#Preview {
    TDEECalculatorView(vm: MealPlannerViewModel())
        .preferredColorScheme(.light)
}