//
//  DesignTokens.swift
//  ClipForge
//
//  Color palette, typography, and layout tokens pulled directly
//  from the Figma source file via Figma MCP. All views reference
//  these constants — never hardcode values.
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

// MARK: - Design Tokens

/// Centralized design tokens for the ClipForge design system.
/// Values pulled from Figma source file via Figma MCP on 2026-04-16.
/// All views reference these constants — never hardcode colors, fonts,
/// spacing, or corner radii directly.
struct DesignTokens {

    // MARK: Colors

    /// Warm off-white background — #F5F0EB
    static let background = Color(red: 245/255, green: 240/255, blue: 235/255)

    /// Vermillion primary accent — #EF3340
    static let vermillion = Color(red: 239/255, green: 51/255, blue: 64/255)

    /// Primary text — #1A1A1A
    static let textPrimary = Color(red: 26/255, green: 26/255, blue: 26/255)

    /// Secondary text — #6B6B6B
    static let textSecondary = Color(red: 107/255, green: 107/255, blue: 107/255)

    /// Card/modal surface — #FFFFFF
    static let surface = Color.white

    /// Near-black for video player areas — #1C1C1E
    static let darkSurface = Color(red: 28/255, green: 28/255, blue: 30/255)

    /// Error state — #D95A52
    static let error = Color(hex: 0xD95A52)

    /// Accent pressed/tap-down — #CC2A36
    static let accentPressed = Color(hex: 0xCC2A36)

    /// Text on vermillion gradient — warm white #F5F0EB
    static let textOnGradient = Color(red: 245/255, green: 240/255, blue: 235/255)

    /// Brand brown — primary text on warm backgrounds — #382F2D
    static let brandBrown = Color(hex: 0x382F2D)

    /// Warm muted grey — platform list, counters, inactive labels — #968C83
    static let mutedWarm = Color(hex: 0x968C83)

    /// Pure black — CTA label text
    static let textBlack = Color.black

    // MARK: Liquid Glass — Shared

    /// Glass card/button fill — white at 10% opacity
    static let glassBackground = Color.white.opacity(0.1)

    /// Glass border — white at 39% opacity
    static let glassBorder = Color.white.opacity(0.39)

    /// Glass highlight (inner shadow / top edge) — white at 15% opacity
    static let glassHighlight = Color.white.opacity(0.15)

    /// Glass backdrop blur radius
    static let glassBlur: CGFloat = 16

    /// Glass corner radius (cards)
    static let glassCornerRadius: CGFloat = 12

    // MARK: Liquid Glass — Buttons (Trim Modal)

    /// Light glass button base fill
    static let glassButtonBase = Color.white.opacity(0.65)

    /// Color-burn overlay for glass buttons — #DDDDDD
    static let glassButtonBurn = Color(hex: 0xDDDDDD)

    /// Darken overlay for glass buttons — #F7F7F7
    static let glassButtonDarken = Color(hex: 0xF7F7F7)

    /// Glass button text — #1A1A1A
    static let glassButtonText = Color(hex: 0x1A1A1A)

    // MARK: Trim Bar

    /// Trim bar background — #3A3A3C
    static let trimBarColor = Color(red: 58/255, green: 58/255, blue: 60/255)

    /// Filmstrip border — #ADADAD
    static let filmstripBorderColor = Color(red: 173/255, green: 173/255, blue: 173/255)

    /// Trim bar height (Figma)
    static let trimBarHeight: CGFloat = 50

    /// Trim bar corner radius
    static let trimBarCornerRadius: CGFloat = 10

    // MARK: Typography
    //
    // PostScript names verified via fontTools against ClipForge/Resources/*.ttf:
    //   JetBrainsMono-Bold  → JetBrainsMono-Bold.ttf
    //   JetBrainsMono-Medium → JetBrainsMono-Medium.ttf
    //   JetBrainsMono-Regular → JetBrainsMono-Regular.ttf
    //   Inter (variable font family) → Inter-VariableFont_opsz,wght.ttf
    //
    // Only these 4 files are registered in Info.plist UIAppFonts.

    /// JetBrains Mono Bold — headings, large display text, duration readout.
    static func headingFont(size: CGFloat) -> Font {
        .custom("JetBrainsMono-Bold", size: size)
    }

    /// JetBrains Mono Medium — button labels, UI elements, nav titles.
    static func labelFont(size: CGFloat) -> Font {
        .custom("JetBrainsMono-Medium", size: size)
    }

    /// Inter Regular — body text, descriptions, error messages.
    static func bodyFont(size: CGFloat) -> Font {
        .custom("Inter", size: size)
    }

    /// Inter Medium — emphasized body text, secondary buttons.
    static func bodyFontMedium(size: CGFloat) -> Font {
        .custom("Inter", size: size).weight(.medium)
    }

    /// Inter Bold — platform list per Figma spec.
    static func bodyFontBold(size: CGFloat) -> Font {
        .custom("Inter", size: size).weight(.bold)
    }

    // MARK: Figma Type Sizes

    /// "CLIPFORGE" / "GALLERY" title — 24px JetBrains Mono Bold
    static let titleSize: CGFloat = 24

    /// "CREATE GIF" label — 20px JetBrains Mono Bold
    static let ctaLabelSize: CGFloat = 20

    /// Platform list — 14px Inter Bold
    static let platformListSize: CGFloat = 14

    /// Duration readout — 32px JetBrains Mono Bold
    static let durationSize: CGFloat = 32

    // MARK: Spacing

    static let paddingXSmall: CGFloat = 8
    static let paddingSmall: CGFloat = 12
    static let paddingStandard: CGFloat = 16
    static let paddingLarge: CGFloat = 24
    static let paddingXLarge: CGFloat = 32

    // MARK: Gradient

    /// Vermillion gradient fades to transparent at this point (52.25% down).
    static let gradientStop: CGFloat = 0.5225

    // MARK: CTA Button

    /// CTA glass bubble diameter — 159pt per Figma.
    static let ctaSize: CGFloat = 159

    /// The glow/shadow extends ~25% beyond the circle bounds.
    static let ctaGlowExtension: CGFloat = 0.25

    /// CTA progress ring stroke width.
    static let ctaStrokeWidth: CGFloat = 4

    /// Menu button circle diameter — 39.5pt per Figma.
    static let menuButtonSize: CGFloat = 39.5

    // MARK: Page Dots

    /// Active page dot diameter — 16pt per Figma.
    static let pageDotActive: CGFloat = 16

    /// Inactive page dot diameter — 10pt per Figma.
    static let pageDotInactive: CGFloat = 10

    // MARK: Corner Radii

    static let cornerRadiusCard: CGFloat = 16
    static let cornerRadiusButton: CGFloat = 24
    static let cornerRadiusThumbnail: CGFloat = 12
}
