//
//  DrawingView.swift
//  NNN
//
//  Created by John Zheng on 4/1/25.
//

import Cocoa

class DrawingView: NSView {
    var onDrawingChanged: (() -> Void)?
    private var path = NSBezierPath()

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        path = NSBezierPath()
        path.move(to: point)
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        path.line(to: point)
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        NSColor.white.setFill()
        dirtyRect.fill()

        NSColor.black.setStroke()
        path.lineWidth = 15.0  // Adjust stroke width as needed
        path.stroke()
    }
    
    override func mouseUp(with event: NSEvent) {
        onDrawingChanged?()
    }

    /// Capture the current drawing as an NSImage.
    func snapshot() -> NSImage? {
        let image = NSImage(size: bounds.size)
        image.lockFocus()
        draw(bounds)
        image.unlockFocus()
        return image
    }
}

extension NSImage {
    /// Convert the image to a grayscale CVPixelBuffer.
    /// - Parameters:
    ///   - applyThreshold: If true, apply a binary threshold to the pixel values.
    ///   - threshold: The threshold value (0...255) used when applyThreshold is true.
    func toGrayScalePixelBuffer(applyThreshold: Bool = false, threshold: UInt8 = 128) -> CVPixelBuffer? {
        let attrs: [CFString: Any] = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true
        ]
        var pixelBuffer: CVPixelBuffer?
        let width = Int(self.size.width)
        let height = Int(self.size.height)
        let status = CVPixelBufferCreate(kCFAllocatorDefault, width, height,
                                         kCVPixelFormatType_OneComponent8,
                                         attrs as CFDictionary, &pixelBuffer)
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else { return nil }
    
        CVPixelBufferLockBaseAddress(buffer, [])
        let context = CGContext(data: CVPixelBufferGetBaseAddress(buffer),
                                width: width,
                                height: height,
                                bitsPerComponent: 8,
                                bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                                space: CGColorSpaceCreateDeviceGray(),
                                bitmapInfo: 0)
        guard let cgContext = context else {
            CVPixelBufferUnlockBaseAddress(buffer, [])
            return nil
        }
        if let cgImage = self.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            // Draw the original image into the context.
            cgContext.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
            
            // Apply either thresholding or manual inversion.
            if let baseAddress = CVPixelBufferGetBaseAddress(buffer) {
                let bytesPerRow = CVPixelBufferGetBytesPerRow(buffer)
                let pixelData = baseAddress.assumingMemoryBound(to: UInt8.self)
                
                for y in 0..<height {
                    for x in 0..<width {
                        let pixelIndex = y * bytesPerRow + x
                        if applyThreshold {
                            // Set pixel to 0 if below threshold, else 255.
                            pixelData[pixelIndex] = pixelData[pixelIndex] < threshold ? 0 : 255
                        } else {
                            // Manual inversion: convert pixel to 255 - pixel.
                            pixelData[pixelIndex] = 255 - pixelData[pixelIndex]
                        }
                    }
                }
                if applyThreshold {
                    print("Threshold applied with threshold \(threshold).")
                } else {
                    print("Manual pixel inversion applied.")
                }
            } else {
                print("Error: Could not get base address for pixel processing.")
            }
        }
        CVPixelBufferUnlockBaseAddress(buffer, [])
        return buffer
    }
}
