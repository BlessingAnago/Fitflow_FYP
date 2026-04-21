//
//  WorkoutViewModel.swift
//  FitFlow
//
//  MVVM ViewModel for workout CRUD operations with Core Data.
//

import SwiftUI
import CoreData
import Observation

@Observable
@MainActor
final class WorkoutViewModel {
    private var viewContext: NSManagedObjectContext
    var workouts: [CDWorkout] = []
    var todaysWorkouts: [CDWorkout] = []

    init(context: NSManagedObjectContext) {
        self.viewContext = context
        fetchWorkouts()
    }

    func fetchWorkouts() {
        guard let rawEmail = KeychainService.getLoggedInEmail() else {
            workouts = []
            todaysWorkouts = []
            return
        }
        let email = rawEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let request: NSFetchRequest<CDWorkout> = CDWorkout.fetchRequest()
        request.predicate = NSPredicate(format: "userProfile.email == %@", email)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDWorkout.date, ascending: false)]

        do {
            workouts = try viewContext.fetch(request)
            filterTodaysWorkouts()
        } catch {
            print("Failed to fetch workouts: \(error)")
        }
    }

    private func filterTodaysWorkouts() {
        let calendar = Calendar.current
        todaysWorkouts = workouts.filter { workout in
            guard let date = workout.date else { return false }
            return calendar.isDateInToday(date)
        }
    }

    var totalWorkoutsCount: Int { workouts.count }

    var completedWorkoutsCount: Int {
        workouts.filter { $0.isCompleted }.count
    }

    var completedSessionCount: Int {
        workouts.reduce(0) { total, workout in
            guard workout.isCompleted else { return total }
            let history = workout.sessionHistory ?? ""
            return total + sessionCount(in: history)
        }
    }

    var completedTodayCount: Int {
        todaysWorkouts.filter { $0.isCompleted }.count
    }

    // MARK: - Create Workout

    /// Creates a workout for the current user. Returns the created workout (e.g. to open detail/start flow), or nil if not logged in.
    @discardableResult
    func createWorkout(
        title: String,
        category: String,
        difficulty: String,
        durationMinutes: Int,
        caloriesBurned: Int,
        exercises: [(name: String, muscleGroup: String, sets: Int, reps: Int, weightKg: Double)]
    ) -> CDWorkout? {
        guard let profile = fetchUserProfile() else { return nil }

        let workout = CDWorkout(context: viewContext)
        workout.id = UUID()
        workout.title = title
        workout.category = category
        workout.difficulty = difficulty
        workout.durationMinutes = Int16(durationMinutes)
        workout.caloriesBurned = Int16(caloriesBurned)
        workout.date = Date()
        workout.completedAt = nil
        workout.sessionHistory = ""
        workout.sessionNotes = ""
        workout.isCompleted = false
        workout.userProfile = profile

        for (index, ex) in exercises.enumerated() {
            let exercise = CDExercise(context: viewContext)
            exercise.id = UUID()
            exercise.name = ex.name
            exercise.muscleGroup = ex.muscleGroup
            exercise.sets = Int16(ex.sets)
            exercise.reps = Int16(ex.reps)
            exercise.weightKg = ex.weightKg
            exercise.orderIndex = Int16(index)
            exercise.workout = workout
        }

        save()
        fetchWorkouts()
        return workout
    }

    // MARK: - Complete Workout

    func completeWorkout(_ workout: CDWorkout) {
        workout.isCompleted = true
        workout.completedAt = Date()
        save()
        fetchWorkouts()
    }

    // MARK: - Delete Workout

    func deleteWorkout(_ workout: CDWorkout) {
        viewContext.delete(workout)
        save()
        fetchWorkouts()
    }

    // MARK: - Helpers

    private func fetchUserProfile() -> CDUserProfile? {
        guard let rawEmail = KeychainService.getLoggedInEmail() else { return nil }
        let email = rawEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let request: NSFetchRequest<CDUserProfile> = CDUserProfile.fetchRequest()
        request.predicate = NSPredicate(format: "email == %@", email)
        request.fetchLimit = 1

        do {
            return try viewContext.fetch(request).first
        } catch {
            print("Failed to fetch profile: \(error)")
            return nil
        }
    }

    private func save() {
        do {
            try viewContext.save()
        } catch {
            print("Failed to save: \(error)")
        }
    }

    private func sessionCount(in notes: String) -> Int {
        notes
            .components(separatedBy: "\n")
            .filter { $0.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("Session ") }
            .count
            .clamped(to: 1...)
    }
}

private extension Comparable {
    func clamped(to range: PartialRangeFrom<Self>) -> Self {
        max(self, range.lowerBound)
    }
}
