import Foundation
import SwiftUI

struct Notebook: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var colorHex: String
    var createdAt: Date
    var notes: [Note]

    init(
        id: UUID = UUID(),
        title: String,
        colorHex: String = "#5C7CFA",
        createdAt: Date = Date(),
        notes: [Note] = []
    ) {
        self.id = id
        self.title = title
        self.colorHex = colorHex
        self.createdAt = createdAt
        self.notes = notes
    }

    var color: Color {
        Color(hex: colorHex)
    }
}

extension Notebook {
    static let coverColors: [String] = [
        "#FF6B6B", "#FF8E53", "#FFC72C", "#96CEB4",
        "#4ECDC4", "#45B7D1", "#5C7CFA", "#A855F7",
        "#EC4899", "#14B8A6", "#6366F1", "#F59E0B"
    ]

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: createdAt)
    }
}
