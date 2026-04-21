//
//  OnboardingStep4View.swift
//  FitFlow
//
//  Step 4 of 4 – Your Plan is Ready. Summary cards (Main Goal, Commitment, Body Metrics) + Edit, Finish Setup.
//

import SwiftUI

struct OnboardingStep4View: View {
    var viewModel: OnboardingViewModel

    private var bodyMetricsSummary: String {
        let h = viewModel.heightUnitIsCm ? "\(viewModel.heightCm) cm" : "\(viewModel.heightDisplayValue) in"
        let w = viewModel.weightUnitIsKg ? "\(viewModel.weightKg) kg" : "\(viewModel.weightDisplayValue) lb"
        return "\(h) • \(w)"
    }

    var body: some View {
        ZStack {
            AppColors.darkBackground.ignoresSafeArea()
            VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    OnboardingHeader(title: "Step 4 of 4", isLight: false, onBack: { viewModel.previousStep() })
                        .padding(.horizontal, AppLayout.screenPadding)
                    OnboardingProgressBar(step: 3, total: 4, useGreen: true)
                        .padding(.horizontal, AppLayout.screenPadding)
                        .padding(.bottom, 8)
                    Text("Your Plan is Ready")
                        .font(AppTypography.largeTitle())
                        .foregroundStyle(AppColors.darkText)
                        .padding(.horizontal, AppLayout.screenPadding)
                    Text("Here is the summary of your personalized fitness journey.")
                        .font(AppTypography.body())
                        .foregroundStyle(AppColors.darkTextSecondary)
                        .padding(.horizontal, AppLayout.screenPadding)
                    if let goal = viewModel.selectedGoal {
                        planCard(
                            icon: "dumbbell.fill",
                            label: "Main Goal",
                            value: goal.rawValue,
                            subtitle: goal.subtitle,
                            onEdit: { viewModel.beginEdit(step: .step2Goal) }
                        )
                    }
                    planCard(
                        icon: "calendar",
                        label: "Commitment",
                        value: viewModel.commitmentDaysLabel,
                        subtitle: viewModel.commitmentShortLabel,
                        onEdit: { viewModel.beginEdit(step: .step3Habit) }
                    )
                    planCard(
                        icon: "figure.stand",
                        label: "Body Metrics",
                        value: bodyMetricsSummary,
                        subtitle: "BMI: \(String(format: "%.1f", viewModel.bmiValue)) (\(viewModel.bmiCategory))",
                        onEdit: { viewModel.beginEdit(step: .step1Personal) }
                    )
                    Spacer(minLength: 80)
                }
                .padding(.vertical, 8)
            }
                VStack(spacing: 0) {
                    Button("Finish Setup") { viewModel.finishOnboarding() }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.horizontal, AppLayout.screenPadding)
                }
                .padding(.top, 16)
                .padding(.bottom, 32)
                .background(AppColors.darkBackground)
            }
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }

    private func planCard(icon: String, label: String, value: String, subtitle: String, onEdit: @escaping () -> Void) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppColors.darkBackground)
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(AppColors.primaryGreen)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(AppTypography.caption2())
                    .foregroundStyle(AppColors.darkTextSecondary)
                Text(value)
                    .font(AppTypography.title3())
                    .foregroundStyle(AppColors.darkText)
                Text(subtitle)
                    .font(AppTypography.caption2())
                    .foregroundStyle(AppColors.darkTextSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Button("Edit", action: onEdit)
                .font(AppTypography.callout().weight(.semibold))
                .foregroundStyle(AppColors.primaryGreen)
        }
        .frame(height: 110)
        .padding(AppLayout.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.darkSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadiusSmall))
        .padding(.horizontal, AppLayout.screenPadding)
    }
}
