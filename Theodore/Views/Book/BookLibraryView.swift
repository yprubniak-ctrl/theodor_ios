import SwiftUI
import SwiftData

struct BookLibraryView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) private var scheme
    @Query(sort: \Chapter.createdAt) private var chapters: [Chapter]

    @State private var showChat = false
    @State private var showPaywall = false
    @State private var selectedChapter: Chapter?
    @State private var viewModel = BookViewModel()

    @ObservedObject private var subscriptionService = SubscriptionService.shared

    private var book: Book? { chapters.first?.book }
    private var newPhotoCount: Int { viewModel.newPhotoCount(since: chapters.last) }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                Color.theoPaper(scheme).ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {

                        // ── Header ───────────────────────────
                        VStack(alignment: .leading, spacing: 4) {
                            Text("My Book")
                                .font(.theoTitle)
                                .foregroundStyle(Color.theoText(scheme))
                            Text("Written by Theodore")
                                .font(.theoPoem)
                                .foregroundStyle(Color.theoMuted)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        .padding(.bottom, 12)

                        // ── Stats ────────────────────────────
                        Text("\(chapters.count) chapters  ·  \(totalPhotos) photos")
                            .font(.theoCaption)
                            .foregroundStyle(Color.theoMuted2)
                            .padding(.horizontal, 24)

                        Divider().padding(.horizontal, 24).padding(.vertical, 12)

                        // ── Theodore nudge ───────────────────
                        if newPhotoCount >= NotificationService.nudgePhotoThreshold {
                            NudgeCard(count: newPhotoCount) { handleNewChapterTap() }
                                .padding(.horizontal, 16)
                                .padding(.bottom, 12)
                        }

                        // ── Chapter list ─────────────────────
                        LazyVStack(spacing: 6) {
                            ForEach(Array(chapters.enumerated()), id: \.element.id) { i, chapter in
                                ChapterRow(number: i + 1, chapter: chapter)
                                    .onTapGesture {
                                        chapter.isRead = true
                                        selectedChapter = chapter
                                    }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 100)
                    }
                }

                // ── FAB — new chapter ─────────────────────────
                Button { handleNewChapterTap() } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(Color.theoCream)
                        .frame(width: 56, height: 56)
                        .background(Color.theoRed, in: Circle())
                        .shadow(color: Color.theoRed.opacity(0.4), radius: 12, y: 4)
                }
                .padding(.trailing, 24)
                .padding(.bottom, 32)
            }
            .navigationBarHidden(true)
            .navigationDestination(item: $selectedChapter) { chapter in
                ChapterReadingView(chapter: chapter)
            }
            .sheet(isPresented: $showChat) {
                TheodoreChatView(chapter: nil)
            }
            .paywallGate(isPresented: $showPaywall)
            .task {
                // Schedule notification nudge on app open if new photos accumulate
                if newPhotoCount >= NotificationService.nudgePhotoThreshold {
                    await NotificationService.shared.scheduleNudge(newPhotoCount: newPhotoCount)
                }
                NotificationService.shared.clearBadge()
            }
        }
    }

    // ── Helpers ───────────────────────────────────────────────

    private func handleNewChapterTap() {
        if subscriptionService.canCreateChapter(existingCount: chapters.count) {
            // Cancel the nudge notification — user is acting on it
            NotificationService.shared.cancelNudge()
            showChat = true
        } else {
            showPaywall = true
        }
    }

    private var totalPhotos: Int {
        chapters.reduce(0) { $0 + $1.photoAssetIDs.count }
    }
}

// ── MARK: NudgeCard ───────────────────────────────────────────────

private struct NudgeCard: View {
    @Environment(\.colorScheme) private var scheme
    let count: Int
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "sparkles")
                .foregroundStyle(Color.theoAmber)

            Text("\"You've added \(count) new photos since we last spoke. Shall I write about them?\"")
                .font(.theoCaption.italic())
                .foregroundStyle(Color.theoText(scheme))

            Spacer()

            Button("Write →", action: onTap)
                .font(.theoLabel)
                .foregroundStyle(Color.theoAmber)
        }
        .padding(16)
        .background(Color.theoCard(scheme), in: RoundedRectangle(cornerRadius: 14))
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(Color.theoAmber)
                .frame(width: 3)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// ── MARK: ChapterRow ──────────────────────────────────────────────

private struct ChapterRow: View {
    @Environment(\.colorScheme) private var scheme
    let number: Int
    let chapter: Chapter

    var body: some View {
        HStack(spacing: 14) {

            // Thumbnail — real photo if available
            if let coverID = chapter.coverAssetID {
                PhotoThumbnail(assetID: coverID, size: 70, cornerRadius: 10)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.theoS2)
                        .frame(width: 70, height: 70)
                    Text("\(number)")
                        .font(.system(size: 22, weight: .semibold, design: .serif))
                        .foregroundStyle(Color.theoText(scheme).opacity(0.15))
                }
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(chapter.title)
                    .font(.system(size: 16, weight: .semibold, design: .serif))
                    .foregroundStyle(Color.theoText(scheme))
                    .opacity(chapter.isRead ? 0.75 : 1)

                Text(chapter.period)
                    .font(.theoCaption)
                    .foregroundStyle(Color.theoAmber)

                Text(chapter.openingLines.isEmpty ? chapter.moodTag : chapter.openingLines)
                    .font(.theoCaption.italic())
                    .foregroundStyle(Color.theoMuted)
                    .lineLimit(2)

                Text("\(chapter.photoAssetIDs.count) photos")
                    .font(.theoCaption)
                    .foregroundStyle(Color.theoMuted2)
            }

            Spacer()

            VStack(spacing: 8) {
                if !chapter.isRead {
                    Circle().fill(Color.theoRed).frame(width: 8, height: 8)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.theoMuted2)
            }
        }
        .padding(14)
        .background(Color.theoCard(scheme), in: RoundedRectangle(cornerRadius: 14))
    }
}
