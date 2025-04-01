//
//  ContentView.swift
//  NNN
//
//  Created by John Zheng on 4/1/25.
//

import SwiftUI
import CoreML

struct ContentView: View {
    // Store a reference to the DrawingView instance.
    @State private var drawingView: DrawingView? = nil
    @State private var result: String = "Draw a number"

    var body: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading) {
                Text(result)
                    .font(.headline)
                    .padding()
                Spacer()
            }
            .frame(minWidth: 100, maxWidth: .infinity, alignment: .leading)
        
            // Embed the DrawingView using our representable.
            DrawingViewRepresentable(
                onCreate: { view in
                    self.drawingView = view
                },
                onDrawingChanged: {
                    classifyDrawing()
                }
            )
            .frame(width: 300, height: 300)
            .border(Color.gray, width: 1)
            .clipped()
        }
        .padding()
    }

    func classifyDrawing() {
        guard let drawingView = drawingView,
              let snapshot = drawingView.snapshot() else {
            DispatchQueue.main.async {
                result = "Error: No snapshot captured."
            }
            print("Error: Snapshot is nil.")
            return
        }
        print("Snapshot captured.")
        
        guard let resizedImage = snapshot.resized(to: NSSize(width: 28, height: 28)) else {
            DispatchQueue.main.async {
                result = "Error: Resized image is nil."
            }
            print("Error: Failed to resize image.")
            return
        }
        print("Image resized to 28x28.")
        
        guard let pixelBuffer = resizedImage.toGrayScalePixelBuffer() else {
            DispatchQueue.main.async {
                result = "Error: Failed to convert image to pixel buffer."
            }
            print("Error: Pixel buffer conversion failed.")
            return
        }
        print("Pixel buffer created.")
        
        do {
            let config = MLModelConfiguration()
//            config.computeUnits = .cpuOnly  // Ensuring CPU-only mode
            let model = try MNISTClassifier(configuration: config)
            let prediction = try model.prediction(image: pixelBuffer)
            DispatchQueue.main.async {
                result = "\(prediction.classLabel)"
            }
            print("Prediction: \(prediction.classLabel)")
        } catch {
            DispatchQueue.main.async {
                result = "Prediction error: \(error.localizedDescription)"
            }
            print("Prediction error: \(error)")
        }
    }
}

#Preview {
    ContentView()
}
