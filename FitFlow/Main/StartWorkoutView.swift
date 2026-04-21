//
//  StartWorkoutView.swift
//  FitFlow
//
//  Dedicated start-workout screen showing only user-saved workouts.
//

import SwiftUI
import CoreData

private struct StartWorkoutSelection: Identifiable {
    let id: NSManagedObjectID
}

struct StartWorkoutView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @State private var workoutVM: WorkoutViewModel?
    @State private var showAddWorkout = false
    @State private var selectedWorkout: StartWorkoutSelection?

    private var savedWorkouts: [CDWorkout] {
        workoutVM?.workouts ?? []
    }

    private var suggestedWorkouts: [WorkoutItem] {
        MockWorkoutData.globalWorkoutTemplates
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.darkBackground.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Global suggested workouts (for all users)
                        if !suggestedWorkouts.isEmpty {
                            Text("SUGGESTED WORKOUTS")
                                .font(AppTypography.caption2())
                                .foregroundStyle(AppColors.darkTextSecondary)
                                .padding(.horizontal, AppLayout.screenPadding)
                            suggestedWorkoutRows
                        }

                        // User's saved workouts
                        if savedWorkouts.isEmpty && suggestedWorkouts.isEmpty {
                            emptyState
                        } else if !savedWorkouts.isEmpty {
                            Text("YOUR WORKOUTS")
                                .font(AppTypography.caption2())
                                .foregroundStyle(AppColors.darkTextSecondary)
                                .padding(.horizontal, AppLayout.screenPadding)
                            savedWorkoutRows
                        }

                        createWorkoutButton
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Start Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(AppColors.darkBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(AppColors.darkText)
                    }
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
            .sheet(isPresented: $showAddWorkout, onDismiss: {
                workoutVM?.fetchWorkouts()
            }) {
                AddWorkoutView()
            }
            .sheet(item: $selectedWorkout) { selection in
                if let workout = workoutFromObjectID(selection.id) {
                    SavedWorkoutDetailView(workout: workout) {
                        workoutVM?.fetchWorkouts()
                    }
                } else {
                    workoutUnavailableView
                }
            }
            .onAppear { loadData() }
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        }
    }

    private func loadData() {
        if workoutVM == nil { workoutVM = WorkoutViewModel(context: viewContext) }
        workoutVM?.fetchWorkouts()
    }

    private func workoutFromObjectID(_ id: NSManagedObjectID) -> CDWorkout? {
        (try? viewContext.existingObject(with: id)) as? CDWorkout
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 36))
                .foregroundStyle(AppColors.primaryGreen)
            Text("No saved workouts yet")
                .font(AppTypography.title3())
                .foregroundStyle(AppColors.darkText)
            Text("Pick a suggested workout above or create a custom one.")
                .font(AppTypography.caption())
                .foregroundStyle(AppColors.darkTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(AppLayout.screenPadding)
        .background(AppColors.darkSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius))
        .padding(.horizontal, AppLayout.screenPadding)
    }

    private var suggestedWorkoutRows: some View {
        VStack(spacing: 0) {
            ForEach(suggestedWorkouts) { template in
                suggestedWorkoutRow(template)
            }
        }
        .padding(.horizontal, AppLayout.screenPadding)
        .padding(.bottom, 8)
    }

    private func suggestedWorkoutRow(_ template: WorkoutItem) -> some View {
        Button {
            startFromTemplate(template)
        } label: {
            HStack(alignment: .center, spacing: 12) {
                workoutThumbnail(iconForCategory(template.category.rawValue))
                VStack(alignment: .leading, spacing: 4) {
                    Text(template.title)
                        .font(AppTypography.title3())
                        .foregroundStyle(AppColors.darkText)
                    HStack(spacing: 4) {
                        Text(template.category.rawValue)
                            .font(AppTypography.caption())
                            .foregroundStyle(AppColors.darkTextSecondary)
                        Text("•")
                            .foregroundStyle(AppColors.darkTextSecondary)
                        Text("\(template.durationMinutes) min")
                            .font(AppTypography.caption())
                            .foregroundStyle(AppColors.darkTextSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .trailing, spacing: 6) {
                    Text("Start")
                        .font(AppTypography.caption2().weight(.semibold))
                        .foregroundStyle(AppColors.primaryGreen)
                    Image(systemName: "chevron.right")
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(AppColors.darkTextSecondary)
                }
            }
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func startFromTemplate(_ template: WorkoutItem) {
        guard let vm = workoutVM else { return }
        let created = vm.createWorkout(
            title: template.title,
            category: template.category.rawValue,
            difficulty: template.difficulty,
            durationMinutes: template.durationMinutes,
            caloriesBurned: template.estimatedCalories,
            exercises: template.exercises.map { ex in
                (name: ex.name, muscleGroup: ex.muscleGroup, sets: ex.sets, reps: ex.reps, weightKg: ex.weightKg)
            }
        )
        if let workout = created {
            selectedWorkout = StartWorkoutSelection(id: workout.objectID)
        }
    }

    private var savedWorkoutRows: some View {
        VStack(spacing: 0) {
            ForEach(savedWorkouts, id: \.objectID) { workout in
                savedWorkoutRow(workout)
            }
        }
        .padding(.horizontal, AppLayout.screenPadding)
    }

    private func savedWorkoutRow(_ workout: CDWorkout) -> some View {
        Button {
            selectedWorkout = StartWorkoutSelection(id: workout.objectID)
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
                    Text(workout.isCompleted ? "Start Again" : "Start")
                        .font(AppTypography.caption2().weight(.semibold))
                        .foregroundStyle(AppColors.primaryGreen)
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

    private var createWorkoutButton: some View {
        Button {
            showAddWorkout = true
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Create New Workout")
            }
        }
        .buttonStyle(PrimaryButtonStyle())
        .padding(.horizontal, AppLayout.screenPadding)
        .padding(.top, 8)
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

#Preview {
    StartWorkoutView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
