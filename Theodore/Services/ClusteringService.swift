import Photos
import CoreLocation

/// Groups a flat list of photos into meaningful time clusters.
/// Each cluster becomes a chapter proposal candidate.
final class ClusteringService {

    // ── Configuration ─────────────────────────────────────────
    /// Photos within this many days of each other stay in the same cluster
    private let gapThresholdDays: Double = 5
    /// Clusters with fewer photos than this get merged into adjacent clusters
    private let minClusterSize: Int = 3
    /// Maximum photos to send to Claude per cluster (to control API cost)
    private let maxPhotosPerCluster: Int = 8

    // ── MARK: Main Clustering ─────────────────────────────────

    func cluster(fetchResult: PHFetchResult<PHAsset>) async -> [PhotoCluster] {
        // 1. Extract assets into sortable structs
        var assets: [(id: String, date: Date, location: CLLocation?)] = []
        fetchResult.enumerateObjects { asset, _, _ in
            assets.append((
                id: asset.localIdentifier,
                date: asset.creationDate ?? .distantPast,
                location: asset.location
            ))
        }

        // Sort by date (should already be sorted, but ensure)
        assets.sort { $0.date < $1.date }

        // 2. Split on time gaps
        var rawClusters: [[( id: String, date: Date, location: CLLocation?)]] = []
        var current: [(id: String, date: Date, location: CLLocation?)] = []

        for asset in assets {
            if let last = current.last {
                let gap = asset.date.timeIntervalSince(last.date) / 86400 // days
                if gap > gapThresholdDays {
                    rawClusters.append(current)
                    current = []
                }
            }
            current.append(asset)
        }
        if \!current.isEmpty { rawClusters.append(current) }

        // 3. Merge small clusters
        let merged = mergSmallClusters(rawClusters)

        // 4. Reverse geocode dominant locations
        var result: [PhotoCluster] = []
        for cluster in merged {
            let location = await dominantLocationName(for: cluster)
            let dateRange = dateRangeString(for: cluster)
            let representativeIDs = selectRepresentative(from: cluster)

            result.append(PhotoCluster(
                dateRange: dateRange,
                count: cluster.count,
                dominantLocation: location,
                assetIDs: cluster.map(\.id),
                representativeAssetIDs: representativeIDs
            ))
        }

        return result
    }

    // ── MARK: Helpers ─────────────────────────────────────────

    private func mergSmallClusters(
        _ clusters: [[(id: String, date: Date, location: CLLocation?)]]
    ) -> [[(id: String, date: Date, location: CLLocation?)]] {
        var result: [[(id: String, date: Date, location: CLLocation?)]] = []

        for cluster in clusters {
            if cluster.count < minClusterSize, \!result.isEmpty {
                // Merge into previous cluster
                result[result.count - 1].append(contentsOf: cluster)
            } else {
                result.append(cluster)
            }
        }
        return result
    }

    /// Pick evenly-spaced representative photos from a cluster for API analysis.
    private func selectRepresentative(
        from cluster: [(id: String, date: Date, location: CLLocation?)]
    ) -> [String] {
        guard cluster.count > maxPhotosPerCluster else {
            return cluster.map(\.id)
        }
        let step = Double(cluster.count) / Double(maxPhotosPerCluster)
        return (0..<maxPhotosPerCluster).map { i in
            cluster[Int(Double(i) * step)].id
        }
    }

    /// Format a human-readable date range.
    private func dateRangeString(
        for cluster: [(id: String, date: Date, location: CLLocation?)]
    ) -> String {
        guard let first = cluster.first?.date, let last = cluster.last?.date else { return "" }
        let formatter = DateFormatter()

        let calendar = Calendar.current
        if calendar.isDate(first, inSameDayAs: last) {
            formatter.dateStyle = .medium
            return formatter.string(from: first)
        } else if calendar.component(.year, from: first) == calendar.component(.year, from: last) {
            formatter.dateFormat = "MMM d"
            return "\(formatter.string(from: first)) — \(formatter.string(from: last)), \(calendar.component(.year, from: first))"
        } else {
            formatter.dateFormat = "MMM yyyy"
            return "\(formatter.string(from: first)) — \(formatter.string(from: last))"
        }
    }

    /// Reverse geocode the most common location in a cluster.
    private func dominantLocationName(
        for cluster: [(id: String, date: Date, location: CLLocation?)]
    ) async -> String? {
        let locations = cluster.compactMap(\.location)
        guard let location = locations.first else { return nil }

        return await withCheckedContinuation { continuation in
            CLGeocoder().reverseGeocodeLocation(location) { placemarks, _ in
                let name = placemarks?.first?.locality
                    ?? placemarks?.first?.administrativeArea
                continuation.resume(returning: name)
            }
        }
    }
}
