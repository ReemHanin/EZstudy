import SwiftUI
import PencilKit
import UIKit

// MARK: - NoteEditorView

struct NoteEditorView: View {
    @EnvironmentObject var store: NotesStore
    @EnvironmentObject var tabsManager: TabsManager

    let initialNoteId: UUID
    let initialNotebookId: UUID

    // Current note (may change when user switches tabs)
    @State private var currentNoteId: UUID
    @State private var currentNotebookId: UUID
    @State private var loadedNote: Note?

    // Editor content state
    @State private var titleText = ""
    @State private var bodyText = ""
    @State private var drawingData: Data?
    @State private var imageAttachments: [Data] = []
    @State private var formatting = TextFormatting()
    @State private var editorMode: EditorMode = .text
    @State private var canvasSize: CGSize = .zero
    @State private var hasUnsavedChanges = false

    // UI state
    @State private var isKeyboardVisible = false
    @FocusState private var bodyFocused: Bool

    // Feature sheet triggers
    @State private var browserURL: IdentifiableURL?
    @State private var showAI = false
    @State private var showSolver = false
    @State private var showGraph = false
    @State private var showImagePicker = false
    @State private var showPDFImporter = false
    @State private var shareItems: [Any] = []
    @State private var showShareSheet = false

    // OCR state
    @State private var isRecognizing = false
    @State private var ocrResult: String?

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

    init(noteId: UUID, notebookId: UUID) {
        self.initialNoteId = noteId
        self.initialNotebookId = notebookId
        _currentNoteId = State(initialValue: noteId)
        _currentNotebookId = State(initialValue: notebookId)
    }

    var body: some View {
        VStack(spacing: 0) {
            // ── Tabs bar ───────────────────────────────────────────────────
            if tabsManager.tabs.count > 1 {
                NoteTabsBar()
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.spring(response: 0.3), value: tabsManager.tabs.count)
            }

            // ── Mode picker ────────────────────────────────────────────────
            Picker("Mode", selection: $editorMode) {
                ForEach(EditorMode.allCases, id: \.self) { m in
                    Label(m.rawValue, systemImage: m.icon).tag(m)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(.bar)

            Divider()

            // ── Content area ───────────────────────────────────────────────
            ZStack {
                if editorMode == .text {
                    textContent
                } else {
                    GeometryReader { geo in
                        DrawingCanvasView(drawingData: $drawingData)
                            .onAppear { canvasSize = geo.size }
                            .onChange(of: geo.size) { _, s in canvasSize = s }
                    }
                    .ignoresSafeArea(edges: .bottom)
                }
            }
            .animation(.easeInOut(duration: 0.15), value: editorMode)

            // ── Formatting toolbar (text mode + keyboard) ──────────────────
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

            // ── Feature toolbar ────────────────────────────────────────────
            featureToolbar
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                TextField("Title", text: $titleText)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .onChange(of: titleText) { _, t in
                        hasUnsavedChanges = true
                        tabsManager.updateTitle(t.isEmpty ? "Untitled" : t, for: currentNoteId)
                    }
            }
        }
        .onAppear {
            loadNote()
            tabsManager.open(
                notebookId: currentNotebookId,
                noteId: currentNoteId,
                title: titleText.isEmpty ? "Untitled" : titleText
            )
        }
        .onDisappear { saveIfNeeded() }
        .onChange(of: bodyText)         { _, _ in hasUnsavedChanges = true }
        .onChange(of: drawingData)      { _, _ in hasUnsavedChanges = true }
        .onChange(of: imageAttachments) { _, _ in hasUnsavedChanges = true }
        .onChange(of: tabsManager.activeTabId) { _, newId in switchToTab(id: newId) }
        .onReceive(NotificationCenter.default.publisher(
            for: UIResponder.keyboardWillShowNotification)) { _ in
                withAnimation(.easeOut(duration: 0.2)) { isKeyboardVisible = true }
        }
        .onReceive(NotificationCenter.default.publisher(
            for: UIResponder.keyboardWillHideNotification)) { _ in
                withAnimation(.easeOut(duration: 0.2)) { isKeyboardVisible = false }
        }
        // Sheets
        .sheet(item: $browserURL) { item in
            InAppBrowserView(url: item.url).ignoresSafeArea()
        }
        .sheet(isPresented: $showAI) {
            AIAssistantView(noteContext: bodyText)
        }
        .sheet(isPresented: $showSolver) {
            MathSolverView(prefill: selectedText())
        }
        .sheet(isPresented: $showGraph) {
            GraphView()
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePickerView { images in
                for img in images {
                    if let data = img.jpegData(compressionQuality: 0.75) {
                        imageAttachments.append(data)
                    }
                }
                showImagePicker = false
            }
        }
        .sheet(isPresented: $showPDFImporter) {
            DocumentPickerView { data in
                let text = PDFService.extractText(from: data)
                if !text.isEmpty {
                    bodyText += bodyText.isEmpty ? text : "\n\n---\n\n\(text)"
                }
                showPDFImporter = false
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: shareItems)
        }
        .alert("Handwriting Recognized", isPresented: .init(
            get: { ocrResult != nil },
            set: { if !$0 { ocrResult = nil } }
        )) {
            Button("Insert into Note") {
                if let text = ocrResult {
                    bodyText += bodyText.isEmpty ? text : "\n\(text)"
                    editorMode = .text
                }
                ocrResult = nil
            }
            Button("Discard", role: .destructive) { ocrResult = nil }
        } message: {
            Text(ocrResult ?? "")
        }
    }

