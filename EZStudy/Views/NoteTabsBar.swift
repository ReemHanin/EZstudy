import SwiftUI

struct NoteTabsBar: View {
    @EnvironmentObject var tabsManager: TabsManager

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 2) {
                    ForEach(tabsManager.tabs) { tab in
                        TabChip(tab: tab)
                            .id(tab.id)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
            }
            .onChange(of: tabsManager.activeTabId) { _, newId in
                withAnimation { proxy.scrollTo(newId, anchor: .center) }
            }
        }
        .frame(height: 38)
        .background(Color(.secondarySystemBackground))
        .overlay(alignment: .bottom) { Divider() }
    }
}

private struct TabChip: View {
    @EnvironmentObject var tabsManager: TabsManager
    let tab: NoteTab

    private var isActive: Bool { tabsManager.activeTabId == tab.id }

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "doc.text")
                .font(.system(size: 10))
                .foregroundStyle(isActive ? Color.accentColor : Color.secondary)

            Text(tab.title.isEmpty ? "Untitled" : tab.title)
                .font(.system(size: 12, weight: isActive ? .semibold : .regular))
                .lineLimit(1)
                .foregroundStyle(isActive ? Color.primary : Color.secondary)
                .frame(maxWidth: 120)

            Button {
                tabsManager.close(tab)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color.secondary)
                    .padding(2)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 7)
                .fill(isActive ? Color(.systemBackground) : Color.clear)
                .shadow(color: .black.opacity(isActive ? 0.08 : 0), radius: 2, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 7)
                .stroke(isActive ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.25)) {
                tabsManager.activeTabId = tab.id
            }
        }
        .animation(.spring(response: 0.25), value: isActive)
    }
}
