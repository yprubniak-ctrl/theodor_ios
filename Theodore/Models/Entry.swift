import Foundation
import SwiftData

@Model
final class Entry {
    var id: UUID
    var photoAssetID: String
    var poem: String       // italic verse — 1–4 lines
    var prose: String      // connecting prose from Theodore
    var photoDate: Date
    var sortOrder: Int
    var chapter: Chapter?

    init(photoAssetID: String, poem: String, prose: String, photoDate: Date, sortOrder: Int) {
        self.id = UUID()
        self.photoAssetID = photoAssetID
        self.poem = poem
        self.prose = prose
        self.photoDate = photoDate
        self.sortOrder = sortOrder
    }
}
