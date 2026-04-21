//
//  OnboardingStep2View.swift
//  FitFlow
//
//  Step 2 of 4 – What is your main goal? Dark theme, 2x2 grid: Lose Weight, Build Muscle, Stay Fit, Improve Endurance.
//

import SwiftUI

struct OnboardingStep2View: View {
    var viewModel: OnboardingViewModel

    var body: some View {
        ZStack {
            AppColors.darkBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        OnboardingHeader(title: "Step 2 of 4", isLight: false, onBack: { viewModel.previousStep() })
                            .padding(.horizontal, AppLayout.screenPadding)
                        OnboardingProgressBar(step: 1, total: 4, useGreen: false)
                            .padding(.horizontal, AppLayout.screenPadding)
                            .padding(.bottom, 8)
                        Text("What is your main goal?")
                            .font(AppTypography.title())
                            .foregroundStyle(AppColors.darkText)
                            .padding(.horizontal, AppLayout.screenPadding)
                        Text("Select what matters most to you right now. This helps us tailor your workout plan.")
                            .font(AppTypography.body())
                            .foregroundStyle(AppColors.darkTextSecondary)
                            .padding(.horizontal, AppLayout.screenPadding)
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(GoalOption.allCases) { option in
                                Button {
                                    viewModel.selectedGoal = option
                                } label: {
                                    VStack(spacing: 12) {
                                        Image(systemName: option.icon)
                                            .font(.title2)
                                        Text(option.rawValue)
                                            .font(AppTypography.caption())
                                            .multilineTextAlignment(.center)
                                    }
                                    .foregroundStyle(viewModel.selectedGoal == option ? AppColors.onboardingBlue : AppColors.darkText)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 20)
                                    .background(AppColors.darkSurface)
                                    .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadiusSmall))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AppLayout.cornerRadiusSmall)
                                            .stroke(viewModel.selectedGoal == option ? AppColors.onboardingBlue : Color.clear, lineWidth: 2)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, AppLayout.screenPadding)
                        Spacer(minLength: 80)
                    }
                    .padding(.vertical, 8)
                }
                Button("Continue") {
                    guard viewModel.canProceedFromStep2 else { return }
                    viewModel.nextStep()
                }
                .buttonStyle(PrimaryButtonStyle(color: AppColors.onboardingBlue))
                .disabled(!viewModel.canProceedFromStep2)
                .opacity(viewModel.canProceedFromStep2 ? 1 : 0.6)
                .padding(.horizontal, AppLayout.screenPadding)
                .padding(.top, 16)
                .padding(.bottom, 32)
                .background(AppColors.darkBackground)
            }
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }
}
