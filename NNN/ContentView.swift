//
//  ContentView.swift
//  NNN
//
//  Created by John Zheng on 4/1/25.
//

import SwiftUI
import CoreML

struct ContentView: View {
    // State for image previews
    @State private var resizedPreviewImage: NSImage? = nil
    @State private var grayscalePreviewImage: NSImage? = nil

    // Reference to the DrawingView instance
    @State private var drawingView: DrawingView? = nil
    @State private var result: String = "Draw a number" // Updated initial text

    var body: some View {
        GeometryReader { geometry in
            // Main horizontal layout, align content to the top
            HStack(alignment: .top, spacing: 0) {

                // --- LEFT SIDE (2/3 width): Previews & Large result text ---
                VStack(alignment: .center) { // Center align items in this column
                    
                    // Previews for resized and grayscale images (Moved to top)
                    HStack(spacing: 30) {
                        // Resized (28x28) Preview
                        VStack {
                            Text("Resized:")
                                .font(.caption)
                            if let resized = resizedPreviewImage {
                                Image(nsImage: resized)
                                    .resizable()
                                    .interpolation(.none)
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 56, height: 56)
                            } else {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.1))
                                    .frame(width: 56, height: 56)
                            }
                        }
                        
                        // Grayscale Preview
                        VStack {
                            Text("Inverted:")
                                .font(.caption)
                            if let grayscale = grayscalePreviewImage {
                                Image(nsImage: grayscale)
                                    .resizable()
                                    .interpolation(.none)
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 56, height: 56)
                            } else {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.1))
                                    .frame(width: 56, height: 56)
                            }
                        }
                    }
                    .padding(.top) // Add padding above previews

                    // Large prediction text (Below previews)
                    Text(result)
                        .font(.system(size: 280, weight: .bold))
                        .minimumScaleFactor(0.3)
                        .lineLimit(1)
                        .padding(.vertical) // Add some vertical padding

                    Spacer() // Push content towards top
                }
                .frame(width: geometry.size.width * 2/3, height: geometry.size.height) // Take 2/3 width
                .padding(.horizontal) // Add horizontal padding

                // --- RIGHT SIDE (1/3 width): Full-height drawing area ---
                // No extra VStack needed here if DrawingViewRepresentable fills space
                DrawingViewRepresentable(
                    onCreate: { view in
                        self.drawingView = view
                    },
                    onDrawingChanged: {
                        classifyDrawing()
                    }
                )
                .border(Color.gray, width: 1)
                .clipped()
                // Use the remaining width and full height
                .frame(width: geometry.size.width / 3, height: geometry.size.height)

            }
        }
        // Apply a background color to easily see frame boundaries if needed
        // .background(Color.red.opacity(0.1))
    }

    // MARK: - Classification Logic
    func classifyDrawing() {
        guard let drawingView = drawingView,
              let snapshot = drawingView.snapshot() else {
            DispatchQueue.main.async {
                self.resizedPreviewImage = nil
                self.grayscalePreviewImage = nil
                result = "Error"
            }
            print("Error: Snapshot is nil.")
            return
        }
        print("Snapshot captured.")

        guard let resizedImage = snapshot.resized(to: NSSize(width: 28, height: 28)) else {
            DispatchQueue.main.async {
                self.resizedPreviewImage = nil
                self.grayscalePreviewImage = nil
                result = "Error"
            }
            print("Error: Failed to resize image.")
            return
        }
        print("Image resized to 28x28.")

        // Update resized preview
        DispatchQueue.main.async {
            self.resizedPreviewImage = resizedImage
        }

        guard let pixelBuffer = resizedImage.toGrayScalePixelBuffer() else {
            DispatchQueue.main.async {
                result = "Error"
                self.grayscalePreviewImage = nil
            }
            print("Error: Pixel buffer conversion failed.")
            return
        }
        print("Pixel buffer created.")

        // Update grayscale preview
        DispatchQueue.main.async {
            self.grayscalePreviewImage = imageFromPixelBuffer(pixelBuffer)
        }

        do {
            let config = MLModelConfiguration()
            let model = try MNISTClassifier(configuration: config)
            let prediction = try model.prediction(image: pixelBuffer)
            DispatchQueue.main.async {
                result = "\(prediction.classLabel)"
            }
            print("Prediction: \(prediction.classLabel)")
        } catch {
            DispatchQueue.main.async {
                result = "Error"
            }
            print("Prediction error: \(error)")
        }
    }
}

// MARK: - NSImage Extension
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
}

// Helper function to convert CVPixelBuffer to NSImage
func imageFromPixelBuffer(_ pixelBuffer: CVPixelBuffer) -> NSImage? {
    CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
    defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

    guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else {
        print("Error: Could not get pixel buffer base address.")
        return nil
    }

    let width = CVPixelBufferGetWidth(pixelBuffer)
    let height = CVPixelBufferGetHeight(pixelBuffer)
    let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
    let colorSpace = CGColorSpaceCreateDeviceGray()
    let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)

    guard let context = CGContext(data: baseAddress,
                                  width: width,
                                  height: height,
                                  bitsPerComponent: 8,
                                  bytesPerRow: bytesPerRow,
                                  space: colorSpace,
                                  bitmapInfo: bitmapInfo.rawValue) else {
        print("Error: Could not create CGContext from pixel buffer.")
        return nil
    }

    guard let cgImage = context.makeImage() else {
        print("Error: Could not create CGImage from context.")
        return nil
    }

    return NSImage(cgImage: cgImage, size: NSSize(width: width, height: height))
}

#Preview {
    ContentView()
}
