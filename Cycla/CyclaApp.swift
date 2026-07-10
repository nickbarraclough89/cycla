import SwiftUI
import RevenueCat

@main
struct CyclaApp: App {

    /// Owned here so it lives for the whole app session and is injected into the
    /// environment for every screen.
    @StateObject private var subscriptions = SubscriptionManager()

    init() {
        // Verbose logs are great during development. Turn this down (or to
        // `.info`) before shipping.
        Purchases.logLevel = .debug

        // Configure the SDK exactly once, as early as possible.
        // We pass no appUserID, so RevenueCat generates an anonymous ID and will
        // transparently link purchases if you later call `Purchases.shared.logIn`.
        Purchases.configure(withAPIKey: Constants.revenueCatAPIKey)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(subscriptions)
                // Kick off offerings load + the customerInfo stream. This task is
                // tied to the root view, so it runs for the app's lifetime.
                .task { await subscriptions.start() }
        }
    }
}
