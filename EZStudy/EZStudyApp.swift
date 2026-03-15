import SwiftUI

@main
struct EZStudyApp: App {
    @StateObject private var store = NotesStore()
    @StateObject private var tabsManager = TabsManager()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(store)
                .environmentObject(tabsManager)
        }
    }
}
