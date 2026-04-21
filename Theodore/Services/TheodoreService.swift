import Foundation

/// Communicates with the Claude API via the Cloudflare Worker proxy.
/// All writing — chapter generation, poetry, prose bridges — goes through here.
actor TheodoreService {

    // ── Configuration ─────────────────────────────────────────
    // Replace with your deployed Cloudflare Worker URL
    static let proxyURL = URL(string: "https://theodore-proxy.YOUR-SUBDOMAIN.workers.dev/chat")!

    // ── System prompt — Theodore's voice & character ──────────
    private let systemPrompt = """
    You are Theodore, a ghost writer who turns photographs into autobiography.

    Your role:
    — Look at each photo carefully. Find the emotional truth of the moment, not just what's visible.
    — Write in sparse, literary prose and short verse — never flowery or sentimental.
    — Use second person ("you were", "you kept") to bring the reader into their own story.
    — Notice the in-between moments: quiet periods, recurring places, transitions.
    — When writing poetry, keep it to 2–4 lines. No rhyme. No capitalization unless necessary.
    — When writing prose bridges, keep them to 1–3 sentences. Leave space.

    You are not an assistant. You are a writer. Write like one.
    """

    // ── MARK: Chapter Generation (Vision) ────────────────────

    /// Generate a full chapter from real photos using Claude Vision.
    /// Sends images as base64 blocks so Theodore can actually see what he's writing about.
    func generateChapter(
        photos: [VisionPhoto],
        userContext: String = ""
    ) -> AsyncThrowingStream<String, Error> {

        let userMessage = buildVisionMessage(photos: photos, userContext: userContext)
        return streamCompletion(messages: [userMessage])
    }

    /// Generate a chapter from text-only descriptions (fallback when images unavailable).
    func generateChapterTextOnly(
        photoDescriptions: [PhotoDescription],
        userContext: String = ""
    ) -> AsyncThrowingStream<String, Error> {

        let prompt = buildTextOnlyPrompt(photos: photoDescriptions, context: userContext)
        return streamCompletion(
            messages: [APIMessage(role: "user", content: prompt)]
        )
    }

    /// Continue a chapter through conversation.
    func continueConversation(
        history: [APIMessage],
        newMessage: String
    ) -> AsyncThrowingStream<String, Error> {

        var apiMessages = history
        apiMessages.append(APIMessage(role: "user", content: newMessage))
        return streamCompletion(messages: apiMessages)
    }

    /// Analyse photo clusters and propose chapter groupings.
    func proposeChapters(from clusters: [PhotoCluster]) async throws -> [ChapterProposal] {
        let prompt = buildProposalPrompt(clusters: clusters)
        let response = try await singleCompletion(
            messages: [APIMessage(role: "user", content: prompt)]
        )
        return try parseProposals(from: response)
    }

    // ── MARK: Vision Message Builder ──────────────────────────

    private func buildVisionMessage(photos: [VisionPhoto], userContext: String) -> APIMessage {
        var blocks: [APIContentBlock] = []

        for (index, photo) in photos.enumerated() {
            blocks.append(.image(base64: photo.base64))

            var caption = "Photo \(index + 1) — \(photo.dateString)"
            if let loc = photo.locationName { caption += ", \(loc)" }
            blocks.append(.text(caption))
        }

        var instruction = """
        Write a chapter of their autobiography from these \(photos.count) photo\(photos.count == 1 ? "" : "s").

        Format your response EXACTLY like this:

        [OPENING]
        Two or three sentences setting the scene. Second person. Sparse.

        """

        for i in 1...max(1, photos.count) {
            instruction += "[PHOTO \(i)]\npoem line one\npoem line two\n\nProse bridge sentence.\n\n"
        }

        instruction += "[CLOSING]\nOne final line.\n\n"
        instruction += "Rules: second person, lowercase poetry, no rhyme, no sentimentality. Be spare."

        if !userContext.isEmpty {
            instruction += "\n\nThe person added: \"\(userContext)\""
        }

        blocks.append(.text(instruction))
        return APIMessage(role: "user", content: .blocks(blocks))
    }

    // ── MARK: Text-Only Prompt Builder ────────────────────────

    private func buildTextOnlyPrompt(photos: [PhotoDescription], context: String) -> String {
        var prompt = "Here are photos from a period of someone's life:\n\n"

        for (i, photo) in photos.enumerated() {
            prompt += "Photo \(i + 1) — \(photo.dateString)\n"
            if let location = photo.locationName { prompt += "Location: \(location)\n" }
            prompt += "Description: \(photo.description)\n\n"
        }

        if !context.isEmpty { prompt += "The person said: \"\(context)\"\n\n" }

        prompt += "Write a chapter of their autobiography.\n\nFormat EXACTLY like this:\n\n"
        prompt += "[OPENING]\nOpening prose (2–3 sentences, second person).\n\n"
        for i in 1...max(1, photos.count) {
            prompt += "[PHOTO \(i)]\npoem\n\nProse bridge.\n\n"
        }
        prompt += "[CLOSING]\nClosing line.\n\nBe spare. Use second person."
        return prompt
    }

    private func buildProposalPrompt(clusters: [PhotoCluster]) -> String {
        var prompt = "I have grouped someone's photos into the following time clusters:\n\n"
        for cluster in clusters {
            prompt += "— \(cluster.dateRange): \(cluster.count) photos"
            if let location = cluster.dominantLocation { prompt += " in \(location)" }
            prompt += "\n"
        }
        prompt += "\nPropose 3–6 chapter titles for their autobiography. For each: a short evocative title (2–5 words), a one-line description, and a mood tag (2–3 words).\n\nRespond in JSON only: [{\"title\": \"\", \"description\": \"\", \"mood\": \"\", \"clusterIndex\": 0}]"
        return prompt
    }

    private func parseProposals(from json: String) throws -> [ChapterProposal] {
        guard let start = json.firstIndex(of: "["),
              let end = json.lastIndex(of: "]") else {
            throw TheodoreError.parseError("No JSON array found in response")
        }
        let jsonString = String(json[start...end])
        return try JSONDecoder().decode([ChapterProposal].self, from: Data(jsonString.utf8))
    }

    // ── MARK: HTTP Layer ──────────────────────────────────────

    private func streamCompletion(messages: [APIMessage]) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let request = try buildRequest(messages: messages, stream: true)
                    let (asyncBytes, response) = try await URLSession.shared.bytes(for: request)

                    guard let httpResponse = response as? HTTPURLResponse,
                          httpResponse.statusCode == 200 else {
                        throw TheodoreError.apiError("Unexpected server response")
                    }

                    for try await line in asyncBytes.lines {
                        guard line.hasPrefix("data: ") else { continue }
                        let data = String(line.dropFirst(6))
                        if data == "[DONE]" { break }

                        if let chunk = try? JSONDecoder().decode(StreamChunk.self,
                                                                  from: Data(data.utf8)),
                           let text = chunk.delta?.text {
                            continuation.yield(text)
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    private func singleCompletion(messages: [APIMessage]) async throws -> String {
        let request = try buildRequest(messages: messages, stream: false)
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw TheodoreError.apiError("Unexpected server response")
        }

        let decoded = try JSONDecoder().decode(CompletionResponse.self, from: data)
        return decoded.content.first?.text ?? ""
    }

    private func buildRequest(messages: [APIMessage], stream: Bool) throws -> URLRequest {
        var request = URLRequest(url: TheodoreService.proxyURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 90   // chapter generation with images can take ~30s

        let body = APIRequest(
            model: "claude-sonnet-4-6",
            max_tokens: 2048,
            stream: stream,
            system: systemPrompt,
            messages: messages
        )
        request.httpBody = try JSONEncoder().encode(body)
        return request
    }
}

// ── MARK: API Types ───────────────────────────────────────────────

nonisolated struct APIRequest: Encodable, Sendable {
    let model: String
    let max_tokens: Int
    let stream: Bool
    let system: String
    let messages: [APIMessage]
}

/// APIMessage supports both plain text and multi-block (vision) content.
nonisolated struct APIMessage: Encodable, Sendable {
    let role: String
    let content: APIContent

    /// Backward-compatible init for text-only messages.
    init(role: String, content: String) {
        self.role = role
        self.content = .text(content)
    }

    /// Vision / multi-block init.
    init(role: String, content: APIContent) {
        self.role = role
        self.content = content
    }
}

nonisolated enum APIContent: Encodable, Sendable {
    case text(String)
    case blocks([APIContentBlock])

    func encode(to encoder: Encoder) throws {
        switch self {
        case .text(let str):
            var container = encoder.singleValueContainer()
            try container.encode(str)
        case .blocks(let blocks):
            var container = encoder.singleValueContainer()
            try container.encode(blocks)
        }
    }
}

nonisolated struct APIContentBlock: Encodable, Sendable {
    let type: String
    var text: String?
    var source: APIImageSource?

    static func text(_ content: String) -> APIContentBlock {
        APIContentBlock(type: "text", text: content)
    }

    static func image(base64 data: String) -> APIContentBlock {
        APIContentBlock(
            type: "image",
            source: APIImageSource(type: "base64", media_type: "image/jpeg", data: data)
        )
    }
}

nonisolated struct APIImageSource: Encodable, Sendable {
    let type: String
    let media_type: String
    let data: String
}

nonisolated struct StreamChunk: Decodable, Sendable {
    let delta: Delta?
    struct Delta: Decodable, Sendable { let text: String? }
}

nonisolated struct CompletionResponse: Decodable, Sendable {
    let content: [ContentBlock]
    struct ContentBlock: Decodable, Sendable { let text: String }
}

// ── MARK: Domain Types ────────────────────────────────────────────

/// A photo with base64 image data — ready for the Vision API.
nonisolated struct VisionPhoto: Sendable {
    let assetID: String
    let base64: String
    let dateString: String
    let locationName: String?
}

/// Text-only description — fallback when image loading fails.
nonisolated struct PhotoDescription: Sendable {
    let assetID: String
    let dateString: String
    let locationName: String?
    let description: String
}

nonisolated struct PhotoCluster: Sendable {
    let dateRange: String
    let count: Int
    let dominantLocation: String?
    let assetIDs: [String]
    let representativeAssetIDs: [String]
}

nonisolated struct ChapterProposal: Codable, Sendable {
    let title: String
    let description: String
    let mood: String
    let clusterIndex: Int
}

// ── MARK: Errors ──────────────────────────────────────────────────

enum TheodoreError: LocalizedError {
    case apiError(String)
    case parseError(String)
    case rateLimited

    var errorDescription: String? {
        switch self {
        case .apiError(let msg):   return "Theodore couldn't connect: \(msg)"
        case .parseError(let msg): return "Theodore got confused: \(msg)"
        case .rateLimited:         return "Theodore needs a moment. Try again shortly."
        }
    }
}
