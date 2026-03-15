import Foundation
import Vision
import PencilKit
import UIKit

struct HandwritingRecognizer {
    /// Renders a PKDrawing to an image and runs Vision text recognition on it.
    static func recognize(drawing: PKDrawing, in canvasSize: CGSize) async -> String {
        guard canvasSize != .zero else { return "" }
        let scale = UIScreen.main.scale
        let rect = CGRect(origin: .zero, size: canvasSize)
        let image = drawing.image(from: rect, scale: scale)
        guard let cgImage = image.cgImage else { return "" }

        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { req, err in
                guard err == nil,
                      let observations = req.results as? [VNRecognizedTextObservation]
                else {
                    continuation.resume(returning: "")
                    return
                }
                let text = observations
                    .compactMap { $0.topCandidates(1).first?.string }
                    .joined(separator: "\n")
                continuation.resume(returning: text)
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
        }
    }
}
