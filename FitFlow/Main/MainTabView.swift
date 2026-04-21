//
//  MainTabView.swift
//  FitFlow
//
//  Four tabs: Dashboard, Workouts, Stats, Profile (per architecture).
//  Passes authViewModel to ProfileView for logout functionality.
//

import SwiftUI
import CoreData

struct MainTabView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedTab: Int = 0
    @State private var sharedProfileVM: UserProfileViewModel?
    @State private var sharedProgressVM: ProgressViewModel?
    var authViewModel: AuthViewModel

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView(sharedProfileVM: sharedProfileVM)
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }
                .tag(0)
            WorkoutsListView(sharedProfileVM: sharedProfileVM)
                .tabItem {
                    Label("Workouts", systemImage: "dumbbell.fill")
                }
                .tag(1)
            StatsView(sharedProfileVM: sharedProfileVM, sharedProgressVM: sharedProgressVM)
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }
                .tag(2)
            ProfileView(authViewModel: authViewModel, sharedProfileVM: sharedProfileVM, sharedProgressVM: sharedProgressVM, selectedTab: selectedTab)
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(3)
        }
        .tint(AppColors.onboardingBlue)
        .onAppear {
            if sharedProfileVM == nil {
                let vm = UserProfileViewModel(context: viewContext)
                vm.loadProfile()
                sharedProfileVM = vm
            }
            if sharedProgressVM == nil {
                sharedProgressVM = ProgressViewModel(context: viewContext)
            }
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(AppColors.darkSurface)
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

#Preview {
    MainTabView(authViewModel: AuthViewModel())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
