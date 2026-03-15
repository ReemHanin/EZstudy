import SwiftUI
import PencilKit

struct NoteEditorView: View {
    @EnvironmentObject var store: NotesStore
    let noteId: UUID
    let notebookId: UUID

    @State private var note: Note?
    @State private var editorMode: EditorMode = .text
    @State private var titleText = ""
    @State private var bodyText = ""
    @State private var drawingData: Data?
    @State private var isEditingTitle = false
    @State private var hasUnsavedChanges = false
    @FocusState private var titleFocused: Bool
    @FocusState private var bodyFocused: Bool

    enum EditorMode: String, CaseIterable {
        case text = "Text"
        case draw = "Draw"

        var icon: String {
            switch self {
            case .text: return "text.cursor"
            case .draw: return "pencil.tip.crop.circle"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Mode picker
            Picker("Mode", selection: $editorMode) {
                ForEach(EditorMode.allCases, id: \.self) { mode in
                    Label(mode.rawValue, systemImage: mode.icon).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(.bar)

            Divider()

            // Content
            ZStack {
                if editorMode == .text {
                    textEditorContent
                } else {
                    DrawingCanvasView(drawingData: $drawingData)
                        .ignoresSafeArea(edges: .bottom)
                }
            }
            .animation(.easeInOut(duration: 0.15), value: editorMode)
        }
        .navigationTitle(titleText.isEmpty ? "Note" : titleText)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                titleField
            }
            ToolbarItemGroup(placement: .keyboard) {
                Button {
                    bodyFocused = false
                } label: {
                    Image(systemName: "keyboard.chevron.compact.down")
                }
                Spacer()
                Text(wordCountLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear(perform: loadNote)
        .onDisappear(perform: saveIfNeeded)
        .onChange(of: bodyText) { _, _ in hasUnsavedChanges = true }
        .onChange(of: titleText) { _, _ in hasUnsavedChanges = true }
        .onChange(of: drawingData) { _, _ in hasUnsavedChanges = true }
    }

    // MARK: - Title Field

    private var titleField: some View {
        TextField("Title", text: $titleText)
            .font(.headline)
            .multilineTextAlignment(.center)
            .submitLabel(.done)
            .focused($titleFocused)
            .onSubmit { bodyFocused = true }
    }

    // MARK: - Text Editor

    private var textEditorContent: some View {
        ZStack(alignment: .topLeading) {
            // Ruled paper background
            GeometryReader { geo in
                Canvas { ctx, size in
                    let spacing: CGFloat = 30
                    let startY: CGFloat = 12
                    var y = startY
                    while y <= size.height {
                        let path = Path { p in
                            p.move(to: CGPoint(x: 0, y: y))
                            p.addLine(to: CGPoint(x: size.width, y: y))
                        }
                        ctx.stroke(path, with: .color(.secondary.opacity(0.12)), lineWidth: 0.7)
                        y += spacing
                    }
                    // Margin line
                    let margin = Path { p in
                        p.move(to: CGPoint(x: 52, y: 0))
                        p.addLine(to: CGPoint(x: 52, y: size.height))
                    }
                    ctx.stroke(margin, with: .color(.red.opacity(0.18)), lineWidth: 1)
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }

            // Text placeholder
            if bodyText.isEmpty {
                Text("Start writing…")
                    .font(.system(size: 16))
                    .foregroundStyle(.tertiary)
                    .padding(.leading, 62)
                    .padding(.top, 16)
                    .allowsHitTesting(false)
            }

            TextEditor(text: $bodyText)
                .font(.system(size: 16))
                .lineSpacing(8)
                .padding(.leading, 56)
                .padding(.trailing, 16)
                .padding(.top, 12)
                .scrollContentBackground(.hidden)
                .background(.clear)
                .focused($bodyFocused)
        }
        .background(Color(.systemBackground))
        .onTapGesture {
            bodyFocused = true
        }
    }

    // MARK: - Helpers

    private var wordCountLabel: String {
        let words = bodyText.split { $0.isWhitespace }.count
        return words == 1 ? "1 word" : "\(words) words"
    }

    private func loadNote() {
        guard
            let nb = store.notebooks.first(where: { $0.id == notebookId }),
            let found = nb.notes.first(where: { $0.id == noteId })
        else { return }
        note = found
        titleText = found.title
        bodyText = found.textContent
        drawingData = found.drawingData
    }

    private func saveIfNeeded() {
        guard hasUnsavedChanges, var current = note else { return }
        current.title = titleText.trimmingCharacters(in: .whitespaces).isEmpty
            ? "Untitled Note"
            : titleText
        current.textContent = bodyText
        current.drawingData = drawingData
        store.updateNote(current, in: notebookId)
    }
}
