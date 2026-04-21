//
//  LogMealView.swift
//  FitFlow
//
//  Today's Nutrition: remaining calories ring, macros, search, meals – connected to Core Data.
//

import SwiftUI
import CoreData

struct LogMealView: View {
    private let selectedDate: Date
    private let forceReadOnly: Bool
    private let embedInNavigationStack: Bool

    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showNutritionHistory = false
    @State private var mealVM: MealViewModel?
    @State private var profileVM: UserProfileViewModel?
    @State private var foodItemToDelete: CDFoodItem?
    @State private var showDeleteFoodAlert = false

    init(selectedDate: Date = Date(), forceReadOnly: Bool = false, embedInNavigationStack: Bool = true) {
        self.selectedDate = selectedDate
        self.forceReadOnly = forceReadOnly
        self.embedInNavigationStack = embedInNavigationStack
    }

    private var calorieGoal: Int { profileVM?.dailyCalorieGoal ?? 2000 }
    private var consumed: Int { mealVM?.totalCaloriesToday ?? 0 }
    private var remaining: Int { max(0, calorieGoal - consumed) }
    private var progress: Double { calorieGoal > 0 ? min(1, Double(consumed) / Double(calorieGoal)) : 0 }

    private var proteinTotal: String { String(format: "%.0fg", mealVM?.totalProteinToday ?? 0) }
    private var carbsTotal: String { String(format: "%.0fg", mealVM?.totalCarbsToday ?? 0) }
    private var fatTotal: String { String(format: "%.0fg", mealVM?.totalFatToday ?? 0) }

    private var isPastDay: Bool {
        let calendar = Calendar.current
        return calendar.startOfDay(for: selectedDate) < calendar.startOfDay(for: Date())
    }

    private var isReadOnly: Bool {
        forceReadOnly || isPastDay
    }

    private var titleText: String {
        if Calendar.current.isDateInToday(selectedDate) {
            return "Today's Nutrition"
        }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "Nutrition • \(formatter.string(from: selectedDate))"
    }

    var body: some View {
        Group {
            if embedInNavigationStack {
                NavigationStack { content }
            } else {
                content
            }
        }
    }

