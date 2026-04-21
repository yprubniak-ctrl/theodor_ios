import SwiftUI
import Photos

// ── MARK: AsyncPhotoView ──────────────────────────────────────────
// Drop-in replacement for Rectangle() photo placeholders.
// Loads a PHAsset by localIdentifier, shows a shimmer while loading.

struct AsyncPhotoView: View {
    let assetID: String
    var contentMode: ContentMode = .fill

    @State private var image: UIImage?
    @State private var phase: LoadPhase = .idle

    enum LoadPhase { case idle, loading, loaded, failed }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                switch phase {
                case .idle, .loading:
                    ShimmerRect()

                case .loaded:
                    if let image {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: contentMode)
                            .frame(width: geo.size.width, height: geo.size.height)
                            .clipped()
                            .transition(.opacity.animation(.easeIn(duration: 0.25)))
                    }

                case .failed:
                    Color.theoS2
                    Image(systemName: "photo")
                        .font(.system(size: 28))
                        .foregroundStyle(Color.theoMuted)
                }
            }
        }
        .task(id: assetID) {
            await load()
        }
    }

    // ── Async load ────────────────────────────────────────────

    @MainActor
    private func load() async {
        guard !assetID.isEmpty else { phase = .failed; return }
        phase = .loading
        image = nil

        let result = PHAsset.fetchAssets(withLocalIdentifiers: [assetID], options: nil)
        guard let asset = result.firstObject else { phase = .failed; return }

        let scale = await UIScreen.main.scale
        let targetSize = CGSize(width: 800 * scale, height: 800 * scale)

        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat   // single callback
        options.isNetworkAccessAllowed = true
        options.isSynchronous = false

        let loaded: UIImage? = await withCheckedContinuation { continuation in
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFill,
                options: options
            ) { img, _ in
                continuation.resume(returning: img)
            }
        }

        if let loaded {
            image = loaded
            phase = .loaded
        } else {
            phase = .failed
        }
    }
}

// ── MARK: PhotoThumbnail ──────────────────────────────────────────
// Compact square thumbnail — use in chapter cards, grids, chat.

struct PhotoThumbnail: View {
    let assetID: String
    var size: CGFloat = 80
    var cornerRadius: CGFloat = 8

    var body: some View {
        AsyncPhotoView(assetID: assetID, contentMode: .fill)
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

// ── MARK: CoverPhotoView ──────────────────────────────────────────
// Full-bleed header image with a gradient overlay for text legibility.

struct CoverPhotoView: View {
    let assetID: String
    var height: CGFloat = 240

    var body: some View {
        AsyncPhotoView(assetID: assetID, contentMode: .fill)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .overlay {
                LinearGradient(
                    colors: [.clear, .black.opacity(0.6)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .clipped()
    }
}

// ── MARK: ShimmerRect ─────────────────────────────────────────────
// Animated loading placeholder.

private struct ShimmerRect: View {
    @State private var phase: CGFloat = 0

    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    stops: [
                        .init(color: Color.theoS2, location: phase - 0.3),
                        .init(color: Color.theoS3, location: phase),
                        .init(color: Color.theoS2, location: phase + 0.3)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .onAppear {
                withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
                    phase = 1.3
                }
            }
    }
}
