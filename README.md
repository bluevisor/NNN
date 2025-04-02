# NNN (Number Neural Network)

NNN is a simple macOS application demonstrating real-time handwritten digit recognition using a Core ML model trained on the MNIST dataset. Users can draw a digit (0-9) in the provided canvas, and the application will predict the digit in real-time.

<img width="1012" alt="image" src="https://github.com/user-attachments/assets/90b9fe95-0fc0-4f18-9edc-c688c976b208" />


## Features

*   **Real-time Drawing:** A dedicated canvas allows users to draw digits using a mouse or trackpad.
*   **Live Prediction:** The application continuously processes the drawing and updates the predicted digit as the user draws.
*   **MNIST Classification:** Utilizes a pre-trained Core ML model (`MNISTClassifier.mlpackage`) based on the well-known MNIST dataset for digit recognition.
*   **Preprocessing Visualization:** Displays intermediate steps of the image processing pipeline:
    *   The drawing resized to 28x28 pixels.
    *   The 28x28 image converted to inverted grayscale (format expected by the model).
*   **Clear Output:** Shows the final predicted digit in a large, easy-to-read format.
*   **Built with SwiftUI:** Modern macOS application built using Apple's SwiftUI framework.

## How It Works

1.  **Capture:** The `DrawingView` captures the user's strokes.
2.  **Snapshot:** When the drawing changes, a snapshot of the view is taken.
3.  **Resize:** The snapshot is resized to 28x28 pixels, the input size required by the MNIST model.
4.  **Grayscale Conversion:** The resized image is converted into a grayscale pixel buffer. The colors are likely inverted during this process to match the MNIST training data format (white digit on black background).
5.  **Predict:** The `MNISTClassifier` Core ML model takes the 28x28 grayscale pixel buffer as input and outputs a prediction (the recognized digit).
6.  **Display:** The application UI updates to show the resized preview, the grayscale preview, and the final predicted digit.

## Requirements

*   macOS (Check the project's deployment target in Xcode for the minimum required version)
*   Xcode (To build and run the project)

## How to Build and Run

1.  Clone this repository:
    ```bash
    git clone https://github.com/bluevisor/NNN/
    cd NNN
    ```
2.  Open the `NNN.xcodeproj` file in Xcode.
3.  Select a target device (Your Mac).
4.  Click the "Run" button (or press `Cmd + R`).

## Model

The application uses a Core ML model (`MNISTClassifier.mlpackage`) trained for handwritten digit classification, likely based on the standard MNIST dataset. The model expects a 28x28 grayscale image as input.

## Potential Improvements

*   Improve drawing smoothness and stroke handling.
*   Add a "Clear" button to easily erase the canvas.
*   Display prediction confidence scores alongside the predicted digit.
*   Allow loading different Core ML models.
*   Experiment with different preprocessing techniques.
