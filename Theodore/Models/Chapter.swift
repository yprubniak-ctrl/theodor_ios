import Foundation
import SwiftData

@Model
final class Chapter {
    var id: UUID
    var title: String
    var period: String            // e.g. "Oct 11–13, 2024"
    var moodTag: String           // e.g. "Present, alive"
    var photoAssetIDs: [String]   // PHAsset localIdentifiers
    var coverAssetID: String?     // First photo for thumbnail
    var isRead: Bool
    var isDraft: Bool
    var createdAt: Date
    var book: Book?

    @Relationship(deleteRule: .cascade, inverse: \Entry.chapter)
    var entries: [Entry]

    @Relationship(deleteRule: .cascade, inverse: \ConversationMessage.chapter)
    var messages: [ConversationMessage]

    init(title: String, period: String, moodTag: String = "", photoAssetIDs: [String]) {
        self.id = UUID()
        self.title = title
        self.period = period
        self.moodTag = moodTag
        self.photoAssetIDs = photoAssetIDs
        self.coverAssetID = photoAssetIDs.first
        self.isRead = false
        self.isDraft = true
        self.createdAt = .now
        self.entries = []
        self.messages = []
    }

    var openingLines: String {
        entries.first?.poem ?? ""
    }
}
