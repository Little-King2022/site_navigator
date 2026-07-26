//
//  ImageProcessing.swift
//  site_navigator
//

import UIKit

nonisolated enum ImageProcessing {
    /// Decodes `data` as an image, scales it down so its largest dimension is
    /// at most `maxDimension`, and re-encodes it. Used both for auto-fetched
    /// favicons and for photos manually picked from the library, so stored
    /// icons never bloat the SwiftData store.
    static func resizedAndCompressed(_ data: Data, maxDimension: CGFloat = 128) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        return resizedAndCompressed(image, maxDimension: maxDimension)
    }

    static func resizedAndCompressed(_ image: UIImage, maxDimension: CGFloat = 128) -> Data? {
        let size = image.size
        guard size.width > 0, size.height > 0 else { return nil }

        let scale = min(1, maxDimension / max(size.width, size.height))
        let targetSize = CGSize(width: size.width * scale, height: size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        return resized.pngData() ?? resized.jpegData(compressionQuality: 0.85)
    }
}
