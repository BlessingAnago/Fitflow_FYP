//
//  MockWorkoutData.swift
//  FitFlow
//
//  Global mock workouts and exercises for all users. Not scoped to any user;
//  new users can select from these templates and exercise library.
//

import SwiftUI

// MARK: - Template exercise (used in workouts and exercise picker)

struct WorkoutTemplateExercise: Identifiable {
    let id = UUID()
    let name: String
    let muscleGroup: String
    let sets: Int
    let reps: Int
    let weightKg: Double
}

// MARK: - Template workout

struct WorkoutItem: Identifiable {
    let id: UUID
    let title: String
    let summary: String
    let targetMuscles: String
    let difficulty: String
    let category: WorkoutCategory
    let durationMinutes: Int
    let estimatedCalories: Int
    let imageSystemName: String
    let exercises: [WorkoutTemplateExercise]
}

// MARK: - Global mock data (single source of truth for all users)

enum MockWorkoutData {

    /// Global workout templates. Shown in Start Workout and Workouts tab for every user.
    static let globalWorkoutTemplates: [WorkoutItem] = [
        WorkoutItem(
            id: UUID(),
            title: "Full Body Strength",
            summary: "Balanced push/pull/legs session for overall strength development.",
            targetMuscles: "Chest, Back, Legs",
            difficulty: "Intermediate",
            category: .strength,
            durationMinutes: 50,
            estimatedCalories: 420,
            imageSystemName: "figure.strengthtraining.traditional",
            exercises: [
                WorkoutTemplateExercise(name: "Barbell Squat", muscleGroup: "Quads & Glutes", sets: 4, reps: 6, weightKg: 60),
                WorkoutTemplateExercise(name: "Bench Press", muscleGroup: "Chest", sets: 4, reps: 8, weightKg: 50),
                WorkoutTemplateExercise(name: "Bent-Over Row", muscleGroup: "Back", sets: 3, reps: 10, weightKg: 40),
                WorkoutTemplateExercise(name: "Romanian Deadlift", muscleGroup: "Hamstrings", sets: 3, reps: 10, weightKg: 50),
                WorkoutTemplateExercise(name: "Plank", muscleGroup: "Core", sets: 3, reps: 45, weightKg: 0)
            ]
        ),
        WorkoutItem(
            id: UUID(),
            title: "Push Day Builder",
            summary: "Upper-body push session focused on chest, shoulders, and triceps.",
            targetMuscles: "Chest & Shoulders",
            difficulty: "Beginner",
            category: .strength,
            durationMinutes: 40,
            estimatedCalories: 320,
            imageSystemName: "figure.strengthtraining.functional",
            exercises: [
                WorkoutTemplateExercise(name: "Incline Dumbbell Press", muscleGroup: "Upper Chest", sets: 3, reps: 10, weightKg: 20),
                WorkoutTemplateExercise(name: "Seated Shoulder Press", muscleGroup: "Shoulders", sets: 3, reps: 10, weightKg: 18),
                WorkoutTemplateExercise(name: "Lateral Raise", muscleGroup: "Side Delts", sets: 3, reps: 12, weightKg: 8),
                WorkoutTemplateExercise(name: "Cable Triceps Pushdown", muscleGroup: "Triceps", sets: 3, reps: 12, weightKg: 18)
            ]
        ),
        WorkoutItem(
            id: UUID(),
            title: "HIIT Sprint Intervals",
            summary: "Short high-intensity intervals to improve conditioning and speed.",
            targetMuscles: "Legs & Cardio",
            difficulty: "Advanced",
            category: .cardio,
            durationMinutes: 28,
            estimatedCalories: 360,
            imageSystemName: "figure.run",
            exercises: [
                WorkoutTemplateExercise(name: "Warm-up Jog", muscleGroup: "Cardio", sets: 1, reps: 8, weightKg: 0),
                WorkoutTemplateExercise(name: "Sprint", muscleGroup: "Legs", sets: 8, reps: 30, weightKg: 0),
                WorkoutTemplateExercise(name: "Walk Recovery", muscleGroup: "Cardio", sets: 8, reps: 60, weightKg: 0),
                WorkoutTemplateExercise(name: "Cooldown Walk", muscleGroup: "Cardio", sets: 1, reps: 5, weightKg: 0)
            ]
        ),
        WorkoutItem(
            id: UUID(),
            title: "Steady Endurance Run",
            summary: "Moderate pace aerobic run to build endurance and heart health.",
            targetMuscles: "Cardio Base",
            difficulty: "All Levels",
            category: .cardio,
            durationMinutes: 35,
            estimatedCalories: 330,
            imageSystemName: "figure.run",
            exercises: [
                WorkoutTemplateExercise(name: "Easy Warm-up", muscleGroup: "Cardio", sets: 1, reps: 5, weightKg: 0),
                WorkoutTemplateExercise(name: "Steady Pace Run", muscleGroup: "Cardio", sets: 1, reps: 25, weightKg: 0),
                WorkoutTemplateExercise(name: "Cooldown", muscleGroup: "Cardio", sets: 1, reps: 5, weightKg: 0)
            ]
        ),
        WorkoutItem(
            id: UUID(),
            title: "Morning Vinyasa Flow",
            summary: "A dynamic yoga flow for mobility, balance, and posture.",
            targetMuscles: "Full Body Mobility",
            difficulty: "All Levels",
            category: .yoga,
            durationMinutes: 30,
            estimatedCalories: 170,
            imageSystemName: "figure.yoga",
            exercises: [
                WorkoutTemplateExercise(name: "Sun Salutation", muscleGroup: "Full Body", sets: 4, reps: 1, weightKg: 0),
                WorkoutTemplateExercise(name: "Warrior Sequence", muscleGroup: "Legs & Core", sets: 3, reps: 1, weightKg: 0),
                WorkoutTemplateExercise(name: "Chair Pose Hold", muscleGroup: "Quads", sets: 3, reps: 30, weightKg: 0),
                WorkoutTemplateExercise(name: "Pigeon Stretch", muscleGroup: "Hips", sets: 2, reps: 45, weightKg: 0)
            ]
        ),
        WorkoutItem(
            id: UUID(),
            title: "Core & Mobility Reset",
            summary: "Low-impact session to improve trunk stability and flexibility.",
            targetMuscles: "Core & Hips",
            difficulty: "Beginner",
            category: .yoga,
            durationMinutes: 25,
            estimatedCalories: 150,
            imageSystemName: "figure.mind.and.body",
            exercises: [
                WorkoutTemplateExercise(name: "Dead Bug", muscleGroup: "Core", sets: 3, reps: 12, weightKg: 0),
                WorkoutTemplateExercise(name: "Bird Dog", muscleGroup: "Core", sets: 3, reps: 10, weightKg: 0),
                WorkoutTemplateExercise(name: "Hip Flexor Stretch", muscleGroup: "Hips", sets: 2, reps: 45, weightKg: 0),
                WorkoutTemplateExercise(name: "Child's Pose", muscleGroup: "Back", sets: 2, reps: 60, weightKg: 0)
            ]
        )
    ]

