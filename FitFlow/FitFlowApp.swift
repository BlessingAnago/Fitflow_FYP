//
//  FitFlowApp.swift
//  FitFlow
//
//  Created by SYed Shah Abdur Rehman on 02/02/2026.
//

import SwiftUI
import CoreData

@main
struct FitFlowApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
