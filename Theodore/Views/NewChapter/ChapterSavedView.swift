import SwiftUI

struct ChapterSavedView: View {
    let chapterTitle: String
    let onViewInLibrary: () -> Void
    let onShare: () -> Void

    var body: some View {
        ZStack {
            parchBackground
            VStack(spacing: 0) {
                Spacer()
                VStack(spacing: 0) {
                    // Gold checkmark
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.theoGold.opacity(0.10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.theoGold.opacity(0.25), lineWidth: 1)
                            )
                        Image(systemName: "checkmark")
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundStyle(Color.theoGold)
                    }
                    .frame(width: 64, height: 64)
                    .padding(.bottom, 22)

                    Text("Chapter saved")
                        .font(.system(size: 24, weight: .bold, design: .serif))
                        .foregroundStyle(Color.theoNavy)
                        .padding(.bottom, 8)

                    GoldLine()
                        .padding(.bottom, 18)

                    Text("\"you went back like it still held something of yours.\nmaybe it did.\"")
                        .font(.system(size: 15, weight: .regular, design: .serif))
                        .italic()
                        .foregroundStyle(Color.theoSlate)
                        .multilineTextAlignment(.center)
                        .lineSpacing(5)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 12)

                    Text("New chapter · just now")
                        .font(.system(size: 11, weight: .regular, design: .serif))
                        .foregroundStyle(Color.theoMuted)
                        .padding(.bottom, 32)

                    PrimaryButton(title: "View in Library", action: onViewInLibrary)
                        .padding(.horizontal, 36)
                        .padding(.bottom, 14)

                    Button("Share this chapter", action: onShare)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.theoBrown)
                }
                .multilineTextAlignment(.center)
                Spacer()
            }
        }
    }

    private var parchBackground: some View {
        LinearGradient(
            colors: [Color(red: 0.961, green: 0.941, blue: 0.910),
                     Color(red: 0.929, green: 0.910, blue: 0.871),
                     Color(red: 0.902, green: 0.867, blue: 0.816)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}
