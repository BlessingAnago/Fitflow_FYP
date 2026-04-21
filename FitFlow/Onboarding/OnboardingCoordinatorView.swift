//
//  OnboardingCoordinatorView.swift
//  FitFlow
//
//  Linear flow: Step 1 (Personal) → Step 2 (Goal) → Step 3 (Habit) → Step 4 (Plan Ready).
//  Saves profile data to Core Data on completion.
//

import SwiftUI
import CoreData

struct OnboardingCoordinatorView: View {
    @State private var viewModel = OnboardingViewModel()
    var authViewModel: AuthViewModel
    var onComplete: () -> Void

    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        Group {
            switch viewModel.currentStep {
            case .secureProgress:
                SecureProgressView(viewModel: viewModel, authViewModel: authViewModel)
            case .step1Personal:
                OnboardingStep1View(viewModel: viewModel)
            case .step2Goal:
                OnboardingStep2View(viewModel: viewModel)
            case .step3Habit:
                OnboardingStep3View(viewModel: viewModel)
            case .step4PlanReady:
                OnboardingStep4View(viewModel: viewModel)
            }
        }
        .onChange(of: viewModel.hasCompletedOnboarding) { _, completed in
            if completed {
                if saveOnboardingData() {
                    onComplete()
                } else {
                    viewModel.hasCompletedOnboarding = false
                }
            }
        }
    }

    /// Save onboarding selections to the user's Core Data profile
    private func saveOnboardingData() -> Bool {
        let profileVM = UserProfileViewModel(context: viewContext)
        let saved = profileVM.updateFromOnboarding(
            heightCm: viewModel.heightCm,
            weightKg: viewModel.weightKg,
            age: viewModel.age,
            gender: viewModel.selectedGender.rawValue,
            fitnessGoal: viewModel.selectedGoal?.rawValue ?? "Stay Fit",
            daysPerWeek: viewModel.daysPerWeek,
            workoutWeekdays: viewModel.workoutWeekdaysString.isEmpty ? nil : viewModel.workoutWeekdaysString,
            workoutTime: viewModel.selectedWorkoutTime,
            biometricsEnabled: viewModel.biometricsEnabled
        )

        guard saved else { return false }

        // Also log initial weight as first progress entry
        let progressVM = ProgressViewModel(context: viewContext)
        progressVM.logProgress(weightKg: Double(viewModel.weightKg))
        return true
    }
}
