//
//  MealViewModel.swift
//  FitFlow
//
//  MVVM ViewModel for meal/nutrition CRUD operations with Core Data.
//

import SwiftUI
import CoreData
import Observation

enum NutritionHistoryPeriod: String, CaseIterable, Identifiable {
    case week = "Week"
    case month = "Month"
    case year = "Year"

    var id: String { rawValue }

    var shortLabel: String {
        switch self {
        case .week: return "1W"
        case .month: return "1M"
        case .year: return "1Y"
        }
    }

    var daySpan: Int {
        switch self {
        case .week: return 7
        case .month: return 30
        case .year: return 365
        }
    }
}

struct DailyNutritionPoint: Identifiable {
    let date: Date
    var breakfastCalories: Int
    var lunchCalories: Int
    var dinnerCalories: Int
    var otherCalories: Int
    var protein: Double
    var carbs: Double
    var fat: Double
    var mealsLogged: Int

    var id: Date { date }
    var totalCalories: Int { breakfastCalories + lunchCalories + dinnerCalories + otherCalories }
}

@Observable
@MainActor
final class MealViewModel {
    private var viewContext: NSManagedObjectContext
    var loadedMeals: [CDMeal] = []
    var loadedDate: Date = Date()

    init(context: NSManagedObjectContext) {
        self.viewContext = context
        fetchTodaysMeals()
    }

    func fetchTodaysMeals() {
        fetchMeals(for: loadedDate)
    }

