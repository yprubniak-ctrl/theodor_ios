import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var context
    @State private var viewModel = BookViewModel()
    @State private var phase: OnboardingPhase = .splash
    @Binding var isOnboarded: Bool

    var body: some View {
        ZStack {
            // Parchment gradient fills the whole screen
            LinearGradient(
                colors: [
                    Color(red: 0.961, green: 0.941, blue: 0.910),
                    Color(red: 0.902, green: 0.867, blue: 0.816),
                ],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            switch phase {
            case .splash:    WelcomeView(onNext: requestAccess)
            case .reading:   ReadingView(viewModel: viewModel)
            case .proposals: ProposalsView(viewModel: viewModel, onSelect: createChapter)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: phase)
    }

    // ── Actions ───────────────────────────────────────────────

    private func requestAccess() {
        Task {
            let granted = await viewModel.requestGalleryAccess()
            if granted {
                phase = .reading
                await viewModel.readGallery()
                withAnimation { phase = .proposals }
            }
        }
    }

    private func createChapter(proposal: ChapterProposal) {
        Task {
            let descriptor = FetchDescriptor<Book>()
            let books = (try? context.fetch(descriptor)) ?? []
            let book = books.first ?? {
                let b = Book(); context.insert(b); return b
            }()
            if let chapter = await viewModel.createChapter(from: proposal, in: book, context: context) {
                try? context.save()
                // Signal BookLibraryView to open this chapter in chat for generation
                UserDefaults.standard.set(chapter.id.uuidString, forKey: "pendingChapterID")
            }
            isOnboarded = true
        }
    }
}

// ══════════════════════════════════════════════════════════════════
// SCREEN 1 — Welcome
// ══════════════════════════════════════════════════════════════════

private struct WelcomeView: View {
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Logo + title
            VStack(spacing: 16) {
                TLogo(size: 56)
                VStack(spacing: 6) {
                    Text("Theodore")
                        .font(.system(size: 34, weight: .bold, design: .serif))
                        .foregroundStyle(Color.theoNavy)
                    Text("Your ghost writer")
                        .font(.system(size: 17, weight: .regular, design: .serif).italic())
                        .foregroundStyle(Color.theoSlate)
                }
                GoldLine()
            }

            Spacer().frame(height: 32)

            // Description
            Text("Reads your photos and writes your autobiography — one chapter at a time.")
                .font(.system(size: 16, weight: .regular, design: .serif))
                .foregroundStyle(Color.theoSlate)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .padding(.horizontal, 40)

            Spacer().frame(height: 28)

            // Glass card — what Theodore does
            HStack(alignment: .top, spacing: 14) {
                RoundedRectangle(cornerRadius: 11)
                    .fill(Color.theoGold.opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 11)
                            .stroke(Color.theoGold.opacity(0.20), lineWidth: 1)
                    )
                    .frame(width: 40, height: 40)
                    .overlay {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 16))
                            .foregroundStyle(Color.theoGold)
                    }
                VStack(alignment: .leading, spacing: 5) {
                    Text("Access your photo library")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.theoNavy)
                    Text("Theodore reads your existing photos to find the stories already there.")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(Color.theoMuted)
                        .lineSpacing(3)
                }
                Spacer()
            }
            .padding(20)
            .glassCard(cornerRadius: 22)
            .padding(.horizontal, 28)

            Spacer()

            // CTA
            VStack(spacing: 0) {
                PrimaryButton(title: "Let Theodore read my photos", action: onNext)
                    .padding(.horizontal, 28)

                Spacer().frame(height: 14)

                Text("Nothing leaves your device without your approval")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(Color.theoMuted)
                    .multilineTextAlignment(.center)
            }
            .padding(.bottom, 40)
        }
    }
}

// ══════════════════════════════════════════════════════════════════
// SCREEN 2 — Reading (Theodore analysing photos)
// ══════════════════════════════════════════════════════════════════

private struct ReadingView: View {
    let viewModel: BookViewModel

    // Animated strip
    @State private var stripOffset: CGFloat = 0
    private let blockColors: [Color] = [
        Color(red: 0.867, green: 0.831, blue: 0.776),
        Color(red: 0.784, green: 0.816, blue: 0.847),
        Color(red: 0.800, green: 0.847, blue: 0.784),
        Color(red: 0.847, green: 0.784, blue: 0.808),
        Color(red: 0.784, green: 0.784, blue: 0.847),
        Color(red: 0.867, green: 0.851, blue: 0.792),
        Color(red: 0.800, green: 0.824, blue: 0.847),
        Color(red: 0.816, green: 0.851, blue: 0.800),
    ]
    private let itemWidth: CGFloat = 50
    private let itemGap:  CGFloat = 6

