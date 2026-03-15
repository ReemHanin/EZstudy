import Foundation

struct Note: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var textContent: String
    var drawingData: Data?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String = "Untitled Note",
        textContent: String = "",
        drawingData: Data? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.textContent = textContent
        self.drawingData = drawingData
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var preview: String {
        let text = textContent.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return "No additional text" }
        return String(text.prefix(120))
    }

    var hasDrawing: Bool { drawingData != nil }

    var formattedDate: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(updatedAt) {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return formatter.string(from: updatedAt)
        } else if calendar.isDateInYesterday(updatedAt) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: updatedAt)
        }
    }
}
