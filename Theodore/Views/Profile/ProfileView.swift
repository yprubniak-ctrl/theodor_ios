import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var context
    @Query private var chapters: [Chapter]
    @State private var showSettings = false

    private var wordCount: Int {
        chapters.reduce(0) { total, ch in
            let text = ch.entries.map { $0.poem + " " + $0.prose }.joined(separator: " ")
            return total + text.split(separator: " ").count
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                parchBackground
                ScrollView {
                    VStack(spacing: 0) {
                        header
                        content
                    }
                    .padding(.bottom, 100)
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $showSettings) {
                SettingsView()
            }
        }
    }

    // ── Header ────────────────────────────────────────────────────

    private var header: some View {
        HStack {
            Text("You")
                .font(.system(size: 24, weight: .bold, design: .serif))
                .foregroundStyle(Color.theoNavy)
            Spacer()
            Button { showSettings = true } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.theoMuted)
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 14)
        .background(Color.theoParch.opacity(0.88).background(.ultraThinMaterial))
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.theoNavy.opacity(0.06)).frame(height: 1)
        }
    }

    // ── Content ───────────────────────────────────────────────────

    private var content: some View {
        VStack(spacing: 18) {
            memoirCard
            streakCard
            progressCard
            chaptersSection
        }
        .padding(.horizontal, 18)
        .padding(.top, 20)
    }

    // ── Memoir card ───────────────────────────────────────────────

    private var memoirCard: some View {
        VStack(spacing: 0) {
            // Avatar
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.theoNavy)
                .frame(width: 68, height: 68)
                .overlay {
                    Text("A")
                        .font(.system(size: 32, weight: .bold, design: .serif))
                        .foregroundStyle(Color.theoParch)
                }
                .padding(.bottom, 14)

            Text("Your Memoir")
                .font(.system(size: 20, weight: .bold, design: .serif))
                .foregroundStyle(Color.theoNavy)
                .padding(.bottom, 4)

            Text("An ongoing autobiography, written with Theodore")
                .font(.system(size: 13, weight: .regular, design: .serif))
                .italic()
                .foregroundStyle(Color.theoSlate)
                .multilineTextAlignment(.center)
                .padding(.bottom, 16)

            // Stats grid
            HStack(spacing: 0) {
                StatCell(value: "\(chapters.count)", label: "Chapters")
                Divider().frame(width: 1).background(Color.theoNavy.opacity(0.08))
                StatCell(value: wordCount > 999 ? "\(wordCount/1000).\((wordCount%1000)/100)k" : "\(wordCount)", label: "Words")
                Divider().frame(width: 1).background(Color.theoNavy.opacity(0.08))
                StatCell(value: "0", label: "Photos")
                Divider().frame(width: 1).background(Color.theoNavy.opacity(0.08))
                StatCell(value: "—", label: "Streak")
            }
            .frame(maxWidth: .infinity)
            .background(Color.theoNavy.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 20)
        .glassCard(cornerRadius: 20)
        .multilineTextAlignment(.center)
    }

    // ── Streak card ───────────────────────────────────────────────

    private var streakCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("WRITING STREAK")
                    .font(.theoLabel)
                    .foregroundStyle(Color.theoBrown)
                Spacer()
                Text("0 days")
                    .font(.system(size: 18, weight: .bold, design: .serif))
                    .foregroundStyle(Color.theoGold)
            }
            .padding(.bottom, 14)

            HStack(spacing: 4) {
                ForEach(0..<14) { i in
                    RoundedRectangle(cornerRadius: 5)
                        .fill(i < 0 ? Color.theoGold.opacity(0.7) : Color.theoNavy.opacity(0.08))
                        .frame(maxWidth: .infinity)
                        .frame(height: 28)
                }
            }
            .padding(.bottom, 10)

            Text("Write a chapter today to start your streak")
                .font(.system(size: 11, weight: .regular, design: .serif))
                .foregroundStyle(Color.theoMuted)
        }
        .padding(18)
        .glassCard(cornerRadius: 18)
    }

    // ── Progress card ─────────────────────────────────────────────

    private var progressCard: some View {
        let total = max(chapters.count, 12)
        let pct = Double(chapters.count) / Double(total)

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("MEMOIR PROGRESS")
                    .font(.theoLabel)
                    .foregroundStyle(Color.theoBrown)
                Spacer()
                Text("\(chapters.count) of ~\(total)")
                    .font(.system(size: 11, weight: .regular, design: .serif))
                    .foregroundStyle(Color.theoMuted)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.theoGold.opacity(0.12))
                    Capsule().fill(Color.theoGold)
                        .frame(width: geo.size.width * pct)
                }
            }
            .frame(height: 6)

            Text(chapters.isEmpty
                 ? "Begin your story. Every chapter starts with one memory."
                 : "You're building something real. Keep writing.")
                .font(.system(size: 13, weight: .regular, design: .serif))
                .italic()
                .foregroundStyle(Color.theoSlate)
                .lineSpacing(3)
        }
        .padding(18)
        .glassCard(cornerRadius: 18)
    }

    // ── Chapters section ──────────────────────────────────────────

    private var chaptersSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("ALL CHAPTERS")
                .font(.theoLabel)
                .foregroundStyle(Color.theoBrown)
                .padding(.leading, 4)
                .padding(.bottom, 12)

            if chapters.isEmpty {
                Text("No chapters yet")
                    .font(.system(size: 14, weight: .regular, design: .serif))
                    .italic()
                    .foregroundStyle(Color.theoMuted)
                    .padding(.leading, 4)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(chapters.enumerated()), id: \.element.id) { i, ch in
                        HStack(spacing: 14) {
                            Text(romanNumeral(i + 1))
                                .font(.system(size: 11, weight: .semibold, design: .serif))
                                .foregroundStyle(Color.theoMuted)
                                .frame(width: 20, alignment: .leading)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(ch.title)
                                    .font(.system(size: 14, weight: .bold, design: .serif))
                                    .foregroundStyle(Color.theoNavy)
                                let text = ch.entries.map { $0.poem + " " + $0.prose }.joined(separator: " ")
                                let wc = text.split(separator: " ").count
                                Text("\(wc) words")
                                    .font(.system(size: 11, weight: .regular, design: .serif))
                                    .foregroundStyle(Color.theoMuted)
                            }
                            Spacer()
                            Circle()
                                .fill(Color.theoGold)
                                .frame(width: 6, height: 6)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 4)
                        if i < chapters.count - 1 {
                            Divider().overlay(Color.theoNavy.opacity(0.06))
                        }
                    }
                }
            }
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

    private func romanNumeral(_ n: Int) -> String {
        let values = [(1000,"M"),(900,"CM"),(500,"D"),(400,"CD"),(100,"C"),(90,"XC"),
                      (50,"L"),(40,"XL"),(10,"X"),(9,"IX"),(5,"V"),(4,"IV"),(1,"I")]
        var result = ""; var n = n
        for (v, s) in values { while n >= v { result += s; n -= v } }
        return result
    }
}

// ── Stat cell ─────────────────────────────────────────────────────

private struct StatCell: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .serif))
                .foregroundStyle(Color.theoNavy)
            Text(label)
                .font(.system(size: 10, weight: .regular))
                .foregroundStyle(Color.theoMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }
}
