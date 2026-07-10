import Foundation

/// Central place for all RevenueCat-related configuration.
///
/// ⚠️ Demo app: the API key below is hard-coded for convenience. In a real app
/// you should inject it from a build setting / xcconfig / environment variable and
/// NEVER ship a *Test Store* key to the App Store.
enum Constants {

    /// Public SDK key from RevenueCat → Project Settings → API keys.
    /// This is the "testing account" app key you provided.
    static let revenueCatAPIKey = "test_hKqAJgktsskZdSLdWmJuGZhUpjH"

    /// The entitlement identifier that unlocks Pro content.
    ///
    /// This MUST match the entitlement identifier configured in the RevenueCat
    /// dashboard exactly (Project → Entitlements). You told me it is
    /// "testing account Pro".
    static let proEntitlementID = "testing account Pro"

    /// Separate entitlement that unlocks the advanced "Peloton" nutrition plan.
    /// Independent of Pro — its own purchase path.
    static let pelotonEntitlementID = "Peloton"

    /// Optional: the identifier of the Offering you want to display.
    /// `nil` = use the "current" offering configured in the dashboard (recommended).
    static let offeringIdentifier: String? = nil

    /// Named offerings used for specific surfaces. Create these in the RevenueCat
    /// dashboard (Offerings) to serve tailored paywalls; if an offering doesn't
    /// exist, the app gracefully falls back to the current offering.
    enum Offering {
        /// Shown once to brand-new users (first launch).
        static let welcome = "welcome"
        /// The advanced "Peloton" nutrition plan paywall (matches the dashboard
        /// offering name exactly — it's case-sensitive).
        static let peloton = "Peloton"
        /// Retention / win-back offer shown in the cancellation flow.
        static let retention = "retention"
    }

    /// Product identifiers you configured in App Store Connect / RevenueCat.
    /// Kept here for reference — the paywall and offerings are driven by the
    /// dashboard, so you normally don't reference these directly in code.
    enum ProductID {
        static let lifetime = "lifetime"
        static let yearly = "yearly"
        static let monthly = "monthly"
    }
}
