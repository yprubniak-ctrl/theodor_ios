import SwiftUI
import SwiftData
import PhotosUI

struct TheodoreChatView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    var chapter: Chapter?

    @State private var viewModel     = TheodoreViewModel()
    @State private var inputText     = ""
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var showPhotoPicker = false
    @FocusState private var inputFocused: Bool

    private var messages: [ConversationMessage] { chapter?.messages ?? [] }
    private var isNewChapter: Bool { chapter == nil }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Parchment background
            LinearGradient(
                colors: [
                    Color(red: 0.961, green: 0.941, blue: 0.910),
                    Color(red: 0.902, green: 0.867, blue: 0.816),
                ],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // ── Header bar ────────────────────────────────
                TheodoreBar(
                    left: AnyView(
                        Button { dismiss() } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 11, weight: .medium))
                                Text("My Book")
                                    .font(.system(size: 13, weight: .regular))
                            }
                            .foregroundStyle(Color.theoMuted)
                        }
                    ),
                    center: AnyView(
                        Text("Theodore")
                            .font(.system(size: 15, weight: .bold, design: .serif))
                            .foregroundStyle(Color.theoNavy)
                    )
                )

                // ── Messages ──────────────────────────────────
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            if isNewChapter {
                                openingMessage
                            }

                            // Photo picker panel — shown before first user message
                            if messages.isEmpty {
                                photoPickerPanel
                                    .padding(.horizontal, 16)
                                    .padding(.bottom, 4)
                            }

                            ForEach(messages) { message in
                                MessageBubble(
                                    content: message.content,
                                    isUser: message.role == .user
                                )
                                .id(message.id)
                            }

                            if viewModel.isGenerating {
                                if viewModel.streamingText.isEmpty {
                                    TypingIndicator()
                                } else {
                                    draftCard(text: viewModel.streamingText)
                                        .padding(.horizontal, 16)
                                }
                            }
                        }
                        .padding(.vertical, 16)
                        .padding(.bottom, 100)
                    }
                    .onChange(of: viewModel.streamingText) {
                        proxy.scrollTo(messages.last?.id)
                    }
                }

                Spacer(minLength: 0)
            }

            // ── Input bar ─────────────────────────────────────
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color.theoNavy.opacity(0.06))
                    .frame(height: 1)
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
                            .foregroundStyle(
                                inputText.isEmpty ? Color.theoMuted : Color.theoParch
                            )
                            .frame(width: 44, height: 44)
                            .background(
                                inputText.isEmpty
                                    ? Color.theoNavy.opacity(0.12)
                                    : Color.theoNavy,
                                in: Circle()
                            )
                            .shadow(
                                color: inputText.isEmpty ? .clear : Color.theoNavy.opacity(0.25),
                                radius: 10, y: 2
                            )
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
    }

    // ── Sub-views ─────────────────────────────────────────────

    private var openingMessage: some View {
        MessageBubble(
            content: "You have new photos since we last spoke.\n\nWhat happened?",
            isUser: false
        )
    }

    private var photoPickerPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PHOTOS FROM THIS CHAPTER")
                .font(.theoLabel)
                .foregroundStyle(Color.theoBrown)
                .tracking(1.2)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(0..<5, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 9)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.867, green: 0.831, blue: 0.776),
                                        Color(red: 0.867, green: 0.831, blue: 0.776).opacity(0.6),
                                    ],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 54, height: 72)
                            .overlay(
                                RoundedRectangle(cornerRadius: 9)
                                    .stroke(Color.white.opacity(0.5), lineWidth: 1)
                            )
                    }
                    Button { showPhotoPicker = true } label: {
                        RoundedRectangle(cornerRadius: 9)
                            .fill(Color.theoNavy.opacity(0.04))
                            .frame(width: 54, height: 72)
                            .overlay(
                                RoundedRectangle(cornerRadius: 9)
                                    .stroke(Color.theoGold.opacity(0.4), lineWidth: 1.5, antialiased: true)
                            )
                            .overlay {
                                Image(systemName: "plus")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(Color.theoGold)
                            }
                    }
                }
            }

            Text("0 selected · Theodore can see these")
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(Color.theoMuted)
        }
        .padding(14)
        .glassCard(cornerRadius: 18)
    }

    private func draftCard(text: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                Rectangle()
                    .fill(Color.theoGold)
                    .frame(width: 2)
                    .cornerRadius(99)
                VStack(alignment: .leading, spacing: 10) {
                    Text("DRAFT")
                        .font(.theoLabel)
                        .foregroundStyle(Color.theoBrown)
                        .tracking(1.2)
                    Text(text)
                        .font(.system(size: 14, weight: .regular, design: .serif).italic())
                        .foregroundStyle(Color.theoNavy)
                        .lineSpacing(5)
                }
                Spacer()
            }
            .padding(16)
        }
        .glassCard(cornerRadius: 18)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.80), lineWidth: 1))
    }

    // ── Actions ───────────────────────────────────────────────

    private func sendMessage() {
        guard !inputText.isEmpty, let chapter else { return }
        let text = inputText
        inputText = ""
        Task {
            await viewModel.send(message: text, chapter: chapter, context: context)
        }
    }
}
