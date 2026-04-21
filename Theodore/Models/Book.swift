import Foundation
import SwiftData

@Model
final class Book {
    var id: UUID
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \Chapter.book)
    var chapters: [Chapter]

    init() {
        self.id = UUID()
        self.createdAt = .now
        self.chapters = []
    }

    var sortedChapters: [Chapter] {
        chapters.sorted { $0.createdAt < $1.createdAt }
    }

    var totalPhotos: Int {
        chapters.reduce(0) { $0 + $1.photoAssetIDs.count }
    }

    var unreadCount: Int {
        chapters.filter { !$0.isRead }.count
    }
}
