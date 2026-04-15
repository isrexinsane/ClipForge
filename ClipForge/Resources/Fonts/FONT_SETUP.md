# Font Setup — ClipForge

Add the following .ttf files to this folder, then drag them into the Xcode project navigator with **"Copy items if needed"** checked and **ClipForge target membership** enabled.

## Required Files

### JetBrains Mono (Display / UI)
Download: https://www.jetbrains.com/mono/
License: SIL Open Font License 1.1

- `JetBrainsMono-Regular.ttf`
- `JetBrainsMono-Medium.ttf`
- `JetBrainsMono-Bold.ttf`

### Inter (Body Text)
Download: https://rsms.me/inter/
License: SIL Open Font License 1.1

- `Inter-Regular.ttf`
- `Inter-Medium.ttf`

## Verification

After adding files to Xcode:
1. Build the project
2. Open Trim Modal — duration readout should be JetBrains Mono Bold
3. Open Home screen — "CREATE GIF" should be JetBrains Mono Medium
4. Error messages should be Inter Regular

If fonts don't render (system font fallback), check:
- Files are listed in Info.plist under `UIAppFonts` (already configured)
- Files have correct target membership (ClipForge checkbox in File Inspector)
- File names match exactly (case-sensitive)
