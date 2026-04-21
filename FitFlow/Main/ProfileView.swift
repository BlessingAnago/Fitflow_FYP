//
//  ProfileView.swift
//  FitFlow
//
//  Profile: light theme, avatar, name, email from Core Data,
//  Personal Details, App Preferences, Security, Log Out.
//

import SwiftUI
import CoreData
import LocalAuthentication

struct ProfileView: View {
    var authViewModel: AuthViewModel
    var sharedProfileVM: UserProfileViewModel? = nil
    var sharedProgressVM: ProgressViewModel? = nil
    var selectedTab: Int = 0
    @Environment(\.managedObjectContext) private var viewContext
    @State private var profileVM: UserProfileViewModel?
    @State private var progressVM: ProgressViewModel?
    @State private var metricSystemOn = true
    @State private var faceIDOn = true
    @State private var showLogoutAlert = false
    @State private var showEditHeight = false
    @State private var showEditWeight = false
    @State private var showEditAge = false
    @State private var showEditCalorieGoal = false
    @State private var showEditGoal = false
    @State private var showChangePassword = false

    private var displayName: String { profileVM?.fullName ?? "User" }
    private var displayEmail: String { profileVM?.email ?? "" }
    private var displayHeight: String {
        let cm = profileVM?.heightCm ?? 0
        guard cm > 0 else { return "Not set" }
        if metricSystemOn {
            return "\(cm) cm"
        }
        return "\(Int(round(Double(cm) / 2.54))) in"
    }
    private var displayWeight: String {
        let kg = profileVM?.weightKg ?? 0
        guard kg > 0 else { return "Not set" }
        if metricSystemOn {
            return "\(kg) kg"
        }
        return "\(Int(round(Double(kg) * 2.205))) lb"
    }
    private var displayAge: String {
        let age = profileVM?.age ?? 0
        return age > 0 ? "\(age)" : "Not set"
    }

    private var faceIDToggleLabel: String {
        switch authViewModel.biometricType {
        case .faceID: return "Enable Face ID"
        case .touchID: return "Enable Touch ID"
        default: return "Enable Biometrics"
        }
    }

    private var biometricsSupported: Bool {
        authViewModel.biometricsAvailable
    }

