import SwiftUI
import PencilKit

struct DrawingCanvasView: UIViewRepresentable {
    @Binding var drawingData: Data?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.delegate = context.coordinator
        canvas.drawingPolicy = .anyInput
        canvas.backgroundColor = UIColor.systemBackground
        canvas.alwaysBounceVertical = true

        // Restore saved drawing
        if let data = drawingData,
           let drawing = try? PKDrawing(data: data) {
            canvas.drawing = drawing
        }

        // Attach tool picker
        let picker = PKToolPicker()
        picker.setVisible(true, forFirstResponder: canvas)
        picker.addObserver(canvas)
        context.coordinator.toolPicker = picker
        canvas.becomeFirstResponder()

        return canvas
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        // Avoid feedback loops: only update from external changes
        guard !context.coordinator.isUpdating else { return }
        if let data = drawingData,
           let drawing = try? PKDrawing(data: data),
           uiView.drawing.dataRepresentation() != data {
            uiView.drawing = drawing
        }
    }

    class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: DrawingCanvasView
        var toolPicker: PKToolPicker?
        var isUpdating = false

        init(_ parent: DrawingCanvasView) {
            self.parent = parent
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            isUpdating = true
            parent.drawingData = canvasView.drawing.dataRepresentation()
            isUpdating = false
        }
    }
}
