import SwiftUI
import SwiftData

struct ChapterReadingView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dismiss) private var dismiss
    let chapter: Chapter

    @State private var currentEntry: Int = 0
    @State private var showEntryEditSheet = false
    @State private var entryToEdit: Entry?

    private var sortedEntries: [Entry] {
        chapter.entries.sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [Color(red: 0.961, green: 0.941, blue: 0.910),
                         Color(red: 0.902, green: 0.867, blue: 0.816)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {

                        // ── Chapter header ───────────────────
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Chapter \(chapterNumber)")
                                .font(.theoLabel)
                                .foregroundStyle(Color.theoAmber)

                            Text(chapter.title)
                                .font(.theoTitle)
                                .foregroundStyle(Color.theoText(scheme))

                            Text(chapter.period + (chapter.photoAssetIDs.isEmpty ? "" :
                                 "  ·  \(chapter.photoAssetIDs.count) photos"))
                                .font(.theoCaption)
                                .foregroundStyle(Color.theoMuted)

                            if !chapter.moodTag.isEmpty {
                                Text(chapter.moodTag.uppercased())
                                    .font(.system(size: 9, weight: .semibold, design: .default))
                                    .tracking(1.4)
                                    .foregroundStyle(Color.theoAmber.opacity(0.7))
                                    .padding(.top, 2)
                            }

                            Rectangle()
                                .fill(Color.theoGold)
                                .frame(width: 32, height: 1.5)
                                .cornerRadius(99)
                                .padding(.top, 4)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        .padding(.bottom, 24)

                        // ── Theodore's opening prose ─────────
                        if let opening = chapter.messages.first(where: { $0.role == .assistant }) {
                            let openingText = extractOpening(from: opening.content)
                            if !openingText.isEmpty {
                                Text(openingText)
                                    .font(.theoPoem)
                                    .foregroundStyle(Color.theoText(scheme).opacity(0.9))
                                    .lineSpacing(6)
                                    .padding(.horizontal, 24)
                                    .padding(.bottom, 32)
                            }
                        }

                        // ── Entries ──────────────────────────
                        ForEach(Array(sortedEntries.enumerated()), id: \.element.id) { index, entry in
                            EntryView(entry: entry, index: index, isCurrentEntry: index == currentEntry)
                                .id(index)
                                .onTapGesture(count: 2) {
                                    entryToEdit = entry
                                    showEntryEditSheet = true
                                }
                        }

                        Spacer().frame(height: 120)
                    }
                }
                .onChange(of: currentEntry) { _, newIndex in
                    withAnimation(.easeInOut(duration: 0.4)) {
                        proxy.scrollTo(newIndex, anchor: .top)
                    }
                }
            }

            // ── Bottom nav bar ────────────────────────────────
            bottomBar
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    Label("My Book", systemImage: "chevron.left")
                        .font(.theoCaption)
                        .foregroundStyle(Color.theoMuted)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    ShareLink(
                        item: shareText,
                        subject: Text(chapter.title),
                        message: Text("A chapter from my Theodore autobiography")
                    ) {
                        Label("Share Chapter", systemImage: "square.and.arrow.up")
                    }
                    Button("Edit with Theodore", systemImage: "pencil") {}
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(Color.theoMuted)
                }
            }
        }
        .sheet(item: $entryToEdit) { entry in
            EntryEditSheet(entry: entry)
        }
    }

    // ── Bottom progress bar ───────────────────────────────────

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Divider().overlay(Color.theoS2)

            HStack {
                // Dots
                HStack(spacing: 5) {
                    ForEach(0..<sortedEntries.count, id: \.self) { i in
                        Circle()
                            .fill(i == currentEntry ? Color.theoRed : Color.theoS3)
                            .frame(width: i == currentEntry ? 6 : 4,
                                   height: i == currentEntry ? 6 : 4)
                            .animation(.spring(response: 0.3), value: currentEntry)
                    }
                }

                Spacer()

                Button {
                    if currentEntry < sortedEntries.count - 1 {
                        withAnimation { currentEntry += 1 }
                    } else {
                        dismiss()
                    }
                } label: {
                    Text(currentEntry < sortedEntries.count - 1 ? "Continue  →" : "Finish  ✓")
                        .font(.system(size: 13, weight: .semibold, design: .serif))
                        .foregroundStyle(Color.theoText(scheme))
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)

            // Thin progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle().fill(Color.theoS2)
                    Rectangle()
                        .fill(Color.theoRed)
                        .frame(width: geo.size.width * progress)
                        .animation(.spring(response: 0.4), value: progress)
                }
            }
            .frame(height: 3)
        }
        .background(Color.theoParch)
    }

    // ── Helpers ───────────────────────────────────────────────

    private var progress: CGFloat {
        guard sortedEntries.count > 0 else { return 0 }
        return CGFloat(currentEntry + 1) / CGFloat(sortedEntries.count)
    }

    private var shareText: String {
        var parts: [String] = [chapter.title, chapter.period, ""]
        for entry in sortedEntries {
            if !entry.poem.isEmpty { parts.append(entry.poem) }
            if !entry.prose.isEmpty { parts.append(entry.prose) }
            parts.append("")
        }
        return parts.joined(separator: "\n")
    }

    private var chapterNumber: Int {
        (chapter.book?.sortedChapters.firstIndex(where: { $0.id == chapter.id }) ?? 0) + 1
    }

    /// Extract the [OPENING] section from the raw assistant message text.
    private func extractOpening(from text: String) -> String {
        let lines = text.components(separatedBy: "\n")
        var collecting = false
        var result: [String] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed == "[OPENING]" { collecting = true; continue }
            if trimmed.hasPrefix("[PHOTO") || trimmed == "[CLOSING]" { break }
            if collecting && !trimmed.isEmpty { result.append(trimmed) }
        }

        // Fallback: if no [OPENING] marker, return first non-empty lines up to 3
        if result.isEmpty {
            result = lines
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty && !$0.hasPrefix("[") }
                .prefix(3)
                .map { String($0) }
        }

        return result.joined(separator: "\n")
    }
}

