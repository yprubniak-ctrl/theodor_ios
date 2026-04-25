import SwiftUI
import SwiftData

struct BookLibraryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Chapter.createdAt) private var chapters: [Chapter]

    @State private var showNewChapterRec = false
    @State private var showChat = false
    @State private var showPaywall = false
    @State private var selectedChapter: Chapter?
    @State private var pendingChatChapter: Chapter?
    @State private var viewModel = BookViewModel()

    @ObservedObject private var subscriptionService = SubscriptionService.shared

    private var book: Book? { chapters.first?.book }
    private var newPhotoCount: Int { viewModel.newPhotoCount(since: chapters.last) }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                // Parchment gradient background
                LinearGradient(
                    colors: [
                        Color(red: 0.961, green: 0.941, blue: 0.910),
                        Color(red: 0.902, green: 0.867, blue: 0.816),
                    ],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {

                        // ── Header ───────────────────────────
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("My Book")
                                    .font(.system(size: 24, weight: .bold, design: .serif))
                                    .foregroundStyle(Color.theoNavy)
                                Text("\(chapters.count) chapter\(chapters.count == 1 ? "" : "s")  ·  \(totalPhotos) photos")
                                    .font(.system(size: 11, weight: .regular))
                                    .foregroundStyle(Color.theoMuted)
                            }
                            Spacer()
                            TLogo(size: 34)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        .padding(.bottom, 20)
                        .background(Color.theoParch.opacity(0.85).background(.ultraThinMaterial))
                        .overlay(alignment: .bottom) {
                            Rectangle()
                                .fill(Color.theoNavy.opacity(0.06))
                                .frame(height: 1)
                        }

                        // ── Theodore nudge card ───────────────
                        if newPhotoCount >= NotificationService.nudgePhotoThreshold {
                            NudgeCard(count: newPhotoCount) { handleNewChapterTap() }
                                .padding(.horizontal, 16)
                                .padding(.top, 16)
                                .padding(.bottom, 4)
                        }

                        // ── Chapters label ───────────────────
                        Text("CHAPTERS")
                            .font(.theoLabel)
                            .foregroundStyle(Color.theoBrown)
                            .tracking(1.2)
                            .padding(.horizontal, 24)
                            .padding(.top, 20)
                            .padding(.bottom, 12)

                        // ── Chapter list ─────────────────────
                        LazyVStack(spacing: 8) {
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
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(Color.theoParch)
                        .frame(width: 52, height: 52)
                        .background(Color.theoNavy, in: Circle())
                        .shadow(color: Color.theoNavy.opacity(0.28), radius: 24, y: 8)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 32)
            }
            .navigationBarHidden(true)
            .navigationDestination(item: $selectedChapter) { chapter in
                ChapterReadingView(chapter: chapter)
            }
            .fullScreenCover(isPresented: $showNewChapterRec) {
                NewChapterRecView(
                    onStart: {
                        showNewChapterRec = false
                        showChat = true
                    },
                    onDismiss: { showNewChapterRec = false },
                    assetIDs: viewModel.latestClusterAssetIDs,
                    photoCount: viewModel.latestClusterAssetIDs.count
                )
            }
            .sheet(isPresented: $showChat) {
                TheodoreChatView(chapter: nil)
            }
            .sheet(item: $pendingChatChapter) { chapter in
                TheodoreChatView(chapter: chapter)
            }
            .paywallGate(isPresented: $showPaywall)
            .task {
                // Open chat for a chapter that was just created during onboarding
                if let idString = UserDefaults.standard.string(forKey: "pendingChapterID"),
                   let id = UUID(uuidString: idString),
                   let chapter = chapters.first(where: { $0.id == id }) {
                    UserDefaults.standard.removeObject(forKey: "pendingChapterID")
                    try? await Task.sleep(nanoseconds: 400_000_000)
                    pendingChatChapter = chapter
                }
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
            NotificationService.shared.cancelNudge()
            // Load recent asset IDs if not already loaded
            if viewModel.recentAssetIDs.isEmpty {
                Task { await viewModel.loadRecentAssetIDs() }
            }
            showNewChapterRec = true
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
    let count: Int
    let onTap: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 9)
                .fill(Color.theoGold.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 9)
                        .stroke(Color.theoGold.opacity(0.20), lineWidth: 1)
                )
                .frame(width: 32, height: 32)
                .overlay {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.theoGold)
                }

            VStack(alignment: .leading, spacing: 8) {
                Text("\"You've added \(count) new photos since we last spoke. Shall I write about them?\"")
                    .font(.system(size: 13, weight: .regular, design: .serif).italic())
                    .foregroundStyle(Color.theoNavy)
                    .lineSpacing(4)
                Button("Start new chapter →", action: onTap)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.theoBrown)
            }
            Spacer()
        }
        .padding(16)
        .glassCard(cornerRadius: 20)
    }
}

// ── MARK: ChapterRow ──────────────────────────────────────────────

private struct ChapterRow: View {
    let number: Int
    let chapter: Chapter

    private let romans = ["I","II","III","IV","V","VI","VII","VIII","IX","X"]

    var body: some View {
        HStack(spacing: 0) {
            // Roman numeral / photo thumb
            ZStack {
                Rectangle()
                    .fill(Color.theoNavy.opacity(0.04))
                if let coverID = chapter.coverAssetID {
                    PhotoThumbnail(assetID: coverID, size: 64, cornerRadius: 0)
                        .opacity(chapter.isRead ? 0.65 : 1)
                } else {
                    Text(number <= romans.count ? romans[number - 1] : "\(number)")
                        .font(.system(size: 11, weight: .semibold, design: .serif))
                        .foregroundStyle(Color.theoMuted)
                        .tracking(0.5)
                }
            }
            .frame(width: 48)
            .overlay(alignment: .trailing) {
                Rectangle()
                    .fill(Color.theoNavy.opacity(0.06))
                    .frame(width: 1)
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(chapter.title)
                    .font(.system(size: 15, weight: .bold, design: .serif))
                    .foregroundStyle(Color.theoNavy)
                    .opacity(chapter.isRead ? 0.75 : 1)

                Text(chapter.period)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(Color.theoMuted)

                Text(chapter.openingLines.isEmpty ? chapter.moodTag : chapter.openingLines)
                    .font(.system(size: 12, weight: .regular, design: .serif).italic())
                    .foregroundStyle(Color.theoSlate)
                    .lineLimit(2)
                    .lineSpacing(2)

                Text("\(chapter.photoAssetIDs.count) photo\(chapter.photoAssetIDs.count == 1 ? "" : "s")")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(Color.theoMuted)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 14)

            Spacer()

            VStack(spacing: 8) {
                if !chapter.isRead {
                    Circle()
                        .fill(Color.theoGold)
                        .frame(width: 6, height: 6)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.theoMuted)
            }
            .padding(.trailing, 12)
        }
        .background(Color.white.opacity(0.62), in: RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.80), lineWidth: 1)
        )
        .shadow(color: Color.theoNavy.opacity(0.04), radius: 12, x: 0, y: 2)
        .clipped()
    }
}
