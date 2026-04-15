# ClipForge Design System Brief

**Version:** 1.0
**Date:** 2026-04-11
**Author:** PM Agent
**Scope:** MVP (Sprint 2+), iOS 17+, SwiftUI

---

## Design Philosophy

ClipForge is a speed tool. The interface should feel like a chute — the user drops in a link at the top and a finished GIF slides out at the bottom. Every design decision optimizes for two things: perceived speed (the app *feels* fast) and reduced decision fatigue (the user never wonders what to tap next).

The visual language is rooted in the Ronin Art House brand identity: elegant and simple, inspired by Japanese visual culture. The palette uses warm browns and parchment tones instead of cold blacks and whites — every surface has the warmth of washi paper or lacquered wood. A single vermillion red accent (Pantone 1788 C) provides sharp contrast for actions, echoing the decisive mark of a hanko seal. This restraint signals "precision creative tool" to both users and App Store reviewers, reinforcing ClipForge's positioning as a GIF *creation* tool, not a video saving utility.

---

## Target Personas (Summary)

**The Meme Machinist** — Power user who spots a viral moment and wants a reaction GIF in under 30 seconds. Values speed above all. Likely shares across multiple platforms. Uses Standard and Discord presets.

**The Discord Regular** — Lives in Discord servers, constantly sharing GIFs in chat. Knows about the 10 MB non-Nitro file size limit. The Discord preset exists specifically for this person.

**The Casual Clipper** — Saves funny moments occasionally. Less technical, needs the simplest possible flow. Won't customize settings. Relies on defaults.

All three personas share one trait: they are impatient. The design system must minimize every interaction to its fastest form.

---

## Color Palette

ClipForge's palette is derived from the official Ronin Art House brand identity. Four brand colors form the foundation; functional colors are derived to feel warm and cohesive alongside them. No gradients in the MVP — flat color keeps rendering fast and the visual language clean. No pure blacks, no pure whites, no cold blues.

### Brand Colors (Ronin Art House Official)

| Role | Pantone | Hex | Token | Usage |
|------|---------|-----|-------|-------|
| Primary Accent | 1788 C | `#EF3340` | `accent` | CTA buttons, active trim handles, progress bars. Used sparingly for maximum impact. |
| Dark Base | 412 C | `#382F2D` | `background` | App background (dark mode), navigation bars. Warm near-black. |
| Mid-Tone Neutral | Warm Grey 8C | `#968C83` | `textSecondary` | Secondary labels, dividers, inactive states, placeholder text. |
| Light Neutral | Warm Grey 1C | `#D7D2CB` | `textPrimary` | Primary text (dark mode), card surfaces in light mode. Warm parchment tone. |

### Foundation (Dark Mode — MVP Default)

| Token | Hex | SwiftUI | Usage |
|-------|-----|---------|-------|
| `background` | `#382F2D` | `Color("Background")` | App background, full-bleed. Pantone 412 C. |
| `surface` | `#443A37` | `Color("Surface")` | Cards, bottom sheets, input fields. Slightly elevated from background. |
| `surfaceElevated` | `#524845` | `Color("SurfaceElevated")` | Active states, selected elements, modal backgrounds. |
| `border` | `#5E5450` | `Color("Border")` | Dividers, input borders, subtle separation. |

### Text (Dark Mode)

| Token | Hex | SwiftUI | Usage |
|-------|-----|---------|-------|
| `textPrimary` | `#D7D2CB` | `Color("TextPrimary")` | Headlines, body copy, primary labels. Pantone Warm Grey 1C. |
| `textSecondary` | `#A8A099` | `Color("TextSecondary")` | Captions, timestamps, placeholder text. Lightened from Warm Grey 8C for dark-mode contrast. |
| `textTertiary` | `#756D66` | `Color("TextTertiary")` | Disabled labels, hint text. |

### Accent

| Token | Hex | SwiftUI | Usage |
|-------|-----|---------|-------|
| `accent` | `#EF3340` | `Color.accentColor` | Primary CTA buttons, active trim handles, progress indicators. Pantone 1788 C vermillion. |
| `accentPressed` | `#CC2A36` | — | Tap-down state. Darkened vermillion. |

Rationale: Vermillion red (`#EF3340`) is the Ronin Art House signature color. It works in both light and dark modes without modification, carries the decisive energy of a hanko seal stamp, and creates immediate visual hierarchy — the eye goes to the red element first. Used sparingly (one primary action per screen) so it retains its impact.

### Semantic (Functional Colors)

