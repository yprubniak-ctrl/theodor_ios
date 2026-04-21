import SwiftUI
import SwiftData

/// Drives the Theodore chat interface and chapter generation.
@MainActor
@Observable
final class TheodoreViewModel {

    private let theodore     = TheodoreService()
    private let photoService = PhotoLibraryService()

    var streamingText: String = ""
    var isGenerating: Bool = false
    var generationPhase: GenerationPhase = .idle
    var error: String?

    enum GenerationPhase: String {
        case idle         = ""
        case loadingPhotos = "Loading your photos…"
        case analysing    = "Theodore is looking…"
        case writing      = "Theodore is writing…"
        case saving       = "Saving chapter…"
    }

    // ── MARK: Send Message ────────────────────────────────────

    func send(
        message: String,
        chapter: Chapter,
        context: ModelContext
    ) async {
        // 1. Save user message
        let userMsg = ConversationMessage(role: .user, content: message)
        userMsg.chapter = chapter
        chapter.messages.append(userMsg)
        context.insert(userMsg)

        // 2. Stream Theodore's response
        isGenerating = true
        generationPhase = .writing
        streamingText = ""

        do {
            let history = chapter.messages.dropLast().map {
                APIMessage(role: $0.role.rawValue, content: $0.content)
            }
            let stream = await theodore.continueConversation(
                history: history,
                newMessage: message
            )

            for try await chunk in stream {
                streamingText += chunk
            }

            // 3. Persist assistant message
            let assistantMsg = ConversationMessage(role: .assistant, content: streamingText)
            assistantMsg.chapter = chapter
            chapter.messages.append(assistantMsg)
            context.insert(assistantMsg)
            streamingText = ""

        } catch {
            self.error = error.localizedDescription
        }

        isGenerating = false
        generationPhase = .idle
    }

    // ── MARK: Generate Initial Chapter ───────────────────────

    func generateInitialChapter(
        chapter: Chapter,
        context: ModelContext
    ) async {
        isGenerating = true
        streamingText = ""
        error = nil

        // ── Step 1: Load photos ────────────────────────────
        generationPhase = .loadingPhotos
        let assets = photoService.fetchAssets(ids: chapter.photoAssetIDs)
        let selected = Array(assets.prefix(8))   // cap at 8 for token budget

        var visionPhotos: [VisionPhoto] = []
        var photoDates: [String: Date] = [:]
        let formatter = DateFormatter()
        formatter.dateStyle = .medium

        for asset in selected {
            let meta = photoService.metadata(for: asset)
            photoDates[meta.assetID] = meta.date

            if let b64 = await photoService.base64(for: asset) {
                visionPhotos.append(VisionPhoto(
                    assetID: meta.assetID,
                    base64: b64,
                    dateString: formatter.string(from: meta.date),
                    locationName: meta.locationName
                ))
            } else {
                // Image load failed — record the date for parsing but skip vision
            }
        }

        // ── Step 2: Call Theodore ─────────────────────────
        generationPhase = .analysing
        streamingText = ""

        do {
            let stream: AsyncThrowingStream<String, Error>

            if !visionPhotos.isEmpty {
                // Real vision: Theodore sees the actual photos
                stream = await theodore.generateChapter(photos: visionPhotos)
            } else {
                // Fallback: text descriptions only
                let descriptions = selected.map { asset -> PhotoDescription in
                    let meta = photoService.metadata(for: asset)
                    return PhotoDescription(
                        assetID: meta.assetID,
                        dateString: formatter.string(from: meta.date),
                        locationName: meta.locationName,
                        description: "Photo from \(formatter.string(from: meta.date))"
                    )
                }
                stream = await theodore.generateChapterTextOnly(photoDescriptions: descriptions)
            }

            generationPhase = .writing

            for try await chunk in stream {
                streamingText += chunk
            }

            // ── Step 3: Parse and save ─────────────────────
            generationPhase = .saving

            let fullText = streamingText

            // Save the raw conversation message
            let assistantMsg = ConversationMessage(role: .assistant, content: fullText)
            assistantMsg.chapter = chapter
            chapter.messages.append(assistantMsg)
            context.insert(assistantMsg)

            // Parse into structured entries
            let parsed = EntryParserService.parse(
                text: fullText,
                photoCount: chapter.photoAssetIDs.count
            )

            let entries = EntryParserService.materialize(
                parsed: parsed,
                photoAssetIDs: chapter.photoAssetIDs,
                photoDates: photoDates
            )

            for entry in entries {
                entry.chapter = chapter
                chapter.entries.append(entry)
                context.insert(entry)
            }

            chapter.isDraft = false
            streamingText = ""

        } catch {
            self.error = error.localizedDescription
        }

        isGenerating = false
        generationPhase = .idle
    }

    // ── MARK: Regenerate Entry ────────────────────────────────

    /// Ask Theodore to rewrite a single entry's poem in a different mood.
    func regenerate(entry: Entry, withInstruction instruction: String, context: ModelContext) async {
        isGenerating = true
        generationPhase = .writing
        streamingText = ""

        let prompt = """
        You previously wrote this poem for a photo:

        \(entry.poem)

        The person asked: \"\(instruction)\"

        Rewrite the poem (2–4 lines, same photo). Keep the prose bridge unless it no longer fits.
        Reply with JUST the new poem, then a blank line, then the new prose bridge (optional).
        """

        do {
            let history = [APIMessage(role: "user", content: prompt)]
            let stream = await theodore.continueConversation(history: history, newMessage: "")

            for try await chunk in stream {
                streamingText += chunk
            }

            // Parse the short response: first block = poem, second = prose
            let parts = streamingText
                .components(separatedBy: "\n\n")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }

            if let newPoem = parts.first {
                entry.poem = newPoem
            }
            if parts.count > 1 {
                entry.prose = parts[1]
            }

            streamingText = ""
        } catch {
            self.error = error.localizedDescription
        }

        isGenerating = false
        generationPhase = .idle
    }
}
