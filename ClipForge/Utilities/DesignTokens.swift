//
//  DesignTokens.swift
//  ClipForge
//
//  Color palette and typography tokens from the Design System Brief.
//  Light mode with Ronin Art House brand identity.
//
//  STORY-012: Design tokens for HomeView and CTA button.
//

import SwiftUI

// MARK: - Colors

extension Color {

    // MARK: Brand

    /// Vermillion accent — CTA buttons, progress rings, active elements.
    /// Pantone 1788 C.
    static let cfAccent = Color(hex: 0xEF3340)

    /// Pressed/tap-down state of accent.
    static let cfAccentPressed = Color(hex: 0xCC2A36)

    // MARK: Backgrounds

    /// Warm off-white shell background. Light mode default.
    static let cfBackground = Color(hex: 0xF5F0EB)

    /// Dark base — used for dark surfaces (Trim Modal, video area).
    /// Pantone 412 C.
    static let cfDarkBase = Color(hex: 0x382F2D)

    // MARK: Text

    /// Primary text on light background.
    static let cfTextPrimary = Color(hex: 0x382F2D)

    /// Secondary text — platform list, error messages, inactive labels.
    /// Warm Grey 8C.
    static let cfTextSecondary = Color(hex: 0x968C83)

    /// Title text on gradient — reads as warm white.
    static let cfTextOnGradient = Color(hex: 0xF5F0EB)

    // MARK: Semantic

    static let cfError = Color(hex: 0xD95A52)

    // MARK: Hex Initializer

    /// Creates a Color from a hex integer (e.g., `0xEF3340`).
    init(hex: UInt, opacity: Double = 1.0) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: opacity
        )
    }
}

// MARK: - Typography

/// Font helpers wrapping the design system's dual-font approach.
/// JetBrains Mono for display/UI, Inter for body text.
///
/// Font files registered in Info.plist under UIAppFonts:
/// - JetBrainsMono-Regular.ttf, JetBrainsMono-Medium.ttf, JetBrainsMono-Bold.ttf
/// - Inter-Regular.ttf, Inter-Medium.ttf
///
/// Download from:
/// - JetBrains Mono: https://www.jetbrains.com/mono/ (SIL Open Font License)
/// - Inter: https://rsms.me/inter/ (SIL Open Font License)
///
/// Add .ttf files to the ClipForge target in Xcode (drag into Resources folder,
/// ensure "Copy items if needed" and target membership are checked).
enum CFFont {

    /// JetBrains Mono — display, UI labels, buttons, monospace identity.
    static func jetBrainsMono(size: CGFloat, weight: Font.Weight = .medium) -> Font {
        let name: String
        switch weight {
        case .bold:
            name = "JetBrainsMono-Bold"
        case .regular:
            name = "JetBrainsMono-Regular"
        default:
            name = "JetBrainsMono-Medium"
        }
        return .custom(name, size: size)
    }

    /// Inter — body text, error messages, readable prose.
    ///
    /// Inter is loaded as a variable font (Inter-VariableFont_opsz,wght.ttf).
    /// iOS registers it under the family name "Inter", and SwiftUI applies
    /// the weight through the `.weight()` modifier.
    static func inter(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom("Inter", size: size).weight(weight)
    }
}
