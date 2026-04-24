import SwiftUI

struct NewChapterRecView: View {
    let onStart: () -> Void
    let onDismiss: () -> Void
    var assetIDs: [String] = []         // real photo asset IDs from the latest cluster
    var photoCount: Int = 0             // total photo count for the "+N" badge

    private let reasons: [(icon: String, label: String, sub: String)] = [
        ("📸", "New photos available", "since your last chapter"),
        ("📅", "A few weeks have passed", "a natural chapter break"),
        ("✦",  "A recurring moment", "Theodore noticed a pattern"),
    ]

    @State private var revealed = 0

    var body: some View {
        ZStack {
            parchBackground
            VStack(spacing: 0) {
                navBar
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        theodoreQuote
                        photoPlaceholderStrip
                        whyNowSection
                        suggestedChapterCard
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 16)
                }
                ctaBar
            }
        }
        .onAppear { animateReasons() }
    }

    // ── Nav bar ───────────────────────────────────────────────────

    private var navBar: some View {
        TheodoreBar(
            left: AnyView(
                Button(action: onDismiss) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Library")
                            .font(.system(size: 13))
                    }
                    .foregroundStyle(Color.theoMuted)
                }
            ),
            center: AnyView(TLogo(size: 26)),
            right: AnyView(
                Button("Not now", action: onDismiss)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.theoMuted)
            )
        )
    }

    // ── Theodore quote ────────────────────────────────────────────

    private var theodoreQuote: some View {
        HStack(alignment: .top, spacing: 12) {
            TLogo(size: 36)
            VStack(alignment: .leading, spacing: 6) {
                Text("Theodore · just now")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.theoBrown)

                HStack(alignment: .top, spacing: 8) {
                    RoundedRectangle(cornerRadius: 99)
                        .fill(Color.theoGold)
                        .frame(width: 2)
                    VStack(alignment: .leading, spacing: 0) {
                        Text("I've been looking at your recent photos.\nThere's a new chapter in here.\nShall I write it?")
                            .font(.system(size: 15, weight: .regular, design: .serif))
                            .italic()
                            .foregroundStyle(Color.theoNavy)
                            .lineSpacing(6)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .glassCard(cornerRadius: 16)
                .overlay(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.clear)
                        .cornerRadius(16, corners: .topLeft)
                }
            }
        }
        .padding(.bottom, 22)
    }

    // ── Photo strip ───────────────────────────────────────────────

    private var photoPlaceholderStrip: some View {
        let shown = Array(assetIDs.prefix(3))
        let overflow = max(0, photoCount - 3)
        let fallbackColors: [Color] = [
            Color(red: 0.867, green: 0.831, blue: 0.776),
            Color(red: 0.784, green: 0.812, blue: 0.847),
            Color(red: 0.804, green: 0.847, blue: 0.784),
        ]

        return HStack(spacing: 8) {
            if shown.isEmpty {
                ForEach(0..<3) { i in
                    RoundedRectangle(cornerRadius: 14)
                        .fill(LinearGradient(
                            colors: [fallbackColors[i], fallbackColors[i].opacity(0.5)],
                            startPoint: .topLeading, endPoint: .bottomTrailing))
                        .aspectRatio(1, contentMode: .fit)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.6), lineWidth: 1.5))
                }
            } else {
                ForEach(shown, id: \.self) { id in
                    AsyncPhotoView(assetID: id, contentMode: .fill)
                        .aspectRatio(1, contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.6), lineWidth: 1.5))
                }
                if overflow > 0 {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.theoNavy.opacity(0.08))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.theoNavy.opacity(0.10), lineWidth: 1.5))
                        Text("+\(overflow)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.theoMuted)
                    }
                    .aspectRatio(1, contentMode: .fit)
                    .frame(width: 60)
                }
            }
        }
        .padding(.bottom, 22)
    }

    // ── Why now section ───────────────────────────────────────────

    private var whyNowSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("WHY NOW")
                .font(.theoLabel)
                .foregroundStyle(Color.theoBrown)

            VStack(spacing: 0) {
                ForEach(Array(reasons.enumerated()), id: \.offset) { i, reason in
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.theoGold.opacity(0.10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.theoGold.opacity(0.18), lineWidth: 1)
                                )
                            Text(reason.icon)
                                .font(.system(size: 15))
                        }
                        .frame(width: 36, height: 36)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(reason.label)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Color.theoNavy)
                            Text(reason.sub)
                                .font(.system(size: 11))
                                .foregroundStyle(Color.theoMuted)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 10)
                    .opacity(i < revealed ? 1 : 0)
                    .offset(y: i < revealed ? 0 : 6)
                    .animation(.easeOut(duration: 0.4).delay(Double(i) * 0.05), value: revealed)

                    if i < reasons.count - 1 {
                        Divider().overlay(Color.theoNavy.opacity(0.06))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
            .glassCard(cornerRadius: 18)
        }
        .padding(.bottom, 20)
    }

    // ── Suggested chapter card ────────────────────────────────────

    private var suggestedChapterCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SUGGESTED CHAPTER")
                .font(.theoLabel)
                .foregroundStyle(Color.theoBrown)

            HStack(alignment: .top, spacing: 10) {
                RoundedRectangle(cornerRadius: 99)
                    .fill(Color.theoGold)
                    .frame(width: 2)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Something in April")
                        .font(.system(size: 18, weight: .bold, design: .serif))
                        .foregroundStyle(Color.theoNavy)

                    Text("a few weeks apart — Theodore thinks there's a thread running through them")
                        .font(.system(size: 13, weight: .regular, design: .serif))
                        .italic()
                        .foregroundStyle(Color.theoSlate)
                        .lineSpacing(3)

                    HStack(spacing: 16) {
                        Text(photoCount > 0 ? "\(photoCount) photos" : "your photos")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.theoMuted)
                        Text("~3 weeks")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.theoMuted)
                    }
                    .padding(.top, 4)
                }
            }
            .padding(16)
            .background(Color.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.80), lineWidth: 1))
            .shadow(color: Color.theoNavy.opacity(0.06), radius: 20, x: 0, y: 2)
        }
    }

    // ── CTA bar ───────────────────────────────────────────────────

    private var ctaBar: some View {
        VStack(spacing: 0) {
            Divider().overlay(Color.theoNavy.opacity(0.08))
            VStack(spacing: 10) {
                PrimaryButton(title: "Start writing with Theodore", action: onStart)
                Button("Remind me later", action: onDismiss)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.theoMuted)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.theoParch.opacity(0.90).background(.ultraThinMaterial))
        }
    }

    // ── Helpers ───────────────────────────────────────────────────

    private var parchBackground: some View {
        LinearGradient(
            colors: [Color(red: 0.961, green: 0.941, blue: 0.910),
                     Color(red: 0.929, green: 0.910, blue: 0.871),
                     Color(red: 0.902, green: 0.867, blue: 0.816)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private func animateReasons() {
        for i in 0..<reasons.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.6) {
                withAnimation { revealed = i + 1 }
            }
        }
    }
}

// ── Corner radius helper ──────────────────────────────────────────

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

private struct RoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners,
                                cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
