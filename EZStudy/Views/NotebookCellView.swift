import SwiftUI

struct NotebookCellView: View {
    let notebook: Notebook
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Cover
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 14)
                    .fill(notebook.color.gradient)
                    .frame(height: 140)
                    .shadow(color: notebook.color.opacity(0.4), radius: 8, x: 0, y: 4)

                // Spiral rings on left edge
                VStack(spacing: 11) {
                    ForEach(0..<5, id: \.self) { _ in
                        Circle()
                            .fill(.white.opacity(0.55))
                            .frame(width: 13, height: 13)
                    }
                }
                .padding(.leading, 10)
                .padding(.vertical, 16)

                // Lines decoration
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(0..<4, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(.white.opacity(i == 0 ? 0.6 : 0.25))
                            .frame(height: i == 0 ? 4 : 2.5)
                            .padding(.trailing, 12)
                    }
                }
                .padding(.leading, 34)
                .padding(.trailing, 8)

                // Note count badge
                VStack {
                    HStack {
                        Spacer()
                        Text("\(notebook.notes.count)")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.45))
                            .padding(.trailing, 12)
                            .padding(.top, 12)
                    }
                    Spacer()
                }
            }

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(notebook.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(notebook.notes.count == 1 ? "1 note" : "\(notebook.notes.count) notes")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 2)
            .padding(.top, 6)
            .padding(.bottom, 4)
        }
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label("Delete Notebook", systemImage: "trash")
            }
        }
    }
}
