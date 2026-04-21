//
//  SecureProgressView.swift
//  FitFlow
//
//  Secure Your Progress – dark theme, Face ID icon, Enable Biometrics, Maybe Later, PRIVATE & SECURE.
//

import SwiftUI
import LocalAuthentication

struct SecureProgressView: View {
    var viewModel: OnboardingViewModel
    var authViewModel: AuthViewModel

    private var biometricName: String {
        switch authViewModel.biometricType {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        default: return "Biometrics"
        }
    }

    private var biometricIcon: String {
        switch authViewModel.biometricType {
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        default: return "lock.fill"
        }
    }

    var body: some View {
        ZStack {
            AppColors.darkBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer()
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(AppColors.onboardingBlue.opacity(0.2))
                        .frame(width: 88, height: 88)
                    Image(systemName: biometricIcon)
                        .font(.system(size: 44))
                        .foregroundStyle(AppColors.onboardingBlue)
                }
                Text("Secure Your\nProgress")
                    .font(AppTypography.largeTitle())
                    .foregroundStyle(AppColors.darkText)
                    .multilineTextAlignment(.center)
                    .padding(.top, 28)
                Text("Keep your fitness stats and habits\nprivate. Enable \(biometricName) for faster,\nsecure access to your FitFlow\naccount")
                    .font(AppTypography.body())
                    .foregroundStyle(AppColors.darkTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.top, 12)
                Spacer()
                VStack(spacing: 16) {
                    Button("Enable \(biometricName)") {
                        viewModel.biometricsEnabled = true
                        viewModel.nextStep()
                    }
                    .buttonStyle(PrimaryButtonStyle(color: AppColors.onboardingBlue))
                    Button("Maybe Later") {
                        viewModel.biometricsEnabled = false
                        viewModel.skipSecureProgress()
                    }
                        .font(AppTypography.headline())
                        .foregroundStyle(AppColors.darkText)
                }
                .padding(.horizontal, AppLayout.screenPadding)
                .padding(.bottom, 24)
                HStack(spacing: 6) {
                    Image(systemName: "lock.fill")
                        .font(.caption2)
                    Text("PRIVATE & SECURE")
                        .font(AppTypography.caption2())
                }
                .foregroundStyle(AppColors.darkTextSecondary)
                .padding(.bottom, 40)
            }
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }
}
