//
//  WorkoutsListView.swift
//  FitFlow
//
//  Workouts tab – search, filters, workouts list from Core Data, templates.
//

import SwiftUI
import CoreData

// MARK: - Category filter (shared with AddWorkoutView; templates from MockWorkoutData)

enum WorkoutCategory: String, CaseIterable {
    case all = "All"
    case strength = "Strength"
    case cardio = "Cardio"
    case yoga = "Yoga"
}

private struct SavedWorkoutSelection: Identifiable {
    let id: NSManagedObjectID
}

// MARK: - View

struct WorkoutsListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    var sharedProfileVM: UserProfileViewModel? = nil
    @State private var searchText = ""
    @State private var selectedFilter: WorkoutCategory = .all
    @State private var showAddWorkout = false
    @State private var selectedSavedWorkout: SavedWorkoutSelection?
    @State private var selectedTemplate: WorkoutItem?
    @State private var showTemplateSavedAlert = false
    @State private var savedTemplateTitle = ""
    @State private var workoutVM: WorkoutViewModel?
    @State private var profileVM: UserProfileViewModel?

    private static let lbPerKg = 2.205
    private var useMetric: Bool { profileVM?.useMetricSystem ?? true }

    private var loggedWorkouts: [CDWorkout] {
        var list = workoutVM?.workouts ?? []
        if selectedFilter != .all {
            list = list.filter { $0.category == selectedFilter.rawValue }
        }
        if !searchText.isEmpty {
            list = list.filter {
                ($0.title ?? "").localizedCaseInsensitiveContains(searchText) ||
                ($0.category ?? "").localizedCaseInsensitiveContains(searchText) ||
                sortedExercises(for: $0).contains { ($0.name ?? "").localizedCaseInsensitiveContains(searchText) }
            }
        }
        return list
    }

    private var filteredTemplates: [WorkoutItem] {
        var list = MockWorkoutData.globalWorkoutTemplates
        if selectedFilter != .all {
            list = list.filter { $0.category == selectedFilter }
        }
        if !searchText.isEmpty {
            list = list.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.targetMuscles.localizedCaseInsensitiveContains(searchText) ||
                $0.summary.localizedCaseInsensitiveContains(searchText) ||
                $0.exercises.contains { $0.name.localizedCaseInsensitiveContains(searchText) }
            }
        }
        return list
    }

    var body: some View {
        let _ = profileVM?.profileUpdateCounter
        return NavigationStack {
            ZStack {
                AppColors.darkBackground.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        searchBar
                        filterChips
                        if !loggedWorkouts.isEmpty {
                            sectionHeader("YOUR WORKOUTS")
                            loggedWorkoutRows
                        }
                        sectionHeader("AVAILABLE WORKOUTS")
                        workoutRows
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(AppColors.darkBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Workouts")
                        .font(AppTypography.title().weight(.bold))
                        .foregroundStyle(AppColors.darkText)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddWorkout = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(AppColors.primaryGreen)
                    }
                }
            }
            .sheet(isPresented: $showAddWorkout) {
                AddWorkoutView()
            }
            .sheet(item: $selectedSavedWorkout) { selection in
                if let workout = workoutFromObjectID(selection.id) {
                    SavedWorkoutDetailView(
                        workout: workout,
                        onWorkoutUpdated: { workoutVM?.fetchWorkouts() },
                        onDelete: {
                            workoutVM?.deleteWorkout(workout)
                            selectedSavedWorkout = nil
                        }
                    )
                } else {
                    workoutUnavailableView
                }
            }
            .sheet(item: $selectedTemplate) { template in
                TemplateWorkoutDetailView(workout: template, useMetric: useMetric) {
                    saveTemplateWorkout(template)
                }
            }
            .alert("Workout Saved", isPresented: $showTemplateSavedAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("\"\(savedTemplateTitle)\" was added to your workouts.")
            }
            .onAppear { loadData() }
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        }
    }

    private func loadData() {
        if profileVM == nil { profileVM = sharedProfileVM ?? UserProfileViewModel(context: viewContext) }
        if workoutVM == nil { workoutVM = WorkoutViewModel(context: viewContext) }
        profileVM?.loadProfile()
        workoutVM?.fetchWorkouts()
    }

    private func workoutFromObjectID(_ id: NSManagedObjectID) -> CDWorkout? {
        (try? viewContext.existingObject(with: id)) as? CDWorkout
    }

    private func sortedExercises(for workout: CDWorkout) -> [CDExercise] {
        let exercises = workout.exercises as? Set<CDExercise> ?? []
        return exercises.sorted { lhs, rhs in
            if lhs.orderIndex == rhs.orderIndex {
                return (lhs.name ?? "") < (rhs.name ?? "")
            }
            return lhs.orderIndex < rhs.orderIndex
        }
    }

    private func saveTemplateWorkout(_ template: WorkoutItem) {
        if workoutVM == nil { workoutVM = WorkoutViewModel(context: viewContext) }
        workoutVM?.createWorkout(
            title: template.title,
            category: template.category.rawValue,
            difficulty: template.difficulty,
            durationMinutes: template.durationMinutes,
            caloriesBurned: template.estimatedCalories,
            exercises: template.exercises.map { exercise in
                (
                    name: exercise.name,
                    muscleGroup: exercise.muscleGroup,
                    sets: exercise.sets,
                    reps: exercise.reps,
                    weightKg: exercise.weightKg
                )
            }
        )
        workoutVM?.fetchWorkouts()
        savedTemplateTitle = template.title
        showTemplateSavedAlert = true
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.body)
                .foregroundStyle(AppColors.darkTextSecondary)
            TextField("Search workouts", text: $searchText)
                .font(AppTypography.body())
                .foregroundStyle(AppColors.darkText)
        }
        .padding(.horizontal, AppLayout.cardPadding)
        .padding(.vertical, 12)
        .background(AppColors.darkSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadiusSmall))
        .padding(.horizontal, AppLayout.screenPadding)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(WorkoutCategory.allCases, id: \.self) { category in
                    Button {
                        selectedFilter = category
                    } label: {
                        Text(category.rawValue)
                            .font(AppTypography.callout())
                            .foregroundStyle(selectedFilter == category ? .white : AppColors.darkText)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(selectedFilter == category ? AppColors.primaryGreen : AppColors.darkSurface)
                            .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadiusSmall))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AppLayout.screenPadding)
        }
        .padding(.bottom, 16)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(AppTypography.caption2())
            .foregroundStyle(AppColors.darkTextSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, AppLayout.screenPadding)
            .padding(.bottom, 8)
    }

    // MARK: - Logged workouts from Core Data

    private var loggedWorkoutRows: some View {
        VStack(spacing: 0) {
            ForEach(loggedWorkouts, id: \.objectID) { workout in
                loggedWorkoutRow(workout)
            }
        }
        .padding(.horizontal, AppLayout.screenPadding)
        .padding(.bottom, 16)
    }

    private func loggedWorkoutRow(_ workout: CDWorkout) -> some View {
        Button {
            selectedSavedWorkout = SavedWorkoutSelection(id: workout.objectID)
        } label: {
            HStack(alignment: .center, spacing: 12) {
                workoutThumbnail(iconForCategory(workout.category ?? "Strength"))
                VStack(alignment: .leading, spacing: 4) {
                    Text(workout.title ?? "Workout")
                        .font(AppTypography.title3())
                        .foregroundStyle(AppColors.darkText)
                    HStack(spacing: 4) {
                        Text(workout.category ?? "")
                            .font(AppTypography.caption())
                            .foregroundStyle(AppColors.darkTextSecondary)
                        Text("•")
                            .foregroundStyle(AppColors.darkTextSecondary)
                        Text("\(workout.durationMinutes) min")
                            .font(AppTypography.caption())
                            .foregroundStyle(AppColors.darkTextSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                VStack(alignment: .trailing, spacing: 6) {
                    if workout.isCompleted {
                        Label("Done", systemImage: "checkmark.circle.fill")
                            .font(AppTypography.caption2())
                            .foregroundStyle(AppColors.primaryGreen)
                    }
                    Image(systemName: "chevron.right")
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(AppColors.darkTextSecondary)
                }
            }
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                workoutVM?.deleteWorkout(workout)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func iconForCategory(_ category: String) -> String {
        switch category {
        case "Strength": return "figure.strengthtraining.traditional"
        case "Cardio": return "figure.run"
        case "Yoga": return "figure.mind.and.body"
        default: return "dumbbell.fill"
        }
    }

    // MARK: - Template workouts

    private var workoutRows: some View {
        VStack(spacing: 0) {
            ForEach(filteredTemplates) { workout in
                workoutRow(workout)
            }
        }
        .padding(.horizontal, AppLayout.screenPadding)
        .padding(.bottom, 8)
    }

    private func workoutRow(_ workout: WorkoutItem) -> some View {
        Button {
            selectedTemplate = workout
        } label: {
            HStack(alignment: .center, spacing: 12) {
                workoutThumbnail(workout.imageSystemName)
                VStack(alignment: .leading, spacing: 4) {
                    Text(workout.title)
                        .font(AppTypography.title3())
                        .foregroundStyle(AppColors.darkText)
                    Text("\(workout.targetMuscles) • \(workout.durationMinutes) min • \(workout.difficulty)")
                        .font(AppTypography.caption())
                        .foregroundStyle(AppColors.darkTextSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.right")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(AppColors.darkTextSecondary)
            }
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func workoutThumbnail(_ systemName: String) -> some View {
        RoundedRectangle(cornerRadius: AppLayout.cornerRadiusSmall)
            .fill(AppColors.darkSurface)
            .frame(width: 56, height: 56)
            .overlay(
                Image(systemName: systemName)
                    .font(.title2)
                    .foregroundStyle(AppColors.primaryGreen)
            )
    }

    private var workoutUnavailableView: some View {
        VStack(spacing: 12) {
            Text("Workout not found")
                .font(AppTypography.title3())
                .foregroundStyle(AppColors.darkText)
            Text("This workout may have been deleted.")
                .font(AppTypography.caption())
                .foregroundStyle(AppColors.darkTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(AppLayout.screenPadding)
        .background(AppColors.darkBackground)
    }

}

private struct TemplateWorkoutDetailView: View {
    @Environment(\.dismiss) private var dismiss

    let workout: WorkoutItem
    let useMetric: Bool
    let onSave: () -> Void

    private static let lbPerKg = 2.205

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.darkBackground.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        headerCard
                        exercisesSection
                    }
                    .padding(.horizontal, AppLayout.screenPadding)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }

                VStack {
                    Spacer()
                    Button {
                        onSave()
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add to My Workouts")
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.horizontal, AppLayout.screenPadding)
                    .padding(.bottom, 24)
                    .background(AppColors.darkBackground)
                }
            }
            .navigationTitle(workout.title)
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
        }
        .presentationDetents([.large])
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(workout.summary)
                .font(AppTypography.body())
                .foregroundStyle(AppColors.darkTextSecondary)

            HStack(spacing: 8) {
                statPill("\(workout.durationMinutes) min")
                statPill("\(workout.estimatedCalories) kcal")
                statPill(workout.difficulty)
            }
        }
        .padding(AppLayout.cardPadding)
        .background(AppColors.darkSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadiusSmall))
    }

    private var exercisesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Exercises")
                .font(AppTypography.title3())
                .foregroundStyle(AppColors.darkText)

            ForEach(workout.exercises) { exercise in
                HStack(alignment: .center, spacing: 10) {
                    Circle()
                        .fill(AppColors.primaryGreen.opacity(0.25))
                        .frame(width: 36, height: 36)
                        .overlay(
                            Image(systemName: "figure.strengthtraining.traditional")
                                .font(.caption)
                                .foregroundStyle(AppColors.primaryGreen)
                        )
                    VStack(alignment: .leading, spacing: 2) {
                        Text(exercise.name)
                            .font(AppTypography.callout().weight(.semibold))
                            .foregroundStyle(AppColors.darkText)
                        Text("\(exercise.muscleGroup) • \(exercise.sets)x\(exercise.reps) • \(weightLabel(for: exercise))")
                            .font(AppTypography.caption())
                            .foregroundStyle(AppColors.darkTextSecondary)
                    }
                    Spacer()
                }
                .padding(AppLayout.cardPadding)
                .background(AppColors.darkSurface)
                .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadiusSmall))
            }
        }
    }

    private func statPill(_ text: String) -> some View {
        Text(text)
            .font(AppTypography.caption())
            .foregroundStyle(AppColors.darkText)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(AppColors.darkBackground)
            .clipShape(Capsule())
    }

    private func weightLabel(for exercise: WorkoutTemplateExercise) -> String {
        guard exercise.weightKg > 0 else { return "Bodyweight" }
        if useMetric {
            return "\(Int(exercise.weightKg)) kg"
        }
        return "\(Int(round(exercise.weightKg * Self.lbPerKg))) lb"
    }
}


#Preview {
    WorkoutsListView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
