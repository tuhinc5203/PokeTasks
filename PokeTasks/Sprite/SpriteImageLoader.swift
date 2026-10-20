import AppKit
import CoreGraphics
import ImageIO
import os

enum SpriteSubdirectory: String {
    case root = "Assets/Sprites"
    case gen1 = "Assets/Sprites/Gen_1"
}

final class SpriteImageLoader {
    static let shared = SpriteImageLoader()

    private let logger = Logger(subsystem: "com.poketasks.app", category: "SpriteLoader")
    private var cachedMenuBarIcon: NSImage?
    private var cachedPetSprites: [String: NSImage] = [:]

    private init() {}

    func loadMenuBarIcon() -> NSImage {
        if let cachedMenuBarIcon { return cachedMenuBarIcon }

        let sourceImage = loadPNGCGImage(named: "pokeball2", in: .root) ?? placeholderCGImage()
        let icon = TemplateIconRenderer.makeTemplateIcon(from: sourceImage, pointSize: 18)
        cachedMenuBarIcon = icon
        return icon
    }

    func loadSprite(named resourceName: String, in subdirectory: SpriteSubdirectory) -> NSImage {
        let cacheKey = "\(subdirectory.rawValue)/\(resourceName)"
        if let cached = cachedPetSprites[cacheKey] { return cached }

        let sourceImage = loadPNGCGImage(named: resourceName, in: subdirectory) ?? placeholderCGImage()
        let cleanedImage = SpriteBackgroundRemoval.removingBackground(from: sourceImage)
        let sprite = NSImage(cgImage: cleanedImage, size: NSSize(width: cleanedImage.width, height: cleanedImage.height))
        cachedPetSprites[cacheKey] = sprite
        return sprite
    }

    private func loadPNGCGImage(named resourceName: String, in subdirectory: SpriteSubdirectory) -> CGImage? {
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: "png", subdirectory: subdirectory.rawValue) else {
            logger.error("\(resourceName).png not found at \(subdirectory.rawValue) in the app bundle — using placeholder sprite")
            return nil
        }
        guard let data = try? Data(contentsOf: url),
              let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            logger.error("\(resourceName).png could not be decoded — using placeholder sprite")
            return nil
        }
        return image
    }

    private func placeholderCGImage() -> CGImage {
        let size = 56
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        var pixels = [UInt8](repeating: 0, count: size * size * 4)
        for pixelIndex in 0..<(size * size) {
            let offset = pixelIndex * 4
            pixels[offset] = 142
            pixels[offset + 1] = 142
            pixels[offset + 2] = 147
            pixels[offset + 3] = 255
        }
        return pixels.withUnsafeMutableBytes { buffer -> CGImage in
            let context = CGContext(
                data: buffer.baseAddress,
                width: size,
                height: size,
                bitsPerComponent: 8,
                bytesPerRow: size * 4,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )!
            return context.makeImage()!
        }
    }
}
