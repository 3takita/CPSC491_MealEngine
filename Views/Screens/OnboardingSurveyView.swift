

// PURPOSE: Onboarding survey shown to new users on first launch.
// Collects sex, age, body measurements, activity level, and physique goal,
// then calculates TDEE and sets macro targets. Users can skip at any step.

import SwiftUI

// MARK: - Onboarding State

final class OnboardingState: ObservableObject {
    @Published var step: OnboardingStep = .welcome
    @Published var sex: BiologicalSex = .male
    @Published var hasSex = false
    @Published var age: String = ""
    @Published var weightVal: String = ""
    @Published var weightUnit: WeightUnit = .kg
    @Published var heightCm: String = ""
    @Published var heightFt: String = ""
    @Published var heightIn: String = ""
    @Published var heightUnit: HeightUnit = .cm
    @Published var activityLevel: ActivityLevel = .moderate
    @Published var hasActivity = false
    @Published var physiqGoal: PhysiqGoal = .maintaining
    @Published var hasGoal = false
    @Published var dietaryProfile = DietaryProfile()

    var isBodyValid: Bool {
        guard
            let a = Int(age), a > 0, a < 120,
            let w = Double(weightVal), w > 0
        else { return false }
        if heightUnit == .cm {
            return (Double(heightCm) ?? 0) > 0
        } else {
            return (Double(heightFt) ?? 0) > 0
        }
    }

    func calculate() -> TDEEResult? {
        guard
            let ageVal = Double(age),
            let weightRaw = Double(weightVal)
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

        let bmr: Double
        switch sex {
        case .male:
            bmr = (10 * weightKg) + (6.25 * heightCmVal) - (5 * ageVal) + 5
        case .female:
            bmr = (10 * weightKg) + (6.25 * heightCmVal) - (5 * ageVal) - 161
        }

        let tdee = bmr * activityLevel.multiplier
        let targetCalories = max(1200, tdee + physiqGoal.calorieAdjustment)

        let proteinPerKg: Double
        let fatPct: Double
        switch physiqGoal {
        case .cutting:     proteinPerKg = 2.4; fatPct = 0.25
        case .maintaining: proteinPerKg = 2.0; fatPct = 0.30
        case .bulking:     proteinPerKg = 2.2; fatPct = 0.28
        }

        let protein = weightKg * proteinPerKg
        let fat = (targetCalories * fatPct) / 9
        let carbs = max((targetCalories - protein * 4 - fat * 9) / 4, 0)

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
}

enum OnboardingStep {
    case welcome, sex, body, activity, goal, dietary, result
}

// MARK: - Root View

struct OnboardingSurveyView: View {
    @ObservedObject var vm: MealPlannerViewModel
    @StateObject private var onboarding = OnboardingState()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.surface.ignoresSafeArea()

                Group {
                    switch onboarding.step {
                    case .welcome:  WelcomeStep(onboarding: onboarding)
                    case .sex:      SexStep(onboarding: onboarding)
                    case .body:     BodyStep(onboarding: onboarding)
                    case .activity: ActivityStep(onboarding: onboarding)
                    case .goal:     GoalStep(onboarding: onboarding)
                    case .dietary:  DietaryStep(onboarding: onboarding)
                    case .result:   ResultStep(onboarding: onboarding, vm: vm, dismiss: dismiss)
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .id(onboarding.step)
            }
            .animation(.easeInOut(duration: 0.25), value: onboarding.step)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if onboarding.step != .welcome && onboarding.step != .result {
                        Button("Skip all") {
                            withAnimation { onboarding.step = .result }
                        }
                        .foregroundColor(Theme.textSecondary)
                        .font(.subheadline)
                    }
                }
            }
        }
    }
}

// MARK: - Progress Bar

private struct OnboardingProgressBar: View {
    let progress: Double // 0.0 – 1.0

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.textSecondary.opacity(0.15))
                Capsule().fill(Theme.primary)
                    .frame(width: geo.size.width * progress)
            }
        }
        .frame(height: 4)
        .animation(.easeInOut(duration: 0.35), value: progress)
    }
}

// MARK: - Step Shell (shared chrome)

private struct StepShell<Content: View>: View {
    let stepLabel: String
    let progress: Double
    let onBack: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Back + progress
                HStack(spacing: 12) {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.subheadline.bold())
                            .foregroundColor(Theme.textSecondary)
                    }
                    OnboardingProgressBar(progress: progress)
                }
                .padding(.bottom, 6)

                Text(stepLabel)
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
                    .padding(.bottom, 16)

                content()
            }
            .padding(20)
        }
    }
}

