//
//  OnboardingProgressBar.swift
//  FitFlow
//
//  Horizontal progress bar for onboarding steps (blue steps 1–2, green 3–4).
//

import SwiftUI

struct OnboardingProgressBar: View {
    let step: Int
    let total: Int
    var useGreen: Bool = false

    private var progress: CGFloat {
        guard total > 0 else { return 0 }
        return CGFloat(step + 1) / CGFloat(total)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(AppColors.darkSurface)
                    .frame(height: 4)
                RoundedRectangle(cornerRadius: 2)
                    .fill(useGreen ? AppColors.primaryGreen : AppColors.onboardingBlue)
                    .frame(width: geo.size.width * progress, height: 4)
            }
        }
        .frame(height: 4)
    }
}
