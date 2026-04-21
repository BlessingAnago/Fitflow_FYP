//
//  AuthViewModel.swift
//  FitFlow
//
//  MVVM ViewModel for offline authentication (signup/login).
//  Stores credentials in Keychain, user profile in Core Data.
//

import SwiftUI
import Observation
import CoreData
import LocalAuthentication

@Observable
@MainActor
final class AuthViewModel {
    var email = ""
    var password = ""
    var confirmPassword = ""
    var fullName = ""

    var isLoading = false
    var errorMessage: String?
    var isAuthenticated = false

    // Biometric
    var biometricsAvailable = false
    var biometricType: LABiometryType = .none

    init() {
        checkBiometrics()
        // Restore email if session exists; do not auto-unlock (lock screen may be required)
        if let savedEmail = KeychainService.getLoggedInEmail(),
           KeychainService.accountExists(email: savedEmail) {
            email = savedEmail
        } else {
            KeychainService.clearLoggedInEmail()
        }
    }

    /// Call after successful biometric or password unlock when app was locked
    func unlock() {
        if let savedEmail = KeychainService.getLoggedInEmail() {
            email = savedEmail
        }
        isAuthenticated = true
    }

    // MARK: - Validation

    var isSignupValid: Bool {
        !fullName.trimmingCharacters(in: .whitespaces).isEmpty &&
        isValidEmail(email) &&
        password.count >= 6 &&
        password == confirmPassword
    }

    var isLoginValid: Bool {
        isValidEmail(email) && !password.isEmpty
    }

    private func isValidEmail(_ email: String) -> Bool {
        let pattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: email)
    }

    // MARK: - Signup

    func signup(context: NSManagedObjectContext) {
        errorMessage = nil

        guard isSignupValid else {
            if fullName.trimmingCharacters(in: .whitespaces).isEmpty {
                errorMessage = "Please enter your full name."
            } else if !isValidEmail(email) {
                errorMessage = "Please enter a valid email."
            } else if password.count < 6 {
                errorMessage = "Password must be at least 6 characters."
            } else if password != confirmPassword {
                errorMessage = "Passwords do not match."
            }
            return
        }

        isLoading = true

        do {
            let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let normalizedName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)

            // Save Core Data profile first (before Keychain) so we don't have credentials without profile
            let profile = CDUserProfile(context: context)
            profile.id = UUID()
            profile.email = normalizedEmail
            profile.fullName = normalizedName
            profile.username = normalizedName
            profile.createdAt = Date()
            profile.dailyCalorieGoal = 2000

            try context.save()

            let hash = KeychainService.hashPassword(password)
            try KeychainService.saveCredentials(email: normalizedEmail, passwordHash: hash)

            KeychainService.saveLoggedInEmail(normalizedEmail)
            errorMessage = nil
            isAuthenticated = true
        } catch {
            context.rollback()
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Login

    func login() {
        errorMessage = nil

        guard isLoginValid else {
            errorMessage = "Please enter a valid email and password."
            return
        }

        isLoading = true

        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if KeychainService.validateCredentials(email: normalizedEmail, password: password) {
            KeychainService.saveLoggedInEmail(normalizedEmail)
            errorMessage = nil
            isAuthenticated = true
        } else {
            errorMessage = "Invalid email or password."
        }

        isLoading = false
    }

    // MARK: - Biometric Auth

    func checkBiometrics() {
        let context = LAContext()
        var error: NSError?
        biometricsAvailable = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        biometricType = context.biometryType
    }

    func authenticateWithBiometrics() {
        guard let savedEmail = KeychainService.getLoggedInEmail() else {
            errorMessage = "No saved account. Please log in first."
            return
        }

        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            errorMessage = error?.localizedDescription ?? "Biometrics are not available."
            return
        }

        let reason = "Authenticate to access FitFlow"

        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
            DispatchQueue.main.async {
                if success {
                    self.email = savedEmail
                    self.errorMessage = nil
                    self.isAuthenticated = true
                } else {
                    self.errorMessage = error?.localizedDescription ?? "Biometric authentication failed."
                }
            }
        }
    }

    // MARK: - Logout

    func logout() {
        KeychainService.clearLoggedInEmail()
        isAuthenticated = false
        email = ""
        password = ""
        confirmPassword = ""
        fullName = ""
        errorMessage = nil
    }
}
