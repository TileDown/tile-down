import Foundation
import TileCore

#if canImport(CoreGraphics) && canImport(ImageIO)
    import CoreGraphics
    import ImageIO

    public extension TileKit.Image.PDFAssetConverter {
        static var isAvailable: Bool {
            true
        }

        @discardableResult
        func convertToJPEG(
            sourcePath: String,
            destinationPath: String,
        ) -> Bool {
            let sourceURL = URL(fileURLWithPath: sourcePath)
            guard let imageSource = CGImageSourceCreateWithURL(sourceURL as CFURL, nil),
                  let image = CGImageSourceCreateImageAtIndex(imageSource, 0, nil)
            else {
                return false
            }

            let destinationURL = URL(fileURLWithPath: destinationPath)
            do {
                try FileManager.default.createDirectory(
                    at: destinationURL.deletingLastPathComponent(),
                    withIntermediateDirectories: true,
                )
                if FileManager.default.fileExists(atPath: destinationPath) {
                    try FileManager.default.removeItem(at: destinationURL)
                }
            } catch {
                return false
            }

            guard let destination = CGImageDestinationCreateWithURL(
                destinationURL as CFURL,
                "public.jpeg" as CFString,
                1,
                nil,
            ) else {
                return false
            }

            let options = [
                kCGImageDestinationLossyCompressionQuality: 0.92,
            ] as CFDictionary
            CGImageDestinationAddImage(destination, image, options)
            guard CGImageDestinationFinalize(destination) else {
                try? FileManager.default.removeItem(at: destinationURL)
                return false
            }
            return true
        }
    }
#else
    public extension TileKit.Image.PDFAssetConverter {
        static var isAvailable: Bool {
            false
        }

        @discardableResult
        func convertToJPEG(
            sourcePath _: String,
            destinationPath _: String,
        ) -> Bool {
            false
        }
    }
#endif