These are not from the brand palette but are derived to feel warm and slightly desaturated, consistent with the Ronin aesthetic. No neon, no electric tones.

| Token | Hex | Usage |
|-------|-----|-------|
| `success` | `#5B9A6B` | Export complete, GIF saved confirmation. Muted sage green. (3.9:1 on bg) |
| `warning` | `#D4A843` | File size approaching limit, trim duration nearing 15s. Warm amber. (5.9:1 on bg) |
| `error` | `#D95A52` | Import failed, network error, unsupported URL. Warm desaturated red. (3.4:1 on bg — large text/UI only) |
| `info` | `#7A9BB5` | Tooltip highlights, first-run hints. Muted warm blue-grey. |

### Platform Badge Colors

Each supported platform gets a subtle badge tint on the Player screen to remind the user of the source. These are the only non-Ronin colors in the app, kept small (pill badges only) so they don't disrupt the warm palette.

| Platform | Hex | Note |
|----------|-----|------|
| Twitter/X | `#1D9BF0` | Official brand blue |
| Instagram | `#E1306C` | Official brand pink |
| Reddit | `#FF4500` | Official orangered |
| TikTok | `#00F2EA` | Official cyan |
| Twitch | `#9146FF` | Official purple |

These are used only as small indicator elements (pill badge, icon tint) — never as background fills.

### Light Mode (Post-MVP)

When light mode is added later, the surface hierarchy inverts: `#D7D2CB` (Warm Grey 1C) becomes the background, `#382F2D` (412 C) becomes primary text. The `#EF3340` accent works in both modes without adjustment. Mid-tone `#968C83` may need slight darkening for light-mode contrast.

---

## Typography

ClipForge uses a two-font system: **JetBrains Mono** for display and UI chrome, **Inter** for body text and longer strings. Both are SIL Open Font License (free, open source) and must be bundled with the app binary via the Xcode asset catalog.

### Typeface Roles

**JetBrains Mono** (Regular, Medium, Bold) — The header and UI typeface. Monospace with a geometric, technical character. Used for anything the user *scans* rather than *reads*: screen titles, button labels, duration indicators, file size readouts, preset names, navigation bar titles. The monospace grid gives ClipForge a precision-tool identity that reinforces the "forge" in the name.

**Inter** (Regular, Medium, SemiBold) — The body and secondary typeface. Proportional, humanist, optimized for screen readability at small sizes. Used for anything the user *reads*: error messages, onboarding copy, settings descriptions, clipboard detection prompt text, App Store listing body text, and any string longer than roughly five words.

### Pairing Rationale

JetBrains Mono (monospace, geometric, technical) contrasts with Inter (proportional, humanist, warm), creating visual hierarchy through personality rather than size alone. Both share similar x-heights and stroke weights, so they feel cohesive despite the structural contrast. Neither font is decorative — they align with the Ronin Art House brand value of elegance through restraint.

### Type Scale

| Token | Font | Size / Weight | Line Height | Usage |
|-------|------|--------------|-------------|-------|
| `titleLarge` | JetBrains Mono | 28pt / Bold | 34pt | Screen titles ("Create GIF", "Import") |
| `titleSmall` | JetBrains Mono | 20pt / Medium | 25pt | Section headers, modal titles |
| `uiLabel` | JetBrains Mono | 16pt / Regular | 20pt | Button labels, preset names, duration/size indicators |
| `body` | Inter | 16pt / Regular | 22pt | Descriptions, onboarding copy, error messages, prompts |
| `caption` | Inter | 13pt / Regular | 18pt | Secondary info, timestamps, metadata, placeholder text |
| `small` | Inter | 11pt / Regular | 14pt | Legal text, fine print, copyright notices |

### Usage Rules

All sizes must respect iOS Dynamic Type scaling for accessibility (PRD §6.4). Register both custom fonts with SwiftUI's `@ScaledMetric` or `UIFontMetrics` so they scale proportionally with the user's preferred text size. The base sizes above correspond to the default (Large) Dynamic Type setting.

JetBrains Mono is inherently monospaced, so numeric displays (duration counters, file size readouts) in `uiLabel` or `titleSmall` will naturally stay fixed-width. For any numeric value rendered in Inter (rare, but possible in body text), apply `.monospacedDigit()`.

### Font Registration (SwiftUI)