// MARK: - Step 0: Welcome

private struct WelcomeStep: View {
    @ObservedObject var onboarding: OnboardingState

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer(minLength: 48)

            Image(systemName: "bolt.heart.fill")
                .font(.system(size: 44))
                .foregroundColor(Theme.primary)
                .padding(.bottom, 20)

            Text("Welcome to MealEngine")
                .font(.largeTitle.bold())
                .foregroundColor(Theme.textPrimary)
                .padding(.bottom, 12)

            Text("Answer a few quick questions to set up your personalised calorie and macro targets. It takes about 60 seconds.")
                .font(.body)
                .foregroundColor(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 40)

            Button {
                withAnimation { onboarding.step = .sex }
            } label: {
                Text("Get started")
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Theme.primary)
                    .foregroundColor(.white)
                    .cornerRadius(14)
            }
            .padding(.bottom, 12)

            Button {
                withAnimation { onboarding.step = .result }
            } label: {
                Text("Skip for now")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundColor(Theme.textSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Theme.textSecondary.opacity(0.3), lineWidth: 1)
                    )
            }

            Spacer()
        }
        .padding(24)
    }
}

// MARK: - Step 1: Sex

private struct SexStep: View {
    @ObservedObject var onboarding: OnboardingState

    var body: some View {
        StepShell(stepLabel: "Step 1 of 4", progress: 0.25,
                  onBack: { withAnimation { onboarding.step = .welcome } }) {

            Text("Biological sex")
                .font(.title2.bold())
                .foregroundColor(Theme.textPrimary)
                .padding(.bottom, 4)

            Text("Used in the Mifflin-St Jeor BMR formula.")
                .font(.subheadline)
                .foregroundColor(Theme.textSecondary)
                .padding(.bottom, 24)

            HStack(spacing: 12) {
                ForEach(BiologicalSex.allCases) { s in
                    SexOptionCard(
                        label: s.rawValue,
                        icon: s == .male ? "person.fill" : "person.fill",
                        isSelected: onboarding.hasSex && onboarding.sex == s
                    ) {
                        onboarding.sex = s
                        onboarding.hasSex = true
                    }
                }
            }
            .padding(.bottom, 32)

            StepActions(
                canContinue: onboarding.hasSex,
                continueLabel: "Continue",
                onContinue: { withAnimation { onboarding.step = .body } },
                onSkip:     { withAnimation { onboarding.step = .body } }
            )
        }
    }
}

private struct SexOptionCard: View {
    let label: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? Theme.primary : Theme.textSecondary)
                Text(label)
                    .font(.headline)
                    .foregroundColor(isSelected ? Theme.primary : Theme.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(isSelected ? Theme.primary.opacity(0.08) : Theme.surface)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Theme.primary : Theme.textSecondary.opacity(0.2),
                            lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - Step 2: Body Measurements

private struct BodyStep: View {
    @ObservedObject var onboarding: OnboardingState

    var body: some View {
        StepShell(stepLabel: "Step 2 of 4", progress: 0.50,
                  onBack: { withAnimation { onboarding.step = .sex } }) {

            Text("Body measurements")
                .font(.title2.bold())
                .foregroundColor(Theme.textPrimary)
                .padding(.bottom, 4)

            Text("Your stats let us calculate your maintenance calories (TDEE).")
                .font(.subheadline)
                .foregroundColor(Theme.textSecondary)
                .padding(.bottom, 24)

            // Age
            MeasurementRow(label: "Age") {
                HStack {
                    TextField("e.g. 28", text: $onboarding.age)
                        .keyboardType(.numberPad)
                        .padding(10)
                        .background(Theme.primary.opacity(0.06))
                        .cornerRadius(10)
                        .frame(maxWidth: 90)
                    Text("yrs").foregroundColor(Theme.textSecondary).font(.caption)
                }
            }

            // Weight
            MeasurementRow(label: "Weight") {
                VStack(alignment: .leading, spacing: 6) {
                    Picker("Unit", selection: $onboarding.weightUnit) {
                        ForEach(WeightUnit.allCases) { u in Text(u.rawValue).tag(u) }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 120)

                    HStack {
                        TextField(onboarding.weightUnit == .kg ? "e.g. 75" : "e.g. 165",
                                  text: $onboarding.weightVal)
                            .keyboardType(.decimalPad)
                            .padding(10)
                            .background(Theme.primary.opacity(0.06))
                            .cornerRadius(10)
                        Text(onboarding.weightUnit.rawValue)
                            .foregroundColor(Theme.textSecondary).font(.caption)
                    }
                }
            }

            // Height
            MeasurementRow(label: "Height") {
                VStack(alignment: .leading, spacing: 6) {
                    Picker("Unit", selection: $onboarding.heightUnit) {
                        ForEach(HeightUnit.allCases) { u in Text(u.rawValue).tag(u) }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 120)

                    if onboarding.heightUnit == .cm {
                        HStack {
                            TextField("e.g. 175", text: $onboarding.heightCm)
                                .keyboardType(.decimalPad)
                                .padding(10)
                                .background(Theme.primary.opacity(0.06))
                                .cornerRadius(10)
                            Text("cm").foregroundColor(Theme.textSecondary).font(.caption)
                        }
                    } else {
                        HStack(spacing: 10) {
                            HStack {
                                TextField("5", text: $onboarding.heightFt)
                                    .keyboardType(.numberPad)
                                    .padding(10)
                                    .background(Theme.primary.opacity(0.06))
                                    .cornerRadius(10)
                                Text("ft").foregroundColor(Theme.textSecondary).font(.caption)
                            }
                            HStack {
                                TextField("10", text: $onboarding.heightIn)
                                    .keyboardType(.numberPad)
                                    .padding(10)
                                    .background(Theme.primary.opacity(0.06))
                                    .cornerRadius(10)
                                Text("in").foregroundColor(Theme.textSecondary).font(.caption)
                            }
                        }
                    }
                }
            }

            Spacer(minLength: 24)

            StepActions(
                canContinue: onboarding.isBodyValid,
                continueLabel: "Continue",
                onContinue: { withAnimation { onboarding.step = .activity } },
                onSkip:     { withAnimation { onboarding.step = .activity } }
            )
        }
    }
}

private struct MeasurementRow<Content: View>: View {
    let label: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(Theme.textSecondary)
            content()
        }
        .padding(.bottom, 16)
    }
}