    var body: some View {
        let _ = profileVM?.profileUpdateCounter
        return NavigationStack {
            ZStack {
                AppColors.lightSurface.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 24) {
                        profileHeader
                        personalDetailsCard
                        appPreferencesCard
                        securityCard
                        logoutButton
                    }
                    .padding(.vertical, 24)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .onAppear { loadProfile(); loadProgressVM() }
            .onChange(of: selectedTab) { _, newVal in
                if newVal == 3 { profileVM?.loadProfile() }
            }
            .sheet(isPresented: $showEditHeight, onDismiss: { profileVM?.loadProfile() }) {
                if let vm = profileVM {
                    EditHeightSheet(profileVM: vm, useMetric: metricSystemOn, isPresented: $showEditHeight)
                }
            }
            .sheet(isPresented: $showEditWeight, onDismiss: { profileVM?.loadProfile(); progressVM?.fetchEntries() }) {
                if let vm = profileVM {
                    EditWeightSheet(profileVM: vm, progressVM: progressVM, useMetric: metricSystemOn, isPresented: $showEditWeight)
                }
            }
            .sheet(isPresented: $showEditAge, onDismiss: { profileVM?.loadProfile() }) {
                if let vm = profileVM {
                    EditAgeSheet(profileVM: vm, isPresented: $showEditAge)
                }
            }
            .sheet(isPresented: $showEditCalorieGoal, onDismiss: { profileVM?.loadProfile() }) {
                if let vm = profileVM {
                    EditCalorieGoalSheet(profileVM: vm, isPresented: $showEditCalorieGoal)
                }
            }
            .sheet(isPresented: $showEditGoal, onDismiss: { profileVM?.loadProfile() }) {
                if let vm = profileVM {
                    EditGoalSheet(profileVM: vm, isPresented: $showEditGoal)
                }
            }
            .sheet(isPresented: $showChangePassword) {
                if let vm = profileVM {
                    ChangePasswordSheet(email: vm.email, isPresented: $showChangePassword)
                }
            }
            .alert("Log Out", isPresented: $showLogoutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Log Out", role: .destructive) {
                    authViewModel.logout()
                }
            } message: {
                Text("Are you sure you want to log out?")
            }
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        }
    }

    private func loadProfile() {
        if profileVM == nil { profileVM = sharedProfileVM ?? UserProfileViewModel(context: viewContext) }
        profileVM?.loadProfile()
        faceIDOn = profileVM?.biometricsEnabled ?? false
        metricSystemOn = profileVM?.useMetricSystem ?? true
    }

    private func loadProgressVM() {
        if progressVM == nil { progressVM = sharedProgressVM ?? ProgressViewModel(context: viewContext) }
        progressVM?.fetchEntries()
    }

    private var profileHeader: some View {
        VStack(spacing: 12) {
            Text(displayName)
                .font(AppTypography.title())
                .foregroundStyle(AppColors.lightText)
            Text(displayEmail)
                .font(AppTypography.callout())
                .foregroundStyle(AppColors.lightTextSecondary)
        }
        .padding(.top, 16)
    }

    private var personalDetailsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Personal Details")
                .font(AppTypography.caption())
                .foregroundStyle(AppColors.lightTextSecondary)
                .padding(.horizontal, AppLayout.screenPadding)
                .padding(.bottom, 8)
            VStack(spacing: 0) {
                Button { showEditHeight = true } label: { profileRow(title: "Height", value: displayHeight, showChevron: true) }
                    .buttonStyle(.plain)
                Divider().padding(.leading, AppLayout.screenPadding)
                Button { showEditWeight = true } label: { profileRow(title: "Weight", value: displayWeight, showChevron: true) }
                    .buttonStyle(.plain)
                Divider().padding(.leading, AppLayout.screenPadding)
                Button { showEditAge = true } label: { profileRow(title: "Age", value: displayAge, showChevron: true) }
                    .buttonStyle(.plain)
                Divider().padding(.leading, AppLayout.screenPadding)
                Button { showEditGoal = true } label: { profileRow(title: "Goal", value: profileVM?.fitnessGoal ?? "Not set", showChevron: true) }
                    .buttonStyle(.plain)
            }
            .padding(AppLayout.cardPadding)
            .background(AppColors.lightBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadiusSmall))
        }
        .padding(.horizontal, AppLayout.screenPadding)
    }

    private var appPreferencesCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("App Preferences")
                .font(AppTypography.caption())
                .foregroundStyle(AppColors.lightTextSecondary)
                .padding(.horizontal, AppLayout.screenPadding)
                .padding(.bottom, 8)
            VStack(spacing: 0) {
                HStack {
                    Text("Metric System")
                        .font(AppTypography.body())
                        .foregroundStyle(AppColors.lightText)
                    Spacer()
                    Toggle("", isOn: $metricSystemOn)
                        .labelsHidden()
                        .tint(AppColors.profileActiveBlue)
                        .onChange(of: metricSystemOn) { _, newVal in
                            profileVM?.updateUseMetricSystem(newVal)
                        }
                }
                .padding(AppLayout.cardPadding)
                Divider().padding(.leading, AppLayout.screenPadding)
                Button { showEditCalorieGoal = true } label: { profileRow(title: "Daily Calorie Goal", value: "\(profileVM?.dailyCalorieGoal ?? 2000) kcal", showChevron: true) }
                    .buttonStyle(.plain)
            }
            .background(AppColors.lightBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadiusSmall))
        }
        .padding(.horizontal, AppLayout.screenPadding)
    }

    private var securityCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Security")
                .font(AppTypography.caption())
                .foregroundStyle(AppColors.lightTextSecondary)
                .padding(.horizontal, AppLayout.screenPadding)
                .padding(.bottom, 8)
            VStack(spacing: 0) {
                HStack {
                    Text(faceIDToggleLabel)
                        .font(AppTypography.body())
                        .foregroundStyle(AppColors.lightText)
                    Spacer()
                    Toggle("", isOn: $faceIDOn)
                        .labelsHidden()
                        .tint(AppColors.profileActiveBlue)
                        .onChange(of: faceIDOn) { _, newVal in
                            guard biometricsSupported || !newVal else {
                                faceIDOn = false
                                return
                            }
                            profileVM?.toggleBiometrics(newVal)
                        }
                        .disabled(!biometricsSupported && !faceIDOn)
                }
                .padding(AppLayout.cardPadding)
                Divider().padding(.leading, AppLayout.screenPadding)
                Button { showChangePassword = true } label: { profileRow(title: "Change Password", value: "", showChevron: true) }
                    .buttonStyle(.plain)
            }
            .background(AppColors.lightBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadiusSmall))
            if !biometricsSupported {
                Text("Biometrics are not available on this device.")
                    .font(AppTypography.caption2())
                    .foregroundStyle(AppColors.lightTextSecondary)
                    .padding(.horizontal, AppLayout.screenPadding)
                    .padding(.top, 8)
            }
        }
        .padding(.horizontal, AppLayout.screenPadding)
    }

    private var logoutButton: some View {
        Button("Log Out") {
            showLogoutAlert = true
        }
        .font(AppTypography.headline())
        .foregroundStyle(AppColors.negativeRed)
        .frame(maxWidth: .infinity)
        .padding(.top, 24)
    }

    private func profileRow(title: String, value: String, showChevron: Bool = false) -> some View {
        HStack {
            Text(title)
                .font(AppTypography.body())
                .foregroundStyle(AppColors.lightText)
            Spacer()
            if !value.isEmpty {
                Text(value)
                    .font(AppTypography.callout())
                    .foregroundStyle(AppColors.lightTextSecondary)
            }
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(AppColors.lightTextSecondary)
            }
        }
        .padding(AppLayout.cardPadding)
    }
}

