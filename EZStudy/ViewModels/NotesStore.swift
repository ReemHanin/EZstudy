import Foundation
import SwiftUI
import Combine

class NotesStore: ObservableObject {
    @Published var notebooks: [Notebook] = []

    private let saveKey = "EZStudy_Notebooks_v1"

    init() {
        loadNotebooks()
        if notebooks.isEmpty {
            createSampleData()
        }
    }

    // MARK: - Notebook Operations

    func addNotebook(title: String, colorHex: String) {
        let notebook = Notebook(title: title, colorHex: colorHex)
        notebooks.insert(notebook, at: 0)
        save()
    }

    func deleteNotebook(_ notebook: Notebook) {
        notebooks.removeAll { $0.id == notebook.id }
        save()
    }

    func updateNotebook(_ notebook: Notebook) {
        guard let index = notebooks.firstIndex(where: { $0.id == notebook.id }) else { return }
        notebooks[index] = notebook
        save()
    }

    func renameNotebook(_ notebook: Notebook, newTitle: String) {
        guard let index = notebooks.firstIndex(where: { $0.id == notebook.id }) else { return }
        notebooks[index].title = newTitle
        save()
    }

    // MARK: - Note Operations

    @discardableResult
    func addNote(to notebookId: UUID, title: String) -> Note {
        let note = Note(title: title)
        guard let index = notebooks.firstIndex(where: { $0.id == notebookId }) else { return note }
        notebooks[index].notes.insert(note, at: 0)
        save()
        return note
    }

    func updateNote(_ note: Note, in notebookId: UUID) {
        guard
            let nbIndex = notebooks.firstIndex(where: { $0.id == notebookId }),
            let noteIndex = notebooks[nbIndex].notes.firstIndex(where: { $0.id == note.id })
        else { return }
        var updated = note
        updated.updatedAt = Date()
        notebooks[nbIndex].notes[noteIndex] = updated
        // Sort notes by most recently updated
        notebooks[nbIndex].notes.sort { $0.updatedAt > $1.updatedAt }
        save()
    }

    func deleteNote(_ note: Note, from notebookId: UUID) {
        guard let index = notebooks.firstIndex(where: { $0.id == notebookId }) else { return }
        notebooks[index].notes.removeAll { $0.id == note.id }
        save()
    }

    // MARK: - Persistence

    private func save() {
        guard let encoded = try? JSONEncoder().encode(notebooks) else { return }
        UserDefaults.standard.set(encoded, forKey: saveKey)
    }

    private func loadNotebooks() {
        guard
            let data = UserDefaults.standard.data(forKey: saveKey),
            let decoded = try? JSONDecoder().decode([Notebook].self, from: data)
        else { return }
        notebooks = decoded
    }

    // MARK: - Sample Data

    private func createSampleData() {
        let welcomeNote = Note(
            title: "Welcome to EZStudy!",
            textContent: """
            Welcome to EZStudy Notes 📒

            Here are some things you can do:
            • Create notebooks and organize your notes
            • Write notes with the text editor
            • Draw and sketch with PencilKit
            • Search across all your notebooks

            Tap the + button to create a new notebook, or tap the pencil icon inside a notebook to add notes.

            Happy studying!
            """,
            createdAt: Date(),
            updatedAt: Date()
        )

        let lectureNote = Note(
            title: "Chapter 1: Introduction",
            textContent: """
            Key Concepts:
            • Definition and scope of the subject
            • Historical background
            • Core principles to explore

            Remember to review chapters 1–3 before next class.
            Quiz on Friday – focus on definitions!
            """,
            createdAt: Date().addingTimeInterval(-3600),
            updatedAt: Date().addingTimeInterval(-3600)
        )

        let studyNote = Note(
            title: "Weekly Goals",
            textContent: """
            This week's study targets:

            ✓ Complete reading assignments (Ch 1–3)
            ✓ Practice problems set 1–5
            ☐ Review lecture notes
            ☐ Prepare for Friday quiz
            ☐ Group study session – Thursday 4pm
            """,
            createdAt: Date().addingTimeInterval(-7200),
            updatedAt: Date().addingTimeInterval(-7200)
        )

        notebooks = [
            Notebook(
                title: "Quick Notes",
                colorHex: "#5C7CFA",
                notes: [welcomeNote]
            ),
            Notebook(
                title: "Lecture Notes",
                colorHex: "#4ECDC4",
                notes: [lectureNote]
            ),
            Notebook(
                title: "Study Plan",
                colorHex: "#FF6B6B",
                notes: [studyNote]
            ),
            Notebook(
                title: "Ideas & Sketches",
                colorHex: "#A855F7",
                notes: []
            )
        ]
        save()
    }
}
