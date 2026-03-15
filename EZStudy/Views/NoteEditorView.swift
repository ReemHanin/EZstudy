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
    @State private var formatting = TextFormatting()
    @State private var hasUnsavedChanges = false
    @State private var browserURL: IdentifiableURL?    // drives the in-app browser sheet
    @State private var isKeyboardVisible = false
    @FocusState private var titleFocused: Bool

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
            // ── Mode picker ────────────────────────────────────────────────
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

            // ── Content ────────────────────────────────────────────────────
            ZStack {
                if editorMode == .text {
                    textEditorContent
                } else {
                    DrawingCanvasView(drawingData: $drawingData)
                        .ignoresSafeArea(edges: .bottom)
                }
            }
            .animation(.easeInOut(duration: 0.15), value: editorMode)

            // ── Formatting toolbar (text mode, keyboard visible) ───────────
            if editorMode == .text && isKeyboardVisible {
                Divider()
                FormattingToolbar(formatting: $formatting) {
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder),
                        to: nil, from: nil, for: nil
                    )
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                titleField
            }
        }
        .onAppear(perform: loadNote)
        .onDisappear(perform: saveIfNeeded)
        .onChange(of: bodyText)    { _, _ in hasUnsavedChanges = true }
        .onChange(of: titleText)   { _, _ in hasUnsavedChanges = true }
        .onChange(of: drawingData) { _, _ in hasUnsavedChanges = true }
        // Track keyboard visibility to show/hide formatting toolbar
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            withAnimation(.easeOut(duration: 0.2)) { isKeyboardVisible = true }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.easeOut(duration: 0.2)) { isKeyboardVisible = false }
        }
        // ── In-app browser: opens when user taps a URL inside the note ─────
        .sheet(item: $browserURL) { item in
            InAppBrowserView(url: item.url)
                .ignoresSafeArea()
        }
    }

    // MARK: - Title bar

    private var titleField: some View {
        TextField("Title", text: $titleText)
            .font(.headline)
            .multilineTextAlignment(.center)
            .submitLabel(.done)
            .focused($titleFocused)
    }

    // MARK: - Text editor (ruled paper + link-aware UITextView)

    private var textEditorContent: some View {
        ZStack(alignment: .topLeading) {
            // Ruled paper background
            GeometryReader { _ in
                Canvas { ctx, size in
                    let spacing: CGFloat = 30
                    var y: CGFloat = 12
                    while y <= size.height {
                        let line = Path { p in
                            p.move(to: CGPoint(x: 0, y: y))
                            p.addLine(to: CGPoint(x: size.width, y: y))
                        }
                        ctx.stroke(line, with: .color(.secondary.opacity(0.12)), lineWidth: 0.7)
                        y += spacing
                    }
                    let margin = Path { p in
                        p.move(to: CGPoint(x: 52, y: 0))
                        p.addLine(to: CGPoint(x: 52, y: size.height))
                    }
                    ctx.stroke(margin, with: .color(.red.opacity(0.18)), lineWidth: 1)
                }
            }

            // Placeholder
            if bodyText.isEmpty {
                Text("Start writing… URLs are tappable links")
                    .font(.system(size: 16))
                    .foregroundStyle(.tertiary)
                    .padding(.leading, 62)
                    .padding(.top, 16)
                    .allowsHitTesting(false)
            }

            // Link-aware editor: URLs appear blue & underlined; tapping opens in-app browser
            LinkedTextEditor(text: $bodyText, formatting: formatting) { url in
                browserURL = IdentifiableURL(url: url)
            }
        }
        .background(Color(.systemBackground))
    }

    // MARK: - Persistence

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
