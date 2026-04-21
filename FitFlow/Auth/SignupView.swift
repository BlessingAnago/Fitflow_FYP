//
//  SignupView.swift
//  FitFlow
//
//  Signup screen – dark theme, full name + email + password + confirm,
//  create account, biometric opt-in. Matches FitFlow design system.
//

import SwiftUI
import CoreData

struct SignupView: View {
    @Bindable var authViewModel: AuthViewModel
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?
    @State private var showPassword = false
    @State private var showConfirmPassword = false

    enum Field { case name, email, password, confirm }

    var body: some View {
        ZStack {
            AppColors.darkBackground.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 0) {
                    Spacer().frame(height: 40)
                    headerSection
                    Spacer().frame(height: 32)
                    formSection
                    Spacer().frame(height: 24)
                    if let error = authViewModel.errorMessage {
                        errorBanner(error)
                    }
                    passwordRequirements
                    Spacer().frame(height: 24)
                    signupButton
                    Spacer().frame(height: 24)
                    loginLink
                    Spacer().frame(height: 60)
                }
                .padding(.horizontal, AppLayout.screenPadding)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .onChange(of: authViewModel.isAuthenticated) { _, newValue in
            if newValue {
                dismiss()
            }
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }

    // MARK: - Subviews

    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppColors.primaryGreen.opacity(0.15))
                    .frame(width: 80, height: 80)
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(AppColors.primaryGreen)
            }
            Text("Create Account")
                .font(AppTypography.largeTitle())
                .foregroundStyle(AppColors.darkText)
            Text("Start your fitness journey today")
                .font(AppTypography.body())
                .foregroundStyle(AppColors.darkTextSecondary)
        }
    }

    private var formSection: some View {
        VStack(spacing: 16) {
            // Full Name
            fieldRow(label: "Full Name", icon: "person.fill", field: .name) {
                TextField("Alex Johnson", text: $authViewModel.fullName)
                    .font(AppTypography.body())
                    .foregroundStyle(AppColors.darkText)
                    .textContentType(.name)
                    .focused($focusedField, equals: .name)
            }

            // Email
            fieldRow(label: "Email", icon: "envelope.fill", field: .email) {
                TextField("your@email.com", text: $authViewModel.email)
                    .font(AppTypography.body())
                    .foregroundStyle(AppColors.darkText)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .focused($focusedField, equals: .email)
            }

            // Password
            fieldRow(label: "Password", icon: "lock.fill", field: .password) {
                HStack(spacing: 8) {
                    Group {
                        if showPassword {
                            TextField("Min 6 characters", text: $authViewModel.password)
                        } else {
                            SecureField("Min 6 characters", text: $authViewModel.password)
                        }
                    }
                    .font(AppTypography.body())
                    .foregroundStyle(AppColors.darkText)
                    .textContentType(.newPassword)
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
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Confirm Password
            fieldRow(label: "Confirm Password", icon: "lock.shield.fill", field: .confirm) {
                HStack(spacing: 8) {
                    Group {
                        if showConfirmPassword {
                            TextField("Re-enter password", text: $authViewModel.confirmPassword)
                        } else {
                            SecureField("Re-enter password", text: $authViewModel.confirmPassword)
                        }
                    }
                    .font(AppTypography.body())
                    .foregroundStyle(AppColors.darkText)
                    .textContentType(.newPassword)
                    .focused($focusedField, equals: .confirm)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Button {
                        showConfirmPassword.toggle()
                    } label: {
                        Image(systemName: showConfirmPassword ? "eye.slash" : "eye")
                            .font(.callout)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(AppColors.darkTextSecondary)
                    .accessibilityLabel(showConfirmPassword ? "Hide password confirmation" : "Show password confirmation")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func fieldRow<Content: View>(label: String, icon: String, field: Field, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(AppTypography.caption())
                .foregroundStyle(AppColors.darkTextSecondary)
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundStyle(AppColors.darkTextSecondary)
                    .frame(width: 20)
                content()
            }
            .padding(.horizontal, AppLayout.cardPadding)
            .padding(.vertical, 14)
            .background(AppColors.darkSurface)
            .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadiusSmall))
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
        .padding(.bottom, 8)
    }

    private var passwordRequirements: some View {
        VStack(alignment: .leading, spacing: 6) {
            requirementRow("At least 6 characters", met: authViewModel.password.count >= 6)
            requirementRow("Passwords match", met: !authViewModel.confirmPassword.isEmpty && authViewModel.password == authViewModel.confirmPassword)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func requirementRow(_ text: String, met: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: met ? "checkmark.circle.fill" : "circle")
                .font(.caption)
                .foregroundStyle(met ? AppColors.primaryGreen : AppColors.darkTextSecondary)
            Text(text)
                .font(AppTypography.caption2())
                .foregroundStyle(met ? AppColors.primaryGreen : AppColors.darkTextSecondary)
        }
    }

    private var signupButton: some View {
        Button {
            focusedField = nil
            authViewModel.signup(context: viewContext)
        } label: {
            if authViewModel.isLoading {
                ProgressView()
                    .tint(.white)
            } else {
                Text("Create Account")
            }
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(authViewModel.isLoading)
    }

    private var loginLink: some View {
        HStack(spacing: 4) {
            Text("Already have an account?")
                .font(AppTypography.callout())
                .foregroundStyle(AppColors.darkTextSecondary)
            Button("Log In") {
                authViewModel.errorMessage = nil
                dismiss()
            }
            .font(AppTypography.callout().weight(.semibold))
            .foregroundStyle(AppColors.primaryGreen)
        }
    }
}

#Preview {
    SignupView(authViewModel: AuthViewModel())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
