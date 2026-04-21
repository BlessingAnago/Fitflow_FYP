//
//  ProgressViewModel.swift
//  FitFlow
//
//  MVVM ViewModel for progress/weight tracking with Core Data.
//

import SwiftUI
import CoreData
import Observation

enum DailyWeightLogResult {
    case success
    case alreadyLoggedToday
}

@Observable
@MainActor
final class ProgressViewModel {
    private var viewContext: NSManagedObjectContext
    var entries: [CDProgressEntry] = []

    init(context: NSManagedObjectContext) {
        self.viewContext = context
        fetchEntries()
    }

    func fetchEntries() {
        guard let rawEmail = KeychainService.getLoggedInEmail() else {
            entries = []
            return
        }
        let email = rawEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let request: NSFetchRequest<CDProgressEntry> = CDProgressEntry.fetchRequest()
        request.predicate = NSPredicate(format: "userProfile.email == %@", email)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDProgressEntry.date, ascending: true)]

        do {
            entries = try viewContext.fetch(request)
        } catch {
            print("Failed to fetch progress: \(error)")
        }
    }

    // MARK: - Computed Stats

    var latestWeight: Double? {
        entries.last?.weightKg
    }

    var previousWeight: Double? {
        guard entries.count >= 2 else { return nil }
        return entries[entries.count - 2].weightKg
    }

    var weightChange: Double? {
        guard let latest = latestWeight, let previous = previousWeight else { return nil }
        return latest - previous
    }

    var weightChangePercent: Double? {
        guard let change = weightChange, let previous = previousWeight, previous > 0 else { return nil }
        return (change / previous) * 100
    }

    func entriesForPeriod(_ period: String) -> [CDProgressEntry] {
        let calendar = Calendar.current
        let now = calendar.startOfDay(for: Date())
        var startDate: Date

        switch period {
        case "1W":
            startDate = calendar.date(byAdding: .weekOfYear, value: -1, to: now) ?? now
        case "1M":
            startDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case "3M":
            startDate = calendar.date(byAdding: .month, value: -3, to: now) ?? now
        case "1Y":
            startDate = calendar.date(byAdding: .year, value: -1, to: now) ?? now
        default:
            startDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        }

        return entries.filter { entry in
            guard let date = entry.date else { return false }
            return calendar.startOfDay(for: date) >= startDate
        }
    }

    var weightTrendLast30Days: Double {
        let monthEntries = entriesForPeriod("1M")
        guard let first = monthEntries.first?.weightKg,
              let last = monthEntries.last?.weightKg else { return 0 }
        return last - first
    }

    var hasLoggedWeightToday: Bool {
        let calendar = Calendar.current
        return entries.contains { entry in
            guard let date = entry.date else { return false }
            return calendar.isDateInToday(date)
        }
    }

    // MARK: - Log Progress

    func logProgress(weightKg: Double, bodyFatPercentage: Double? = nil, notes: String? = nil) {
        guard let profile = fetchUserProfile() else { return }

        let entry = CDProgressEntry(context: viewContext)
        entry.id = UUID()
        entry.date = Date()
        entry.weightKg = weightKg
        entry.bodyFatPercentage = bodyFatPercentage ?? 0
        entry.notes = notes
        entry.userProfile = profile

        // Update profile's current weight so it stays in sync app-wide
        profile.weightKg = Int16(round(weightKg))

        save()
        fetchEntries()
    }

    /// Updates today's weight entry if one exists, otherwise creates a new entry. Ensures one weight per day;
    /// e.g. logging in Stats then changing weight in Profile overwrites the same day's entry.
    func updateOrCreateTodayEntry(weightKg: Double, bodyFatPercentage: Double? = nil, notes: String? = nil) {
        guard let profile = fetchUserProfile() else { return }
        let calendar = Calendar.current
        let today = Date()

        if let existing = entries.first(where: { entry in
            guard let date = entry.date else { return false }
            return calendar.isDateInToday(date)
        }) {
            existing.weightKg = weightKg
            existing.bodyFatPercentage = bodyFatPercentage ?? existing.bodyFatPercentage
            if let n = notes { existing.notes = n }
            profile.weightKg = Int16(round(weightKg))
        } else {
            let entry = CDProgressEntry(context: viewContext)
            entry.id = UUID()
            entry.date = today
            entry.weightKg = weightKg
            entry.bodyFatPercentage = bodyFatPercentage ?? 0
            entry.notes = notes
            entry.userProfile = profile
            profile.weightKg = Int16(round(weightKg))
        }
        save()
        fetchEntries()
    }

    @discardableResult
    func logTodayWeight(weightKg: Double, bodyFatPercentage: Double? = nil, notes: String? = nil) -> DailyWeightLogResult {
        if hasLoggedWeightToday {
            return .alreadyLoggedToday
        }
        updateOrCreateTodayEntry(weightKg: weightKg, bodyFatPercentage: bodyFatPercentage, notes: notes)
        return .success
    }

    // MARK: - Delete Entry

    func deleteEntry(_ entry: CDProgressEntry) {
        viewContext.delete(entry)
        save()
        fetchEntries()
        syncProfileWeightAfterDeletion()
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

    private func syncProfileWeightAfterDeletion() {
        guard let profile = fetchUserProfile() else { return }
        guard let latestEntry = entries.last else { return }
        profile.weightKg = Int16(round(latestEntry.weightKg))
        save()
    }
}