// MARK: - Edit sheets

private let cmPerInch = 2.54
private let lbPerKg = 2.205

struct EditHeightSheet: View {
    var profileVM: UserProfileViewModel
    var useMetric: Bool
    @Binding var isPresented: Bool
    @State private var value: Int = 170

    private var unitLabel: String { useMetric ? "cm" : "in" }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                TextField("Height", value: $value, format: .number)
                    .font(AppTypography.title3())
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(AppColors.lightSurface)
                    .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadiusSmall))
                Text(unitLabel)
                    .font(AppTypography.caption())
                    .foregroundStyle(AppColors.lightTextSecondary)
            }
            .padding(AppLayout.screenPadding)
            .navigationTitle("Height")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                        .foregroundStyle(AppColors.profileActiveBlue)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let cm = useMetric ? value : Int(round(Double(value) * cmPerInch))
                        profileVM.updateHeight(cm)
                        isPresented = false
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColors.profileActiveBlue)
                }
            }
            .onAppear { value = useMetric ? profileVM.heightCm : Int(round(Double(profileVM.heightCm) / cmPerInch)) }
        }
        .presentationDetents([.medium])
    }
}

struct EditWeightSheet: View {
    var profileVM: UserProfileViewModel
    var progressVM: ProgressViewModel?
    var useMetric: Bool
    @Binding var isPresented: Bool
    @State private var value: Int = 70

    private var unitLabel: String { useMetric ? "kg" : "lb" }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                TextField("Weight", value: $value, format: .number)
                    .font(AppTypography.title3())
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(AppColors.lightSurface)
                    .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadiusSmall))
                Text(unitLabel)
                    .font(AppTypography.caption())
                    .foregroundStyle(AppColors.lightTextSecondary)
            }
            .padding(AppLayout.screenPadding)
            .navigationTitle("Weight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                        .foregroundStyle(AppColors.profileActiveBlue)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let kg = useMetric ? value : Int(round(Double(value) / lbPerKg))
                        if let progressVM = progressVM {
                            progressVM.updateOrCreateTodayEntry(weightKg: Double(kg))
                        } else {
                            profileVM.updateWeight(kg)
                        }
                        profileVM.loadProfile()
                        isPresented = false
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColors.profileActiveBlue)
                }
            }
            .onAppear { value = useMetric ? profileVM.weightKg : Int(round(Double(profileVM.weightKg) * lbPerKg)) }
        }
        .presentationDetents([.medium])
    }
}

struct EditAgeSheet: View {
    var profileVM: UserProfileViewModel
    @Binding var isPresented: Bool
    @State private var value: Int = 28

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                TextField("Age", value: $value, format: .number)
                    .font(AppTypography.title3())
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(AppColors.lightSurface)
                    .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadiusSmall))
            }
            .padding(AppLayout.screenPadding)
            .navigationTitle("Age")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                        .foregroundStyle(AppColors.profileActiveBlue)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        profileVM.updateAge(value)
                        isPresented = false
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColors.profileActiveBlue)
                }
            }
            .onAppear { value = profileVM.age }
        }
        .presentationDetents([.medium])
    }
}

struct EditCalorieGoalSheet: View {
    var profileVM: UserProfileViewModel
    @Binding var isPresented: Bool
    @State private var value: Int = 2000

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                TextField("Daily calorie goal", value: $value, format: .number)
                    .font(AppTypography.title3())
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(AppColors.lightSurface)
                    .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadiusSmall))
                Text("kcal")
                    .font(AppTypography.caption())
                    .foregroundStyle(AppColors.lightTextSecondary)
            }
            .padding(AppLayout.screenPadding)
            .navigationTitle("Daily Calorie Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                        .foregroundStyle(AppColors.profileActiveBlue)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        profileVM.updateDailyCalorieGoal(value)
                        isPresented = false
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColors.profileActiveBlue)
                }
            }
            .onAppear { value = profileVM.dailyCalorieGoal }
        }
        .presentationDetents([.medium])
    }
}