    func fetchMeals(for day: Date) {
        guard let rawEmail = KeychainService.getLoggedInEmail() else {
            loadedMeals = []
            loadedDate = Date()
            return
        }
        let email = rawEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: day)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let request: NSFetchRequest<CDMeal> = CDMeal.fetchRequest()
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "userProfile.email == %@", email),
            NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
        ])
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDMeal.date, ascending: true)]

        loadedDate = day
        do {
            loadedMeals = try viewContext.fetch(request)
        } catch {
            print("Failed to fetch meals: \(error)")
        }
    }

    // MARK: - Nutrition Summary

    var totalCaloriesToday: Int {
        loadedMeals.reduce(0) { total, meal in
            total + foodItemsCalories(for: meal)
        }
    }

    var totalProteinToday: Double {
        loadedMeals.reduce(0) { total, meal in
            total + foodItemsMacro(for: meal, keyPath: \.proteinPer100g)
        }
    }

    var totalCarbsToday: Double {
        loadedMeals.reduce(0) { total, meal in
            total + foodItemsMacro(for: meal, keyPath: \.carbsPer100g)
        }
    }

    var totalFatToday: Double {
        loadedMeals.reduce(0) { total, meal in
            total + foodItemsMacro(for: meal, keyPath: \.fatPer100g)
        }
    }

    func mealForType(_ type: String) -> CDMeal? {
        mealsForType(type).first
    }

    func mealsForType(_ type: String) -> [CDMeal] {
        loadedMeals
            .filter { ($0.mealType ?? "").caseInsensitiveCompare(type) == .orderedSame }
            .sorted { ($0.date ?? .distantPast) < ($1.date ?? .distantPast) }
    }

    func foodItemsForMeal(_ meal: CDMeal) -> [CDFoodItem] {
        (meal.foodItems as? Set<CDFoodItem>)?.sorted { ($0.name ?? "") < ($1.name ?? "") } ?? []
    }

    func caloriesForMeal(_ meal: CDMeal) -> Int {
        foodItemsCalories(for: meal)
    }

    // MARK: - Nutrition History

    func dailyNutritionHistory(for period: NutritionHistoryPeriod, referenceDate: Date = Date()) -> [DailyNutritionPoint] {
        let calendar = Calendar.current
        let endDay = calendar.startOfDay(for: referenceDate)
        let startDay = calendar.date(byAdding: .day, value: -(period.daySpan - 1), to: endDay) ?? endDay
        let endExclusive = calendar.date(byAdding: .day, value: 1, to: endDay) ?? endDay

        var pointsByDate: [Date: DailyNutritionPoint] = [:]
        for offset in 0..<period.daySpan {
            guard let date = calendar.date(byAdding: .day, value: offset, to: startDay) else { continue }
            pointsByDate[date] = DailyNutritionPoint(
                date: date,
                breakfastCalories: 0,
                lunchCalories: 0,
                dinnerCalories: 0,
                otherCalories: 0,
                protein: 0,
                carbs: 0,
                fat: 0,
                mealsLogged: 0
            )
        }

        let meals = fetchMeals(from: startDay, to: endExclusive)
        for meal in meals {
            guard let mealDate = meal.date else { continue }
            let day = calendar.startOfDay(for: mealDate)
            guard var point = pointsByDate[day] else { continue }

            let calories = foodItemsCalories(for: meal)
            let protein = foodItemsMacro(for: meal, keyPath: \.proteinPer100g)
            let carbs = foodItemsMacro(for: meal, keyPath: \.carbsPer100g)
            let fat = foodItemsMacro(for: meal, keyPath: \.fatPer100g)

            let type = (meal.mealType ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if type == "breakfast" {
                point.breakfastCalories += calories
            } else if type == "lunch" {
                point.lunchCalories += calories
            } else if type == "dinner" {
                point.dinnerCalories += calories
            } else {
                point.otherCalories += calories
            }

            point.protein += protein
            point.carbs += carbs
            point.fat += fat
            point.mealsLogged += 1
            pointsByDate[day] = point
        }

        return pointsByDate.values.sorted { $0.date < $1.date }
    }

    // MARK: - Log Meal with Food Items

    @discardableResult
    func createFoodItem(
        name: String,
        brand: String,
        caloriesPer100g: Double,
        proteinPer100g: Double,
        carbsPer100g: Double,
        fatPer100g: Double,
        quantityGrams: Double = 100
    ) -> CDFoodItem? {
        guard let profile = fetchUserProfile() else { return nil }
        let meal = CDMeal(context: viewContext)
        meal.id = UUID()
        meal.mealType = "Food Library"
        meal.date = Date()
        meal.userProfile = profile

        let foodItem = CDFoodItem(context: viewContext)
        foodItem.id = UUID()
        foodItem.name = name
        foodItem.brand = brand
        foodItem.caloriesPer100g = caloriesPer100g
        foodItem.proteinPer100g = proteinPer100g
        foodItem.carbsPer100g = carbsPer100g
        foodItem.fatPer100g = fatPer100g
        foodItem.quantityGrams = quantityGrams
        foodItem.meal = meal

        guard save() else { return nil }
        return foodItem
    }

    @discardableResult
    func logMeal(
        mealType: String,
        date: Date = Date(),
        foodItems: [(name: String, brand: String, caloriesPer100g: Double, proteinPer100g: Double, carbsPer100g: Double, fatPer100g: Double, quantityGrams: Double)]
    ) -> Bool {
        guard let profile = fetchUserProfile() else { return false }

        let meal = CDMeal(context: viewContext)
        meal.id = UUID()
        meal.mealType = mealType
        meal.date = date
        meal.userProfile = profile

        for item in foodItems {
            let foodItem = CDFoodItem(context: viewContext)
            foodItem.id = UUID()
            foodItem.name = item.name
            foodItem.brand = item.brand
            foodItem.caloriesPer100g = item.caloriesPer100g
            foodItem.proteinPer100g = item.proteinPer100g
            foodItem.carbsPer100g = item.carbsPer100g
            foodItem.fatPer100g = item.fatPer100g
            foodItem.quantityGrams = item.quantityGrams
            foodItem.meal = meal
        }

        guard save() else { return false }
        fetchMeals(for: date)
        return true
    }

    // MARK: - Add food item to existing meal

    func addFoodItem(
        to meal: CDMeal,
        name: String,
        brand: String,
        caloriesPer100g: Double,
        proteinPer100g: Double,
        carbsPer100g: Double,
        fatPer100g: Double,
        quantityGrams: Double
    ) {
        let foodItem = CDFoodItem(context: viewContext)
        foodItem.id = UUID()
        foodItem.name = name
        foodItem.brand = brand
        foodItem.caloriesPer100g = caloriesPer100g
        foodItem.proteinPer100g = proteinPer100g
        foodItem.carbsPer100g = carbsPer100g
        foodItem.fatPer100g = fatPer100g
        foodItem.quantityGrams = quantityGrams
        foodItem.meal = meal

        guard save() else { return }
        fetchMeals(for: loadedDate)
    }

    // MARK: - Recent & Frequent Foods

    /// Returns food items ordered by most recently logged (by meal date), unique by name+brand.
    func recentFoodItems(limit: Int = 30) -> [CDFoodItem] {
        guard let rawEmail = KeychainService.getLoggedInEmail() else { return [] }
        let email = rawEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let request: NSFetchRequest<CDFoodItem> = CDFoodItem.fetchRequest()
        request.predicate = NSPredicate(format: "meal.userProfile.email == %@", email)
        request.sortDescriptors = [
            NSSortDescriptor(key: "meal.date", ascending: false),
            NSSortDescriptor(keyPath: \CDFoodItem.name, ascending: true)
        ]
        request.fetchLimit = limit * 3 // fetch extra to dedupe

        do {
            let all = try viewContext.fetch(request)
            var seen = Set<String>()
            var result: [CDFoodItem] = []
            for item in all {
                let key = "\(item.name ?? "")|\(item.brand ?? "")"
                if seen.insert(key).inserted {
                    result.append(item)
                    if result.count >= limit { break }
                }
            }
            return result
        } catch {
            print("Failed to fetch recent food items: \(error)")
            return []
        }
    }

    /// Returns food items ordered by frequency (most logged first), unique by name+brand.
    func frequentFoodItems(limit: Int = 30) -> [CDFoodItem] {
        guard let rawEmail = KeychainService.getLoggedInEmail() else { return [] }
        let email = rawEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let request: NSFetchRequest<CDFoodItem> = CDFoodItem.fetchRequest()
        request.predicate = NSPredicate(format: "meal.userProfile.email == %@", email)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDFoodItem.name, ascending: true)]

        do {
            let all = try viewContext.fetch(request)
            var countByKey: [String: (count: Int, item: CDFoodItem)] = [:]
            for item in all {
                let key = "\(item.name ?? "")|\(item.brand ?? "")"
                if let existing = countByKey[key] {
                    countByKey[key] = (existing.count + 1, existing.item)
                } else {
                    countByKey[key] = (1, item)
                }
            }
            return countByKey.values
                .sorted { $0.count == $1.count ? (($0.item.name ?? "") < ($1.item.name ?? "")) : $0.count > $1.count }
                .prefix(limit)
                .map(\.item)
        } catch {
            print("Failed to fetch frequent food items: \(error)")
            return []
        }
    }

    // MARK: - Delete

    func deleteMeal(_ meal: CDMeal) {
        viewContext.delete(meal)
        save()
        fetchTodaysMeals()
    }

    func deleteFoodItem(_ item: CDFoodItem) {
        guard let meal = item.meal, let mealDate = meal.date else {
            viewContext.delete(item)
            save()
            fetchMeals(for: loadedDate)
            return
        }

        viewContext.delete(item)

        if (meal.foodItems as? Set<CDFoodItem>)?.isEmpty == true {
            viewContext.delete(meal)
        }

        save()
        fetchMeals(for: mealDate)
    }

    func deleteSavedFoodItem(with objectID: NSManagedObjectID) {
        do {
            if let item = try viewContext.existingObject(with: objectID) as? CDFoodItem {
                viewContext.delete(item)
                save()
            }
        } catch {
            print("Failed to delete saved food item: \(error)")
        }
    }

    // MARK: - Helpers

    private func foodItemsCalories(for meal: CDMeal) -> Int {
        guard let items = meal.foodItems as? Set<CDFoodItem> else { return 0 }
        return items.reduce(0) { total, item in
            total + Int(round(item.caloriesPer100g * (item.quantityGrams / 100)))
        }
    }

    private func foodItemsMacro(for meal: CDMeal, keyPath: KeyPath<CDFoodItem, Double>) -> Double {
        guard let items = meal.foodItems as? Set<CDFoodItem> else { return 0 }
        return items.reduce(0) { total, item in
            total + (item[keyPath: keyPath] * (item.quantityGrams / 100))
        }
    }

    private func fetchMeals(from startDate: Date, to endDate: Date) -> [CDMeal] {
        guard let rawEmail = KeychainService.getLoggedInEmail() else { return [] }
        let email = rawEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let request: NSFetchRequest<CDMeal> = CDMeal.fetchRequest()
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "userProfile.email == %@", email),
            NSPredicate(format: "date >= %@ AND date < %@", startDate as NSDate, endDate as NSDate)
        ])
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDMeal.date, ascending: true)]

        do {
            return try viewContext.fetch(request)
        } catch {
            print("Failed to fetch historical meals: \(error)")
            return []
        }
    }

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

    @discardableResult
    private func save() -> Bool {
        do {
            try viewContext.save()
            return true
        } catch {
            print("Failed to save: \(error)")
            return false
        }
    }
}
