//
//  DashboardView.swift
//  FitFlow
//
//  Dashboard: Welcome back {name}, calorie/workout KPIs,
//  Start Workout, Log Meal – connected to Core Data.
//

import SwiftUI
import CoreData

struct DashboardView: View {
    @Environment(\.managedObjectContext) private var viewContext
    var sharedProfileVM: UserProfileViewModel? = nil
    @State private var showLogMeal = false
    @State private var showStartWorkout = false
    @State private var profileVM: UserProfileViewModel?
    @State private var workoutVM: WorkoutViewModel?
    @State private var mealVM: MealViewModel?

    private var userName: String {
        let fullName = profileVM?.fullName ?? "User"
        return fullName.components(separatedBy: " ").first ?? fullName
    }

    private var calorieGoal: Int { profileVM?.dailyCalorieGoal ?? 2000 }
    private var caloriesConsumed: Int { mealVM?.totalCaloriesToday ?? 0 }
    private var caloriesRemaining: Int { max(0, calorieGoal - caloriesConsumed) }

    var body: some View {
        let _ = profileVM?.profileUpdateCounter
        return NavigationStack {
            ZStack {
                AppColors.darkBackground.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        topBar
                        caloriesSummary
                        todaysSummarySection
                        tipCard
                        actionButtons
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showLogMeal) {
                LogMealView()
            }
            .sheet(isPresented: $showStartWorkout, onDismiss: {
                workoutVM?.fetchWorkouts()
            }) {
                StartWorkoutView()
            }
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            .onAppear { loadViewModels() }
        }
    }

    private func loadViewModels() {
        if profileVM == nil { profileVM = sharedProfileVM ?? UserProfileViewModel(context: viewContext) }
        if workoutVM == nil { workoutVM = WorkoutViewModel(context: viewContext) }
        if mealVM == nil { mealVM = MealViewModel(context: viewContext) }
        profileVM?.loadProfile()
        workoutVM?.fetchWorkouts()
        mealVM?.fetchTodaysMeals()
    }

    private var topBar: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Welcome back, \(userName)")
                .font(AppTypography.title())
                .foregroundStyle(AppColors.darkText)
            Text("Ready for your next session?")
                .font(AppTypography.caption())
                .foregroundStyle(AppColors.darkTextSecondary)
        }
        .padding(.horizontal, AppLayout.screenPadding)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    private var caloriesSummary: some View {
        HStack(spacing: 12) {
            summaryCard(label: "Consumed", value: "\(caloriesConsumed)", unit: "kcal", color: AppColors.primaryGreen)
            summaryCard(label: "Remaining", value: "\(caloriesRemaining)", unit: "kcal", color: AppColors.carbsBlue)
            summaryCard(label: "Workouts", value: "\(workoutVM?.completedTodayCount ?? 0)", unit: "today", color: AppColors.fatsAmber)
        }
        .padding(.horizontal, AppLayout.screenPadding)
    }

    private var todaysSummaryMessage: String {
        let workouts = workoutVM?.completedTodayCount ?? 0
        let meals = mealVM?.loadedMeals.count ?? 0
        if caloriesConsumed > 0 && workouts > 0 {
            return "You've logged \(caloriesConsumed) kcal and \(workouts) workout\(workouts == 1 ? "" : "s") today. Keep it up."
        }
        if caloriesConsumed > 0 {
            return "\(caloriesConsumed) kcal in so far. Start a workout or log another meal to round out your day."
        }
        if workouts > 0 {
            return "\(workouts) workout\(workouts == 1 ? "" : "s") done. Log a meal to track your nutrition too."
        }
        return "Your day is a blank slate. Start a workout or log a meal to begin."
    }

    private var todaysSummarySection: some View {
        Text(todaysSummaryMessage)
            .font(AppTypography.body())
            .foregroundStyle(AppColors.darkTextSecondary)
            .padding(AppLayout.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.darkSurface)
            .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadiusSmall))
            .padding(.horizontal, AppLayout.screenPadding)
    }

    private var tipCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 20))
                .foregroundStyle(AppColors.fatsAmber)
            VStack(alignment: .leading, spacing: 4) {
                Text("Tip")
                    .font(AppTypography.caption2())
                    .foregroundStyle(AppColors.darkTextSecondary)
                Text(dashboardTip)
                    .font(AppTypography.callout())
                    .foregroundStyle(AppColors.darkText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(AppLayout.cardPadding)
        .background(AppColors.darkSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadiusSmall))
        .padding(.horizontal, AppLayout.screenPadding)
    }

    private var dashboardTip: String {
        let tips = [
            "Consistency beats intensity. Short daily sessions add up more than rare marathons.",
            "Log meals soon after eating for the most accurate calorie tracking.",
            "Stay hydrated — it helps energy and recovery. Aim for a glass with each meal.",
            "Mix strength and cardio. Both support weight and heart health.",
        ]
        let day = Calendar.current.component(.day, from: Date())
        return tips[day % tips.count]
    }

    private func summaryCard(label: String, value: String, unit: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(AppTypography.caption2())
                .foregroundStyle(AppColors.darkTextSecondary)
            Text(value)
                .font(AppTypography.title3())
                .foregroundStyle(AppColors.darkText)
            Text(unit)
                .font(AppTypography.caption2())
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppLayout.cardPadding)
        .background(AppColors.darkSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadiusSmall))
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                showStartWorkout = true
            } label: {
                HStack {
                    Image(systemName: "dumbbell.fill")
                    Text("Start Workout")
                }
            }
            .buttonStyle(PrimaryButtonStyle(color: AppColors.onboardingBlue))
            Button {
                showLogMeal = true
            } label: {
                HStack {
                    Image(systemName: "fork.knife")
                    Text("Log Meal")
                }
            }
            .buttonStyle(SecondaryButtonStyle())
        }
        .padding(.horizontal, AppLayout.screenPadding)
        .padding(.top, 8)
        .padding(.bottom, 32)
    }
}

#Preview {
    DashboardView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
