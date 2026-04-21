//
//  Persistence.swift
//  FitFlow
//
//  Core Data stack with preview support.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext

        // Create a sample user profile for previews
        let profile = CDUserProfile(context: viewContext)
        profile.id = UUID()
        profile.email = "alex@fitflow.com"
        profile.fullName = "Alex Johnson"
        profile.username = "Alex Johnson"
        profile.heightCm = 178
        profile.weightKg = 75
        profile.age = 28
        profile.gender = "Male"
        profile.fitnessGoal = "Build Muscle"
        profile.workoutDaysPerWeek = 4
        profile.dailyCalorieGoal = 2200
        profile.createdAt = Date()
        profile.useMetricSystem = true
        profile.biometricsEnabled = false

        // Sample workout
        let workout = CDWorkout(context: viewContext)
        workout.id = UUID()
        workout.title = "Morning Strength"
        workout.category = "Strength"
        workout.difficulty = "Intermediate"
        workout.durationMinutes = 45
        workout.caloriesBurned = 350
        workout.date = Date()
        workout.isCompleted = false
        workout.userProfile = profile

        let exercise = CDExercise(context: viewContext)
        exercise.id = UUID()
        exercise.name = "Bench Press"
        exercise.muscleGroup = "Chest"
        exercise.sets = 4
        exercise.reps = 10
        exercise.weightKg = 60
        exercise.orderIndex = 0
        exercise.workout = workout

        // Sample meal
        let meal = CDMeal(context: viewContext)
        meal.id = UUID()
        meal.mealType = "Breakfast"
        meal.date = Date()
        meal.userProfile = profile

        let food = CDFoodItem(context: viewContext)
        food.id = UUID()
        food.name = "Oatmeal & Berries"
        food.brand = "Generic"
        food.caloriesPer100g = 95
        food.proteinPer100g = 3.4
        food.carbsPer100g = 17
        food.fatPer100g = 1.5
        food.quantityGrams = 200
        food.meal = meal

        // Sample progress entries
        let calendar = Calendar.current
        for i in 0..<7 {
            let entry = CDProgressEntry(context: viewContext)
            entry.id = UUID()
            entry.date = calendar.date(byAdding: .day, value: -i * 4, to: Date())
            entry.weightKg = 75.0 - Double(i) * 0.3
            entry.userProfile = profile
        }

        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "FitFlow")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
