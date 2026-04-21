//
//  OnboardingStep1View.swift
//  FitFlow
//
//  Step 1 of 4 – body metrics. Height (cm/inch), Weight (kg/lb), Age, Gender. Continue pinned at bottom.
//

import SwiftUI

struct OnboardingStep1View: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        ZStack {
            AppColors.darkBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        OnboardingHeader(title: "Step 1 of 4", isLight: false, onBack: { viewModel.previousStep() })
                            .padding(.horizontal, AppLayout.screenPadding)
                        OnboardingProgressBar(step: 0, total: 4, useGreen: false)
                            .padding(.horizontal, AppLayout.screenPadding)
                            .padding(.bottom, 4)
                        Text("To Create your personalized plan, We need a few details about your body metrics.")
                            .font(AppTypography.callout())
                            .foregroundStyle(AppColors.darkTextSecondary)
                            .padding(.horizontal, AppLayout.screenPadding)
                        heightRow
                        weightRow
                        ageRow
                        Text("Gender")
                            .font(AppTypography.title3())
                            .foregroundStyle(AppColors.darkText)
                            .padding(.horizontal, AppLayout.screenPadding)
                        HStack(spacing: 10) {
                            ForEach([GenderOption.male, GenderOption.female], id: \.self) { option in
                                Button {
                                    viewModel.selectedGender = option
                                } label: {
                                    VStack(spacing: 4) {
                                        Text(option.symbol)
                                            .font(.title3)
                                        Text(option.rawValue)
                                            .font(AppTypography.caption())
                                    }
                                    .foregroundStyle(viewModel.selectedGender == option ? AppColors.onboardingBlue : AppColors.darkTextSecondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(AppColors.darkSurface)
                                    .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadiusSmall))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, AppLayout.screenPadding)
                        Spacer(minLength: 16)
                    }
                    .padding(.vertical, 4)
                }
                .scrollDismissesKeyboard(.interactively)
                continueButton
            }
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }

    private var heightRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Height")
                .font(AppTypography.callout().weight(.semibold))
                .foregroundStyle(AppColors.darkText)
            HStack {
                TextField("Height", value: Binding(
                    get: { viewModel.heightDisplayValue },
                    set: { viewModel.setHeightFromDisplay($0) }
                ), format: .number)
                .font(AppTypography.title3())
                .foregroundStyle(AppColors.darkText)
                .keyboardType(.numberPad)
                .frame(maxWidth: .infinity, alignment: .leading)
                Button {
                    viewModel.heightUnitIsCm.toggle()
                } label: {
                    Text(viewModel.heightUnitIsCm ? "cm" : "in")
                        .font(AppTypography.caption())
                        .foregroundStyle(AppColors.darkTextSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(AppColors.darkSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, AppLayout.cardPadding)
            .padding(.vertical, 14)
            .background(AppColors.darkSurface)
            .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadiusSmall))
        }
        .padding(.horizontal, AppLayout.screenPadding)
    }

    private var weightRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Weight")
                .font(AppTypography.callout().weight(.semibold))
                .foregroundStyle(AppColors.darkText)
            HStack {
                TextField("Weight", value: Binding(
                    get: { viewModel.weightDisplayValue },
                    set: { viewModel.setWeightFromDisplay($0) }
                ), format: .number)
                .font(AppTypography.title3())
                .foregroundStyle(AppColors.darkText)
                .keyboardType(.numberPad)
                .frame(maxWidth: .infinity, alignment: .leading)
                Button {
                    viewModel.weightUnitIsKg.toggle()
                } label: {
                    Text(viewModel.weightUnitIsKg ? "kg" : "lb")
                        .font(AppTypography.caption())
                        .foregroundStyle(AppColors.darkTextSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(AppColors.darkSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, AppLayout.cardPadding)
            .padding(.vertical, 14)
            .background(AppColors.darkSurface)
            .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadiusSmall))
        }
        .padding(.horizontal, AppLayout.screenPadding)
    }

    private var ageRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Age")
                .font(AppTypography.callout().weight(.semibold))
                .foregroundStyle(AppColors.darkText)
            TextField("Age", value: $viewModel.age, format: .number)
                .font(AppTypography.title3())
                .foregroundStyle(AppColors.darkText)
                .keyboardType(.numberPad)
                .padding(.horizontal, AppLayout.cardPadding)
                .padding(.vertical, 14)
                .background(AppColors.darkSurface)
                .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadiusSmall))
        }
        .padding(.horizontal, AppLayout.screenPadding)
    }

    private var continueButton: some View {
        VStack(spacing: 0) {
            Button("Continue") { viewModel.nextStep() }
                .buttonStyle(PrimaryButtonStyle(color: AppColors.onboardingBlue))
                .disabled(!viewModel.canProceedFromStep1)
                .opacity(viewModel.canProceedFromStep1 ? 1 : 0.6)
                .padding(.horizontal, AppLayout.screenPadding)
        }
        .padding(.top, 16)
        .padding(.bottom, 32)
        .background(AppColors.darkBackground)
    }
}
