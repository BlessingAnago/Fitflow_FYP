//
//  RootView.swift
//  FitFlow
//
//  Root: login → lock screen (if biometrics) → onboarding (if first time) → main app.
//

import SwiftUI
import CoreData

struct RootView: View {
    @State private var authViewModel = AuthViewModel()
    @State private var hasCompletedOnboarding = false
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.scenePhase) private var scenePhase
    @State private var biometricLockRequired: Bool?

    private var hasSavedSession: Bool {
        guard let email = KeychainService.getLoggedInEmail() else { return false }
        return KeychainService.accountExists(email: email)
    }

    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                if hasCompletedOnboarding {
                    MainTabView(authViewModel: authViewModel)
                } else {
                    OnboardingCoordinatorView(authViewModel: authViewModel) {
                        refreshOnboardingStatus()
                    }
                }
            } else if !hasSavedSession {
                LoginView(authViewModel: authViewModel)
            } else if biometricLockRequired == nil {
                ProgressView()
                    .tint(AppColors.darkText)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppColors.darkBackground)
                    .task { resolveBiometricLockRequired() }
            } else if biometricLockRequired == true {
                LockScreenView(authViewModel: authViewModel, onUnlock: { })
            } else {
                Color.clear
                    .onAppear { authViewModel.unlock() }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authViewModel.isAuthenticated)
        .animation(.easeInOut(duration: 0.3), value: hasCompletedOnboarding)
        .animation(.easeInOut(duration: 0.2), value: biometricLockRequired)
        .onChange(of: authViewModel.isAuthenticated) { _, newValue in
            if !newValue {
                biometricLockRequired = nil
            } else {
                refreshOnboardingStatus()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                lockIfBiometricsEnabled()
            }
        }
    }

    /// When app goes to background, lock the app so Face ID / Touch ID or password is required on return.
    private func lockIfBiometricsEnabled() {
        guard authViewModel.isAuthenticated else { return }
        let profileVM = UserProfileViewModel(context: viewContext)
        profileVM.loadProfile()
        if profileVM.biometricsEnabled {
            authViewModel.isAuthenticated = false
        }
    }

    private func resolveBiometricLockRequired() {
        let profileVM = UserProfileViewModel(context: viewContext)
        profileVM.loadProfile()
        biometricLockRequired = profileVM.biometricsEnabled
    }

    private func refreshOnboardingStatus() {
        let profileVM = UserProfileViewModel(context: viewContext)
        profileVM.loadProfile()
        hasCompletedOnboarding = profileVM.hasCompletedOnboarding
    }
}

#Preview("Login") {
    RootView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
