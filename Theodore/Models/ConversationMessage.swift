import Foundation
import SwiftData

@Model
final class ConversationMessage {
    var id: UUID
    var role: MessageRole
    var content: String
    var timestamp: Date
    var chapter: Chapter?

    init(role: MessageRole, content: String) {
        self.id = UUID()
        self.role = role
        self.content = content
        self.timestamp = .now
    }

    enum MessageRole: String, Codable {
        case user      = "user"
        case assistant = "assistant"
    }
}
