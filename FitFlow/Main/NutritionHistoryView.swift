//
//  NutritionHistoryView.swift
//  FitFlow
//
//  Historical nutrition analytics with week/month/year filters.
//

import SwiftUI
import CoreData

struct NutritionHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext

    @State private var mealVM: MealViewModel?
    @State private var selectedPeriod: NutritionHistoryPeriod = .week
    @State private var points: [DailyNutritionPoint] = []

    private var hasAnyData: Bool {
        points.contains { $0.totalCalories > 0 }
    }

    private var averageCalories: Int {
        guard !points.isEmpty else { return 0 }
        return points.reduce(0) { $0 + $1.totalCalories } / points.count
    }

    private var averageProtein: Int {
        guard !points.isEmpty else { return 0 }
        let total = points.reduce(0.0) { $0 + $1.protein }
        return Int(round(total / Double(points.count)))
    }

    private var averageCarbs: Int {
        guard !points.isEmpty else { return 0 }
        let total = points.reduce(0.0) { $0 + $1.carbs }
        return Int(round(total / Double(points.count)))
    }

    private var averageFat: Int {
        guard !points.isEmpty else { return 0 }
        let total = points.reduce(0.0) { $0 + $1.fat }
        return Int(round(total / Double(points.count)))
    }

    private var totalMealsLogged: Int {
        points.reduce(0) { $0 + $1.mealsLogged }
    }

    private var daysWithThreeMeals: Int {
        points.filter { $0.breakfastCalories > 0 && $0.lunchCalories > 0 && $0.dinnerCalories > 0 }.count
    }

    private var visibleRows: [DailyNutritionPoint] {
        Array(
            points
                .filter { $0.mealsLogged > 0 || $0.totalCalories > 0 }
                .reversed()
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.darkBackground.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        periodSelector
                        chartSection
                        summarySection
                        dailyBreakdownSection
                    }
                    .padding(.horizontal, AppLayout.screenPadding)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Nutrition History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(AppColors.darkText)
                    }
                }
            }
            .navigationDestination(for: Date.self) { selectedDate in
                LogMealView(selectedDate: selectedDate, forceReadOnly: true, embedInNavigationStack: false)
            }
            .onAppear { loadData() }
            .onChange(of: selectedPeriod) { _ in
                refreshHistory()
            }
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        }
        .presentationDetents([.large])
    }

    private func loadData() {
        if mealVM == nil { mealVM = MealViewModel(context: viewContext) }
        refreshHistory()
    }

    private func refreshHistory() {
        points = mealVM?.dailyNutritionHistory(for: selectedPeriod) ?? []
    }

    private var periodSelector: some View {
        HStack(spacing: 8) {
            ForEach(NutritionHistoryPeriod.allCases) { period in
                Button {
                    selectedPeriod = period
                } label: {
                    Text(period.rawValue)
                        .font(AppTypography.callout().weight(.semibold))
                        .foregroundStyle(selectedPeriod == period ? .white : AppColors.darkTextSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(selectedPeriod == period ? AppColors.primaryGreen : AppColors.darkSurface)
                        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadiusSmall))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Daily Meal Calories")
                .font(AppTypography.title3())
                .foregroundStyle(AppColors.darkText)
            Text(dateRangeLabel)
                .font(AppTypography.caption2())
                .foregroundStyle(AppColors.darkTextSecondary)

            HStack(spacing: 14) {
                legendItem(color: AppColors.primaryGreen, label: "Breakfast")
                legendItem(color: AppColors.carbsBlue, label: "Lunch")
                legendItem(color: AppColors.fatsAmber, label: "Dinner")
            }

            if hasAnyData {
                NutritionMealLinesChart(points: points)
                    .frame(height: 220)
            } else {
                RoundedRectangle(cornerRadius: AppLayout.cornerRadiusSmall)
                    .fill(AppColors.darkBackground)
                    .frame(height: 220)
                    .overlay(
                        Text("No meal history for this period yet")
                            .font(AppTypography.caption())
                            .foregroundStyle(AppColors.darkTextSecondary)
                    )
            }
        }
        .padding(AppLayout.cardPadding)
        .background(AppColors.darkSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius))
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(AppTypography.caption2())
                .foregroundStyle(AppColors.darkTextSecondary)
        }
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Summary")
                .font(AppTypography.title3())
                .foregroundStyle(AppColors.darkText)

            HStack(spacing: 10) {
                summaryCard(title: "Avg Calories", value: "\(averageCalories) kcal")
                summaryCard(title: "Meals Logged", value: "\(totalMealsLogged)")
            }

            HStack(spacing: 10) {
                summaryCard(title: "Days 3 Meals", value: "\(daysWithThreeMeals)")
                summaryCard(title: "Avg Macros", value: "\(averageProtein)P \(averageCarbs)C \(averageFat)F")
            }
        }
    }

    private func summaryCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(AppTypography.caption2())
                .foregroundStyle(AppColors.darkTextSecondary)
            Text(value)
                .font(AppTypography.callout().weight(.semibold))
                .foregroundStyle(AppColors.darkText)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppLayout.cardPadding)
        .background(AppColors.darkSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadiusSmall))
    }

    private var dailyBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent Days")
                .font(AppTypography.title3())
                .foregroundStyle(AppColors.darkText)

            if visibleRows.isEmpty {
                Text("No history available for this period.")
                    .font(AppTypography.caption())
                    .foregroundStyle(AppColors.darkTextSecondary)
                    .padding(AppLayout.cardPadding)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppColors.darkSurface)
                    .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadiusSmall))
            } else {
                ForEach(visibleRows) { point in
                    NavigationLink(value: point.date) {
                        HStack(alignment: .center, spacing: 10) {
                            Text(shortDate(point.date))
                                .font(AppTypography.caption())
                                .foregroundStyle(AppColors.darkText)
                                .frame(width: 52, alignment: .leading)

                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 8) {
                                    macroLabel("B \(point.breakfastCalories)", color: AppColors.primaryGreen)
                                    macroLabel("L \(point.lunchCalories)", color: AppColors.carbsBlue)
                                    macroLabel("D \(point.dinnerCalories)", color: AppColors.fatsAmber)
                                }
                                HStack(spacing: 8) {
                                    Text("\(point.totalCalories) kcal")
                                        .font(AppTypography.caption2())
                                        .foregroundStyle(AppColors.darkTextSecondary)
                                    Text("•")
                                        .foregroundStyle(AppColors.darkTextSecondary)
                                    Text("\(point.mealsLogged) meals")
                                        .font(AppTypography.caption2())
                                        .foregroundStyle(AppColors.darkTextSecondary)
                                }
                            }
                            Spacer()
                        }
                        .padding(AppLayout.cardPadding)
                        .background(AppColors.darkSurface)
                        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadiusSmall))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func macroLabel(_ text: String, color: Color) -> some View {
        Text(text)
            .font(AppTypography.caption2())
            .foregroundStyle(color)
    }

    private func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    private var dateRangeLabel: String {
        guard let start = points.first?.date, let end = points.last?.date else { return "--" }
        return "\(shortDate(start)) - \(shortDate(end))"
    }
}