    private var oneSetWidth: CGFloat {
        CGFloat(blockColors.count) * (itemWidth + itemGap)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top bar
            TheodoreBar(center: AnyView(TLogo(size: 28)))

            Spacer()

            // Heading
            VStack(spacing: 10) {
                Text("Theodore is reading\nyour photos")
                    .font(.system(size: 26, weight: .bold, design: .serif))
                    .foregroundStyle(Color.theoNavy)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                Text("Give him a moment.")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(Color.theoMuted)
            }
            .padding(.horizontal, 40)

            Spacer().frame(height: 28)

            // Animated photo strip — real photos if available, else color blocks
            let stripItems = viewModel.recentAssetIDs.isEmpty
                ? (0..<(blockColors.count * 3)).map { StripItem.color(blockColors[$0 % blockColors.count]) }
                : (Array(repeating: viewModel.recentAssetIDs, count: 3).flatMap { $0 }).map { StripItem.photo($0) }

            HStack(spacing: itemGap) {
                ForEach(Array(stripItems.enumerated()), id: \.offset) { _, item in
                    Group {
                        switch item {
                        case .color(let c):
                            RoundedRectangle(cornerRadius: 9)
                                .fill(LinearGradient(
                                    colors: [c, c.opacity(0.6)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing))
                        case .photo(let id):
                            AsyncPhotoView(assetID: id, contentMode: .fill)
                                .clipShape(RoundedRectangle(cornerRadius: 9))
                        }
                    }
                    .frame(width: itemWidth, height: 72)
                }
            }
            .offset(x: stripOffset)
            .frame(height: 72, alignment: .leading)
            .clipped()
            .onAppear {
                withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                    stripOffset = -oneSetWidth
                }
            }

            Spacer().frame(height: 20)

            // Noticing card
            VStack(alignment: .leading, spacing: 0) {
                Text("THEODORE IS NOTICING")
                    .font(.theoLabel)
                    .foregroundStyle(Color.theoBrown)
                    .tracking(1.2)
                    .padding(.bottom, 14)

                Rectangle()
                    .fill(Color.theoGold.opacity(0.25))
                    .frame(height: 1)
                    .padding(.bottom, 16)

                VStack(alignment: .leading, spacing: 13) {
                    if viewModel.readingProgress.isEmpty {
                        Text("Looking at your photos…")
                            .font(.system(size: 13, weight: .regular, design: .serif).italic())
                            .foregroundStyle(Color.theoMuted)
                    }
                    ForEach(viewModel.readingProgress) { step in
                        HStack(spacing: 10) {
                            Circle()
                                .fill(step.isActive ? Color.theoGold : Color.theoNavy.opacity(0.25))
                                .frame(width: 5, height: 5)
                            Text(step.text)
                                .font(.system(size: 13, weight: step.isActive ? .semibold : .regular, design: .serif))
                                .foregroundStyle(step.isActive ? Color.theoNavy : Color.theoSlate)
                        }
                    }
                }
                .frame(minHeight: 80, alignment: .topLeading)

                // "Finding the words" loader
                if !viewModel.readingProgress.isEmpty &&
                    viewModel.readingProgress.last?.isDone == false {
                    HStack(spacing: 8) {
                        Text("Finding the words")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundStyle(Color.theoMuted)
                        HStack(spacing: 4) {
                            ForEach(0..<3, id: \.self) { _ in
                                Circle()
                                    .fill(Color.theoGold)
                                    .frame(width: 5, height: 5)
                            }
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .background(Color.theoGold.opacity(0.08),
                                in: RoundedRectangle(cornerRadius: 13))
                    .overlay(
                        RoundedRectangle(cornerRadius: 13)
                            .stroke(Color.theoGold.opacity(0.20), lineWidth: 1)
                    )
                    .padding(.top, 18)
                }
            }
            .padding(20)
            .glassCard(cornerRadius: 22)
            .padding(.horizontal, 20)

            Spacer()
        }
    }
}

// ══════════════════════════════════════════════════════════════════
// SCREEN 3 — Chapter proposals
// ══════════════════════════════════════════════════════════════════

private struct ProposalsView: View {
    let viewModel: BookViewModel
    let onSelect: (ChapterProposal) -> Void
    @State private var selected: Int = 0

