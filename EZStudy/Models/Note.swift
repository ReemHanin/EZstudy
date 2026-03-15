import Foundation

struct Note: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var textContent: String
    var drawingData: Data?
    var imageAttachments: [Data]   // JPEG data for embedded photos
    var createdAt: Date
    var updatedAt: Date

    // MARK: - init

    init(
        id: UUID = UUID(),
        title: String = "Untitled Note",
        textContent: String = "",
        drawingData: Data? = nil,
        imageAttachments: [Data] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.textContent = textContent
        self.drawingData = drawingData
        self.imageAttachments = imageAttachments
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Codable (backward-compatible)

    enum CodingKeys: String, CodingKey {
        case id, title, textContent, drawingData, imageAttachments, createdAt, updatedAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id               = try c.decode(UUID.self,   forKey: .id)
        title            = try c.decode(String.self, forKey: .title)
        textContent      = try c.decode(String.self, forKey: .textContent)
        drawingData      = try c.decodeIfPresent(Data.self,   forKey: .drawingData)
        imageAttachments = try c.decodeIfPresent([Data].self, forKey: .imageAttachments) ?? []
        createdAt        = try c.decode(Date.self,   forKey: .createdAt)
        updatedAt        = try c.decode(Date.self,   forKey: .updatedAt)
    }

    // MARK: - Computed

    var preview: String {
        let text = textContent.trimmingCharacters(in: .whitespacesAndNewlines)
        return text.isEmpty ? "No additional text" : String(text.prefix(120))
    }

    var hasDrawing: Bool { drawingData != nil }

    var formattedDate: String {
        let cal = Calendar.current
        if cal.isDateInToday(updatedAt) {
            let f = DateFormatter(); f.dateFormat = "h:mm a"
            return f.string(from: updatedAt)
        } else if cal.isDateInYesterday(updatedAt) {
            return "Yesterday"
        } else {
            let f = DateFormatter(); f.dateFormat = "MMM d"
            return f.string(from: updatedAt)
        }
    }
}