    private var content: some View {
        ZStack {
            AppColors.darkBackground.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    remainingRing
                    macroCards
                    yourMealsSection
                }
            }
        }
        .navigationTitle(titleText)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(AppColors.darkBackground, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(AppColors.darkText)
                }
            }
            if !isReadOnly {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showNutritionHistory = true
                    } label: {
                        Image(systemName: "calendar")
                            .foregroundStyle(AppColors.darkText)
                    }
                }
            }
        }
        .navigationDestination(for: AddFoodMealType.self) { mealType in
            AddFoodView(mealType: mealType, targetDate: selectedDate, mealVM: mealVM)
        }
        .sheet(isPresented: $showNutritionHistory) {
            NutritionHistoryView()
        }
        .onAppear { loadData() }
        .alert("Delete food?", isPresented: $showDeleteFoodAlert) {
            Button("Delete", role: .destructive) {
                if let item = foodItemToDelete {
                    mealVM?.deleteFoodItem(item)
                }
                foodItemToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                foodItemToDelete = nil
            }
        } message: {
            Text("This will remove this food from today’s nutrition log.")
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }

    private func loadData() {
        if mealVM == nil { mealVM = MealViewModel(context: viewContext) }
        if profileVM == nil { profileVM = UserProfileViewModel(context: viewContext) }
        mealVM?.fetchMeals(for: selectedDate)
        profileVM?.loadProfile()
    }

    private var remainingRing: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(AppColors.darkSurface, lineWidth: 16)
                    .frame(width: 200, height: 200)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(AppColors.primaryGreen, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: progress)
                VStack(spacing: 0) {
                    Text("REMAINING")
                        .font(AppTypography.caption2())
                        .foregroundStyle(AppColors.darkTextSecondary)
                    Text("\(remaining)")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundStyle(AppColors.darkText)
                    Text("Kcal")
                        .font(AppTypography.callout())
                        .foregroundStyle(AppColors.primaryGreen)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 16)
    }

    private var macroCards: some View {
        HStack(spacing: 12) {
            macroCard(label: "Protein", value: proteinTotal, color: AppColors.primaryGreen)
            macroCard(label: "Carbs", value: carbsTotal, color: AppColors.carbsBlue)
            macroCard(label: "Fats", value: fatTotal, color: AppColors.fatsAmber)
        }
        .padding(.horizontal, AppLayout.screenPadding)
    }

    private func macroCard(label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                Text(label)
                    .font(AppTypography.caption2())
                    .foregroundStyle(AppColors.darkTextSecondary)
            }
            Text(value)
                .font(AppTypography.title3())
                .foregroundStyle(AppColors.darkText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppLayout.cardPadding)
        .background(AppColors.darkSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadiusSmall))
    }

    private var yourMealsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Meals")
                .font(AppTypography.title3())
                .foregroundStyle(AppColors.darkText)
                .padding(.horizontal, AppLayout.screenPadding)

            ForEach(AddFoodMealType.allCases, id: \.self) { mealType in
                let mealsForType = mealVM?.mealsForType(mealType.rawValue) ?? []
                mealTypeBlock(mealType: mealType, mealsForType: mealsForType)
            }
        }
        .padding(.bottom, 40)
    }

    private func mealTypeBlock(mealType: AddFoodMealType, mealsForType: [CDMeal]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(mealsForType, id: \.objectID) { meal in
                VStack(alignment: .leading, spacing: 8) {
                    singleMealRow(mealType: mealType, meal: meal)
                        .contextMenu {
                            if !isReadOnly {
                                Button("Delete meal", role: .destructive) {
                                    mealVM?.deleteMeal(meal)
                                }
                            }
                        }

                    let foodItems = mealVM?.foodItemsForMeal(meal) ?? []
                    ForEach(foodItems, id: \.objectID) { item in
                        mealFoodRow(foodItem: item)
                    }
                }
            }
            if mealsForType.isEmpty {
                mealRow(
                    meal: mealType.rawValue,
                    mealType: mealType,
                    time: "--",
                    title: isReadOnly ? "No meal logged" : "Add your first meal",
                    kcal: nil,
                    showsAddAction: false
                )
            }
            if !isReadOnly {
                NavigationLink(value: mealType) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle")
                        Text("Add Food")
                            .font(AppTypography.callout())
                    }
                    .foregroundStyle(AppColors.primaryGreen)
                }
                .padding(.horizontal, AppLayout.screenPadding)
            }
        }
    }

    private func singleMealRow(mealType: AddFoodMealType, meal: CDMeal) -> some View {
        let foodItems = mealVM?.foodItemsForMeal(meal) ?? []
        let title = foodItems.isEmpty ? "No items" : foodItems.map { $0.name ?? "" }.joined(separator: ", ")
        let kcal = mealVM?.caloriesForMeal(meal) ?? 0
        return mealRow(
            meal: mealType.rawValue,
            mealType: mealType,
            time: meal.date.map { formatTime($0) } ?? "--",
            title: title,
            kcal: kcal > 0 ? kcal : nil,
            showsAddAction: false
        )
    }

    private func mealFoodRow(foodItem: CDFoodItem) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(AppColors.darkSurface)
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: "leaf")
                        .font(.footnote)
                        .foregroundStyle(AppColors.darkTextSecondary)
                )
            VStack(alignment: .leading, spacing: 2) {
                Text(foodItem.name ?? "Food")
                    .font(AppTypography.body())
                    .foregroundStyle(AppColors.darkText)
                    .lineLimit(1)
                Text("\(Int(foodItem.quantityGrams))g • \(Int(round(foodItem.caloriesPer100g * (foodItem.quantityGrams / 100)))) kcal")
                    .font(AppTypography.caption2())
                    .foregroundStyle(AppColors.darkTextSecondary)
            }
            Spacer()
        }
        .padding(.horizontal, AppLayout.screenPadding)
        .padding(.vertical, 6)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            if !isReadOnly {
                Button(role: .destructive) {
                    foodItemToDelete = foodItem
                    showDeleteFoodAlert = true
                } label: {
                    Text("Delete")
                }
            }
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"
        return formatter.string(from: date)
    }

    private func mealRow(meal: String, mealType: AddFoodMealType, time: String, title: String, kcal: Int?, showsAddAction: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(AppColors.darkSurface)
                        .frame(width: 44, height: 44)
                    Image(systemName: meal == "Breakfast" ? "cup.and.saucer.fill" : meal == "Lunch" ? "takeoutbag.and.cup.and.straw.fill" : "fork.knife")
                        .foregroundStyle(AppColors.darkTextSecondary)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(meal)
                        .font(AppTypography.callout().weight(.semibold))
                        .foregroundStyle(AppColors.darkText)
                    Text(time)
                        .font(AppTypography.caption2())
                        .foregroundStyle(AppColors.darkTextSecondary)
                    Text(title)
                        .font(AppTypography.body())
                        .foregroundStyle(AppColors.darkText)
                        .lineLimit(2)
                }
                Spacer()
                if let k = kcal, k > 0 {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(k)")
                            .font(AppTypography.title3())
                            .foregroundStyle(AppColors.darkText)
                        Text("\(k) Kcal")
                            .font(AppTypography.caption2())
                            .foregroundStyle(AppColors.darkTextSecondary)
                    }
                }
            }
            .padding(AppLayout.cardPadding)
            .background(AppColors.darkSurface)
            .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadiusSmall))
            if showsAddAction {
                NavigationLink(value: mealType) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle")
                        Text("Add Food")
                            .font(AppTypography.callout())
                    }
                    .foregroundStyle(AppColors.primaryGreen)
                }
                .padding(.horizontal, AppLayout.screenPadding)
            }
        }
        .padding(.horizontal, AppLayout.screenPadding)
    }
}

#Preview {
    LogMealView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
