import Photos
import UIKit

/// Handles all PhotoKit interactions — permissions, fetching, thumbnails.
@MainActor
final class PhotoLibraryService: ObservableObject {

    @Published var authorizationStatus: PHAuthorizationStatus = .notDetermined

    // ── MARK: Authorization ───────────────────────────────────

    func requestAccess() async -> Bool {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        authorizationStatus = status
        return status == .authorized || status == .limited
    }

    func checkCurrentStatus() {
        authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }

    var isAuthorized: Bool {
        authorizationStatus == .authorized || authorizationStatus == .limited
    }

    // ── MARK: Fetch All Photos ────────────────────────────────

    /// Returns all photos sorted by creation date, newest last.
    func fetchAllPhotos() -> PHFetchResult<PHAsset> {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        options.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        return PHAsset.fetchAssets(with: options)
    }

    /// Fetch specific assets by their local identifiers.
    func fetchAssets(ids: [String]) -> [PHAsset] {
        let result = PHAsset.fetchAssets(withLocalIdentifiers: ids, options: nil)
        var assets: [PHAsset] = []
        result.enumerateObjects { asset, _, _ in
            assets.append(asset)
        }
        return assets
    }

    // ── MARK: Thumbnails ──────────────────────────────────────

    private let imageManager = PHCachingImageManager()

    /// Request a thumbnail image for a given asset.
    func thumbnail(for asset: PHAsset, size: CGSize = CGSize(width: 200, height: 200)) async -> UIImage? {
        await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .opportunistic
            options.isNetworkAccessAllowed = true
            options.isSynchronous = false

            imageManager.requestImage(
                for: asset,
                targetSize: size,
                contentMode: .aspectFill,
                options: options
            ) { image, _ in
                continuation.resume(returning: image)
            }
        }
    }

    /// Request full resolution image — used before sending to Claude.
    func fullImage(for asset: PHAsset, maxSize: CGFloat = 1024) async -> UIImage? {
        let targetSize = CGSize(width: maxSize, height: maxSize)
        return await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true
            options.isSynchronous = false

            imageManager.requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFit,
                options: options
            ) { image, _ in
                continuation.resume(returning: image)
            }
        }
    }

    /// Convert UIImage to base64 string for Claude Vision API.
    func base64(for asset: PHAsset) async -> String? {
        guard let image = await fullImage(for: asset),
              let jpeg = image.jpegData(compressionQuality: 0.7) else { return nil }
        return jpeg.base64EncodedString()
    }

    // ── MARK: Metadata ────────────────────────────────────────

    struct AssetMetadata {
        let assetID: String
        let date: Date
        let location: CLLocation?
        let locationName: String?
    }

    func metadata(for asset: PHAsset) -> AssetMetadata {
        AssetMetadata(
            assetID: asset.localIdentifier,
            date: asset.creationDate ?? .now,
            location: asset.location,
            locationName: nil  // populated by ClusteringService via reverse geocoding
        )
    }
}