// MARK: - Step 3: Activity Level

private struct ActivityStep: View {
    @ObservedObject var onboarding: OnboardingState

    var body: some View {
        StepShell(stepLabel: "Step 3 of 4", progress: 0.75,
                  onBack: { withAnimation { onboarding.step = .body } }) {

            Text("Activity level")
                .font(.title2.bold())
                .foregroundColor(Theme.textPrimary)
                .padding(.bottom, 4)

            Text("Pick what best matches your average week.")
                .font(.subheadline)
                .foregroundColor(Theme.textSecondary)
                .padding(.bottom, 20)

            ForEach(ActivityLevel.allCases) { level in
                let isSelected = onboarding.hasActivity && onboarding.activityLevel == level
                Button {
                    onboarding.activityLevel = level
                    onboarding.hasActivity = true
                } label: {
                    HStack(spacing: 14) {
                        Circle()
                            .fill(isSelected ? Theme.primary : Theme.textSecondary.opacity(0.2))
                            .frame(width: 12, height: 12)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(level.rawValue)
                                .font(.subheadline.bold())
                                .foregroundColor(Theme.textPrimary)
                            Text(level.description)
                                .font(.caption)
                                .foregroundColor(Theme.textSecondary)
                        }
                        Spacer()
                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.caption.bold())
                                .foregroundColor(Theme.primary)
                        }
                    }
                    .padding(14)
                    .background(isSelected ? Theme.primary.opacity(0.06) : Color.clear)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Theme.primary.opacity(0.4) : Theme.textSecondary.opacity(0.15),
                                    lineWidth: isSelected ? 1.5 : 1)
                    )
                }
                .buttonStyle(.plain)
                .animation(.easeInOut(duration: 0.15), value: isSelected)
                .padding(.bottom, 8)
            }

            StepActions(
                canContinue: onboarding.hasActivity,
                continueLabel: "Continue",
                onContinue: { withAnimation { onboarding.step = .goal } },
                onSkip:     { withAnimation { onboarding.step = .goal } }
            )
        }
    }
}

// MARK: - Step 4: Goal

private struct GoalStep: View {
    @ObservedObject var onboarding: OnboardingState

