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
    /// Resize the image to a new size.
    func resized(to newSize: NSSize) -> NSImage? {
        let img = NSImage(size: newSize)
        img.lockFocus()
        let rect = NSRect(origin: .zero, size: newSize)
        self.draw(in: rect, from: NSRect(origin: .zero, size: self.size), operation: .copy, fraction: 1.0)
        img.unlockFocus()
        return img
    }
    
    /// Convert the image to a grayscale CVPixelBuffer.
    func toGrayScalePixelBuffer() -> CVPixelBuffer? {
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
            cgContext.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        }
        CVPixelBufferUnlockBaseAddress(buffer, [])
        return buffer
    }
}
