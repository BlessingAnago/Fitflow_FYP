//
//  SavedWorkoutFlowViews.swift
//  FitFlow
//
//  Saved workout details + professional exercise-by-exercise session flow
//  with timer, per-exercise log (defaults), and completion summary.
//

import SwiftUI
import CoreData
import Combine

private struct SessionExerciseDraft: Identifiable {
    let id: NSManagedObjectID
    let name: String
    let muscleGroup: String
    var performedSets: Int
    var performedReps: Int
    var performedWeightKg: Double
    var wasPerformed: Bool

    init(exercise: CDExercise) {
        id = exercise.objectID
        name = exercise.name ?? "Exercise"
        muscleGroup = exercise.muscleGroup ?? "General"
        performedSets = max(1, Int(exercise.sets))
        performedReps = max(1, Int(exercise.reps))
        performedWeightKg = max(0, exercise.weightKg)
        wasPerformed = true
    }
}

struct SavedWorkoutDetailView: View {
    @Environment(\.dismiss) private var dismiss

    let workout: CDWorkout
    var onWorkoutUpdated: () -> Void = { }
    /// Called when user confirms delete; caller should delete the workout and dismiss the sheet.
    var onDelete: (() -> Void)? = nil

    @State private var showSession = false
    @State private var showDeleteAlert = false

    private var sortedExercises: [CDExercise] {
        let exercises = workout.exercises as? Set<CDExercise> ?? []
        return exercises.sorted { lhs, rhs in
            if lhs.orderIndex == rhs.orderIndex {
                return (lhs.name ?? "") < (rhs.name ?? "")
            }
            return lhs.orderIndex < rhs.orderIndex
        }
    }

    private var notesText: String {
        (workout.sessionNotes ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var sessionHistory: [String] {
        sessionEntries(from: workout.sessionHistory ?? "")
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.darkBackground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        summaryCard
                        exercisesSection
                        if !sessionHistory.isEmpty { sessionHistorySection }
                        if !notesText.isEmpty { sessionNotesSection }
                    }
                    .padding(.horizontal, AppLayout.screenPadding)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle(workout.title ?? "Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        Image(systemName: "trash")
                            .foregroundStyle(AppColors.negativeRed)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(AppColors.darkText)
                    }
                }
            }
            .alert("Delete Workout", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    onDelete?()
                    dismiss()
                }
            } message: {
                Text("Are you sure you want to delete \"\(workout.title ?? "Workout")\"? This cannot be undone.")
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    showSession = true
                } label: {
                    HStack {
                        Image(systemName: "play.fill")
                        Text(workout.isCompleted ? "Start Again" : "Start Workout")
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(sortedExercises.isEmpty)
                .opacity(sortedExercises.isEmpty ? 0.6 : 1)
                .padding(.horizontal, AppLayout.screenPadding)
                .padding(.top, 8)
                .padding(.bottom, 12)
                .background(AppColors.darkBackground)
            }
        }
        .sheet(isPresented: $showSession) {
            WorkoutSessionView(workout: workout) {
                onWorkoutUpdated()
            }
        }
        .presentationDetents([.large])
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                pill(workout.category ?? "Workout")
                pill("\(workout.durationMinutes) min")
                pill(workout.difficulty ?? "All Levels")
            }

            HStack(spacing: 8) {
                Image(systemName: workout.isCompleted ? "checkmark.circle.fill" : "clock.fill")
                    .foregroundStyle(workout.isCompleted ? AppColors.primaryGreen : AppColors.darkTextSecondary)
                Text(workout.isCompleted ? "Completed workout" : "Not completed yet")
                    .font(AppTypography.caption())
                    .foregroundStyle(AppColors.darkTextSecondary)
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

            if sortedExercises.isEmpty {
                Text("No exercises added to this workout yet.")
                    .font(AppTypography.caption())
                    .foregroundStyle(AppColors.darkTextSecondary)
                    .padding(AppLayout.cardPadding)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppColors.darkSurface)
                    .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadiusSmall))
            } else {
                ForEach(sortedExercises, id: \.objectID) { exercise in
                    HStack(alignment: .center, spacing: 10) {
                        Circle()
                            .fill(AppColors.primaryGreen.opacity(0.22))
                            .frame(width: 34, height: 34)
                            .overlay(
                                Image(systemName: "figure.strengthtraining.traditional")
                                    .font(.caption)
                                    .foregroundStyle(AppColors.primaryGreen)
                            )
                        VStack(alignment: .leading, spacing: 2) {
                            Text(exercise.name ?? "Exercise")
                                .font(AppTypography.callout().weight(.semibold))
                                .foregroundStyle(AppColors.darkText)
                            Text("\(exercise.muscleGroup ?? "General") • \(Int(exercise.sets))x\(Int(exercise.reps)) • \(formattedWeight(exercise.weightKg))")
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
    }

    private var sessionHistorySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Session History")
                .font(AppTypography.title3())
                .foregroundStyle(AppColors.darkText)
            VStack(alignment: .leading, spacing: 8) {
                ForEach(sessionHistory.indices, id: \.self) { index in
                    Text(sessionHistory[index])
                        .font(AppTypography.caption())
                        .foregroundStyle(AppColors.darkTextSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(AppLayout.cardPadding)
            .background(AppColors.darkSurface)
            .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadiusSmall))
        }
    }

    private var sessionNotesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Session Notes")
                .font(AppTypography.title3())
                .foregroundStyle(AppColors.darkText)
            Text(notesText)
                .font(AppTypography.caption())
                .foregroundStyle(AppColors.darkTextSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(AppLayout.cardPadding)
                .background(AppColors.darkSurface)
                .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadiusSmall))
        }
    }

    private func pill(_ text: String) -> some View {
        Text(text)
            .font(AppTypography.caption2())
            .foregroundStyle(AppColors.darkText)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(AppColors.darkBackground)
            .clipShape(Capsule())
    }

    private func formattedWeight(_ value: Double) -> String {
        guard value > 0 else { return "Bodyweight" }
        if value.rounded() == value { return "\(Int(value)) kg" }
        return "\(String(format: "%.1f", value)) kg"
    }

    private func sessionEntries(from history: String) -> [String] {
        history
            .components(separatedBy: "\n\n")
            .filter { $0.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("Session ") }
    }
}