// ── MARK: EntryView ───────────────────────────────────────────────

private struct EntryView: View {
    @Environment(\.colorScheme) private var scheme
    let entry: Entry
    let index: Int
    let isCurrentEntry: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── Photo ────────────────────────────────────────
            AsyncPhotoView(assetID: entry.photoAssetID, contentMode: .fill)
                .aspectRatio(4/3, contentMode: .fill)
                .frame(maxWidth: .infinity)
                .clipped()
                .overlay(alignment: .bottomLeading) {
                    if !entry.photoDate.isSameDay(as: .now) {
                        Text(entry.photoDate.formatted(date: .abbreviated, time: .omitted))
                            .font(.system(size: 10, weight: .regular, design: .serif))
                            .foregroundStyle(.white.opacity(0.7))
                            .padding(.horizontal, 12)
                            .padding(.bottom, 10)
                    }
                }

            // ── Poem ─────────────────────────────────────────
            if !entry.poem.isEmpty {
                Text(entry.poem)
                    .font(.theoPoem)
                    .foregroundStyle(Color.theoText(scheme))
                    .lineSpacing(6)
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, entry.prose.isEmpty ? 32 : 12)
            }

            // ── Prose bridge ──────────────────────────────────
            if !entry.prose.isEmpty {
                Text(entry.prose)
                    .font(.theoProse)
                    .foregroundStyle(Color.theoMuted)
                    .lineSpacing(5)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 36)
            }

            // Separator between entries (not after last)
            Rectangle()
                .fill(Color.theoS2.opacity(0.6))
                .frame(height: 1)
                .padding(.horizontal, 48)
                .padding(.bottom, 4)
        }
        .opacity(isCurrentEntry ? 1.0 : 0.4)
        .animation(.easeInOut(duration: 0.3), value: isCurrentEntry)
    }
}

// ── MARK: EntryEditSheet ──────────────────────────────────────────
// Double-tap an entry to ask Theodore to revise it.

private struct EntryEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @Environment(\.modelContext) private var context
    @State private var instruction: String = ""
    @State private var viewModel = TheodoreViewModel()
    @FocusState private var focused: Bool

    let entry: Entry

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text("Ask Theodore to revise")
                    .font(.theoHeading)
                    .foregroundStyle(Color.theoText(scheme))
                    .padding(.horizontal, 20)

                // Current poem preview
                Text(entry.poem)
                    .font(.theoPoem)
                    .foregroundStyle(Color.theoMuted)
                    .lineSpacing(5)
                    .padding(16)
                    .background(Color.theoCard(scheme))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .padding(.horizontal, 20)

                // Instruction input
                TextField("make it quieter · more about leaving · add the cold", text: $instruction, axis: .vertical)
                    .font(.theoBody)
                    .foregroundStyle(Color.theoText(scheme))
                    .padding(14)
                    .background(Color.theoCard(scheme))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .padding(.horizontal, 20)
                    .focused($focused)
                    .lineLimit(3...6)

                if viewModel.isGenerating {
                    HStack(spacing: 10) {
                        ProgressView().tint(Color.theoAmber)
                        Text("Theodore is rewriting…")
                            .font(.theoCaption)
                            .foregroundStyle(Color.theoMuted)
                    }
                    .padding(.horizontal, 20)
                }

                Spacer()
            }
            .padding(.top, 24)
            .background(Color.theoPaper(scheme).ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .font(.theoCaption)
                        .foregroundStyle(Color.theoMuted)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Revise") {
                        Task {

                            await viewModel.regenerate(entry: entry, withInstruction: instruction, context: context)
                            dismiss()
                        }
                    }
                    .font(.system(size: 14, weight: .semibold, design: .serif))
                    .foregroundStyle(Color.theoRed)
                    .disabled(instruction.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .onAppear { focused = true }
    }
}

// ── MARK: Date Helper ─────────────────────────────────────────────

private extension Date {
    func isSameDay(as other: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: other)
    }
}