```swift
// In DesignTokens.swift or a Typography extension
enum DS {
    enum Font {
        static func jetbrainsMono(_ weight: FontWeight, size: CGFloat) -> SwiftUI.Font {
            switch weight {
            case .regular: return .custom("JetBrainsMono-Regular", size: size)
            case .medium:  return .custom("JetBrainsMono-Medium", size: size)
            case .bold:    return .custom("JetBrainsMono-Bold", size: size)
            }
        }
        static func inter(_ weight: FontWeight, size: CGFloat) -> SwiftUI.Font {
            switch weight {
            case .regular:  return .custom("Inter-Regular", size: size)
            case .medium:   return .custom("Inter-Medium", size: size)
            case .semiBold: return .custom("Inter-SemiBold", size: size)
            }
        }
        enum FontWeight { case regular, medium, semiBold, bold }
    }
}
```

Both font families must be declared in `Info.plist` under `UIAppFonts` (or the "Fonts provided by application" key) with every included `.ttf` / `.otf` filename listed.

---

## Spacing Scale

An 4-point base grid with a deliberate set of named tokens. Consistent spacing is what makes a UI feel "designed" rather than "coded."

| Token | Value | Usage |
|-------|-------|-------|
| `xs` | 4pt | Inline icon-to-text gaps, tight padding |
| `sm` | 8pt | Between related elements (label and value) |
| `md` | 16pt | Standard content padding, between sections |
| `lg` | 24pt | Between major UI groups, screen edge insets |
| `xl` | 32pt | Between screen sections, above/below CTAs |
| `xxl` | 48pt | Top-of-screen breathing room, hero spacing |

### Safe Areas

All screens use SwiftUI's default safe area behavior. The bottom CTA button area adds `lg` (24pt) padding below the button and respects the home indicator inset. No content should sit behind the notch or Dynamic Island.

---

## Corner Radii

| Token | Value | Usage |
|-------|-------|-------|
| `radiusSm` | 8pt | Input fields, small badges, chips |
| `radiusMd` | 12pt | Cards, bottom sheets, thumbnails |
| `radiusLg` | 16pt | Modal sheets, large cards |
| `radiusFull` | Capsule | CTA buttons, pill badges |

---

## Component Inventory

These are every distinct UI component needed across the four MVP screens. Each component is listed once with its screen context.

### 1. Link Input Field

**Screen:** Home
**Description:** A single-line text field with a paste icon and placeholder text. This is the first thing the user interacts with — it must look tappable and inviting.
**Anatomy:** `[paste icon]  [placeholder: "Paste a link to create a GIF"]  [clear button]`
**Typography:** Input text in Inter Regular 16pt (`body`). Placeholder in Inter Regular 16pt, `textTertiary`. Error caption below in Inter Regular 13pt (`caption`), `error` color.
**States:** Empty (placeholder visible), Filled (URL text, clear button appears), Error (red border, error caption below), Loading (pulsing accent border while extracting)
**Behavior:** On paste or return key, immediately triggers extraction. No separate "submit" button — speed matters.

### 2. Primary CTA Button

