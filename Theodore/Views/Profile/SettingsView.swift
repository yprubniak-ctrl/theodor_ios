import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var notificationsEnabled = true
    @State private var fontSize: FontSizeOption = .medium

    enum FontSizeOption: String, CaseIterable {
        case small = "Small", medium = "Medium", large = "Large"
    }

    var body: some View {
        ZStack {
            parchBackground
            VStack(spacing: 0) {
                navBar
                ScrollView {
                    VStack(spacing: 20) {
                        readingSection
                        notificationsSection
                        memoirSection
                        privacySection
                        versionFooter
                    }
                    .padding(16)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true)
    }

    // ── Nav bar ───────────────────────────────────────────────────

    private var navBar: some View {
        TheodoreBar(
            left: AnyView(
                Button { dismiss() } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 11, weight: .semibold))
                        Text("You")
                            .font(.system(size: 13))
                    }
                    .foregroundStyle(Color.theoMuted)
                }
            ),
            center: AnyView(
                Text("Settings")
                    .font(.system(size: 16, weight: .bold, design: .serif))
                    .foregroundStyle(Color.theoNavy)
            )
        )
    }

    // ── Reading section ───────────────────────────────────────────

    private var readingSection: some View {
        SettingsSection(header: "READING") {
            VStack(spacing: 0) {
                HStack {
                    Text("Font size")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.theoNavy)
                    Spacer()
                    HStack(spacing: 2) {
                        ForEach(FontSizeOption.allCases, id: \.self) { opt in
                            Button { fontSize = opt } label: {
                                Text(opt.rawValue)
                                    .font(.system(size: 11, weight: .medium))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(fontSize == opt ? Color.theoNavy : Color.clear,
                                                in: RoundedRectangle(cornerRadius: 8))
                                    .foregroundStyle(fontSize == opt ? Color.theoParch : Color.theoMuted)
                                    .overlay(RoundedRectangle(cornerRadius: 8)
                                        .stroke(fontSize == opt ? Color.theoNavy : Color.theoNavy.opacity(0.15), lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(16)
                Divider().overlay(Color.theoNavy.opacity(0.06))
                SettingsRow(label: "Reading font", value: "Playfair")
            }
        }
    }

    // ── Notifications section ─────────────────────────────────────

    private var notificationsSection: some View {
        SettingsSection(header: "NOTIFICATIONS") {
            HStack {
                Text("Weekly writing prompts")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.theoNavy)
                Spacer()
                Toggle("", isOn: $notificationsEnabled)
                    .labelsHidden()
                    .tint(Color.theoNavy)
            }
            .padding(16)
        }
    }

    // ── Memoir section ────────────────────────────────────────────

    private var memoirSection: some View {
        SettingsSection(header: "MEMOIR") {
            VStack(spacing: 0) {
                SettingsRow(label: "Export as PDF", value: "→")
                Divider().overlay(Color.theoNavy.opacity(0.06))
                SettingsRow(label: "Share memoir link", value: "→")
                Divider().overlay(Color.theoNavy.opacity(0.06))
                SettingsRow(label: "Writing statistics", value: "→")
            }
        }
    }

    // ── Privacy section ───────────────────────────────────────────

    private var privacySection: some View {
        SettingsSection(header: "PRIVACY") {
            VStack(spacing: 0) {
                SettingsRow(label: "Photo access", value: "All Photos")
                Divider().overlay(Color.theoNavy.opacity(0.06))
                HStack {
                    Text("Delete all data")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.theoNavy)
                    Spacer()
                    Text("Delete")
                        .font(.system(size: 13))
                        .foregroundStyle(Color(red: 0.75, green: 0.22, blue: 0.17))
                }
                .padding(16)
            }
        }
    }

    // ── Version footer ────────────────────────────────────────────

    private var versionFooter: some View {
        Text("Theodore · v1.0 · \(currentYear())")
            .font(.system(size: 11, weight: .regular, design: .serif))
            .foregroundStyle(Color.theoMuted)
            .padding(.top, 10)
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

    private func currentYear() -> String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: Date())
    }
}

// ── Shared settings subviews ──────────────────────────────────────

private struct SettingsSection<Content: View>: View {
    let header: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(header)
                .font(.theoLabel)
                .foregroundStyle(Color.theoBrown)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                content()
            }
            .glassCard(cornerRadius: 16)
            .clipped()
        }
    }
}

private struct SettingsRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(Color.theoNavy)
            Spacer()
            Text(value)
                .font(.system(size: 14))
                .foregroundStyle(Color.theoMuted)
        }
        .padding(16)
    }
}
