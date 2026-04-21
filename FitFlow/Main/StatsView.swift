//
//  StatsView.swift
//  FitFlow
//
//  Analytics: period selector, Weight & Workouts cards, Weight Trend graph,
//  Log Weight – connected to Core Data.
//

import SwiftUI
import CoreData

struct StatsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    var sharedProfileVM: UserProfileViewModel? = nil
    var sharedProgressVM: ProgressViewModel? = nil
    @State private var selectedPeriod = "1M"
    @State private var showLogWeight = false
    @State private var newWeight = ""
    @State private var progressVM: ProgressViewModel?
    @State private var workoutVM: WorkoutViewModel?
    @State private var profileVM: UserProfileViewModel?

    let periods = ["1W", "1M", "3M", "1Y"]

    private static let lbPerKg = 2.205

    private var useMetric: Bool { profileVM?.useMetricSystem ?? true }

    private var latestWeight: String {
        guard let w = progressVM?.latestWeight else { return useMetric ? "-- kg" : "-- lb" }
        if useMetric {
            return String(format: "%.1f kg", w)
        }
        return String(format: "%.1f lb", w * Self.lbPerKg)
    }

    private var weightChangeStr: String {
        guard let pct = progressVM?.weightChangePercent else { return "--" }
        let sign = pct >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", pct))%"
    }

    private var isWeightChangePositive: Bool {
        (progressVM?.weightChangePercent ?? 0) >= 0
    }

    private var totalWorkouts: String {
        "\(workoutVM?.completedSessionCount ?? 0)"
    }

    private var trendEntries: [CDProgressEntry] {
        progressVM?.entriesForPeriod(selectedPeriod) ?? []
    }

    private var trendLabel: String {
        let change = progressVM?.weightTrendLast30Days ?? 0
        let sign = change >= 0 ? "+" : ""
        if useMetric {
            return "\(sign)\(String(format: "%.1f", change)) kg last 30 days"
        }
        return "\(sign)\(String(format: "%.1f", change * Self.lbPerKg)) lb last 30 days"
    }

    var body: some View {
        let _ = profileVM?.profileUpdateCounter
        return NavigationStack {
            ZStack {
                AppColors.darkBackground.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Text("Analytics")
                            .font(AppTypography.largeTitle())
                            .foregroundStyle(AppColors.darkText)
                            .padding(.horizontal, AppLayout.screenPadding)
                        HStack(spacing: 12) {
                            ForEach(periods, id: \.self) { p in
                                Button {
                                    selectedPeriod = p
                                } label: {
                                    Text(p)
                                        .font(AppTypography.callout().weight(.semibold))
                                        .foregroundStyle(selectedPeriod == p ? AppColors.primaryGreen : AppColors.darkTextSecondary)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        .background(selectedPeriod == p ? AppColors.primaryGreen.opacity(0.2) : Color.clear)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(selectedPeriod == p ? AppColors.primaryGreen : Color.clear, lineWidth: 1)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, AppLayout.screenPadding)
                        HStack(spacing: 12) {
                            statCard(icon: "scalemass.fill", label: "Weight", value: latestWeight, change: weightChangeStr, positive: !isWeightChangePositive)
                            statCard(icon: "dumbbell.fill", label: "Workouts", value: totalWorkouts, change: "", positive: true)
                        }
                        .padding(.horizontal, AppLayout.screenPadding)
                        weightTrendSection
                        logWeightButton
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .onAppear { loadData() }
            .sheet(isPresented: $showLogWeight, onDismiss: { profileVM?.loadProfile(); progressVM?.fetchEntries() }) {
                logWeightSheet
            }
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        }
    }

    private func loadData() {
        if profileVM == nil { profileVM = sharedProfileVM ?? UserProfileViewModel(context: viewContext) }
        if progressVM == nil { progressVM = sharedProgressVM ?? ProgressViewModel(context: viewContext) }
        if workoutVM == nil { workoutVM = WorkoutViewModel(context: viewContext) }
        profileVM?.loadProfile()
        progressVM?.fetchEntries()
        workoutVM?.fetchWorkouts()
    }

    private func statCard(icon: String, label: String, value: String, change: String, positive: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(AppColors.primaryGreen)
            Text(label)
                .font(AppTypography.caption2())
                .foregroundStyle(AppColors.darkTextSecondary)
            Text(value)
                .font(AppTypography.title())
                .foregroundStyle(AppColors.darkText)
            if !change.isEmpty {
                Text(change)
                    .font(AppTypography.caption2())
                    .foregroundStyle(positive ? AppColors.primaryGreen : AppColors.negativeRed)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppLayout.cardPadding)
        .background(AppColors.darkSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadiusSmall))
    }

    private var weightTrendSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Weight Trend")
                    .font(AppTypography.title3())
                    .foregroundStyle(AppColors.darkText)
                Spacer()
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundStyle(AppColors.darkTextSecondary)
            }
            Text(trendLabel)
                .font(AppTypography.caption())
                .foregroundStyle(AppColors.darkTextSecondary)
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: AppLayout.cornerRadiusSmall)
                    .fill(AppColors.darkSurface)
                    .frame(height: 180)
                if !trendEntries.isEmpty {
                    trendChart
                        .padding(20)
                } else {
                    Text("Log weight to see your trend")
                        .font(AppTypography.caption())
                        .foregroundStyle(AppColors.darkTextSecondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(height: 200)
            if !trendEntries.isEmpty {
                HStack {
                    if let first = trendEntries.first?.date {
                        Text(formatShortDate(first))
                    }
                    Spacer()
                    Text("Today")
                }
                .font(AppTypography.caption2())
                .foregroundStyle(AppColors.darkTextSecondary)
            }
        }
        .padding(AppLayout.screenPadding)
        .background(AppColors.darkSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius))
        .padding(.horizontal, AppLayout.screenPadding)
    }

    @ViewBuilder
    private var trendChart: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let weights = trendEntries.map { $0.weightKg }
            let minW = (weights.min() ?? 0) - 1
            let maxW = (weights.max() ?? 100) + 1
            let range = maxW - minW

            Path { p in
                for (index, entry) in trendEntries.enumerated() {
                    let x = trendEntries.count > 1 ? w * CGFloat(index) / CGFloat(trendEntries.count - 1) : w / 2
                    let y = range > 0 ? h * (1 - CGFloat((entry.weightKg - minW) / range)) : h / 2
                    if index == 0 {
                        p.move(to: CGPoint(x: x, y: y))
                    } else {
                        p.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(AppColors.primaryGreen, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))

            // Data point dots
            ForEach(Array(trendEntries.enumerated()), id: \.offset) { index, entry in
                let x = trendEntries.count > 1 ? w * CGFloat(index) / CGFloat(trendEntries.count - 1) : w / 2
                let y = range > 0 ? h * (1 - CGFloat((entry.weightKg - minW) / range)) : h / 2
                Circle()
                    .fill(AppColors.primaryGreen)
                    .frame(width: 8, height: 8)
                    .position(x: x, y: y)
            }
        }
    }

    private var logWeightButton: some View {
        Group {
            if progressVM?.hasLoggedWeightToday == true {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppColors.primaryGreen)
                    Text("Weight logged for today")
                        .font(AppTypography.body())
                        .foregroundStyle(AppColors.darkTextSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppColors.darkSurface)
                .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadiusSmall))
                .padding(.horizontal, AppLayout.screenPadding)
                .padding(.bottom, 40)
            } else {
                Button {
                    newWeight = ""
                    showLogWeight = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Log Weight")
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, AppLayout.screenPadding)
                .padding(.bottom, 40)
            }
        }
    }

    private var logWeightSheet: some View {
        NavigationStack {
            ZStack {
                AppColors.darkBackground.ignoresSafeArea()
                VStack(spacing: 24) {
                    Text("Log Today's Weight")
                        .font(AppTypography.title())
                        .foregroundStyle(AppColors.darkText)
                    TextField(useMetric ? "Weight in kg" : "Weight in lb", text: $newWeight)
                        .font(AppTypography.title3())
                        .foregroundStyle(AppColors.darkText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppLayout.cardPadding)
                        .padding(.vertical, 14)
                        .background(AppColors.darkSurface)
                        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadiusSmall))
                        .padding(.horizontal, AppLayout.screenPadding)
                    Button("Save") {
                        if let input = Double(newWeight), input > 0 {
                            let weightKg = useMetric ? input : input / Self.lbPerKg
                            let result = progressVM?.logTodayWeight(weightKg: weightKg)
                            if result != .alreadyLoggedToday {
                                profileVM?.loadProfile()
                                progressVM?.fetchEntries()
                                newWeight = ""
                                showLogWeight = false
                            }
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.horizontal, AppLayout.screenPadding)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showLogWeight = false } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(AppColors.darkText)
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func formatShortDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: date)
    }
}

#Preview {
    StatsView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
