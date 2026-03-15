import Foundation
import SwiftUI

struct NoteTab: Identifiable, Equatable {
    let id: UUID
    let notebookId: UUID
    let noteId: UUID
    var title: String

    init(notebookId: UUID, noteId: UUID, title: String) {
        self.id = UUID()
        self.notebookId = notebookId
        self.noteId = noteId
        self.title = title
    }
}

class TabsManager: ObservableObject {
    @Published var tabs: [NoteTab] = []
    @Published var activeTabId: UUID?

    var activeTab: NoteTab? {
        guard let id = activeTabId else { return nil }
        return tabs.first { $0.id == id }
    }

    func open(notebookId: UUID, noteId: UUID, title: String) {
        if let existing = tabs.first(where: { $0.noteId == noteId }) {
            withAnimation(.spring(response: 0.25)) { activeTabId = existing.id }
            return
        }
        let tab = NoteTab(notebookId: notebookId, noteId: noteId, title: title)
        withAnimation(.spring(response: 0.25)) {
            tabs.append(tab)
            activeTabId = tab.id
        }
    }

    func close(_ tab: NoteTab) {
        guard let idx = tabs.firstIndex(of: tab) else { return }
        withAnimation(.spring(response: 0.25)) {
            tabs.remove(at: idx)
            if activeTabId == tab.id {
                if tabs.isEmpty {
                    activeTabId = nil
                } else {
                    activeTabId = tabs[max(0, idx - 1)].id
                }
            }
        }
    }

    func updateTitle(_ title: String, for noteId: UUID) {
        guard let idx = tabs.firstIndex(where: { $0.noteId == noteId }) else { return }
        tabs[idx].title = title
    }
}