struct EditGoalSheet: View {
    var profileVM: UserProfileViewModel
    @Binding var isPresented: Bool
    @State private var selectedGoal: GoalOption?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Choose your main goal (same as onboarding)")
                        .font(AppTypography.caption())
                        .foregroundStyle(AppColors.lightTextSecondary)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(GoalOption.allCases) { option in
                            Button {
                                selectedGoal = option
                            } label: {
                                VStack(spacing: 8) {
                                    Image(systemName: option.icon)
                                        .font(.title2)
                                    Text(option.rawValue)
                                        .font(AppTypography.caption())
                                        .multilineTextAlignment(.center)
                                    Text(option.subtitle)
                                        .font(AppTypography.caption2())
                                        .foregroundStyle(AppColors.lightTextSecondary)
                                        .multilineTextAlignment(.center)
                                        .lineLimit(2)
                                }
                                .foregroundStyle(selectedGoal == option ? AppColors.profileActiveBlue : AppColors.lightText)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .padding(.horizontal, 8)
                                .background(AppColors.lightSurface)
                                .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadiusSmall))
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppLayout.cornerRadiusSmall)
                                        .stroke(selectedGoal == option ? AppColors.profileActiveBlue : Color.clear, lineWidth: 2)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(AppLayout.screenPadding)
            }
            .background(AppColors.lightSurface)
            .navigationTitle("Fitness Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                        .foregroundStyle(AppColors.profileActiveBlue)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let goal = selectedGoal {
                            profileVM.updateFitnessGoal(goal.rawValue)
                        }
                        isPresented = false
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColors.profileActiveBlue)
                    .disabled(selectedGoal == nil)
                }
            }
            .onAppear {
                selectedGoal = GoalOption(rawValue: profileVM.fitnessGoal) ?? .stayFit
            }
        }
        .presentationDetents([.medium, .large])
    }
}

struct ChangePasswordSheet: View {
    var email: String
    @Binding var isPresented: Bool
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var showCurrentPassword = false
    @State private var showNewPassword = false
    @State private var errorMessage: String?
    @State private var success = false

    private var canSave: Bool {
        !currentPassword.isEmpty && newPassword.count >= 6
    }

    /// Reset feedback state so each attempt and each sheet appearance shows only current result.
    private func resetFeedbackState() {
        errorMessage = nil
        success = false
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                if let err = errorMessage {
                    Text(err)
                        .font(AppTypography.caption())
                        .foregroundStyle(AppColors.negativeRed)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("Current password")
                        .font(AppTypography.caption())
                        .foregroundStyle(AppColors.lightTextSecondary)
                    HStack(spacing: 12) {
                        Group {
                            if showCurrentPassword {
                                TextField("Current password", text: $currentPassword)
                            } else {
                                SecureField("Current password", text: $currentPassword)
                            }
                        }
                        .textContentType(.password)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        Button {
                            showCurrentPassword.toggle()
                        } label: {
                            Image(systemName: showCurrentPassword ? "eye.slash" : "eye")
                                .font(.callout)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(AppColors.lightTextSecondary)
                        .accessibilityLabel(showCurrentPassword ? "Hide current password" : "Show current password")
                    }
                    .padding()
                    .background(AppColors.lightSurface)
                    .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadiusSmall))
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("New password (min 6 characters)")
                        .font(AppTypography.caption())
                        .foregroundStyle(AppColors.lightTextSecondary)
                    HStack(spacing: 12) {
                        Group {
                            if showNewPassword {
                                TextField("New password", text: $newPassword)
                            } else {
                                SecureField("New password", text: $newPassword)
                            }
                        }
                        .textContentType(.newPassword)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        Button {
                            showNewPassword.toggle()
                        } label: {
                            Image(systemName: showNewPassword ? "eye.slash" : "eye")
                                .font(.callout)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(AppColors.lightTextSecondary)
                        .accessibilityLabel(showNewPassword ? "Hide new password" : "Show new password")
                    }
                    .padding()
                    .background(AppColors.lightSurface)
                    .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadiusSmall))
                }
                Spacer()
            }
            .padding(AppLayout.screenPadding)
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                        .foregroundStyle(AppColors.profileActiveBlue)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { performChange() }
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColors.profileActiveBlue)
                    .disabled(!canSave)
                }
            }
            .alert("Password Updated", isPresented: $success) {
                Button("OK") {
                    resetFeedbackState()
                    isPresented = false
                }
            } message: {
                Text("Your password has been changed successfully.")
            }
            .onAppear { resetFeedbackState() }
        }
    }

    private func performChange() {
        resetFeedbackState()
        guard newPassword.count >= 6 else {
            errorMessage = "New password must be at least 6 characters."
            return
        }
        do {
            try KeychainService.updatePassword(for: email, currentPassword: currentPassword, newPassword: newPassword)
            success = true
        } catch let e as KeychainError {
            errorMessage = e.errorDescription ?? "Failed to update password."
        } catch {
            errorMessage = "Failed to update password."
        }
    }
}

#Preview {
    ProfileView(authViewModel: AuthViewModel())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