// MARK: - Workout session: exercise-by-exercise flow

private struct WorkoutSessionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    let workout: CDWorkout
    let onSessionSaved: () -> Void

    @State private var drafts: [SessionExerciseDraft] = []
    @State private var currentIndex: Int = 0
    @State private var sessionStartDate = Date()
    @State private var sessionNotes = ""
    @State private var timerTick = false

    private var timer: Timer.TimerPublisher { Timer.publish(every: 1, on: .main, in: .common) }

    private var isShowingSummary: Bool {
        currentIndex >= drafts.count && !drafts.isEmpty
    }

    private var completedCount: Int {
        drafts.filter(\.wasPerformed).count
    }

    private var workoutElapsedSeconds: Int {
        Int(Date().timeIntervalSince(sessionStartDate))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.darkBackground.ignoresSafeArea()

                if drafts.isEmpty {
                    ProgressView()
                        .tint(AppColors.primaryGreen)
                } else if isShowingSummary {
                    WorkoutCompletionSummaryView(
                        workoutTitle: workout.title ?? "Workout",
                        completedDrafts: drafts.filter(\.wasPerformed),
                        totalDurationSeconds: workoutElapsedSeconds,
                        sessionNotes: $sessionNotes,
                        onEndWorkout: { saveAndDismiss() }
                    )
                } else {
                    ActiveExerciseStepView(
                        draft: draftBinding(for: currentIndex),
                        currentIndex: currentIndex,
                        totalCount: drafts.count,
                        workoutElapsedSeconds: workoutElapsedSeconds,
                        timerTick: $timerTick,
                        onNext: { goToNext() },
                        onSkip: { skipCurrent() },
                        formattedWeight: formattedWeight
                    )
                }
            }
            .navigationTitle(isShowingSummary ? "Workout Complete" : "Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(AppColors.darkBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                if !isShowingSummary && !drafts.isEmpty {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("End") {
                            currentIndex = drafts.count
                        }
                        .foregroundStyle(AppColors.darkTextSecondary)
                    }
                }
            }
            .onAppear { loadDraftsIfNeeded() }
            .onReceive(timer.autoconnect()) { _ in timerTick.toggle() }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private func loadDraftsIfNeeded() {
        guard drafts.isEmpty else { return }
        let exercises = workout.exercises as? Set<CDExercise> ?? []
        let sorted = exercises.sorted { lhs, rhs in
            if lhs.orderIndex == rhs.orderIndex {
                return (lhs.name ?? "") < (rhs.name ?? "")
            }
            return lhs.orderIndex < rhs.orderIndex
        }
        drafts = sorted.map(SessionExerciseDraft.init)
        sessionStartDate = Date()
    }

    private func draftBinding(for index: Int) -> Binding<SessionExerciseDraft> {
        Binding(
            get: { drafts[index] },
            set: { newValue in
                var copy = drafts
                copy[index] = newValue
                drafts = copy
            }
        )
    }

    private func goToNext() {
        if currentIndex < drafts.count - 1 {
            withAnimation(.easeInOut(duration: 0.25)) {
                currentIndex += 1
            }
        } else {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentIndex = drafts.count
            }
        }
    }

    private func skipCurrent() {
        var copy = drafts
        copy[currentIndex].wasPerformed = false
        drafts = copy
        if currentIndex < drafts.count - 1 {
            withAnimation(.easeInOut(duration: 0.25)) {
                currentIndex += 1
            }
        } else {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentIndex = drafts.count
            }
        }
    }

    private func saveAndDismiss() {
        let completedDrafts = drafts.filter(\.wasPerformed)
        workout.isCompleted = true
        workout.completedAt = Date()
        let entry = buildSessionEntry(from: completedDrafts)
        let existingHistory = (workout.sessionHistory ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        workout.sessionHistory = existingHistory.isEmpty ? entry : "\(existingHistory)\n\n\(entry)"
        let trimmedNotes = sessionNotes.trimmingCharacters(in: .whitespacesAndNewlines)
        workout.sessionNotes = trimmedNotes.isEmpty ? nil : trimmedNotes
        do {
            try viewContext.save()
            onSessionSaved()
            dismiss()
        } catch {
            print("Failed to save workout session: \(error)")
        }
    }

    private func buildSessionEntry(from completedDrafts: [SessionExerciseDraft]) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        var lines: [String] = ["Session \(formatter.string(from: Date()))"]
        for draft in completedDrafts {
            lines.append("• \(draft.name): \(draft.performedSets)x\(draft.performedReps) @ \(formattedWeight(draft.performedWeightKg))")
        }
        let trimmedNotes = sessionNotes.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedNotes.isEmpty { lines.append("Notes: \(trimmedNotes)") }
        return lines.joined(separator: "\n")
    }

    private func formattedWeight(_ value: Double) -> String {
        guard value > 0 else { return "Bodyweight" }
        if value.rounded() == value { return "\(Int(value)) kg" }
        return "\(String(format: "%.1f", value)) kg"
    }
}

