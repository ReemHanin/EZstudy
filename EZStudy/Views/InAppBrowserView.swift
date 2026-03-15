import SwiftUI
import SafariServices

/// Wraps SFSafariViewController so links open in an in-app browser window.
struct InAppBrowserView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false
        config.barCollapsingEnabled = true
        let safari = SFSafariViewController(url: url, configuration: config)
        safari.preferredControlTintColor = .systemBlue
        safari.dismissButtonStyle = .close
        return safari
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

// MARK: - Identifiable URL wrapper for sheet presentation

struct IdentifiableURL: Identifiable {
    let id = UUID()
    let url: URL
}