    var body: some View {
        StepShell(stepLabel: "Step 4 of 4", progress: 1.0,
                  onBack: { withAnimation { onboarding.step = .activity } }) {

            Text("What's your goal?")
                .font(.title2.bold())
                .foregroundColor(Theme.textPrimary)
                .padding(.bottom, 4)

            Text("This sets your calorie target and macro split.")
                .font(.subheadline)
                .foregroundColor(Theme.textSecondary)
                .padding(.bottom, 20)

            ForEach(PhysiqGoal.allCases) { goal in
                let isSelected = onboarding.hasGoal && onboarding.physiqGoal == goal
                Button {
                    onboarding.physiqGoal = goal
                    onboarding.hasGoal = true
                } label: {
                    HStack(spacing: 14) {
                        Text(goal.emoji).font(.title2)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(goal.rawValue)
                                .font(.headline)
                                .foregroundColor(isSelected ? .white : Theme.textPrimary)
                            Text(goal.description)
                                .font(.caption)
                                .foregroundColor(isSelected ? .white.opacity(0.8) : Theme.textSecondary)
                        }
                        Spacer()
                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.caption.bold())
                                .foregroundColor(.white)
                        }
                    }
                    .padding(16)
                    .background(isSelected ? goal.color : goal.color.opacity(0.07))
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(goal.color.opacity(isSelected ? 0 : 0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .animation(.easeInOut(duration: 0.15), value: isSelected)
                .padding(.bottom, 10)
            }

            StepActions(
                canContinue: onboarding.hasGoal,
                continueLabel: "Calculate my goals",
                onContinue: { withAnimation { onboarding.step = .dietary } },
                onSkip:     { withAnimation { onboarding.step = .dietary } }
            )
        }
    }
}


// MARK: - Step 5: Diet
private struct DietaryStep: View {
    @ObservedObject var onboarding: OnboardingState

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        StepShell(stepLabel: "Almost done", progress: 1.0,
                  onBack: { withAnimation { onboarding.step = .goal } }) {

            Text("Dietary preferences")
                .font(.title2.bold())
                .foregroundColor(Theme.textPrimary)
                .padding(.bottom, 4)

            Text("Select any that apply. This filters your food recommendations. You can change these any time in Settings.")
                .font(.subheadline)
                .foregroundColor(Theme.textSecondary)
                .padding(.bottom, 20)

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(DietaryRestriction.allCases) { restriction in
                    let isOn = onboarding.dietaryProfile.restrictions.contains(restriction)
                    Button {
                        if isOn {
                            onboarding.dietaryProfile.restrictions.remove(restriction)
                        } else {
                            onboarding.dietaryProfile.restrictions.insert(restriction)
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: restriction.icon)
                                .font(.caption)
                                .foregroundColor(isOn ? Theme.primary : Theme.textSecondary)
                            Text(restriction.rawValue)
                                .font(.subheadline)
                                .foregroundColor(isOn ? Theme.primary : Theme.textPrimary)
                            Spacer()
                            if isOn {
                                Image(systemName: "checkmark")
                                    .font(.caption.bold())
                                    .foregroundColor(Theme.primary)
                            }
                        }
                        .padding(12)
                        .background(isOn ? Theme.primary.opacity(0.07) : Theme.surface)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isOn ? Theme.primary.opacity(0.4) : Theme.textSecondary.opacity(0.2),
                                        lineWidth: isOn ? 1.5 : 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .animation(.easeInOut(duration: 0.15), value: isOn)
                }
            }
            .padding(.bottom, 24)

            StepActions(
                canContinue: true,
                continueLabel: "Continue",
                onContinue: { withAnimation { onboarding.step = .result } },
                onSkip:     { withAnimation { onboarding.step = .result } }
            )
        }
    }
}

// MARK: - Step 6: Result

private struct ResultStep: View {
    @ObservedObject var onboarding: OnboardingState
    @ObservedObject var vm: MealPlannerViewModel
    let dismiss: DismissAction
    @State private var showApplyConfirm = false

    private var result: TDEEResult? { onboarding.calculate() }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let res = result {
                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your goals are set")
                            .font(.title2.bold())
                            .foregroundColor(Theme.textPrimary)
                        Text("Based on your stats and the \(onboarding.physiqGoal.rawValue.lowercased()) goal.")
                            .font(.subheadline)
                            .foregroundColor(Theme.textSecondary)
                    }