// MARK: - Single exercise step: details, timer, quick log, Next/Skip

private struct ActiveExerciseStepView: View {
    @Binding var draft: SessionExerciseDraft
    let currentIndex: Int
    let totalCount: Int
    let workoutElapsedSeconds: Int
    @Binding var timerTick: Bool
    let onNext: () -> Void
    let onSkip: () -> Void
    let formattedWeight: (Double) -> String

    @State private var exerciseStartDate = Date()

    private var exerciseElapsedSeconds: Int {
        Int(Date().timeIntervalSince(exerciseStartDate))
    }

    var body: some View {
        let _ = timerTick
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                workoutTimerBar
                exerciseHeader
                exerciseTimerCard
                targetCard
                logCard
                Spacer(minLength: 24)
                actionButtons
            }
            .padding(.horizontal, AppLayout.screenPadding)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .onChange(of: currentIndex) { _, _ in
            exerciseStartDate = Date()
        }
        .onAppear {
            exerciseStartDate = Date()
        }
    }

    private var workoutTimerBar: some View {
        HStack {
            Image(systemName: "clock.fill")
                .font(.callout)
                .foregroundStyle(AppColors.primaryGreen)
            Text(formatTime(workoutElapsedSeconds))
                .font(.system(.title2, design: .monospaced).weight(.medium))
                .foregroundStyle(AppColors.darkText)
            Spacer()
            Text("Exercise \(currentIndex + 1) of \(totalCount)")
                .font(AppTypography.caption())
                .foregroundStyle(AppColors.darkTextSecondary)
        }
        .padding(.vertical, 8)
    }

    private var exerciseHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(draft.name)
                .font(AppTypography.title())
                .foregroundStyle(AppColors.darkText)
            Text(draft.muscleGroup)
                .font(AppTypography.callout())
                .foregroundStyle(AppColors.darkTextSecondary)
        }
    }

    private var exerciseTimerCard: some View {
        VStack(spacing: 12) {
            Text("Exercise timer")
                .font(AppTypography.caption())
                .foregroundStyle(AppColors.darkTextSecondary)
            Text(formatTime(exerciseElapsedSeconds))
                .font(.system(size: 44, weight: .light, design: .monospaced))
                .foregroundStyle(AppColors.primaryGreen)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(AppColors.darkSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadiusSmall))
    }

    private var targetCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Target")
                .font(AppTypography.caption())
                .foregroundStyle(AppColors.darkTextSecondary)
            Text(targetSummary)
                .font(AppTypography.callout())
                .foregroundStyle(AppColors.darkText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppLayout.cardPadding)
        .background(AppColors.darkSurface.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadiusSmall))
    }

    private var targetSummary: String {
        let weightStr = draft.performedWeightKg > 0 ? " @ \(formattedWeight(draft.performedWeightKg))" : " (bodyweight)"
        return "\(draft.performedSets) sets × \(draft.performedReps) reps\(weightStr)"
    }

    private var setsBinding: Binding<Int> {
        Binding(
            get: { draft.performedSets },
            set: { v in var d = draft; d.performedSets = v; draft = d }
        )
    }

    private var repsBinding: Binding<Int> {
        Binding(
            get: { draft.performedReps },
            set: { v in var d = draft; d.performedReps = v; draft = d }
        )
    }

    private var logCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Log")
                .font(AppTypography.caption())
                .foregroundStyle(AppColors.darkTextSecondary)
            HStack(spacing: 12) {
                logChip(title: "Sets", value: setsBinding, range: 1...20)
                logChip(title: "Reps", value: repsBinding, range: 1...50)
            }
            weightRow
        }
        .padding(AppLayout.cardPadding)
        .background(AppColors.darkSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadiusSmall))
    }

    private func logChip(title: String, value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(AppTypography.caption())
                .foregroundStyle(AppColors.darkTextSecondary)
            Spacer(minLength: 4)
            HStack(spacing: 0) {
                Button {
                    value.wrappedValue = max(range.lowerBound, value.wrappedValue - 1)
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppColors.primaryGreen)
                        .frame(width: 36, height: 36)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                Text("\(value.wrappedValue)")
                    .font(.system(.body, design: .monospaced).weight(.medium))
                    .foregroundStyle(AppColors.darkText)
                    .frame(minWidth: 28)
                Button {
                    value.wrappedValue = min(range.upperBound, value.wrappedValue + 1)
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppColors.primaryGreen)
                        .frame(width: 36, height: 36)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .background(AppColors.primaryGreen.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(AppColors.darkBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var weightRow: some View {
        HStack {
            Text("Weight")
                .font(AppTypography.caption())
                .foregroundStyle(AppColors.darkTextSecondary)
            Spacer()
            HStack(spacing: 0) {
                Button {
                    var d = draft
                    d.performedWeightKg = max(0, d.performedWeightKg - 2.5)
                    draft = d
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppColors.primaryGreen)
                        .frame(width: 36, height: 36)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                Text(formattedWeight(draft.performedWeightKg))
                    .font(.system(.callout, design: .monospaced).weight(.medium))
                    .foregroundStyle(AppColors.darkText)
                    .frame(minWidth: 72)
                Button {
                    var d = draft
                    d.performedWeightKg = min(350, d.performedWeightKg + 2.5)
                    draft = d
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppColors.primaryGreen)
                        .frame(width: 36, height: 36)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .background(AppColors.primaryGreen.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(AppColors.darkBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: onNext) {
                HStack {
                    Text("Next exercise")
                    Image(systemName: "arrow.right")
                        .font(.callout.weight(.semibold))
                }
            }
            .buttonStyle(PrimaryButtonStyle())

            Button(action: onSkip) {
                Text("Skip this exercise")
                    .foregroundStyle(AppColors.darkTextSecondary)
            }
            .buttonStyle(.plain)
        }
    }

    private func formatTime(_ totalSeconds: Int) -> String {
        let m = totalSeconds / 60
        let s = totalSeconds % 60
        return String(format: "%d:%02d", m, s)
    }
}

// MARK: - Completion summary

private struct WorkoutCompletionSummaryView: View {
    let workoutTitle: String
    let completedDrafts: [SessionExerciseDraft]
    let totalDurationSeconds: Int
    @Binding var sessionNotes: String
    let onEndWorkout: () -> Void

    private func formattedWeight(_ value: Double) -> String {
        guard value > 0 else { return "Bodyweight" }
        if value.rounded() == value { return "\(Int(value)) kg" }
        return "\(String(format: "%.1f", value)) kg"
    }

    private var durationFormatted: String {
        let m = totalDurationSeconds / 60
        let s = totalDurationSeconds % 60
        if m >= 60 {
            let h = m / 60
            let mm = m % 60
            return "\(h)h \(mm)m"
        }
        return "\(m)m \(s)s"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                successHeader
                statsCard
                exercisesListCard
                notesSection
                endButton
            }
            .padding(.horizontal, AppLayout.screenPadding)
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
    }

    private var successHeader: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(AppColors.primaryGreen)
            Text("Great work!")
                .font(AppTypography.title())
                .foregroundStyle(AppColors.darkText)
            Text(workoutTitle)
                .font(AppTypography.callout())
                .foregroundStyle(AppColors.darkTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 16)
    }

    private var statsCard: some View {
        HStack(spacing: 20) {
            statBlock(value: durationFormatted, label: "Duration")
            Rectangle()
                .fill(AppColors.darkText.opacity(0.3))
                .frame(width: 1, height: 36)
            statBlock(value: "\(completedDrafts.count)", label: "Exercises")
        }
        .padding(AppLayout.cardPadding)
        .frame(maxWidth: .infinity)
        .background(AppColors.darkSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadiusSmall))
    }

    private func statBlock(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(.title3, design: .monospaced).weight(.semibold))
                .foregroundStyle(AppColors.primaryGreen)
            Text(label)
                .font(AppTypography.caption2())
                .foregroundStyle(AppColors.darkTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var exercisesListCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Completed")
                .font(AppTypography.caption())
                .foregroundStyle(AppColors.darkTextSecondary)
            if completedDrafts.isEmpty {
                Text("No exercises logged.")
                    .font(AppTypography.callout())
                    .foregroundStyle(AppColors.darkTextSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 12)
            } else {
                ForEach(completedDrafts) { draft in
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.callout)
                            .foregroundStyle(AppColors.primaryGreen)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(draft.name)
                                .font(AppTypography.callout().weight(.medium))
                                .foregroundStyle(AppColors.darkText)
                            Text("\(draft.performedSets)×\(draft.performedReps) @ \(formattedWeight(draft.performedWeightKg))")
                                .font(AppTypography.caption2())
                                .foregroundStyle(AppColors.darkTextSecondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(AppColors.darkBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding(AppLayout.cardPadding)
        .background(AppColors.darkSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadiusSmall))
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Session notes (optional)")
                .font(AppTypography.caption())
                .foregroundStyle(AppColors.darkTextSecondary)
            TextEditor(text: $sessionNotes)
                .font(AppTypography.body())
                .foregroundStyle(AppColors.darkText)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 80)
                .padding(10)
                .background(AppColors.darkSurface)
                .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadiusSmall))
                .overlay(
                    RoundedRectangle(cornerRadius: AppLayout.cornerRadiusSmall)
                        .stroke(AppColors.darkText.opacity(0.2), lineWidth: 1)
                )
        }
    }

    private var endButton: some View {
        Button(action: onEndWorkout) {
            HStack {
                Text("End Workout")
                Image(systemName: "checkmark.circle.fill")
            }
        }
        .buttonStyle(PrimaryButtonStyle())
        .padding(.top, 8)
    }
}