private struct NutritionMealLinesChart: View {
    let points: [DailyNutritionPoint]

    private var breakfastValues: [Int] { points.map(\.breakfastCalories) }
    private var lunchValues: [Int] { points.map(\.lunchCalories) }
    private var dinnerValues: [Int] { points.map(\.dinnerCalories) }

    private var maxY: Double {
        let maxValue = max(
            breakfastValues.max() ?? 0,
            lunchValues.max() ?? 0,
            dinnerValues.max() ?? 0
        )
        return Double(max(1, maxValue))
    }

    var body: some View {
        VStack(spacing: 8) {
            GeometryReader { geo in
                ZStack {
                    gridLines(size: geo.size)
                    line(values: breakfastValues, color: AppColors.primaryGreen, size: geo.size)
                    line(values: lunchValues, color: AppColors.carbsBlue, size: geo.size)
                    line(values: dinnerValues, color: AppColors.fatsAmber, size: geo.size)
                }
            }

            HStack {
                Text(axisLabel(points.first?.date))
                Spacer()
                Text(axisLabel(points[safe: points.count / 2]?.date))
                Spacer()
                Text(axisLabel(points.last?.date))
            }
            .font(AppTypography.caption2())
            .foregroundStyle(AppColors.darkTextSecondary)
        }
    }

    private func gridLines(size: CGSize) -> some View {
        ZStack {
            ForEach(0..<4, id: \.self) { idx in
                Path { path in
                    let y = size.height * CGFloat(idx) / 3
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                }
                .stroke(AppColors.darkTextSecondary.opacity(0.15), lineWidth: 1)
            }
        }
    }

    private func line(values: [Int], color: Color, size: CGSize) -> some View {
        let path = linePath(values: values, size: size)
        return ZStack {
            path.stroke(color, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
            if values.count <= 60 {
                ForEach(Array(values.enumerated()), id: \.offset) { idx, value in
                    let point = pointFor(index: idx, value: value, count: values.count, size: size)
                    Circle()
                        .fill(color)
                        .frame(width: 5, height: 5)
                        .position(point)
                }
            }
        }
    }

    private func linePath(values: [Int], size: CGSize) -> Path {
        Path { path in
            guard !values.isEmpty else { return }
            for (idx, value) in values.enumerated() {
                let point = pointFor(index: idx, value: value, count: values.count, size: size)
                if idx == 0 {
                    path.move(to: point)
                } else {
                    path.addLine(to: point)
                }
            }
        }
    }

    private func pointFor(index: Int, value: Int, count: Int, size: CGSize) -> CGPoint {
        let x: CGFloat
        if count > 1 {
            x = size.width * CGFloat(index) / CGFloat(count - 1)
        } else {
            x = size.width / 2
        }
        let yRatio = CGFloat(Double(value) / maxY)
        let y = size.height * (1 - yRatio)
        return CGPoint(x: x, y: y)
    }

    private func axisLabel(_ date: Date?) -> String {
        guard let date else { return "--" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