    // MARK: - Text editor

    private var textContent: some View {
        ZStack(alignment: .topLeading) {
            // Ruled paper background
            GeometryReader { _ in
                Canvas { ctx, size in
                    let spacing: CGFloat = 30
                    var y: CGFloat = 12
                    while y <= size.height {
                        let path = Path { p in
                            p.move(to: CGPoint(x: 0, y: y))
                            p.addLine(to: CGPoint(x: size.width, y: y))
                        }
                        ctx.stroke(path, with: .color(.secondary.opacity(0.12)), lineWidth: 0.7)
                        y += spacing
                    }
                    let margin = Path { p in
                        p.move(to: CGPoint(x: 52, y: 0))
                        p.addLine(to: CGPoint(x: 52, y: size.height))
                    }
                    ctx.stroke(margin, with: .color(.red.opacity(0.18)), lineWidth: 1)
                }
            }

            if bodyText.isEmpty {
                Text("Start writing… URLs are tappable links")
                    .font(.system(size: 16))
                    .foregroundStyle(.tertiary)
                    .padding(.leading, 62)
                    .padding(.top, 16)
                    .allowsHitTesting(false)
            }

            VStack(spacing: 0) {
                // Embedded images strip
                if !imageAttachments.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(imageAttachments.indices, id: \.self) { idx in
                                if let img = UIImage(data: imageAttachments[idx]) {
                                    ZStack(alignment: .topTrailing) {
                                        Image(uiImage: img)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 100, height: 100)
                                            .clipped()
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                        Button {
                                            withAnimation { imageAttachments.remove(at: idx) }
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundStyle(.white, .black.opacity(0.6))
                                                .font(.title3)
                                        }
                                        .offset(x: 5, y: -5)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 56)
                        .padding(.vertical, 8)
                    }
                    Divider()
                }

                // Link-aware text editor
                LinkedTextEditor(text: $bodyText, formatting: formatting) { url in
                    browserURL = IdentifiableURL(url: url)
                }
            }
        }
        .background(Color(.systemBackground))
    }

    // MARK: - Feature toolbar

    private var featureToolbar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 2) {
                FeatureButton(icon: "sparkles",        label: "AI",      color: .blue)    { showAI = true }
                FeatureButton(icon: "function",        label: "Solve",   color: .purple)  { showSolver = true }
                FeatureButton(icon: "chart.xyaxis.line",label: "Graph",  color: .green)   { showGraph = true }
                FeatureButton(icon: "doc.richtext",    label: "PDF",     color: .orange)  { exportPDF() }
                FeatureButton(icon: "arrow.down.doc",  label: "Import",  color: .orange)  { showPDFImporter = true }
                FeatureButton(icon: "photo.badge.plus", label: "Image",  color: .pink)    { showImagePicker = true }
                FeatureButton(
                    icon: isRecognizing ? "rays" : "pencil.and.outline",
                    label: "OCR",
                    color: .teal,
                    isLoading: isRecognizing
                ) { runOCR() }
                FeatureButton(
                    icon: editorMode == .text ? "pencil.tip.crop.circle" : "keyboard",
                    label: editorMode == .text ? "Draw" : "Keys",
                    color: .indigo
                ) { toggleInputMode() }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        }
        .background(Color(.secondarySystemBackground))
        .overlay(alignment: .top) { Divider() }
    }

    // MARK: - Actions

    private func toggleInputMode() {
        withAnimation {
            if editorMode == .text {
                editorMode = .draw
            } else {
                editorMode = .text
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { bodyFocused = true }
            }
        }
    }

    private func exportPDF() {
        let images = imageAttachments.compactMap { UIImage(data: $0) }
        let data = PDFService.exportNote(title: titleText, textContent: bodyText, images: images)
        shareItems = [data]
        showShareSheet = true
    }

    private func runOCR() {
        guard let drawing = currentDrawing(), editorMode == .draw else {
            // Switch to draw mode hint
            editorMode = .draw
            return
        }
        guard !drawing.strokes.isEmpty else { return }
        isRecognizing = true
        Task {
            let text = await HandwritingRecognizer.recognize(drawing: drawing, in: canvasSize)
            await MainActor.run {
                isRecognizing = false
                if !text.isEmpty { ocrResult = text }
            }
        }
    }

    private func currentDrawing() -> PKDrawing? {
        guard let data = drawingData else { return PKDrawing() }
        return try? PKDrawing(data: data)
    }

    private func selectedText() -> String { "" }  // future: return UITextView selection

    // MARK: - Tab switching

    private func switchToTab(id: UUID?) {
        guard
            let id,
            let tab = tabsManager.tabs.first(where: { $0.id == id }),
            tab.noteId != currentNoteId
        else { return }
        saveIfNeeded()
        currentNoteId = tab.noteId
        currentNotebookId = tab.notebookId
        loadNote()
    }

    // MARK: - Persistence

    private func loadNote() {
        guard
            let nb = store.notebooks.first(where: { $0.id == currentNotebookId }),
            let found = nb.notes.first(where: { $0.id == currentNoteId })
        else { return }
        loadedNote        = found
        titleText         = found.title
        bodyText          = found.textContent
        drawingData       = found.drawingData
        imageAttachments  = found.imageAttachments
        hasUnsavedChanges = false
    }

    private func saveIfNeeded() {
        guard hasUnsavedChanges, var current = loadedNote else { return }
        current.title = titleText.trimmingCharacters(in: .whitespaces).isEmpty
            ? "Untitled Note" : titleText
        current.textContent      = bodyText
        current.drawingData      = drawingData
        current.imageAttachments = imageAttachments
        store.updateNote(current, in: currentNotebookId)
        hasUnsavedChanges = false
    }
}

// MARK: - FeatureButton

private struct FeatureButton: View {
    let icon: String
    let label: String
    let color: Color
    var isLoading: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                ZStack {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.7)
                            .tint(color)
                    } else {
                        Image(systemName: icon)
                            .font(.system(size: 18))
                            .foregroundStyle(color)
                    }
                }
                .frame(width: 24, height: 24)
                Text(label)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(color.opacity(0.85))
            }
            .frame(width: 54, height: 44)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.08))
            )
        }
        .buttonStyle(.plain)
    }
}
