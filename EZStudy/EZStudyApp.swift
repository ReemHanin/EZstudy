import SwiftUI

@main
struct EZStudyApp: App {
    @StateObject private var store = NotesStore()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(store)
        }
    }
}
