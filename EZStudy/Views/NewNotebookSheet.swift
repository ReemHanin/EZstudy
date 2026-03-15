import SwiftUI

struct NewNotebookSheet: View {
    @EnvironmentObject var store: NotesStore
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var selectedColor = Notebook.coverColors[6] // default blue
    @FocusState private var titleFocused: Bool

    private let colorColumns = Array(repeating: GridItem(.flexible()), count: 6)

    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Notebook Name") {
                    TextField("e.g. Lecture Notes, Study Plan…", text: $title)
                        .focused($titleFocused)
                }

                Section("Cover Color") {
                    LazyVGrid(columns: colorColumns, spacing: 14) {
                        ForEach(Notebook.coverColors, id: \.self) { hex in
                            Button {
                                withAnimation(.spring(response: 0.25)) {
                                    selectedColor = hex
                                }
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: hex))
                                        .frame(width: 38, height: 38)
                                    if selectedColor == hex {
                                        Circle()
                                            .stroke(.white, lineWidth: 3)
                                            .frame(width: 38, height: 38)
                                        Image(systemName: "checkmark")
                                            .font(.caption.bold())
                                            .foregroundStyle(.white)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 6)
                }

                Section("Preview") {
                    HStack {
                        Spacer()
                        VStack(spacing: 6) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(hex: selectedColor).gradient)
                                    .frame(width: 64, height: 80)
                                VStack(spacing: 9) {
                                    ForEach(0..<4, id: \.self) { i in
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(.white.opacity(i == 0 ? 0.7 : 0.3))
                                            .frame(width: 40, height: i == 0 ? 4 : 2)
                                    }
                                }
                            }
                            Text(title.isEmpty ? "Notebook" : title)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("New Notebook")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        store.addNotebook(
                            title: title.trimmingCharacters(in: .whitespaces),
                            colorHex: selectedColor
                        )
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isValid)
                }
            }
            .onAppear { titleFocused = true }
        }
    }
}
