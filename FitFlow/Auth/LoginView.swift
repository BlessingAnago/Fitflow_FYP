//
//  LoginView.swift
//  FitFlow
//
//  Login screen – dark theme, email + password fields, biometric option,
//  link to signup. Matches FitFlow design system.
//

import SwiftUI
import CoreData
import LocalAuthentication

struct LoginView: View {
    @Bindable var authViewModel: AuthViewModel
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showSignup = false
    @State private var showPassword = false
    @FocusState private var focusedField: Field?

    enum Field { case email, password }

    var body: some View {
        ZStack {
            AppColors.darkBackground.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 0) {
                    Spacer().frame(height: 60)
                    logoSection
                    Spacer().frame(height: 40)
                    formSection
                    Spacer().frame(height: 24)
                    if let error = authViewModel.errorMessage {
                        errorBanner(error)
                    }
                    loginButton
                    biometricButton
                    Spacer().frame(height: 32)
                    signupLink
                    Spacer().frame(height: 60)
                }
                .padding(.horizontal, AppLayout.screenPadding)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .fullScreenCover(isPresented: $showSignup) {
            SignupView(authViewModel: authViewModel)
                .environment(\.managedObjectContext, viewContext)
        }
    }

    // MARK: - Subviews

    private var logoSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(AppColors.primaryGreen.opacity(0.15))
                    .frame(width: 100, height: 100)
                Image(systemName: "figure.run")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(AppColors.primaryGreen)
            }
            Text("FitFlow")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.darkText)
            Text("Welcome back")
                .font(AppTypography.body())
                .foregroundStyle(AppColors.darkTextSecondary)
        }
    }

    private var formSection: some View {
        VStack(spacing: 16) {
            // Email
            VStack(alignment: .leading, spacing: 8) {
                Text("Email")
                    .font(AppTypography.caption())
                    .foregroundStyle(AppColors.darkTextSecondary)
                HStack(spacing: 12) {
                    Image(systemName: "envelope.fill")
                        .foregroundStyle(AppColors.darkTextSecondary)
                        .frame(width: 20)
                    TextField("your@email.com", text: $authViewModel.email)
                        .font(AppTypography.body())
                        .foregroundStyle(AppColors.darkText)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .focused($focusedField, equals: .email)
                }
                .padding(.horizontal, AppLayout.cardPadding)
                .padding(.vertical, 14)
                .background(AppColors.darkSurface)
                .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadiusSmall))
            }

            // Password
            VStack(alignment: .leading, spacing: 8) {
                Text("Password")
                    .font(AppTypography.caption())
                    .foregroundStyle(AppColors.darkTextSecondary)
                HStack(spacing: 12) {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(AppColors.darkTextSecondary)
                        .frame(width: 20)
                    Group {
                        if showPassword {
                            TextField("Password", text: $authViewModel.password)
                        } else {
                            SecureField("Password", text: $authViewModel.password)
                        }
                    }
                    .font(AppTypography.body())
                    .foregroundStyle(AppColors.darkText)
                    .textContentType(.password)
                    .focused($focusedField, equals: .password)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Button {
                        showPassword.toggle()
                    } label: {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                            .font(.callout)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(AppColors.darkTextSecondary)
                    .accessibilityLabel(showPassword ? "Hide password" : "Show password")
                }
                .padding(.horizontal, AppLayout.cardPadding)
                .padding(.vertical, 14)
                .background(AppColors.darkSurface)
                .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadiusSmall))
            }
        }
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(AppColors.negativeRed)
            Text(message)
                .font(AppTypography.caption())
                .foregroundStyle(AppColors.negativeRed)
        }
        .padding(AppLayout.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.negativeRed.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadiusSmall))
        .padding(.bottom, 16)
    }

    private var loginButton: some View {
        Button {
            focusedField = nil
            authViewModel.login()
        } label: {
            if authViewModel.isLoading {
                ProgressView()
                    .tint(.white)
            } else {
                Text("Log In")
            }
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(authViewModel.isLoading)
        .padding(.bottom, 12)
    }

    @ViewBuilder
    private var biometricButton: some View {
        if authViewModel.biometricsAvailable,
           KeychainService.getLoggedInEmail() != nil {
            let iconName: String = {
                switch authViewModel.biometricType {
                case .faceID: return "faceid"
                case .touchID: return "touchid"
                default: return "lock.fill"
                }
            }()
            Button {
                authViewModel.authenticateWithBiometrics()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: iconName)
                        .font(.title3)
                    Text(authViewModel.biometricType == .faceID ? "Log in with Face ID" : authViewModel.biometricType == .touchID ? "Log in with Touch ID" : "Use Password")
                }
            }
            .buttonStyle(SecondaryButtonStyle())
        }
    }

    private var signupLink: some View {
        HStack(spacing: 4) {
            Text("Don't have an account?")
                .font(AppTypography.callout())
                .foregroundStyle(AppColors.darkTextSecondary)
            Button("Sign Up") {
                authViewModel.errorMessage = nil
                showSignup = true
            }
            .font(AppTypography.callout().weight(.semibold))
            .foregroundStyle(AppColors.primaryGreen)
        }
    }
}

#Preview {
    LoginView(authViewModel: AuthViewModel())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