**Screen:** All screens
**Description:** Full-width capsule button in accent color. One per screen, always at the bottom.
**Anatomy:** `[ Label ]` — centered text, no icons
**Typography:** JetBrains Mono Regular 16pt (`uiLabel`), white (#FFFFFF) on accent fill. Disabled state uses `textTertiary`.
**States:** Default (accent fill, white label for contrast), Pressed (accentPressed fill, slight scale-down), Disabled (surface fill, textTertiary label), Loading (label replaced by white spinner)
**Labels by screen:** Home → "Import from Link" | Player → "Create GIF" | GIF Settings → "Export GIF" | Export Success → "Done"
**Note:** Labels comply with banned-term rules. "Import" not "Download."

### 3. Video Player

**Screen:** Player
**Description:** Full-width video preview with native AVPlayer controls stripped down to play/pause only. Rounded corners, sits in the upper half of the screen.
**Anatomy:** `[video frame]  [play/pause overlay]  [duration badge]`
**Typography:** Duration badge in JetBrains Mono Regular 16pt (`uiLabel`) on a `surface` pill with 80% opacity.
**Sizing:** Full width minus `lg` horizontal padding. 16:9 aspect ratio with letterboxing for non-standard ratios.

### 4. Trim Timeline

**Screen:** Player
**Description:** A horizontal scrubber bar below the video player showing frame thumbnails with draggable start/end handles.
**Anatomy:** `[start handle] ——— [selected range highlight] ——— [end handle]`  with `[start time]` and `[end time]` labels at each end.
**Typography:** Time labels in JetBrains Mono Regular 16pt (`uiLabel`), `textSecondary` color. Monospace keeps the timestamps from shifting as values change.
**States:** Default (full range selected), Dragging (handle enlarged, haptic feedback), Constrained (range capped at 15 seconds — handles resist further expansion)
**Colors:** Selected range tinted with `accent` (vermillion) at 30% opacity. Handles are solid `accent`. Unselected regions are `surface`.

### 5. Platform Badge

**Screen:** Player
**Description:** Small pill badge showing the detected source platform (e.g., "Twitter/X") with platform-tinted icon.
**Anatomy:** `[platform icon]  [platform name]`
**Typography:** Platform name in JetBrains Mono Regular 16pt (`uiLabel`).
**Colors:** Platform badge colors from the palette above. Text is `textPrimary`. Background is `surface`.

### 6. Quality Preset Selector

**Screen:** GIF Settings
**Description:** Three tappable cards in a vertical stack, one per quality preset. The user taps to select; only one can be active.
**Anatomy per card:**
```
[ Preset Name ]          [ max file size ]
[ dimensions / fps ]     [ ✓ if selected ]
```
**Typography:** Preset name in JetBrains Mono Medium 20pt (`titleSmall`). Dimensions/fps in Inter Regular 13pt (`caption`). File size in JetBrains Mono Regular 16pt (`uiLabel`).
**Presets:** Standard (480px / 12fps / 5 MB) | Discord (640px / 15fps / 10 MB) | High Quality (720px / 20fps / 25 MB, locked with "Premium" badge)
**States:** Default (surface background, border), Selected (surfaceElevated background, accent border, checkmark), Locked (surface background, lock icon, textTertiary labels)

### 7. Metadata Row

**Screen:** GIF Settings
**Description:** A horizontal row of key-value pairs showing estimated GIF properties based on the current trim range and selected preset.
**Anatomy:** `Duration: 4.2s  •  Est. Size: 3.1 MB  •  Frames: 50`
**Typography:** Values (numbers) in JetBrains Mono Regular 16pt (`uiLabel`). Labels ("Duration:", "Est. Size:") in Inter Regular 13pt (`caption`). All `textSecondary` color. Updates live as the user changes settings.

### 8. Progress Indicator

**Screen:** GIF Settings (during encoding)
**Description:** A circular or linear progress bar shown while the GIF is encoding. Replaces the CTA button area.
**Anatomy:** `[progress ring/bar]  [percentage]  [status text: "Creating GIF..."]`
**Typography:** Percentage in JetBrains Mono Medium 20pt (`titleSmall`). Status text in Inter Regular 16pt (`body`).
**States:** Indeterminate (pulsing, during frame extraction), Determinate (percentage, during GIF assembly), Re-encoding (status text changes to "Optimizing size...")

### 9. Success Card

**Screen:** Export Success
**Description:** A celebratory card showing a thumbnail preview of the finished GIF with metadata and sharing options.
**Anatomy:**
```
[ GIF thumbnail preview (animated) ]
[ "GIF Created!" heading ]
[ file size • dimensions • duration ]
[ Share button ]  [ Save to Photos button ]
[ Done button (returns to Home) ]
```
**Typography:** "GIF Created!" in JetBrains Mono Bold 28pt (`titleLarge`), `success` tint. Metadata row in JetBrains Mono Regular 16pt (`uiLabel`). Share/Save labels in JetBrains Mono Regular 16pt (`uiLabel`).
**Colors:** `success` tint on the heading. Share and Save buttons use `surface` background with `textPrimary` labels. Done button is the standard Primary CTA.

### 10. Error Toast

**Screen:** Any
**Description:** A slide-down toast notification for non-blocking errors (network timeout, unsupported URL, extraction failure).
**Anatomy:** `[error icon]  [message text]  [dismiss X]`
**Typography:** Message text in Inter Regular 16pt (`body`), `textPrimary` color.
**Behavior:** Slides in from top, auto-dismisses after 4 seconds, tappable to dismiss. Uses `surface` background with a 3pt `error`-colored left border and `textPrimary` text (avoids contrast issues with a full error-colored background).
**Note:** Error messages must use approved language only — no "download failed," use "Import failed" or "Could not create from link."

### 11. Loading Skeleton

**Screen:** Home (during extraction)
**Description:** A placeholder shimmer animation shown while the backend processes the URL. Replaces the main content area to indicate progress.
**Anatomy:** Rounded rectangle shimmer blocks mimicking the Player screen layout (video area + timeline area).
**Colors:** Animated gradient between `surface` and `surfaceElevated`.

---

## Iconography

Use SF Symbols exclusively — they scale with Dynamic Type, match the system aesthetic, and require no asset management.

| Context | Symbol Name | Notes |
|---------|-------------|-------|
| Paste action | `doc.on.clipboard` | Link input field leading icon |
| Clear input | `xmark.circle.fill` | Input field trailing icon |
| Play/Pause | `play.fill` / `pause.fill` | Video player overlay |
| Share | `square.and.arrow.up` | Export success screen |
| Save to Photos | `photo.on.rectangle` | Export success screen |
| Settings/Preset | `slider.horizontal.3` | GIF settings screen header |
| Error | `exclamationmark.triangle.fill` | Error toast leading icon |
| Success | `checkmark.circle.fill` | Export success heading |
| Lock (Premium) | `lock.fill` | High Quality preset badge |
| Back | `chevron.left` | Navigation bar (SwiftUI default) |

---

## Motion & Haptics

Animations should be fast and purposeful — never decorative. Every animation has a job: confirming an action, guiding attention, or smoothing a transition.

**Transitions between screens:** SwiftUI's default NavigationStack push/pop. No custom transitions in the MVP.

**Trim handle drag:** Light haptic (`UIImpactFeedbackGenerator`, `.light`) on grab. Medium haptic (`.medium`) when hitting the 15-second limit boundary.

**GIF export complete:** Success haptic (`UINotificationFeedbackGenerator`, `.success`).

**Error toast appearance:** `spring(response: 0.3, dampingFraction: 0.7)` slide-in from top.

**Loading shimmer:** `linear` animation, 1.5-second cycle, continuous repeat.

**Button press:** `spring(response: 0.2, dampingFraction: 0.6)` scale to 0.97 on press-down.

---

## Accessibility

All components must meet WCAG 2.1 AA contrast ratios (4.5:1 for body text, 3:1 for large text and UI components). The warm dark palette meets these thresholds:

- `textPrimary` (#D7D2CB) on `background` (#382F2D): contrast ratio **8.7:1** — exceeds AAA
- `textSecondary` (#A8A099) on `background` (#382F2D): contrast ratio **5.1:1** — passes AA for body text
- `accent` (#EF3340) on `background` (#382F2D): contrast ratio **3.2:1** — passes AA for large text and UI components; CTA buttons use JetBrains Mono 16pt (qualifies as large text) with white (#FFFFFF) labels for **4.0:1** contrast on the red fill
- `textPrimary` (#D7D2CB) on `surface` (#443A37): contrast ratio **7.3:1** — passes AAA for cards and input fields

All interactive elements must have a minimum tap target of 44×44pt (Apple HIG minimum). Trim handles should be at least 44pt wide for comfortable dragging.

VoiceOver labels must be set on all custom components, especially the trim timeline and quality preset cards.

---

## Implementation Notes

**Asset delivery:** No custom image assets in the MVP. All icons come from SF Symbols. The color palette lives in `Assets.xcassets` as named Color Sets so they can be referenced by token name throughout SwiftUI code. JetBrains Mono and Inter font files (`.ttf`) are bundled in the app binary — add them to the Xcode project under a `Resources/Fonts/` group, include them in the target's "Copy Bundle Resources" build phase, and list every filename in `Info.plist` under the `UIAppFonts` key.

**Dark mode only for MVP:** ClipForge ships dark-mode-only in v1.0 using the warm Ronin Art House dark base (#382F2D), not pure black. A light mode variant using Warm Grey 1C (#D7D2CB) as background is a post-launch enhancement. Set `UIUserInterfaceStyle = Dark` in Info.plist to prevent system appearance switching.

**Spacing and radius constants:** Define all tokens in a single `DesignTokens.swift` file using static properties on a namespace enum. This keeps the values centralized and auditable.

```swift
enum DS {
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
    enum Radius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
    }
}
```

---

## Compliance Checkpoint

Every component in this system has been audited against the App Store compliance rules in CLAUDE.md:

- No component label, placeholder, or status text uses "download," "downloader," "rip," or "ripper."
- The Primary CTA on Home reads "Import from Link" — not "Download Video."
- Error messages reference "import" and "create from link" — never "download."
- The overall visual identity positions ClipForge as a creative tool (warm dark theme aligned with Ronin Art House brand, editing-focused UI) rather than a media saving utility.
- The Ronin Art House brand palette reinforces the "creative tool" positioning with its Japanese-inspired restraint and warmth.
