import Foundation
import PDFKit
import UIKit

struct PDFService {

    // MARK: - Export

    static func exportNote(title: String, textContent: String, images: [UIImage]) -> Data {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)  // US Letter
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        return renderer.pdfData { ctx in
            ctx.beginPage()

            // Title
            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 24),
                .foregroundColor: UIColor.black
            ]
            NSAttributedString(string: title, attributes: titleAttrs)
                .draw(at: CGPoint(x: 36, y: 36))

            // Divider line
            let line = UIBezierPath()
            line.move(to: CGPoint(x: 36, y: 72))
            line.addLine(to: CGPoint(x: 576, y: 72))
            UIColor.lightGray.setStroke()
            line.lineWidth = 0.5
            line.stroke()

            // Body text
            let bodyAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.black
            ]
            NSAttributedString(string: textContent, attributes: bodyAttrs)
                .draw(in: CGRect(x: 36, y: 84, width: 540, height: 680))

            // Images on subsequent pages
            for image in images {
                ctx.beginPage()
                let available = CGRect(x: 36, y: 36, width: 540, height: 720)
                let fitted = aspectFit(size: image.size, in: available)
                image.draw(in: fitted)
            }
        }
    }

    // MARK: - Import

    static func extractText(from data: Data) -> String {
        guard let doc = PDFDocument(data: data) else { return "" }
        return (0..<doc.pageCount)
            .compactMap { doc.page(at: $0)?.string }
            .joined(separator: "\n\n")
    }

    // MARK: - Helpers

    private static func aspectFit(size: CGSize, in rect: CGRect) -> CGRect {
        let scale = min(rect.width / size.width, rect.height / size.height)
        let w = size.width * scale
        let h = size.height * scale
        return CGRect(x: rect.midX - w / 2, y: rect.midY - h / 2, width: w, height: h)
    }
}
