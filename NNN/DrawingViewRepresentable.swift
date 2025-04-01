//
//  DrawingViewRepresentable.swift
//  NNN
//
//  Created by John Zheng on 4/1/25.
//

import SwiftUI

struct DrawingViewRepresentable: NSViewRepresentable {
    // A callback so that the parent view can capture the instance.
    var onCreate: ((DrawingView) -> Void)?
    var onDrawingChanged: (() -> Void)?

    func makeNSView(context: Context) -> DrawingView {
        let view = DrawingView(frame: .zero)
        view.onDrawingChanged = onDrawingChanged
        DispatchQueue.main.async {
            self.onCreate?(view)
        }
        return view
    }

    func updateNSView(_ nsView: DrawingView, context: Context) {
        // No dynamic updates needed for now.
    }
}
