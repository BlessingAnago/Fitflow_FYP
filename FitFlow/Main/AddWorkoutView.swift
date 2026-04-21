//
//  AddWorkoutView.swift
//  FitFlow
//
//  Form to create and log a new workout with exercises.
//

import SwiftUI
import CoreData

struct AddWorkoutView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var selectedCategory: WorkoutCategory = .strength
    @State private var selectedDifficulty = "Intermediate"
    @State private var durationMinutes = 30
    @State private var caloriesBurned = 200
    @State private var exercises: [ExerciseEntry] = [ExerciseEntry()]
    @State private var showExercisePicker = false

    let difficulties = ["Beginner", "Intermediate", "Advanced", "All Levels"]

    struct ExerciseEntry: Identifiable {
        let id = UUID()
        var name = ""
        var muscleGroup = ""
        var sets = 3
        var reps = 10
        var weightKg: Double = 0
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.darkBackground.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Workout Title
                        inputSection(label: "Workout Name") {
                            VisiblePlaceholderTextField(
                                placeholder: "e.g. Morning Strength",
                                text: $title
                            )
                        }

                        // Category
                        inputSection(label: "Workout Type") {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(WorkoutCategory.allCases, id: \.self) { category in
                                        Button {
                                            selectedCategory = category
                                        } label: {
                                            Text(category.rawValue)
                                                .font(AppTypography.callout())
                                                .foregroundStyle(selectedCategory == category ? .white : AppColors.darkText)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 10)
                                                .background(selectedCategory == category ? AppColors.primaryGreen : AppColors.darkSurface)
                                                .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadiusSmall))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: AppLayout.cornerRadiusSmall)
                                                        .stroke(selectedCategory == category ? Color.clear : AppColors.darkText.opacity(0.25), lineWidth: 1)
                                                )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }

                        // Difficulty
                        inputSection(label: "Difficulty") {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(difficulties, id: \.self) { diff in
                                        Button {
                                            selectedDifficulty = diff
                                        } label: {
                                            Text(diff)
                                                .font(AppTypography.callout())
                                                .foregroundStyle(selectedDifficulty == diff ? .white : AppColors.darkText)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 10)
                                                .background(selectedDifficulty == diff ? AppColors.primaryGreen : AppColors.darkSurface)
                                                .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadiusSmall))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: AppLayout.cornerRadiusSmall)
                                                        .stroke(selectedDifficulty == diff ? Color.clear : AppColors.darkText.opacity(0.25), lineWidth: 1)
                                                )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }

                        // Duration & Calories (full width so values are never truncated)
                        inputSection(label: "Duration (min)") {
                            VisibleStepperView(value: $durationMinutes, range: 5...180, step: 5) {
                                Text("\(durationMinutes) min")
                                    .font(AppTypography.title3())
                                    .foregroundStyle(AppColors.darkText)
                            }
                        }
                        inputSection(label: "Calories") {
                            VisibleStepperView(value: $caloriesBurned, range: 0...2000, step: 25) {
                                Text("\(caloriesBurned.formatted()) kcal")
                                    .font(AppTypography.title3())
                                    .foregroundStyle(AppColors.darkText)
                            }
                        }

                        // Exercises
                        inputSection(label: "Exercises") {
                            VStack(spacing: 12) {
                                Button {
                                    showExercisePicker = true
                                } label: {
                                    HStack {
                                        Image(systemName: "list.bullet.rectangle.fill")
                                        Text("Add from exercise library")
                                    }
                                    .font(AppTypography.callout().weight(.semibold))
                                    .foregroundStyle(AppColors.primaryGreen)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)

                                ForEach($exercises) { $exercise in
                                    exerciseRow(exercise: $exercise)
                                }
                                Button {
                                    exercises.append(ExerciseEntry())
                                } label: {
                                    HStack {
                                        Image(systemName: "plus.circle.fill")
                                        Text("Add blank exercise")
                                    }
                                    .font(AppTypography.callout().weight(.semibold))
                                    .foregroundStyle(AppColors.primaryGreen)
                                }
                            }
                        }

                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, AppLayout.screenPadding)
                    .padding(.top, 16)
                }

                // Save Button
                VStack {
                    Spacer()
                    Button {
                        saveWorkout()
                    } label: {
                        Text("Save Workout")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(!canSaveWorkout)
                    .opacity(canSaveWorkout ? 1 : 0.6)
                    .padding(.horizontal, AppLayout.screenPadding)
                    .padding(.bottom, 32)
                    .background(AppColors.darkBackground)
                }
            }
            .navigationTitle("New Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(AppColors.darkBackground, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(AppColors.darkText)
                    }
                }
            }
            .sheet(isPresented: $showExercisePicker) {
                ExercisePickerSheet(
                    exercises: MockWorkoutData.globalExercises,
                    onSelect: { ex in
                        exercises.append(ExerciseEntry(
                            name: ex.name,
                            muscleGroup: ex.muscleGroup,
                            sets: ex.sets,
                            reps: ex.reps,
                            weightKg: ex.weightKg
                        ))
                        showExercisePicker = false
                    }
                )
            }
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        }
    }

    private var canSaveWorkout: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        durationMinutes > 0 &&
        caloriesBurned >= 0 &&
        exercises.contains { !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    private func inputSection<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(AppTypography.callout().weight(.semibold))
                .foregroundStyle(AppColors.darkText)
            content()
        }
    }

    private func exerciseRow(exercise: Binding<ExerciseEntry>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VisiblePlaceholderTextField(
                placeholder: "Exercise name",
                text: exercise.name,
                font: AppTypography.body(),
                paddingH: 14,
                paddingV: 12,
                cornerRadius: 8,
                backgroundColor: AppColors.darkBackground.opacity(0.6)
            )
            HStack(spacing: 12) {
                VisiblePlaceholderTextField(
                    placeholder: "Muscle group",
                    text: exercise.muscleGroup,
                    font: AppTypography.callout(),
                    paddingH: 14,
                    paddingV: 10,
                    cornerRadius: 8,
                    backgroundColor: AppColors.darkBackground.opacity(0.6)
                )
                Spacer(minLength: 8)
                Text("\(exercise.wrappedValue.sets)s × \(exercise.wrappedValue.reps)r")
                    .font(AppTypography.callout().weight(.medium))
                    .foregroundStyle(AppColors.darkTextSecondary)
                HStack(spacing: 0) {
                    exerciseStepperButton(icon: "minus") {
                        exercise.sets.wrappedValue = max(1, exercise.wrappedValue.sets - 1)
                    }
                    Rectangle()
                        .fill(AppColors.darkText.opacity(0.3))
                        .frame(width: 1, height: 20)
                    exerciseStepperButton(icon: "plus") {
                        exercise.sets.wrappedValue = min(10, exercise.wrappedValue.sets + 1)
                    }
                }
                .background(AppColors.primaryGreen.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
        .padding(AppLayout.cardPadding)
        .background(AppColors.darkSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadiusSmall))
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cornerRadiusSmall)
                .stroke(AppColors.darkText.opacity(0.2), lineWidth: 1)
        )
    }

    private func exerciseStepperButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColors.primaryGreen)
                .frame(width: 36, height: 36)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func saveWorkout() {
        guard canSaveWorkout else { return }
        let vm = WorkoutViewModel(context: viewContext)
        vm.createWorkout(
            title: title.trimmingCharacters(in: .whitespaces),
            category: selectedCategory.rawValue,
            difficulty: selectedDifficulty,
            durationMinutes: durationMinutes,
            caloriesBurned: caloriesBurned,
            exercises: exercises.filter { !$0.name.isEmpty }.map {
                (
                    name: $0.name.trimmingCharacters(in: .whitespacesAndNewlines),
                    muscleGroup: $0.muscleGroup.trimmingCharacters(in: .whitespacesAndNewlines),
                    sets: max(1, $0.sets),
                    reps: max(1, $0.reps),
                    weightKg: max(0, $0.weightKg)
                )
            }
        )
        dismiss()
    }
}

