//
//  FitFlowApp.swift
//  FitFlow
//

//

import SwiftUI
import CoreData
import UIKit

@main
struct FitFlowApp: App {
    let persistenceController = PersistenceController.shared

    init() {
        // Cursor tint to match app accent
        UITextField.appearance().tintColor = UIColor(Color(red: 0x13/255, green: 0xEC/255, blue: 0x5B/255))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
