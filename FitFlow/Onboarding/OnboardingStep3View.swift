//
//  OnboardingStep3View.swift
//  FitFlow
//
//  Step 3 of 4 – Build Your Habit. Days per week (1–7), Preferred Workout Time (hour + minute picker), Get Started.
//

import SwiftUI

struct OnboardingStep3View: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        ZStack {
            AppColors.darkBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        OnboardingHeader(title: "Step 3 of 4", isLight: false, onBack: { viewModel.previousStep() })
                            .padding(.horizontal, AppLayout.screenPadding)
                        OnboardingProgressBar(step: 2, total: 4, useGreen: true)
                            .padding(.horizontal, AppLayout.screenPadding)
                            .padding(.bottom, 8)
                        Text("Build Your Habit")
                            .font(AppTypography.title())
                            .foregroundStyle(AppColors.darkText)
                            .padding(.horizontal, AppLayout.screenPadding)
                        Text("Consistency is the key to progress. Let's set a realistic goal that fits your lifestyle.")
                            .font(AppTypography.body())
                            .foregroundStyle(AppColors.darkTextSecondary)
                            .padding(.horizontal, AppLayout.screenPadding)
                        HStack(spacing: 8) {
                            Image(systemName: "calendar")
                                .foregroundStyle(AppColors.primaryGreen)
                            Text("How often do you want to train?")
                                .font(AppTypography.title3())
                                .foregroundStyle(AppColors.darkText)
                        }
                        .padding(.horizontal, AppLayout.screenPadding)
                        HStack(spacing: 12) {
                            ForEach(1...7, id: \.self) { n in
                                Button {
                                    viewModel.daysPerWeek = n
                                    viewModel.syncSelectedWeekdaysToCount()
                                } label: {
                                    Text("\(n)")
                                        .font(AppTypography.callout().weight(.semibold))
                                        .foregroundStyle(viewModel.daysPerWeek == n ? .white : AppColors.darkText)
                                        .frame(width: 44, height: 44)
                                        .background(viewModel.daysPerWeek == n ? AppColors.primaryGreen : AppColors.darkSurface)
                                        .clipShape(Circle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, AppLayout.screenPadding)
                        Text("days per week")
                            .font(AppTypography.caption())
                            .foregroundStyle(AppColors.darkTextSecondary)
                            .padding(.horizontal, AppLayout.screenPadding)
                        HStack(spacing: 8) {
                            Image(systemName: "calendar.badge.clock")
                                .foregroundStyle(AppColors.primaryGreen)
                            Text("Which days?")
                                .font(AppTypography.title3())
                                .foregroundStyle(AppColors.darkText)
                        }
                        .padding(.horizontal, AppLayout.screenPadding)
                        .padding(.top, 16)
                        HStack(spacing: 10) {
                            ForEach(1...7, id: \.self) { dayIndex in
                                let labels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
                                let label = labels[dayIndex - 1]
                                let isSelected = viewModel.selectedWeekdayIndices.contains(dayIndex)
                                Button {
                                    viewModel.toggleWeekday(dayIndex)
                                } label: {
                                    Text(label)
                                        .font(AppTypography.caption2().weight(.semibold))
                                        .foregroundStyle(isSelected ? .white : AppColors.darkText)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(isSelected ? AppColors.primaryGreen : AppColors.darkSurface)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                .buttonStyle(.plain)
                                .disabled(!viewModel.canToggleWeekday(dayIndex))
                            }
                        }
                        .padding(.horizontal, AppLayout.screenPadding)
                        HStack(spacing: 8) {
                            Image(systemName: "clock")
                                .foregroundStyle(AppColors.primaryGreen)
                            Text("Preferred Workout Time")
                                .font(AppTypography.title3())
                                .foregroundStyle(AppColors.darkText)
                        }
                        .padding(.horizontal, AppLayout.screenPadding)
                        timePickerCard
                        Spacer(minLength: 80)
                    }
                    .padding(.vertical, 8)
                }
                Button {
                    viewModel.nextStep()
                } label: {
                    HStack {
                        Text("Get Started")
                        Image(systemName: "arrow.right")
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, AppLayout.screenPadding)
                .padding(.top, 16)
                .padding(.bottom, 32)
                .background(AppColors.darkBackground)
            }
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }

    private var timePickerCard: some View {
        let selection = Binding<Date>(
            get: { viewModel.selectedWorkoutTime },
            set: { viewModel.selectedWorkoutTime = $0 }
        )
        return DatePicker(
            "Workout time",
            selection: selection,
            displayedComponents: .hourAndMinute
        )
        .datePickerStyle(.wheel)
        .labelsHidden()
        .colorScheme(.dark)
        .tint(AppColors.primaryGreen)
        .frame(height: 140)
        .padding(.horizontal, 8)
        .background(AppColors.darkSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadiusSmall))
        .padding(.horizontal, AppLayout.screenPadding)
    }
}
