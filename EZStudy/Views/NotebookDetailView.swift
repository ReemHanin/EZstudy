import SwiftUI

enum NoteSortOrder: String, CaseIterable, Identifiable {
    case dateModified = "Last Modified"
    case dateCreated  = "Date Created"
    case title        = "Title"
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .dateModified: return "clock"
        case .dateCreated:  return "calendar"
        case .title:        return "textformat.abc"
        }
    }
}

struct NotebookDetailView: View {
    @EnvironmentObject var store: NotesStore
    let notebookId: UUID

    @State private var showingNewNote = false
    @State private var newNoteTitle = ""
    @State private var searchText = ""
    @State private var sortOrder: NoteSortOrder = .dateModified

    private var notebook: Notebook {
        store.notebooks.first { $0.id == notebookId } ?? Notebook(title: "")
    }

    private var filteredNotes: [Note] {
        var notes = notebook.notes
        if !searchText.isEmpty {
            notes = notes.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.textContent.localizedCaseInsensitiveContains(searchText)
            }
        }
        switch sortOrder {
        case .dateModified: return notes.sorted { $0.updatedAt > $1.updatedAt }
        case .dateCreated:  return notes.sorted { $0.createdAt > $1.createdAt }
        case .title:        return notes.sorted { $0.title.localizedCompare($1.title) == .orderedAscending }
        }
    }

    var body: some View {
        Group {
            if notebook.notes.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(filteredNotes) { note in
                        NavigationLink(
                            destination: NoteEditorView(noteId: note.id, notebookId: notebookId)
                        ) {
                            NoteCellView(note: note)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                store.deleteNote(note, from: notebookId)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .searchable(text: $searchText, prompt: "Search notes")
            }
        }
        .navigationTitle(notebook.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    // Sort menu
                    Menu {
                        ForEach(NoteSortOrder.allCases) { order in
                            Button {
                                withAnimation { sortOrder = order }
                            } label: {
                                Label(order.rawValue, systemImage: order.icon)
                                if sortOrder == order {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.title3)
                    }

                    // New note
                    Button {
                        newNoteTitle = ""
                        showingNewNote = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .font(.title3)
                    }
                }
            }
        }
        .alert("New Note", isPresented: $showingNewNote) {
            TextField("Note title…", text: $newNoteTitle)
            Button("Create") {
                let trimmed = newNoteTitle.trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty else { return }
                store.addNote(to: notebookId, title: trimmed)
                newNoteTitle = ""
            }
            Button("Cancel", role: .cancel) { newNoteTitle = "" }
        } message: {
            Text("Enter a title for your new note.")
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "note.text")
                .font(.system(size: 64))
                .foregroundStyle(notebook.color.opacity(0.5))
            Text("No Notes Yet")
                .font(.title2.bold())
            Text("Tap the pencil icon to write your first note.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button {
                newNoteTitle = ""
                showingNewNote = true
            } label: {
                Label("New Note", systemImage: "square.and.pencil")
                    .padding(.horizontal, 8)
            }
            .buttonStyle(.borderedProminent)
            .tint(notebook.color)
            Spacer()
        }
        .padding()
    }
}

// MARK: - Note Cell

struct NoteCellView: View {
    let note: Note

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .firstTextBaseline) {
                Text(note.title)
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
                Text(note.formattedDate)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(note.preview)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            if note.hasDrawing {
                Label("Contains drawing", systemImage: "pencil.tip")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 1)
            }
        }
        .padding(.vertical, 4)
    }
}
