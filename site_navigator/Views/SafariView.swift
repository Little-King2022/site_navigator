//
//  SafariView.swift
//  site_navigator
//

import SwiftUI
import SafariServices

/// Wraps `SFSafariViewController` for the default in-app browsing mode.
/// It runs in a separate system process (`com.apple.SafariViewService`), so
/// it isn't subject to this app's App Transport Security configuration —
/// plain http:// sites still open fine here even without any ATS exception.
struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let configuration = SFSafariViewController.Configuration()
        configuration.entersReaderIfAvailable = false
        return SFSafariViewController(url: url, configuration: configuration)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // Nothing to update — a different Site presents a fresh sheet/instance.
    }
}
