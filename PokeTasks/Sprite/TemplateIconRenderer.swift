import AppKit
import CoreGraphics

enum TemplateIconRenderer {
    static func makeTemplateIcon(from image: CGImage, pointSize: CGFloat) -> NSImage {
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        let width = image.width
        let height = image.height
        var sourcePixels = [UInt8](repeating: 0, count: width * height * 4)

        let silhouette: CGImage? = sourcePixels.withUnsafeMutableBytes { buffer -> CGImage? in
            guard let baseAddress = buffer.baseAddress,
                  let context = CGContext(
                    data: baseAddress,
                    width: width,
                    height: height,
                    bitsPerComponent: 8,
                    bytesPerRow: width * 4,
                    space: colorSpace,
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                  )
            else {
                return nil
            }
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

            // A pixel becomes ink only if it's both opaque and dark. Line-art icons
            // (e.g. a pokeball outline) have fully-opaque light interior regions
            // enclosed by the linework — those need to read as holes, not ink, so
            // alpha alone isn't a reliable "is this part of the shape" signal here.
            let pixels = baseAddress.assumingMemoryBound(to: UInt8.self)
            for pixelIndex in 0..<(width * height) {
                let offset = pixelIndex * 4
                let isOpaque = pixels[offset + 3] > 0
                let isDark = pixels[offset] < 128 && pixels[offset + 1] < 128 && pixels[offset + 2] < 128
                let isInk = isOpaque && isDark
                pixels[offset] = 0
                pixels[offset + 1] = 0
                pixels[offset + 2] = 0
                pixels[offset + 3] = isInk ? 255 : 0
            }
            return context.makeImage()
        }

        guard let silhouette else {
            return placeholderTemplate(pointSize: pointSize)
        }

        let pixelSize = Int(pointSize * 2) // @2x
        var scaledPixels = [UInt8](repeating: 0, count: pixelSize * pixelSize * 4)

        let scaledImage: CGImage? = scaledPixels.withUnsafeMutableBytes { buffer -> CGImage? in
            guard let baseAddress = buffer.baseAddress,
                  let context = CGContext(
                    data: baseAddress,
                    width: pixelSize,
                    height: pixelSize,
                    bitsPerComponent: 8,
                    bytesPerRow: pixelSize * 4,
                    space: colorSpace,
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                  )
            else {
                return nil
            }
            context.interpolationQuality = .high
            context.draw(silhouette, in: CGRect(x: 0, y: 0, width: pixelSize, height: pixelSize))
            return context.makeImage()
        }

        guard let scaledImage else {
            return placeholderTemplate(pointSize: pointSize)
        }

        let templateImage = NSImage(cgImage: scaledImage, size: NSSize(width: pointSize, height: pointSize))
        templateImage.isTemplate = true
        return templateImage
    }

    private static func placeholderTemplate(pointSize: CGFloat) -> NSImage {
        let image = NSImage(size: NSSize(width: pointSize, height: pointSize))
        image.isTemplate = true
        return image
    }
}