    /// Global exercise library for the "add exercise" picker. Users can select from these when building a custom workout.
    static let globalExercises: [WorkoutTemplateExercise] = {
        var byName: [String: WorkoutTemplateExercise] = [:]
        for template in globalWorkoutTemplates {
            for ex in template.exercises {
                byName[ex.name] = ex
            }
        }
        // Add more common exercises not in templates
        let extra: [WorkoutTemplateExercise] = [
            WorkoutTemplateExercise(name: "Deadlift", muscleGroup: "Back", sets: 4, reps: 5, weightKg: 80),
            WorkoutTemplateExercise(name: "Overhead Press", muscleGroup: "Shoulders", sets: 3, reps: 8, weightKg: 40),
            WorkoutTemplateExercise(name: "Pull-Up", muscleGroup: "Back", sets: 3, reps: 8, weightKg: 0),
            WorkoutTemplateExercise(name: "Dumbbell Row", muscleGroup: "Back", sets: 3, reps: 10, weightKg: 25),
            WorkoutTemplateExercise(name: "Leg Press", muscleGroup: "Quads", sets: 4, reps: 10, weightKg: 100),
            WorkoutTemplateExercise(name: "Leg Curl", muscleGroup: "Hamstrings", sets: 3, reps: 12, weightKg: 35),
            WorkoutTemplateExercise(name: "Calf Raise", muscleGroup: "Calves", sets: 3, reps: 15, weightKg: 0),
            WorkoutTemplateExercise(name: "Bicep Curl", muscleGroup: "Biceps", sets: 3, reps: 12, weightKg: 12),
            WorkoutTemplateExercise(name: "Triceps Dip", muscleGroup: "Triceps", sets: 3, reps: 10, weightKg: 0),
            WorkoutTemplateExercise(name: "Push-Up", muscleGroup: "Chest", sets: 3, reps: 15, weightKg: 0),
            WorkoutTemplateExercise(name: "Lunge", muscleGroup: "Legs", sets: 3, reps: 10, weightKg: 0),
            WorkoutTemplateExercise(name: "Mountain Climbers", muscleGroup: "Core", sets: 3, reps: 20, weightKg: 0),
            WorkoutTemplateExercise(name: "Burpee", muscleGroup: "Full Body", sets: 3, reps: 10, weightKg: 0),
            WorkoutTemplateExercise(name: "Jump Rope", muscleGroup: "Cardio", sets: 1, reps: 5, weightKg: 0),
            WorkoutTemplateExercise(name: "Rowing Machine", muscleGroup: "Cardio", sets: 1, reps: 10, weightKg: 0)
        ]
        for ex in extra {
            byName[ex.name] = ex
        }
        return byName.values.sorted { $0.name < $1.name }
    }()
}
