//
//  OnboardingViewModel.swift
//  FitFlow
//
//  MVVM: ViewModel for onboarding flow (per architecture.md).
//

import SwiftUI
import Observation

enum OnboardingStep: Int, CaseIterable {
    case secureProgress = 0
    case step1Personal = 1
    case step2Goal = 2
    case step3Habit = 3
    case step4PlanReady = 4
}

enum GoalOption: String, CaseIterable, Identifiable {
    case loseWeight = "Lose Weight"
    case buildMuscle = "Build Muscle"
    case stayFit = "Stay Fit"
    case improveEndurance = "Improve Endurance"
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .loseWeight: return "scalemass.fill"
        case .buildMuscle: return "dumbbell.fill"
        case .stayFit: return "heart.fill"
        case .improveEndurance: return "figure.run"
        }
    }
    var subtitle: String {
        switch self {
        case .loseWeight: return "Focus on calorie deficit & cardio"
        case .buildMuscle: return "Focus on hypertrophy & strength"
        case .stayFit: return "Maintain balance & consistency"
        case .improveEndurance: return "Focus on stamina & cardio"
        }
    }
}

enum GenderOption: String, CaseIterable, Identifiable {
    case male = "Male"
    case female = "Female"
    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .male: return "♂"
        case .female: return "♀"
        }
    }
}

struct WeekdayOption: Identifiable {
    let id: Int
    let label: String
    static let all: [WeekdayOption] = (1...7).map { WeekdayOption(id: $0, label: ["M", "T", "W", "T", "F", "S", "S"][$0 - 1]) }
}

@Observable
@MainActor
final class OnboardingViewModel {
    var currentStep: OnboardingStep = .secureProgress
    var hasCompletedOnboarding: Bool = false
    var biometricsEnabled: Bool = false
    var editReturnStep: OnboardingStep? = nil

    // Step 1 – Personal (stored in cm / kg; display can toggle units)
    var heightCm: Int = 170
    var weightKg: Int = 70
    var age: Int = 28
    var selectedGender: GenderOption = .male
    var heightUnitIsCm: Bool = true   // true = cm, false = inch
    var weightUnitIsKg: Bool = true   // true = kg, false = lb

    static let cmPerInch = 2.54
    static let lbPerKg = 2.205

    var heightDisplayValue: Int {
        if heightUnitIsCm { return heightCm }
        return Int(round(Double(heightCm) / Self.cmPerInch))
    }
    func setHeightFromDisplay(_ value: Int) {
        if heightUnitIsCm { heightCm = value; return }
        heightCm = Int(round(Double(value) * Self.cmPerInch))
    }
    var heightRange: ClosedRange<Int> {
        if heightUnitIsCm { return 100...220 }
        return 39...87
    }

    var weightDisplayValue: Int {
        if weightUnitIsKg { return weightKg }
        return Int(round(Double(weightKg) * Self.lbPerKg))
    }
    func setWeightFromDisplay(_ value: Int) {
        if weightUnitIsKg { weightKg = value; return }
        weightKg = Int(round(Double(value) / Self.lbPerKg))
    }
    var weightRange: ClosedRange<Int> {
        if weightUnitIsKg { return 30...200 }
        return 66...440
    }

    // Step 2 – Goal
    var selectedGoal: GoalOption?

    // Step 3 – Habit (1–7 days per week); user selects which days (1=Mon...7=Sun)
    var daysPerWeek: Int = 3
    var selectedWeekdayIndices: Set<Int> = [1, 2, 3]  // 1=Mon...7=Sun; default Mon,Tue,Wed
    var selectedWorkoutTime: Date = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()

    static let workoutTimeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "hh : mm a"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.amSymbol = "AM"
        f.pmSymbol = "PM"
        return f
    }()
    var selectedTimeSlot: String { Self.workoutTimeFormatter.string(from: selectedWorkoutTime) }

    var progressDots: Int { OnboardingStep.step4PlanReady.rawValue + 1 }
    var currentDotIndex: Int { currentStep.rawValue }

    func nextStep() {
        if returnToEditSummaryIfNeeded() { return }
        guard let next = OnboardingStep(rawValue: currentStep.rawValue + 1) else {
            finishOnboarding()
            return
        }
        currentStep = next
    }

    func previousStep() {
        if returnToEditSummaryIfNeeded() { return }
        guard currentStep.rawValue > 0, let prev = OnboardingStep(rawValue: currentStep.rawValue - 1) else { return }
        currentStep = prev
    }

    func finishOnboarding() {
        hasCompletedOnboarding = true
    }

    func skipSecureProgress() {
        currentStep = .step1Personal
    }

    func beginEdit(step: OnboardingStep) {
        editReturnStep = .step4PlanReady
        currentStep = step
    }

    private func returnToEditSummaryIfNeeded() -> Bool {
        guard let returnStep = editReturnStep, currentStep != returnStep else { return false }
        currentStep = returnStep
        editReturnStep = nil
        return true
    }

    var canProceedFromStep1: Bool {
        heightRange.contains(heightDisplayValue) &&
        weightRange.contains(weightDisplayValue) &&
        (13...120).contains(age)
    }
    var canProceedFromStep2: Bool { selectedGoal != nil }

    // Step 4 summary
    var bmiValue: Double {
        let h = Double(heightCm) / 100
        guard h > 0 else { return 0 }
        return Double(weightKg) / (h * h)
    }
    var bmiCategory: String {
        switch bmiValue {
        case ..<18.5: return "Underweight"
        case 18.5..<25: return "Healthy"
        case 25..<30: return "Overweight"
        default: return "Obese"
        }
    }
    var commitmentDaysLabel: String { "\(daysPerWeek) Days / Week" }
    var commitmentShortLabel: String {
        let names = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        let sorted = selectedWeekdayIndices.sorted()
        return sorted.map { names[$0 - 1] }.joined(separator: ", ")
    }
    /// Comma-separated weekday indices for storage (e.g. "1,3,5")
    var workoutWeekdaysString: String {
        selectedWeekdayIndices.sorted().map(String.init).joined(separator: ",")
    }

    /// When daysPerWeek changes, trim selectedWeekdayIndices to match
    func syncSelectedWeekdaysToCount() {
        let target = daysPerWeek
        if selectedWeekdayIndices.count > target {
            let sorted = selectedWeekdayIndices.sorted()
            selectedWeekdayIndices = Set(sorted.prefix(target))
        } else if selectedWeekdayIndices.count < target {
            let toAdd = (1...7).filter { !selectedWeekdayIndices.contains($0) }.prefix(target - selectedWeekdayIndices.count)
            selectedWeekdayIndices.formUnion(toAdd)
        }
    }

    func toggleWeekday(_ dayIndex: Int) {
        if selectedWeekdayIndices.contains(dayIndex) {
            if selectedWeekdayIndices.count > 1 {
                selectedWeekdayIndices.remove(dayIndex)
            }
        } else if selectedWeekdayIndices.count < daysPerWeek {
            selectedWeekdayIndices.insert(dayIndex)
        }
    }

    func canToggleWeekday(_ dayIndex: Int) -> Bool {
        if selectedWeekdayIndices.contains(dayIndex) {
            return selectedWeekdayIndices.count > 1
        }
        return selectedWeekdayIndices.count < daysPerWeek
    }
}
