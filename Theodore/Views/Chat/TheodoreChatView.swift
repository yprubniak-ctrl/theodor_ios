import SwiftUI
import SwiftData
import PhotosUI

struct TheodoreChatView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dismiss) private var dismiss

    var chapter: Chapter?  // nil = new chapter flow

    @State private var viewModel = TheodoreViewModel()
    @State private var inputText: String = ""
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var showPhotoPicker = false
    @FocusState private var inputFocused: Bool

    private var messages: [ConversationMessage] { chapter?.messages ?? [] }
    private var isNewChapter: Bool { chapter == nil }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color.theoPaper(scheme).ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    chatHeader

                    Divider().overlay(Color.theoS2)

                    // Messages
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                if isNewChapter {
                                    openingMessage
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
                                        MessageBubble(
                                            content: viewModel.streamingText,
                                            isUser: false
                                        )
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

                // Input bar
                VStack(spacing: 0) {
                    Divider().overlay(Color.theoS2)
                    HStack(spacing: 10) {
                        Button { showPhotoPicker = true } label: {
                            Image(systemName: "photo")
                                .font(.system(size: 18))
                                .foregroundStyle(Color.theoMuted)
                        }
                        TextField("", text: $inputText, prompt:
                            Text("Tell Theodore what happened...")
                                .foregroundStyle(Color.theoMuted)
                                .font(.theoPoem)
                        )
                        .font(.theoBody)
                        .foregroundStyle(Color.theoText(scheme))
                        .focused($inputFocused)
                        .submitLabel(.send)
                        .onSubmit(sendMessage)

                        Button(action: sendMessage) {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(inputText.isEmpty ? Color.theoMuted : Color.theoCream)
                                .frame(width: 34, height: 34)
                                .background(
                                    inputText.isEmpty ? Color.theoS2 : Color.theoRed,
                                    in: Circle()
                                )
                        }
                        .disabled(inputText.isEmpty || viewModel.isGenerating)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.theoCard(scheme))
                }
            }
            .navigationBarHidden(true)
            .photosPicker(isPresented: $showPhotoPicker, selection: $selectedItems, matching: .images)
        }
    }

    // ── Sub-views ─────────────────────────────────────────────

    private var chatHeader: some View {
        HStack {
            Button { dismiss() } label: {
                Text("← My Book")
                    .font(.theoCaption)
                    .foregroundStyle(Color.theoMuted)
            }
            Spacer()
            VStack(spacing: 2) {
                TheodoreAvatar(size: 28)
                Text("Theodore")
                    .font(.system(size: 13, weight: .semibold, design: .serif))
                    .foregroundStyle(Color.theoText(scheme))
            }
            Spacer()
            Color.clear.frame(width: 60)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color.theoCard(scheme))
    }

    private var openingMessage: some View {
        MessageBubble(
            content: "You have new photos since we last spoke.\n\nWhat happened?",
            isUser: false
        )
    }

    // ── Actions ───────────────────────────────────────────────

    private func sendMessage() {
        guard !inputText.isEmpty, let chapter else {
            // New chapter flow — first create a chapter from context
            // then send the message
            return
        }
        let text = inputText
        inputText = ""
        Task {
            await viewModel.send(message: text, chapter: chapter, context: context)
        }
    }
}