    var body: some View {
        VStack(spacing: 0) {
            // Top bar
            TheodoreBar(center: AnyView(TLogo(size: 26)))

            // Theodore's quote card
            HStack(alignment: .top, spacing: 12) {
                Rectangle()
                    .fill(Color.theoGold)
                    .frame(width: 2)
                    .cornerRadius(99)
                VStack(alignment: .leading, spacing: 8) {
                    Text(viewModel.proposals.isEmpty
                         ? "I've been through your photos.\nI found 0 stories worth telling.\nShall I write them?"
                         : "I've looked at your photos carefully.\nI found \(viewModel.proposals.count) stories worth telling.\nShall I write them?")
                        .font(.system(size: 14, weight: .regular, design: .serif).italic())
                        .foregroundStyle(Color.theoNavy)
                        .lineSpacing(4)
                    Text("Theodore  ·  just now")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(Color.theoMuted)
                }
                Spacer()
            }
            .padding(18)
            .glassCard(cornerRadius: 20)
            .padding(.horizontal, 20)
            .padding(.top, 16)

            // Error or empty state
            if let errorMsg = viewModel.error {
                VStack(spacing: 10) {
                    Text("Couldn't connect to Theodore")
                        .font(.system(size: 14, weight: .semibold, design: .serif))
                        .foregroundStyle(Color.theoNavy)
                    Text(errorMsg)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.theoMuted)
                        .multilineTextAlignment(.center)
                }
                .padding(16)
                .glassCard(cornerRadius: 16)
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }

            // Label
            Text("CHOOSE WHAT TO WRITE FIRST")
                .font(.theoLabel)
                .foregroundStyle(Color.theoBrown)
                .tracking(1.2)
                .padding(.vertical, 14)

            // Chapter cards
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(Array(viewModel.proposals.enumerated()), id: \.offset) { i, proposal in
                        ProposalCard(
                            proposal: proposal,
                            index: i,
                            isSelected: selected == i
                        )
                        .onTapGesture { withAnimation(.easeInOut(duration: 0.2)) { selected = i } }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }

            Spacer(minLength: 12)

            // CTA
            if let proposal = viewModel.proposals[safe: selected] {
                PrimaryButton(title: "Write \"\(proposal.title)\"", action: { onSelect(proposal) })
                    .padding(.horizontal, 24)
                    .padding(.bottom, 36)
            }
        }
    }
}

private struct ProposalCard: View {
    let proposal: ChapterProposal
    let index: Int
    let isSelected: Bool

    private let romans = ["I","II","III","IV","V","VI","VII","VIII","IX","X"]

    var body: some View {
        HStack(spacing: 0) {
            // Roman numeral column
            ZStack {
                Rectangle()
                    .fill(isSelected
                          ? Color.theoGold.opacity(0.12)
                          : Color.theoNavy.opacity(0.04))
                Text(index < romans.count ? romans[index] : "\(index + 1)")
                    .font(.system(size: 11, weight: .semibold, design: .serif))
                    .foregroundStyle(isSelected ? Color.theoGold : Color.theoMuted)
                    .tracking(0.5)
            }
            .frame(width: 64)
            .overlay(alignment: .trailing) {
                Rectangle()
                    .fill(isSelected
                          ? Color.theoGold.opacity(0.20)
                          : Color.theoNavy.opacity(0.06))
                    .frame(width: 1)
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top) {
                    Text(proposal.title)
                        .font(.system(size: 15, weight: .bold, design: .serif))
                        .foregroundStyle(Color.theoNavy)
                    Spacer()
                    if isSelected {
                        ZStack {
                            Circle().fill(Color.theoGold)
                                .frame(width: 16, height: 16)
                            Image(systemName: "checkmark")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                }
                Text(proposal.mood)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color.theoMuted)
                    .tracking(0.5)
                    .padding(.top, 1)
                Text(proposal.description)
                    .font(.system(size: 12, weight: .regular, design: .serif))
                    .foregroundStyle(Color.theoSlate)
                    .lineSpacing(3)
                    .lineLimit(2)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
        }
        .background(
            isSelected ? Color.white.opacity(0.78) : Color.white.opacity(0.62),
            in: RoundedRectangle(cornerRadius: 18)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(
                    isSelected ? Color.theoGold.opacity(0.35) : Color.white.opacity(0.80),
                    lineWidth: 1
                )
        )
        .shadow(
            color: isSelected
                ? Color.theoGold.opacity(0.12)
                : Color.theoNavy.opacity(0.04),
            radius: isSelected ? 24 : 12, x: 0, y: isSelected ? 4 : 2
        )
        .clipped()
    }
}

// ── Phase enum & helpers ──────────────────────────────────────────

enum OnboardingPhase { case splash, reading, proposals }

private enum StripItem { case color(Color), photo(String) }

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
