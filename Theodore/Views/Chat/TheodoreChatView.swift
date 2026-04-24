import SwiftUI
import SwiftData
import PhotosUI

struct TheodoreChatView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    var chapter: Chapter?

    @State private var viewModel       = TheodoreViewModel()
    @State private var inputText       = ""
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var showPhotoPicker = false
    @State private var finalDraft: String?
    @State private var showKeepSheet   = false
    @State private var draftAction: DraftAction?
    @FocusState private var inputFocused: Bool

    enum DraftAction { case keep, edit, rewrite }

    private var messages: [ConversationMessage] { chapter?.messages ?? [] }
    private var isNewChapter: Bool { chapter == nil }

    var body: some View {
        ZStack(alignment: .bottom) {
            parchBackground

            VStack(spacing: 0) {
                navBar

                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            if isNewChapter { openingMessage }

                            if messages.isEmpty {
                                photoPickerPanel
                                    .padding(.horizontal, 16)
                                    .padding(.bottom, 4)
                            }

                            // Persisted chapter messages
                            ForEach(messages) { message in
                                MessageBubble(content: message.content, isUser: message.role == .user)
                                    .id(message.id)
                            }
                            // Freeform (no chapter) messages
                            ForEach(viewModel.freeformMessages) { message in
                                MessageBubble(content: message.content, isUser: message.role == "user")
                                    .id(message.id)
                            }

                            if viewModel.isGenerating {
                                if viewModel.streamingText.isEmpty {
                                    TypingIndicator()
                                } else {
                                    draftCard(text: viewModel.streamingText, finalized: false)
                                        .padding(.horizontal, 16)
                                }
                            } else if let draft = finalDraft {
                                draftCard(text: draft, finalized: true)
                                    .padding(.horizontal, 16)
                            }
                        }
                        .padding(.vertical, 16)
                        .padding(.bottom, 120)
                    }
                    .onChange(of: viewModel.streamingText) {
                        if let id = messages.last?.id {
                            proxy.scrollTo(id)
                        } else if let id = viewModel.freeformMessages.last?.id {
                            proxy.scrollTo(id)
                        }
                    }
                    .onChange(of: viewModel.isGenerating) { _, generating in
                        if !generating, !viewModel.streamingText.isEmpty {
                            let txt = viewModel.streamingText
                            let isDraft = txt.contains("\n") && txt.replacingOccurrences(of: " ", with: "").count > 80
                            if isDraft { finalDraft = txt }
                        }
                    }
                }

                Spacer(minLength: 0)
            }

            // ── Input bar ─────────────────────────────────────
            VStack(spacing: 0) {
                Rectangle().fill(Color.theoNavy.opacity(0.06)).frame(height: 1)
                HStack(spacing: 8) {
                    Button { showPhotoPicker = true } label: {
                        Image(systemName: "photo")
                            .font(.system(size: 17))
                            .foregroundStyle(Color.theoMuted)
                    }
                    TextField("", text: $inputText, prompt:
                        Text("Tell Theodore what happened…")
                            .foregroundStyle(Color.theoMuted)
                            .font(.system(size: 13, weight: .regular, design: .serif).italic())
                    )
                    .font(.system(size: 13))
                    .foregroundStyle(Color.theoNavy)
                    .focused($inputFocused)
                    .submitLabel(.send)
                    .onSubmit(sendMessage)
                    .frame(height: 44)
                    .padding(.horizontal, 15)
                    .background(Color.white.opacity(0.62), in: Capsule())
                    .overlay(Capsule().stroke(Color.white.opacity(0.80), lineWidth: 1))

                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(inputText.isEmpty ? Color.theoMuted : Color.theoParch)
                            .frame(width: 44, height: 44)
                            .background(
                                inputText.isEmpty ? Color.theoNavy.opacity(0.12) : Color.theoNavy,
                                in: Circle()
                            )
                            .shadow(color: inputText.isEmpty ? .clear : Color.theoNavy.opacity(0.25),
                                    radius: 10, y: 2)
                    }
                    .disabled(inputText.isEmpty || viewModel.isGenerating)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.theoParch.opacity(0.9).background(.ultraThinMaterial))
            }
        }
        .navigationBarHidden(true)
        .photosPicker(isPresented: $showPhotoPicker, selection: $selectedItems, matching: .images)
        .sheet(isPresented: $showKeepSheet) {
            keepSheet
        }
    }

    // ── Nav bar ───────────────────────────────────────────────────

    private var navBar: some View {
        TheodoreBar(
            left: AnyView(
                Button { dismiss() } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 11, weight: .medium))
                        Text("My Book")
                            .font(.system(size: 13))
                    }
                    .foregroundStyle(Color.theoMuted)
                }
            ),
            center: AnyView(
                VStack(spacing: 2) {
                    TLogo(size: 26)
                    HStack(spacing: 4) {
                        Circle().fill(Color(red: 0.30, green: 0.69, blue: 0.31)).frame(width: 6, height: 6)
                        Text("Online").font(.system(size: 10)).foregroundStyle(Color.theoMuted)
                    }
                }
            )
        )
    }

    // ── Opening message ───────────────────────────────────────────

    private var openingMessage: some View {
        MessageBubble(content: "You have new photos since we last spoke.\n\nWhat happened?", isUser: false)
    }

    // ── Photo picker panel ────────────────────────────────────────

    private var photoPickerPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PHOTOS FROM THIS CHAPTER")
                .font(.theoLabel)
                .foregroundStyle(Color.theoBrown)
                .tracking(1.2)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(0..<5, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 9)
                            .fill(LinearGradient(
                                colors: [Color(red: 0.867, green: 0.831, blue: 0.776),
                                         Color(red: 0.867, green: 0.831, blue: 0.776).opacity(0.6)],
                                startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 54, height: 72)
                            .overlay(RoundedRectangle(cornerRadius: 9).stroke(Color.white.opacity(0.5), lineWidth: 1))
                    }
                    Button { showPhotoPicker = true } label: {
                        RoundedRectangle(cornerRadius: 9)
                            .fill(Color.theoNavy.opacity(0.04))
                            .frame(width: 54, height: 72)
                            .overlay(RoundedRectangle(cornerRadius: 9)
                                .stroke(Color.theoGold.opacity(0.4), lineWidth: 1.5))
                            .overlay {
                                Image(systemName: "plus").font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(Color.theoGold)
                            }
                    }
                }
            }
            Text("0 selected · Theodore can see these")
                .font(.system(size: 11)).foregroundStyle(Color.theoMuted)
        }
        .padding(14)
        .glassCard(cornerRadius: 18)
    }

    // ── Draft card ────────────────────────────────────────────────

    private func draftCard(text: String, finalized: Bool) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 99).fill(Color.theoGold).frame(width: 2)
                VStack(alignment: .leading, spacing: 10) {
                    Text(finalized ? "DRAFT" : "WRITING…")
                        .font(.theoLabel).foregroundStyle(Color.theoBrown).tracking(1.2)
                    Text(text)
                        .font(.system(size: 14, weight: .regular, design: .serif).italic())
                        .foregroundStyle(Color.theoNavy)
                        .lineSpacing(5)
                    if finalized {
                        draftActions
                            .padding(.top, 4)
                    }
                }
                Spacer()
            }
            .padding(16)
        }
        .glassCard(cornerRadius: 18)
    }

    // ── Keep / Edit / Rewrite segmented control ────────────────────

    private var draftActions: some View {
        HStack(spacing: 0) {
            ForEach(Array(["Keep", "Edit", "Rewrite"].enumerated()), id: \.offset) { i, label in
                Button {
                    handleDraftAction(label)
                } label: {
                    Text(label)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(i == 0 ? Color.theoParch : Color.theoBrown)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(
                            i == 0 ? Color.theoNavy : Color.clear,
                            in: segmentShape(index: i, total: 3)
                        )
                        .overlay(
                            segmentShape(index: i, total: 3)
                                .stroke(Color.theoBrown.opacity(0.20), lineWidth: i == 0 ? 0 : 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 9))
    }

    private func segmentShape(index: Int, total: Int) -> some Shape {
        UnevenRoundedRectangle(
            topLeadingRadius: index == 0 ? 9 : 0,
            bottomLeadingRadius: index == 0 ? 9 : 0,
            bottomTrailingRadius: index == total - 1 ? 9 : 0,
            topTrailingRadius: index == total - 1 ? 9 : 0
        )
    }

    private func handleDraftAction(_ action: String) {
        switch action {
        case "Keep":
            showKeepSheet = true
        case "Edit":
            if let draft = finalDraft {
                inputText = draft
                finalDraft = nil
                inputFocused = true
            }
        case "Rewrite":
            finalDraft = nil
            sendMessage()
        default:
            break
        }
    }

    // ── Keep sheet ────────────────────────────────────────────────

    private var keepSheet: some View {
        VStack(spacing: 0) {
            // Handle
            RoundedRectangle(cornerRadius: 99)
                .fill(Color.theoNavy.opacity(0.15))
                .frame(width: 36, height: 4)
                .padding(.top, 10)
                .padding(.bottom, 0)

            Text("Save to Library?")
                .font(.system(size: 18, weight: .bold, design: .serif))
                .foregroundStyle(Color.theoNavy)
                .padding(.vertical, 16)

            if let draft = finalDraft {
                Text(draft.components(separatedBy: "\n").prefix(3).joined(separator: "\n"))
                    .font(.system(size: 14, weight: .regular, design: .serif).italic())
                    .foregroundStyle(Color.theoSlate)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 28)
                    .padding(.bottom, 20)
            }

            VStack(spacing: 10) {
                PrimaryButton(title: "Save as new chapter") {
                    showKeepSheet = false
                    finalDraft = nil
                }
                Button("Keep editing") { showKeepSheet = false }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.theoBrown)
                    .padding(.bottom, 16)
            }
            .padding(.horizontal, 24)
        }
        .background(
            LinearGradient(
                colors: [Color(red: 0.961, green: 0.941, blue: 0.910),
                         Color(red: 0.929, green: 0.910, blue: 0.871)],
                startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
        )
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
    }

    // ── Background ────────────────────────────────────────────────

    private var parchBackground: some View {
        LinearGradient(
            colors: [Color(red: 0.961, green: 0.941, blue: 0.910),
                     Color(red: 0.902, green: 0.867, blue: 0.816)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    // ── Send ──────────────────────────────────────────────────────

    private func sendMessage() {
        guard !inputText.isEmpty else { return }
        let text = inputText
        inputText = ""
        finalDraft = nil
        Task {
            if let chapter {
                await viewModel.send(message: text, chapter: chapter, context: context)
            } else {
                await viewModel.sendFreeform(message: text)
            }
        }
    }
}
