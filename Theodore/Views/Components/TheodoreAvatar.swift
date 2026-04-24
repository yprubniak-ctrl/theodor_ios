import SwiftUI

// The "T" avatar — navy rounded square, used in chat and bars
struct TheodoreAvatar: View {
    var size: CGFloat = 44
    var glowing: Bool = false  // kept for API compat

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.24)
            .fill(Color.theoNavy)
            .frame(width: size, height: size)
            .overlay {
                Text("T")
                    .font(.system(size: size * 0.50, weight: .bold, design: .serif))
                    .foregroundStyle(Color.theoParch)
            }
    }
}

// ── Chat message bubble ───────────────────────────────────────────

struct MessageBubble: View {
    let content: String
    let isUser: Bool

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if !isUser {
                TheodoreAvatar(size: 28)
            }

            Text(content)
                .font(isUser ? .theoBody : .theoPoem)
                .foregroundStyle(Color.theoNavy)
                .padding(.horizontal, 15)
                .padding(.vertical, 11)
                .background(
                    isUser
                        ? Color.theoNavy.opacity(0.08)
                        : Color.white.opacity(0.62),
                    in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(
                            isUser ? Color.theoNavy.opacity(0.10) : Color.white.opacity(0.80),
                            lineWidth: 1
                        )
                )
                .frame(maxWidth: 260, alignment: isUser ? .trailing : .leading)

            if isUser { Spacer(minLength: 0) }
        }
        .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
        .padding(.horizontal, 16)
    }
}

// ── Typing indicator (three gold pulsing dots) ────────────────────

struct TypingIndicator: View {
    @State private var phase: Int = 0

    var body: some View {
        HStack(spacing: 8) {
            TheodoreAvatar(size: 28)
            HStack(spacing: 5) {
                ForEach(0..<3) { i in
                    Circle()
                        .fill(Color.theoGold)
                        .frame(width: 5, height: 5)
                        .opacity(phase == i ? 0.9 : 0.25)
                        .scaleEffect(phase == i ? 1 : 0.7)
                }
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 14)
            .glassCard(cornerRadius: 18)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { _ in
                withAnimation(.easeInOut(duration: 0.4)) {
                    phase = (phase + 1) % 3
                }
            }
        }
    }
}
