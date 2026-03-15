import SwiftUI

struct HomeView: View {
    @EnvironmentObject var store: NotesStore
    @State private var showingNewNotebook = false
    @State private var searchText = ""
    @State private var notebookToDelete: Notebook?
    @State private var showDeleteAlert = false

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var filteredNotebooks: [Notebook] {
        guard !searchText.isEmpty else { return store.notebooks }
        return store.notebooks.filter {
            $0.title.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if store.notebooks.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(filteredNotebooks) { notebook in
                                NavigationLink(
                                    destination: NotebookDetailView(notebookId: notebook.id)
                                ) {
                                    NotebookCellView(notebook: notebook) {
                                        notebookToDelete = notebook
                                        showDeleteAlert = true
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .padding(.bottom, 24)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search notebooks")
            .navigationTitle("My Notebooks")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingNewNotebook = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingNewNotebook) {
                NewNotebookSheet()
            }
            .alert("Delete Notebook?", isPresented: $showDeleteAlert, presenting: notebookToDelete) { nb in
                Button("Delete", role: .destructive) {
                    store.deleteNotebook(nb)
                }
                Button("Cancel", role: .cancel) {}
            } message: { nb in
                Text(""\(nb.title)" and all its notes will be permanently deleted.")
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "books.vertical")
                .font(.system(size: 72))
                .foregroundStyle(.secondary.opacity(0.4))
            Text("No Notebooks Yet")
                .font(.title2.bold())
            Text("Tap + to create your first notebook")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button {
                showingNewNotebook = true
            } label: {
                Label("Create Notebook", systemImage: "plus")
                    .padding(.horizontal, 8)
            }
            .buttonStyle(.borderedProminent)
            Spacer()
        }
        .padding()
    }
}
