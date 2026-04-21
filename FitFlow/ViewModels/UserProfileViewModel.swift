//
//  UserProfileViewModel.swift
//  FitFlow
//
//  MVVM ViewModel managing the logged-in user's Core Data profile.
//

import SwiftUI
import CoreData
import Observation

@Observable
@MainActor
final class UserProfileViewModel {
    private var viewContext: NSManagedObjectContext
    private(set) var profile: CDUserProfile?

    /// Incremented whenever profile is updated so all UI reading profile re-renders in real time.
    private(set) var profileUpdateCounter: Int = 0

    var fullName: String { profile?.fullName ?? "User" }
    var email: String { profile?.email ?? "" }
    var heightCm: Int { Int(profile?.heightCm ?? 170) }
    var weightKg: Int { Int(profile?.weightKg ?? 70) }
    var age: Int { Int(profile?.age ?? 28) }
    var gender: String { profile?.gender ?? "Male" }
    var fitnessGoal: String { profile?.fitnessGoal ?? "Stay Fit" }
    var workoutDaysPerWeek: Int { Int(profile?.workoutDaysPerWeek ?? 3) }
    var dailyCalorieGoal: Int { Int(profile?.dailyCalorieGoal ?? 2000) }
    var biometricsEnabled: Bool { profile?.biometricsEnabled ?? false }
    var useMetricSystem: Bool { profile?.useMetricSystem ?? true }
    var hasCompletedOnboarding: Bool { profile?.hasCompletedOnboarding ?? false }

    init(context: NSManagedObjectContext) {
        self.viewContext = context
        loadProfile()
    }

    func loadProfile() {
        guard let rawEmail = KeychainService.getLoggedInEmail() else {
            profile = nil
            return
        }
        let email = rawEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let request: NSFetchRequest<CDUserProfile> = CDUserProfile.fetchRequest()
        request.predicate = NSPredicate(format: "email == %@", email)
        request.fetchLimit = 1

        do {
            profile = try viewContext.fetch(request).first
        } catch {
            print("Failed to load profile: \(error)")
        }
    }

    // MARK: - Update profile from onboarding data

    @discardableResult
    func updateFromOnboarding(
        heightCm: Int,
        weightKg: Int,
        age: Int,
        gender: String,
        fitnessGoal: String,
        daysPerWeek: Int,
        workoutWeekdays: String?,
        workoutTime: Date,
        biometricsEnabled: Bool
    ) -> Bool {
        guard let profile = profile else { return false }
        profile.heightCm = Int16(heightCm)
        profile.weightKg = Int16(weightKg)
        profile.age = Int16(age)
        profile.gender = gender
        profile.fitnessGoal = fitnessGoal
        profile.workoutDaysPerWeek = Int16(daysPerWeek)
        profile.workoutWeekdays = workoutWeekdays
        profile.preferredWorkoutTime = workoutTime
        profile.biometricsEnabled = biometricsEnabled
        profile.hasCompletedOnboarding = true
        guard save() else { return false }
        profileUpdateCounter += 1
        return true
    }

    // MARK: - Individual updates

    func updateHeight(_ cm: Int) {
        guard let profile else { return }
        profile.heightCm = Int16(cm)
        save()
        profileUpdateCounter += 1
    }

    func updateWeight(_ kg: Int) {
        guard let profile else { return }
        profile.weightKg = Int16(kg)
        save()
        profileUpdateCounter += 1
    }

    func updateAge(_ years: Int) {
        guard let profile else { return }
        profile.age = Int16(years)
        save()
        profileUpdateCounter += 1
    }

    func updateFullName(_ name: String) {
        guard let profile else { return }
        profile.fullName = name
        profile.username = name
        save()
        profileUpdateCounter += 1
    }

    func updateDailyCalorieGoal(_ goal: Int) {
        guard let profile else { return }
        profile.dailyCalorieGoal = Int16(goal)
        save()
        profileUpdateCounter += 1
    }

    func updateFitnessGoal(_ goal: String) {
        guard let profile else { return }
        profile.fitnessGoal = goal
        save()
        profileUpdateCounter += 1
    }

    func toggleBiometrics(_ enabled: Bool) {
        guard let profile else { return }
        profile.biometricsEnabled = enabled
        save()
        profileUpdateCounter += 1
    }

    func updateUseMetricSystem(_ useMetric: Bool) {
        guard let profile else { return }
        profile.useMetricSystem = useMetric
        save()
        profileUpdateCounter += 1
    }

    @discardableResult
    private func save() -> Bool {
        do {
            try viewContext.save()
            return true
        } catch {
            print("Failed to save profile: \(error)")
            return false
        }
    }
}
