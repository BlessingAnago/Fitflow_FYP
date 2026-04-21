//
//  OnboardingHeader.swift
//  FitFlow
//
//  Shared header for onboarding steps: title + back button.
//

import SwiftUI

struct OnboardingHeader: View {
    let title: String
    var isLight: Bool = false
    let onBack: () -> Void

    var body: some View {
        HStack {
            Button { onBack() } label: {
                Image(systemName: "chevron.left")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(isLight ? AppColors.lightText : AppColors.darkText)
                    .frame(width: AppLayout.minTouchTarget, height: AppLayout.minTouchTarget)
            }
            Spacer()
            Text(title)
                .font(AppTypography.title3())
                .foregroundStyle(isLight ? AppColors.lightText : AppColors.darkText)
            Spacer()
            Color.clear.frame(width: AppLayout.minTouchTarget, height: AppLayout.minTouchTarget)
        }
        .padding(.bottom, 8)
    }
}
