import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) private var scheme
    @State private var viewModel = BookViewModel()
    @State private var phase: OnboardingPhase = .splash
    @Binding var isOnboarded: Bool

    var body: some View {
        ZStack {
            Color.theoPaper(scheme).ignoresSafeArea()

            switch phase {
            case .splash:      SplashView(onContinue: requestAccess)
            case .reading:     ReadingView(viewModel: viewModel)
            case .proposals:   ProposalsView(
                                  viewModel: viewModel,
                                  onSelect: createChapter
                               )
            }
        }
        .animation(.easeInOut(duration: 0.4), value: phase)
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
            // Fetch or create the user's Book
            let descriptor = FetchDescriptor<Book>()
            let books = (try? context.fetch(descriptor)) ?? []
            let book = books.first ?? {
                let b = Book(); context.insert(b); return b
            }()

            _ = await viewModel.createChapter(from: proposal, in: book, context: context)
            try? context.save()
            isOnboarded = true
        }
    }
}

// ── Sub-views ─────────────────────────────────────────────────────

private struct SplashView: View {
    @Environment(\.colorScheme) private var scheme
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            TheodoreAvatar(size: 88, glowing: true)
            Spacer().frame(height: 28)
            Text("Theodore")
                .font(.theoTitle)
                .foregroundStyle(Color.theoText(scheme))
            Spacer().frame(height: 6)
            Text("Your ghost writer")
                .font(.theoPoem)
                .foregroundStyle(Color.theoAmber)
            Spacer().frame(height: 20)
            Divider().frame(width: 64).overlay(Color.theoMuted2)
            Spacer().frame(height: 20)
            Text("Theodore reads your photos and writes\nyour autobiography — one chapter at a time.")
                .font(.theoBody)
                .foregroundStyle(Color.theoMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()

            // Permission card
            VStack(alignment: .leading, spacing: 12) {
                Label("Access your photo library", systemImage: "photo.on.rectangle")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.theoText(scheme))
                Text("Theodore reads your existing photos\nto find the stories already there.")
                    .font(.theoCaption)
                    .foregroundStyle(Color.theoMuted)
                Button(action: onContinue) {
                    Text("Let Theodore read my photos")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.theoCream)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.theoRed, in: RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(20)
            .background(Color.theoCard(scheme), in: RoundedRectangle(cornerRadius: 20))
            .padding(.horizontal, 24)

            Spacer().frame(height: 16)
            Text("Nothing leaves your device without your approval")
                .font(.theoCaption)
                .foregroundStyle(Color.theoMuted2)
            Spacer().frame(height: 8)
            Text("\"I'm never lonely.\" — Her, 2013")
                .font(.theoCaption.italic())
                .foregroundStyle(Color.theoMuted2.opacity(0.6))
            Spacer().frame(height: 32)
        }
    }
}

private struct ReadingView: View {
    @Environment(\.colorScheme) private var scheme
    let viewModel: BookViewModel

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            TheodoreAvatar(size: 32, glowing: false)
            VStack(spacing: 8) {
                Text("Theodore is reading\nyour photos")
                    .font(.theoHeading)
                    .foregroundStyle(Color.theoText(scheme))
                    .multilineTextAlignment(.center)
                Text("Give him a moment.")
                    .font(.theoPoem)
                    .foregroundStyle(Color.theoMuted)
            }

            // Notice list
            VStack(alignment: .leading, spacing: 0) {
                Text("Theodore is noticing...")
                    .font(.theoLabel)
                    .foregroundStyle(Color.theoAmber)
                    .padding(.bottom, 10)
                Divider().overlay(Color.theoS3)
                ForEach(viewModel.readingProgress) { step in
                    HStack(spacing: 10) {
                        Circle()
                            .fill(step.isDone ? Color.theoRed :
                                  step.isActive ? Color.theoAmber : Color.theoMuted2)
                            .frame(width: step.isActive ? 10 : 8, height: step.isActive ? 10 : 8)
                        Text(step.text)
                            .font(step.isActive ? .system(size: 13, weight: .semibold, design: .serif)
                                               : .theoCaption)
                            .foregroundStyle(step.isDone ? Color.theoMuted :
                                             step.isActive ? Color.theoText(scheme) : Color.theoMuted2)
                    }
                    .padding(.vertical, 10)
                }
            }
            .padding(20)
            .background(Color.theoCard(scheme), in: RoundedRectangle(cornerRadius: 20))
            .padding(.horizontal, 32)

            Spacer()
        }
    }
}

private struct ProposalsView: View {
    @Environment(\.colorScheme) private var scheme
    let viewModel: BookViewModel
    let onSelect: (ChapterProposal) -> Void
    @State private var selected: Int = 0

    var body: some View {
        VStack(spacing: 0) {
            // Theodore's message
            HStack(alignment: .top, spacing: 12) {
                TheodoreAvatar(size: 26)
                VStack(alignment: .leading, spacing: 4) {
                    Text("I've been through your photos.\nI found \(viewModel.proposals.count) stories worth telling.\nShall I write them?")
                        .font(.theoPoem)
                        .foregroundStyle(Color.theoText(scheme))
                    Text("Theodore  ·  just now")
                        .font(.theoCaption)
                        .foregroundStyle(Color.theoMuted)
                }
                Spacer()
            }
            .padding(20)
            .background(Color.theoCard(scheme))

            Text("Choose what to write first")
                .font(.theoLabel)
                .foregroundStyle(Color.theoAmber)
                .padding(.vertical, 12)

            ScrollView {
                VStack(spacing: 8) {
                    ForEach(Array(viewModel.proposals.enumerated()), id: \.offset) { i, proposal in
                        ProposalCard(proposal: proposal, isSelected: selected == i)
                            .onTapGesture { selected = i }
                    }
                }
                .padding(.horizontal, 16)
            }

            Spacer(minLength: 16)

            if let proposal = viewModel.proposals[safe: selected] {
                Button {
                    onSelect(proposal)
                } label: {
                    Text("Write \"\(proposal.title)\"")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.theoCream)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.theoRed, in: RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
    }
}

private struct ProposalCard: View {
    @Environment(\.colorScheme) private var scheme
    let proposal: ChapterProposal
    let isSelected: Bool

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(proposal.title)
                    .font(.system(size: 16, weight: .semibold, design: .serif))
                    .foregroundStyle(Color.theoText(scheme))
                Text(proposal.mood)
                    .font(.theoCaption)
                    .foregroundStyle(Color.theoAmber)
                Text(proposal.description)
                    .font(.theoCaption.italic())
                    .foregroundStyle(Color.theoMuted)
                    .lineLimit(2)
            }
            Spacer()
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.theoRed)
                    .padding(6)
                    .background(Color.theoRed.opacity(0.15), in: Circle())
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.theoCard(scheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(isSelected ? Color.theoRed.opacity(0.6) : .clear, lineWidth: 1.5)
                )
        )
        .overlay(
            Rectangle()
                .fill(isSelected ? Color.theoRed : Color.clear)
                .frame(width: 3)
                .clipShape(RoundedRectangle(cornerRadius: 2)),
            alignment: .leading
        )
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

enum OnboardingPhase { case splash, reading, proposals }

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
