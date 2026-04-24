import SwiftUI

// ── Theodore Design Tokens v2 ─────────────────────────────────────
// Parchment / Navy / Gold palette — matches the v2 Figma spec.
// Use these everywhere — never hardcode colours.

extension Color {

    // ── Core palette ──────────────────────────────────────────
    static let theoNavy   = Color(red: 0.106, green: 0.165, blue: 0.290)  // #1B2A4A
    static let theoBrown  = Color(red: 0.482, green: 0.369, blue: 0.227)  // #7B5E3A
    static let theoParch  = Color(red: 0.961, green: 0.941, blue: 0.910)  // #F5F0E8
    static let theoSlate  = Color(red: 0.290, green: 0.333, blue: 0.408)  // #4A5568
    static let theoGold   = Color(red: 0.788, green: 0.659, blue: 0.298)  // #C9A84C
    static let theoMuted  = Color(red: 0.549, green: 0.502, blue: 0.439)  // #8C8070

    // ── Alias — keeps old call-sites compiling ────────────────
    static let theoRed    = Color.theoNavy   // CTAs: was red, now navy
    static let theoRed2   = Color.theoNavy
    static let theoAmber  = Color.theoGold   // accents: was amber, now gold
    static let theoCream  = Color.theoParch  // button text on navy
    static let theoInk    = Color.theoNavy
    static let theoInk2   = Color.theoBrown
    static let theoMuted2 = Color.theoBrown

    // Light surfaces (kept for files not yet redesigned)
    static let theoCreamCard = Color(red: 0.945, green: 0.922, blue: 0.890)  // #F1EADE
    static let theoLS2    = Color(red: 0.898, green: 0.871, blue: 0.831)   // #E5DECC

    // Dark surfaces (kept for backward compat)
    static let theoBG      = Color(red: 0.047, green: 0.031, blue: 0.024)
    static let theoSurface = Color(red: 0.106, green: 0.165, blue: 0.290).opacity(0.06)
    static let theoS2      = Color.theoNavy.opacity(0.08)
    static let theoS3      = Color.theoNavy.opacity(0.12)
    static let theoLSurf   = Color(red: 0.945, green: 0.922, blue: 0.890)

    // ── Dynamic — always parchment now ────────────────────────
    static func theoPaper(_ scheme: ColorScheme) -> Color { .theoParch }
    static func theoCard(_ scheme: ColorScheme)  -> Color { Color.white.opacity(0.62) }
    static func theoText(_ scheme: ColorScheme)  -> Color { .theoNavy }
}

extension Font {
    static let theoTitle    = Font.system(size: 34, weight: .semibold, design: .serif)
    static let theoHeading  = Font.system(size: 22, weight: .semibold, design: .serif)
    static let theoBody     = Font.system(size: 16, weight: .regular,  design: .serif)
    static let theoPoem     = Font.system(size: 16, weight: .regular,  design: .serif).italic()
    static let theoProse    = Font.system(size: 15, weight: .regular,  design: .serif)
    static let theoCaption  = Font.system(size: 11, weight: .regular,  design: .serif)
    static let theoLabel    = Font.system(size: 10, weight: .semibold, design: .default)
}

// ── Parchment background gradient ────────────────────────────────

extension View {
    func parchBackground() -> some View {
        background(
            LinearGradient(
                colors: [
                    Color(red: 0.961, green: 0.941, blue: 0.910),
                    Color(red: 0.929, green: 0.910, blue: 0.871),
                    Color(red: 0.902, green: 0.867, blue: 0.816),
                ],
                startPoint: .init(x: 0.1, y: 0),
                endPoint: .init(x: 0.9, y: 1)
            )
            .ignoresSafeArea()
        )
    }

    // Glass card: white 62% + white border + subtle shadow
    func glassCard(cornerRadius: CGFloat = 20) -> some View {
        background(Color.white.opacity(0.62), in: RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(RoundedRectangle(cornerRadius: cornerRadius).stroke(Color.white.opacity(0.80), lineWidth: 1))
            .shadow(color: Color.theoNavy.opacity(0.06), radius: 20, x: 0, y: 2)
    }
}

// ── Reusable primitives ───────────────────────────────────────────

struct TLogo: View {
    var size: CGFloat = 44
    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.24)
            .fill(Color.theoNavy)
            .frame(width: size, height: size)
            .overlay {
                Text("T")
                    .font(.system(size: size * 0.52, weight: .bold, design: .serif))
                    .foregroundStyle(Color.theoParch)
            }
    }
}

struct GoldLine: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 99)
            .fill(Color.theoGold)
            .frame(width: 32, height: 1.5)
    }
}

struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    var disabled: Bool = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(disabled ? Color.theoParch.opacity(0.6) : Color.theoParch)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    disabled ? Color.theoNavy.opacity(0.30) : Color.theoNavy,
                    in: Capsule()
                )
                .shadow(color: disabled ? .clear : Color.theoNavy.opacity(0.22), radius: 20, x: 0, y: 4)
        }
        .disabled(disabled)
    }
}

// Top nav bar: left | center | right
struct TheodoreBar: View {
    var left:   AnyView? = nil
    var center: AnyView? = nil
    var right:  AnyView? = nil

    var body: some View {
        HStack {
            Group { if let l = left { l } else { Color.clear } }
                .frame(width: 72, alignment: .leading)
            Spacer()
            if let c = center { c }
            Spacer()
            Group { if let r = right { r } else { Color.clear } }
                .frame(width: 72, alignment: .trailing)
        }
        .frame(height: 52)
        .padding(.horizontal, 20)
        .background(Color.theoParch.opacity(0.7).background(.ultraThinMaterial))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.theoNavy.opacity(0.06))
                .frame(height: 1)
        }
    }
}
