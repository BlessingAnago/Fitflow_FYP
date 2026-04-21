//
//  LockScreenView.swift
//  FitFlow
//
//  Gate when biometrics are enabled: Face ID / Touch ID or password to unlock.
//

import SwiftUI
import LocalAuthentication

struct LockScreenView: View {
    var authViewModel: AuthViewModel
    var onUnlock: () -> Void

    @State private var showPasswordFields = false

    private var biometricIconName: String {
        switch authViewModel.biometricType {
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        default: return "lock.fill"
        }
    }

    private var biometricLabel: String {
        switch authViewModel.biometricType {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        default: return "biometrics"
        }
    }
    @State private var password = ""
    @FocusState private var passwordFocused: Bool

    var body: some View {
        ZStack {
            AppColors.darkBackground.ignoresSafeArea()
            VStack(spacing: 32) {
                Spacer()
                Image(systemName: biometricIconName)
                    .font(.system(size: 56))
                    .foregroundStyle(AppColors.onboardingBlue)
                Text("Unlock FitFlow")
                    .font(AppTypography.largeTitle())
                    .foregroundStyle(AppColors.darkText)
                Text("Use \(biometricLabel) or your password to continue.")
                    .font(AppTypography.body())
                    .foregroundStyle(AppColors.darkTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                if showPasswordFields {
                    passwordSection
                } else {
                    biometricSection
                }
                Spacer()
            }
        }
        .onAppear {
            if !showPasswordFields {
                attemptBiometric()
            }
        }
        .onChange(of: authViewModel.isAuthenticated) { _, newVal in
            if newVal { onUnlock() }
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }

    private var biometricSection: some View {
        VStack(spacing: 16) {
            Button {
                attemptBiometric()
            } label: {
                HStack {
                    Image(systemName: biometricIconName)
                    Text("Unlock with \(biometricLabel)")
                }
            }
            .buttonStyle(PrimaryButtonStyle(color: AppColors.onboardingBlue))
            .padding(.horizontal, AppLayout.screenPadding)

            Button("Use password") {
                showPasswordFields = true
                passwordFocused = true
            }
            .font(AppTypography.headline())
            .foregroundStyle(AppColors.darkText)
        }
    }

    private var passwordSection: some View {
        VStack(spacing: 16) {
            if let err = authViewModel.errorMessage {
                Text(err)
                    .font(AppTypography.caption())
                    .foregroundStyle(AppColors.negativeRed)
                    .padding(.horizontal)
            }
            HStack(spacing: 12) {
                Image(systemName: "lock.fill")
                    .foregroundStyle(AppColors.darkTextSecondary)
                    .frame(width: 20)
                SecureField("Password", text: $password)
                    .textContentType(.password)
                    .foregroundStyle(AppColors.darkText)
                    .focused($passwordFocused)
            }
            .padding(AppLayout.cardPadding)
            .background(AppColors.darkSurface)
            .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadiusSmall))
            .padding(.horizontal, AppLayout.screenPadding)

            Button("Unlock") {
                unlockWithPassword()
            }
            .buttonStyle(PrimaryButtonStyle(color: AppColors.onboardingBlue))
            .padding(.horizontal, AppLayout.screenPadding)

            Button("Back") {
                showPasswordFields = false
                password = ""
                authViewModel.errorMessage = nil
            }
            .font(AppTypography.callout())
            .foregroundStyle(AppColors.darkTextSecondary)
        }
    }

    private func attemptBiometric() {
        authViewModel.errorMessage = nil
        authViewModel.authenticateWithBiometrics()
    }

    private func unlockWithPassword() {
        authViewModel.errorMessage = nil
        guard let savedEmail = KeychainService.getLoggedInEmail() else {
            authViewModel.errorMessage = "No saved account."
            return
        }
        if KeychainService.validateCredentials(email: savedEmail, password: password) {
            authViewModel.unlock()
            // onUnlock() is called once via onChange(of: authViewModel.isAuthenticated)
        } else {
            authViewModel.errorMessage = "Invalid password."
        }
    }
}

#Preview {
    LockScreenView(authViewModel: AuthViewModel(), onUnlock: {})
}