// MARK: - Exercise picker (global library)

private struct ExercisePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let exercises: [WorkoutTemplateExercise]
    let onSelect: (WorkoutTemplateExercise) -> Void

    @State private var searchText = ""

    private var filteredExercises: [WorkoutTemplateExercise] {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return exercises
        }
        return exercises.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.muscleGroup.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.darkBackground.ignoresSafeArea()
                VStack(spacing: 0) {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(AppColors.darkTextSecondary)
                        TextField("Search exercises", text: $searchText)
                            .font(AppTypography.body())
                            .foregroundStyle(AppColors.darkText)
                    }
                    .padding(AppLayout.cardPadding)
                    .background(AppColors.darkSurface)
                    .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadiusSmall))
                    .padding(.horizontal, AppLayout.screenPadding)
                    .padding(.top, 8)
                    .padding(.bottom, 12)

                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(filteredExercises) { ex in
                                Button {
                                    onSelect(ex)
                                    dismiss()
                                } label: {
                                    HStack(alignment: .center, spacing: 12) {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(ex.name)
                                                .font(AppTypography.callout().weight(.semibold))
                                                .foregroundStyle(AppColors.darkText)
                                            Text("\(ex.muscleGroup) • \(ex.sets)×\(ex.reps)")
                                                .font(AppTypography.caption())
                                                .foregroundStyle(AppColors.darkTextSecondary)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        Image(systemName: "plus.circle.fill")
                                            .font(.title3)
                                            .foregroundStyle(AppColors.primaryGreen)
                                    }
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, AppLayout.screenPadding)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Exercise library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(AppColors.darkBackground, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(AppColors.darkText)
                }
            }
        }
    }
}

#Preview {
    AddWorkoutView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
