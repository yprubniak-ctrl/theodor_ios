import SwiftUI
import SwiftData
import Photos

@MainActor
@Observable
final class BookViewModel {

    // ── Dependencies ──────────────────────────────────────────
    private let photoService   = PhotoLibraryService()
    private let clusterService = ClusteringService()
    private let theodore       = TheodoreService()
    let subscriptionService    = SubscriptionService.shared

    // ── State ─────────────────────────────────────────────────
    var isReadingGallery: Bool = false
    var readingProgress: [ReadingStep] = []
    var proposals: [ChapterProposal] = []
    var clusters: [PhotoCluster] = []
    var error: String?

    // ── MARK: Onboarding Flow ─────────────────────────────────

    func requestGalleryAccess() async -> Bool {
        await photoService.requestAccess()
    }

    /// Main entry: read the gallery, cluster photos, generate proposals.
    func readGallery() async {
        isReadingGallery = true
        readingProgress = []

        // Step 1
        await addStep("A recurring face across 3 years")
        let fetchResult = photoService.fetchAllPhotos()

        // Step 2
        await addStep("A trip you took last autumn")
        let photoClusters = await clusterService.cluster(fetchResult: fetchResult)
        self.clusters = photoClusters

        // Step 3
        await addStep("A period of quiet — fewer photos")

        // Step 4 — active
        await addStep("Something that felt like change", active: true)
        do {
            proposals = try await theodore.proposeChapters(from: photoClusters)
        } catch {
            self.error = error.localizedDescription
        }

        await addStep("The most recent chapter...")
        isReadingGallery = false
    }

    // ── MARK: Chapter Creation ────────────────────────────────

    func createChapter(
        from proposal: ChapterProposal,
        in book: Book,
        context: ModelContext
    ) async -> Chapter? {
        let clusterIndex = min(proposal.clusterIndex, clusters.count - 1)
        guard clusterIndex >= 0 else { return nil }

        let cluster = clusters[clusterIndex]
        let chapter = Chapter(
            title: proposal.title,
            period: cluster.dateRange,
            moodTag: proposal.mood,
            photoAssetIDs: cluster.assetIDs
        )
        chapter.book = book
        book.chapters.append(chapter)
        context.insert(chapter)
        return chapter
    }

    // ── MARK: Nudge Logic ─────────────────────────────────────

    /// Returns count of new photos since the latest chapter was created.
    func newPhotoCount(since chapter: Chapter?) -> Int {
        guard let chapter else { return 0 }
        let fetchResult = photoService.fetchAllPhotos()
        var count = 0
        fetchResult.enumerateObjects { asset, _, _ in
            if let date = asset.creationDate, date > chapter.createdAt {
                count += 1
            }
        }
        return count
    }

    // ── MARK: Helpers ─────────────────────────────────────────

    private func addStep(_ text: String, active: Bool = false) async {
        let step = ReadingStep(text: text, isDone: !active, isActive: active)
        readingProgress.append(step)
        // Simulate reading time
        try? await Task.sleep(nanoseconds: 1_200_000_000)
        if active {
            if let idx = readingProgress.firstIndex(where: { $0.text == text }) {
                readingProgress[idx] = ReadingStep(text: text, isDone: true, isActive: false)
            }
        }
    }
}

struct ReadingStep: Identifiable {
    let id = UUID()
    let text: String
    var isDone: Bool
    var isActive: Bool
}
