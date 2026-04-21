//
//  DesignSystem.swift
//  FitFlow
//
//  Design system per design-spec-from-figma.md: dark theme (green accents),
//  light onboarding (blue/purple), typography, accessibility (Dynamic Type).
//

import SwiftUI

// MARK: - Colors

enum AppColors {
    // Dark theme (main app & onboarding) – #102216 background, #13EC5B green
    static let darkBackground = Color(red: 0x10/255, green: 0x22/255, blue: 0x16/255)
    static let darkSurface = Color(red: 0x18/255, green: 0x2E/255, blue: 0x20/255)
    static let primaryGreen = Color(red: 0x13/255, green: 0xEC/255, blue: 0x5B/255)
    static let primaryGreenGlow = Color(red: 0x13/255, green: 0xEC/255, blue: 0x5B/255).opacity(0.4)
    static let darkText = Color.white
    static let darkTextSecondary = Color.white.opacity(0.7)

    // Onboarding blue (steps 1–2)
    static let onboardingBlue = Color(red: 0.25, green: 0.47, blue: 0.95)
    static let onboardingAccent = Color(red: 0.25, green: 0.47, blue: 0.95)
    static let onboardingAccentSecondary = Color(red: 0.25, green: 0.47, blue: 0.85)

    // Profile (light)
    static let lightBackground = Color.white
    static let lightSurface = Color(red: 0.96, green: 0.96, blue: 0.97)
    static let lightText = Color(red: 0.15, green: 0.15, blue: 0.18)
    static let lightTextSecondary = Color(red: 0.4, green: 0.4, blue: 0.45)
    static let profileActiveBlue = Color(red: 0.25, green: 0.47, blue: 0.95)

    // Nutrition / Stats
    static let carbsBlue = Color(red: 0.3, green: 0.5, blue: 0.95)
    static let fatsAmber = Color(red: 0.95, green: 0.7, blue: 0.2)
    static let negativeRed = Color(red: 0.9, green: 0.35, blue: 0.35)

    // Shared
    static let secondaryButton = Color.white.opacity(0.15)
    static let cardSelected = primaryGreen.opacity(0.25)
}

// MARK: - Typography (Dynamic Type)

enum AppTypography {
    static func largeTitle() -> Font { .largeTitle.weight(.bold) }
    static func title() -> Font { .title2.weight(.semibold) }
    static func title3() -> Font { .title3.weight(.semibold) }
    static func headline() -> Font { .headline }
    static func body() -> Font { .body }
    static func callout() -> Font { .callout }
    static func caption() -> Font { .caption }
    static func caption2() -> Font { .caption2 }
}

// MARK: - Spacing & Layout

enum AppLayout {
    static let screenPadding: CGFloat = 24
    static let cardPadding: CGFloat = 16
    static let buttonHeight: CGFloat = 56
    static let minTouchTarget: CGFloat = 44 // Accessibility
    static let cornerRadius: CGFloat = 16
    static let cornerRadiusSmall: CGFloat = 12
}

// MARK: - View Modifiers

struct PrimaryButtonStyle: ButtonStyle {
    var color: Color = AppColors.primaryGreen
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTypography.headline())
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: max(AppLayout.buttonHeight, AppLayout.minTouchTarget))
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadiusSmall))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    var isLight: Bool = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTypography.headline())
            .foregroundStyle(isLight ? AppColors.lightText : AppColors.darkTextSecondary)
            .frame(maxWidth: .infinity)
            .frame(height: max(AppLayout.buttonHeight, AppLayout.minTouchTarget))
            .background(isLight ? Color.gray.opacity(0.15) : AppColors.secondaryButton)
            .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadiusSmall))
    }
}

struct SelectableCardStyle: ViewModifier {
    var isSelected: Bool
    var isLight: Bool
    func body(content: Content) -> some View {
        content
            .padding(AppLayout.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: AppLayout.cornerRadiusSmall)
                    .fill(isSelected ? (isLight ? AppColors.onboardingAccent.opacity(0.15) : AppColors.cardSelected) : (isLight ? Color.gray.opacity(0.08) : AppColors.darkSurface))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppLayout.cornerRadiusSmall)
                    .stroke(isSelected ? (isLight ? AppColors.onboardingAccent : AppColors.primaryGreen) : Color.clear, lineWidth: 2)
            )
    }
}

extension View {
    func selectableCard(isSelected: Bool, isLight: Bool = false) -> some View {
        modifier(SelectableCardStyle(isSelected: isSelected, isLight: isLight))
    }
}

// MARK: - Visible placeholder for dark theme TextFields

struct VisiblePlaceholderTextField: View {
    let placeholder: String
    @Binding var text: String
    var font: Font = AppTypography.body()
    var paddingH: CGFloat = AppLayout.cardPadding
    var paddingV: CGFloat = 14
    var cornerRadius: CGFloat = AppLayout.cornerRadiusSmall
    var backgroundColor: Color = AppColors.darkSurface

    var body: some View {
        ZStack(alignment: .leading) {
            if text.isEmpty {
                Text(placeholder)
                    .font(font)
                    .foregroundStyle(AppColors.darkText.opacity(0.5))
                    .padding(.horizontal, paddingH)
                    .padding(.vertical, paddingV)
            }
            TextField("", text: $text)
                .font(font)
                .foregroundStyle(AppColors.darkText)
                .tint(AppColors.primaryGreen)
                .padding(.horizontal, paddingH)
                .padding(.vertical, paddingV)
        }
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(AppColors.darkText.opacity(0.25), lineWidth: 1)
        )
    }
}

// MARK: - Visible stepper for dark surfaces (clearly visible + / -)

struct VisibleStepperView<Label: View>: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    let step: Int
    @ViewBuilder let label: () -> Label

    var body: some View {
        HStack(spacing: 0) {
            label()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(minWidth: 72)
                .fixedSize(horizontal: true, vertical: false)
            Spacer(minLength: 12)
            HStack(spacing: 0) {
                stepperButton(systemName: "minus") {
                    value = max(range.lowerBound, value - step)
                }
                Rectangle()
                    .fill(AppColors.darkText.opacity(0.3))
                    .frame(width: 1, height: 24)
                stepperButton(systemName: "plus") {
                    value = min(range.upperBound, value + step)
                }
            }
            .background(AppColors.primaryGreen.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(.horizontal, AppLayout.cardPadding)
        .padding(.vertical, 12)
        .background(AppColors.darkSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadiusSmall))
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cornerRadiusSmall)
                .stroke(AppColors.darkText.opacity(0.2), lineWidth: 1)
        )
    }

    private func stepperButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppColors.primaryGreen)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
