import SwiftUI

// ── Theodore Design Tokens ────────────────────────────────────────
// Matches the Figma file exactly. Use these everywhere — never hardcode colours.

extension Color {
    // Backgrounds
    static let theoBG      = Color(red: 0.047, green: 0.031, blue: 0.024)  // #0C0806
    static let theoSurface = Color(red: 0.098, green: 0.071, blue: 0.051)  // #191209
    static let theoS2      = Color(red: 0.161, green: 0.122, blue: 0.086)  // #292016
    static let theoS3      = Color(red: 0.220, green: 0.173, blue: 0.122)  // #382C1F

    // Light mode backgrounds
    static let theoCream   = Color(red: 0.980, green: 0.961, blue: 0.933)  // #FAF5EE
    static let theoLSurf   = Color(red: 0.945, green: 0.902, blue: 0.843)  // #F1E6D7
    static let theoLS2     = Color(red: 0.898, green: 0.839, blue: 0.769)  // #E5D6C4

    // Accents — same in both modes
    static let theoRed     = Color(red: 0.769, green: 0.255, blue: 0.165)  // #C4412A
    static let theoRed2    = Color(red: 0.831, green: 0.353, blue: 0.220)  // #D45A38
    static let theoAmber   = Color(red: 0.737, green: 0.459, blue: 0.220)  // #BC7538

    // Text
    static let theoInk     = Color(red: 0.102, green: 0.059, blue: 0.024)  // #1A0F06
    static let theoInk2    = Color(red: 0.310, green: 0.224, blue: 0.145)  // #4F3925
    static let theoMuted   = Color(red: 0.541, green: 0.447, blue: 0.353)  // #8A725A
    static let theoMuted2  = Color(red: 0.769, green: 0.667, blue: 0.549)  // #C4AA8C

    // Dynamic — switches with color scheme
    static func theoPaper(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .theoBG : .theoCream
    }
    static func theoCard(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .theoSurface : .theoLSurf
    }
    static func theoText(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.961, green: 0.929, blue: 0.878) : .theoInk
    }
}

extension Font {
    static let theoTitle    = Font.system(size: 34, weight: .semibold, design: .serif)
    static let theoHeading  = Font.system(size: 22, weight: .semibold, design: .serif)
    static let theoBody     = Font.system(size: 16, weight: .regular, design: .serif)
    static let theoPoem     = Font.system(size: 16, weight: .regular, design: .serif).italic()
    static let theoProse    = Font.system(size: 15, weight: .regular, design: .serif)
    static let theoCaption  = Font.system(size: 11, weight: .regular, design: .serif)
    static let theoLabel    = Font.system(size: 11, weight: .semibold, design: .default)
}