                    // Calorie hero card
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Daily target")
                                    .font(.caption)
                                    .foregroundColor(Theme.textSecondary)
                                Text("\(Int(res.targetCalories)) kcal")
                                    .font(.largeTitle.bold())
                                    .foregroundColor(Theme.primary)
                            }
                            Spacer()
                            Text(onboarding.physiqGoal.emoji).font(.system(size: 40))
                        }

                        // Macro bar
                        MacroBarView(protein: res.protein, carbs: res.carbs, fat: res.fat,
                                     targetCalories: res.targetCalories)

                        // Macro pills
                        HStack(spacing: 10) {
                            MacroResultPill(label: "Protein", value: "\(Int(res.protein))g",
                                           color: Theme.success)
                            MacroResultPill(label: "Carbs", value: "\(Int(res.carbs))g",
                                           color: Theme.primary)
                            MacroResultPill(label: "Fat", value: "\(Int(res.fat))g",
                                           color: Theme.warning)
                        }

                        Divider()

                        // TDEE row
                        HStack {
                            Label("TDEE (maintenance)", systemImage: "flame.fill")
                                .font(.caption)
                                .foregroundColor(Theme.textSecondary)
                            Spacer()
                            Text("\(Int(res.tdee)) kcal")
                                .font(.caption.bold())
                                .foregroundColor(Theme.textPrimary)
                        }
                    }
                    .padding(16)
                    .background(Theme.surface)
                    .cornerRadius(18)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(onboarding.physiqGoal.color.opacity(0.3), lineWidth: 1.5)
                    )
                    .shadow(color: onboarding.physiqGoal.color.opacity(0.08), radius: 10, y: 4)

                    // Explanation
                    Text(onboarding.physiqGoal.explanation)
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                        .padding(12)
                        .background(onboarding.physiqGoal.color.opacity(0.07))
                        .cornerRadius(10)

                    // Apply button
                    Button {
                        showApplyConfirm = true
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Apply these goals").bold()
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(onboarding.physiqGoal.color)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                    }
                    .alert("Apply these goals?", isPresented: $showApplyConfirm) {
                        Button("Apply") { applyAndDismiss(res) }
                        Button("Cancel", role: .cancel) {}
                    } message: {
                        Text("This will update your daily targets to \(Int(res.targetCalories)) kcal and set your macro splits.")
                    }

                } else {
                    // Skipped / insufficient data
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 44))
                            .foregroundColor(Theme.primary)

                        Text("All done")
                            .font(.title2.bold())
                            .foregroundColor(Theme.textPrimary)

                        Text("You can set your calorie and macro targets manually in Settings whenever you're ready.")
                            .font(.subheadline)
                            .foregroundColor(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(32)
                }

                // Skip / go to app
                Button {
                    markOnboardingComplete()
                    dismiss()
                } label: {
                    Text(result != nil ? "Maybe later" : "Go to the app")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(Theme.textSecondary)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Theme.textSecondary.opacity(0.3), lineWidth: 1)
                        )
                }
            }
            .padding(20)
        }
        .background(Theme.surface.ignoresSafeArea())
    }

    private func applyAndDismiss(_ res: TDEEResult) {
        vm.goals.calories = res.targetCalories
        vm.goals.protein  = res.protein
        vm.goals.carbs    = res.carbs
        vm.goals.fat      = res.fat
        vm.saveGoals()
        vm.dietaryProfile = onboarding.dietaryProfile
        vm.saveDietaryProfile()
        markOnboardingComplete()
        dismiss()
    }

    private func markOnboardingComplete() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }
}

// MARK: - Reusable sub-views

private struct MacroBarView: View {
    let protein: Double
    let carbs: Double
    let fat: Double
    let targetCalories: Double

    var body: some View {
        let total = protein * 4 + carbs * 4 + fat * 9
        let pPct = total > 0 ? (protein * 4) / total : 0
        let cPct = total > 0 ? (carbs * 4) / total : 0
        let fPct = total > 0 ? (fat * 9) / total : 0

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
        .frame(height: 8)
        .clipShape(Capsule())
    }
}

private struct MacroResultPill: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(value)
                .font(.subheadline.bold())
                .foregroundColor(Theme.textPrimary)
            Text(label)
                .font(.caption2)
                .foregroundColor(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.08))
        .cornerRadius(12)
    }
}

private struct StepActions: View {
    let canContinue: Bool
    let continueLabel: String
    let onContinue: () -> Void
    let onSkip: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onContinue) {
                Text(continueLabel)
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(canContinue ? Theme.primary : Theme.textSecondary.opacity(0.3))
                    .foregroundColor(.white)
                    .cornerRadius(14)
            }
            .disabled(!canContinue)

            Button(action: onSkip) {
                Text("Skip")
                    .padding()
                    .foregroundColor(Theme.textSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Theme.textSecondary.opacity(0.3), lineWidth: 1)
                    )
            }
        }
        .padding(.top, 8)
    }
}

extension UserDefaults {
    var hasCompletedOnboarding: Bool {
        bool(forKey: "hasCompletedOnboarding")
    }
}

// MARK: - Preview

#Preview {
    OnboardingSurveyView(vm: MealPlannerViewModel())
}
