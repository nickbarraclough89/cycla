import SwiftUI
import WebKit

/// The referrer dashboard, powered by the Mention Me **Entry Point API**.
///
/// The backend returns a signed, hosted journey URL (real offer, share tools and
/// — with the auth secret — the full dashboard with stats). We load it here in a
/// web view, which is the intended mobile integration for the hosted journeys.
struct ReferrerDashboardView: View {
    let email: String
    let firstname: String
    let surname: String
    @Environment(\.dismiss) private var dismiss

    @State private var entry: MentionMeEntryPoint?
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading your referral dashboard…")
                } else if let entry, let url = URL(string: entry.url) {
                    WebView(url: url)
                } else {
                    errorView
                }
            }
            .navigationTitle("Refer a friend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
            }
            .task { await load() }
        }
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        do {
            entry = try await MentionMeService.fetchReferrerEntryPoint(
                email: email, firstname: firstname, surname: surname)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private var errorView: some View {
        ContentUnavailableView {
            Label("Couldn't load dashboard", systemImage: "wifi.slash")
        } description: {
            Text(errorMessage ?? "Make sure the Mention Me backend is running (npm start in cycla-mentionme-backend).")
        } actions: {
            Button("Retry") { Task { await load() } }
        }
    }
}

/// Loads a URL in a WKWebView.
private struct WebView: UIViewRepresentable {
    let url: URL
    func makeUIView(context: Context) -> WKWebView { WKWebView() }
    func updateUIView(_ webView: WKWebView, context: Context) {
        webView.load(URLRequest(url: url))
    }
}
