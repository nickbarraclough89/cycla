import Foundation

/// Central place for the identifiers that link this app to your RevenueCat and
/// Mention Me dashboards. These are just the *names/keys* — the actual offerings,
/// products, prices and paywalls are managed in the dashboards and pulled live at
/// runtime. Every string here must match the dashboard **exactly** (case- and
/// space-sensitive).
enum Constants {

    // MARK: RevenueCat

    /// Public SDK key from RevenueCat → Project Settings → API keys. This is the
    /// only connection the app needs — it determines which project's offerings
    /// and entitlements are pulled.
    static let revenueCatAPIKey = "test_hKqAJgktsskZdSLdWmJuGZhUpjH"

    /// Entitlement that unlocks Pro content (RevenueCat → Entitlements).
    static let proEntitlementID = "testing account Pro"

    /// Separate entitlement that unlocks the advanced "Peloton" nutrition plan.
    static let pelotonEntitlementID = "Peloton"

    /// Offering identifiers, matched by name against the dashboard. If one doesn't
    /// exist, the app falls back to the current offering.
    enum Offering {
        /// First-launch welcome offer.
        static let welcome = "welcome"
        /// Advanced "Peloton" nutrition paywall (case-sensitive).
        static let peloton = "Peloton"
        /// Retention offer shown in the cancellation flow.
        static let retention = "retention"
        /// All access pro offering.
        static let Champ_Pro = "Champ_Pro"
        /// All access Peloton offering..
        static let Champ_peloton = "Champ_peloton"
    }

    // MARK: Mention Me

    /// Backend that signs & proxies the Mention Me API (partner code + secrets
    /// live there, never in the app). `http://localhost:8787` works from the
    /// Simulator; point it at your deployed backend for real devices.
    enum MentionMe {
        static let backendBaseURL = "http://localhost:8787"
    }
}
