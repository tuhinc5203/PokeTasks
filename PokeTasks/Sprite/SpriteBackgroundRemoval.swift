import CoreGraphics

enum SpriteBackgroundRemoval {
    private static let nearWhiteThreshold: UInt8 = 239 // 255 - 16 tolerance

    static func removingBackground(from image: CGImage) -> CGImage {
        let width = image.width
        let height = image.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!

        return pixels.withUnsafeMutableBytes { buffer -> CGImage in
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
                return image
            }

            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
            floodFillBackground(baseAddress.assumingMemoryBound(to: UInt8.self), width: width, height: height)
            return context.makeImage() ?? image
        }
    }

    private static func floodFillBackground(_ pixels: UnsafeMutablePointer<UInt8>, width: Int, height: Int) {
        var visited = [Bool](repeating: false, count: width * height)
        var queue: [Int] = []

        func isNearWhite(_ pixelIndex: Int) -> Bool {
            let offset = pixelIndex * 4
            return pixels[offset] >= nearWhiteThreshold
                && pixels[offset + 1] >= nearWhiteThreshold
                && pixels[offset + 2] >= nearWhiteThreshold
        }

        for x in 0..<width {
            for y in [0, height - 1] {
                let i = y * width + x
                if isNearWhite(i) { queue.append(i) }
            }
        }
        for y in 0..<height {
            for x in [0, width - 1] {
                let i = y * width + x
                if isNearWhite(i) { queue.append(i) }
            }
        }

        var head = 0
        while head < queue.count {
            let current = queue[head]
            head += 1
            if visited[current] { continue }
            visited[current] = true

            let offset = current * 4
            pixels[offset] = 0
            pixels[offset + 1] = 0
            pixels[offset + 2] = 0
            pixels[offset + 3] = 0

            let x = current % width
            let y = current / width
            for (nx, ny) in [(x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)] {
                guard nx >= 0, nx < width, ny >= 0, ny < height else { continue }
                let neighborIndex = ny * width + nx
                if !visited[neighborIndex] && isNearWhite(neighborIndex) {
                    queue.append(neighborIndex)
                }
            }
        }
    }
}
