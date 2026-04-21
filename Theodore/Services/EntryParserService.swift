import Foundation

// ── MARK: EntryParserService ──────────────────────────────────────
// Parses Theodore's structured chapter text into discrete Entry objects.
//
// Expected input format from the AI:
//
//   [OPENING]
//   You were somewhere between decisions then.
//
//   [PHOTO 1]
//   a coffee half-drunk
//   someone else's chair
//
//   The afternoon light was familiar.
//
//   [PHOTO 2]
//   the window again
//   always the window
//
//   You took photos of windows that month.
//
//   [CLOSING]
//   Some things don't need a caption.
//
// The parser is resilient: if no markers are found, it treats the
// entire text as opening prose and creates stub entries per photo.

enum EntryParserService {

    struct ParsedChapter {
        let opening: String
        let entries: [ParsedEntry]
        let closing: String

        var hasStructure: Bool { !entries.isEmpty }
    }

    struct ParsedEntry {
        let photoIndex: Int   // 0-based, corresponds to chapter.photoAssetIDs[i]
        let poem: String      // 2–4 lines of verse
        let prose: String     // 1–3 sentences of prose bridge
    }

    // ── MARK: Main Parse ──────────────────────────────────────

    static func parse(text: String, photoCount: Int) -> ParsedChapter {
        let lines = text.components(separatedBy: "\n")

        var section: Section = .before
        var openingLines: [String] = []
        var closingLines: [String] = []
        var currentPhotoIndex: Int? = nil
        var currentPoem: [String] = []
        var currentProse: [String] = []
        var inPoem = true   // after [PHOTO N], poem comes first, then prose
        var entries: [ParsedEntry] = []

        func flushEntry() {
            guard let idx = currentPhotoIndex else { return }
            let poem = currentPoem
                .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                .joined(separator: "\n")
            let prose = currentProse
                .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                .joined(separator: " ")
                .trimmingCharacters(in: .whitespaces)
            entries.append(ParsedEntry(photoIndex: idx, poem: poem, prose: prose))
            currentPhotoIndex = nil
            currentPoem = []
            currentProse = []
            inPoem = true
        }

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // ── Section headers ──────────────────────────────
            if trimmed == "[OPENING]" {
                section = .opening
                continue
            }

            if trimmed == "[CLOSING]" {
                flushEntry()
                section = .closing
                continue
            }

            if trimmed.hasPrefix("[PHOTO ") && trimmed.hasSuffix("]") {
                flushEntry()
                let numStr = trimmed
                    .replacingOccurrences(of: "[PHOTO ", with: "")
                    .replacingOccurrences(of: "]", with: "")
                currentPhotoIndex = (Int(numStr) ?? 1) - 1
                section = .photo
                inPoem = true
                continue
            }

            // ── Content accumulation ─────────────────────────
            switch section {
            case .before:
                // Text before any marker → treat as opening
                if !trimmed.isEmpty { openingLines.append(trimmed) }

            case .opening:
                if !trimmed.isEmpty { openingLines.append(trimmed) }

            case .photo:
                if trimmed.isEmpty {
                    // Blank line = boundary between poem and prose
                    if inPoem && !currentPoem.isEmpty { inPoem = false }
                } else if inPoem {
                    currentPoem.append(trimmed)
                } else {
                    currentProse.append(trimmed)
                }

            case .closing:
                if !trimmed.isEmpty { closingLines.append(trimmed) }
            }
        }

        // Flush any open entry at end of text
        flushEntry()

        let opening = openingLines.joined(separator: "\n")
        let closing = closingLines.joined(separator: "\n")

        // ── Fallback: no structured markers found ────────────
        if entries.isEmpty && opening.isEmpty {
            // Treat the entire text as opening; create stub entries so the reading
            // view has something per photo (empty poem/prose show just the photo).
            let stubEntries = (0..<photoCount).map { i in
                ParsedEntry(photoIndex: i, poem: "", prose: "")
            }
            return ParsedChapter(opening: text, entries: stubEntries, closing: "")
        }

        // Pad missing entries (e.g. AI wrote fewer PHOTO sections than actual count)
        let covered = Set(entries.map { $0.photoIndex })
        var padded = entries
        for i in 0..<photoCount where !covered.contains(i) {
            padded.append(ParsedEntry(photoIndex: i, poem: "", prose: ""))
        }
        padded.sort { $0.photoIndex < $1.photoIndex }

        return ParsedChapter(opening: opening, entries: padded, closing: closing)
    }

    // ── MARK: SwiftData Materializer ──────────────────────────

    /// Converts a ParsedChapter into Entry model objects.
    /// Call this on MainActor and insert results into your ModelContext.
    static func materialize(
        parsed: ParsedChapter,
        photoAssetIDs: [String],
        photoDates: [String: Date]  // assetID → date
    ) -> [Entry] {
        parsed.entries.compactMap { parsedEntry in
            let idx = parsedEntry.photoIndex
            guard idx < photoAssetIDs.count else { return nil }

            let assetID = photoAssetIDs[idx]
            let date = photoDates[assetID] ?? .now

            return Entry(
                photoAssetID: assetID,
                poem: parsedEntry.poem,
                prose: parsedEntry.prose,
                photoDate: date,
                sortOrder: idx
            )
        }
    }

    // ── MARK: Private ─────────────────────────────────────────

    private enum Section {
        case before, opening, photo, closing
    }
}
