import SwiftUI

struct TheodoreAvatar: View {
    var size: CGFloat = 44
    var glowing: Bool = false

    var body: some View {
        ZStack {
            if glowing {
                Circle()
                    .fill(Color.theoRed.opacity(0.15))
                    .frame(width: size + 10, height: size + 10)
            }
            Circle()
                .fill(Color.theoSurface)
                .frame(width: size, height: size)
            Circle()
                .fill(Color.theoS2)
                .frame(width: size - 6, height: size - 6)
            Text("T")
                .font(.system(size: size * 0.38, weight: .semibold, design: .serif))
                .foregroundStyle(Color.theoAmber)
        }
    }
}

struct MessageBubble: View {
    let content: String
    let isUser: Bool
    @Environment(\.colorScheme) var scheme

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if \!isUser {
                TheodoreAvatar(size: 28)
            }

            Text(isUser ? content : content)
                .font(isUser ? .theoBody : .theoPoem)
                .foregroundStyle(Color.theoText(scheme))
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(isUser
                              ? Color.theoRed.opacity(0.12)
                              : Color.theoCard(scheme))
                )
                .frame(maxWidth: 280, alignment: isUser ? .trailing : .leading)

            if isUser { Spacer(minLength: 0) }
        }
        .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
        .padding(.horizontal, 16)
    }
}

struct TypingIndicator: View {
    @State private var phase: Int = 0

    var body: some View {
        HStack(spacing: 4) {
            TheodoreAvatar(size: 28)
            HStack(spacing: 5) {
                ForEach(0..<3) { i in
                    Circle()
                        .fill(Color.theoAmber)
                        .frame(width: 7, height: 7)
                        .opacity(phase == i ? 1.0 : 0.3)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.theoSurface)
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5).repeatForever()) {
                Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                    phase = (phase + 1) % 3
                }
            }
        }
    }
}
