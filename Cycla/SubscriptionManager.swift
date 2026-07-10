import Foundation
import RevenueCat

/// A single source of truth for the user's subscription state.
///
/// This is the modern, recommended pattern:
///   • Configure the SDK once at app launch (see `CyclaApp`).
///   • Observe `Purchases.shared.customerInfoStream` — an `AsyncSequence` that
///     yields the cached `CustomerInfo` immediately and then again every time it
///     changes (after a purchase, restore, renewal, expiry, etc). This replaces
///     the older `PurchasesDelegate` callback for most apps.
///   • Everything is `@MainActor` so published values are always updated on the
///     main thread and are safe to read from SwiftUI.
@MainActor
final class SubscriptionManager: ObservableObject {

    // MARK: Published state

    /// The latest customer info from RevenueCat. `nil` until the first value arrives.
    @Published private(set) var customerInfo: CustomerInfo?

    /// The offerings (packages/products) available to display.
    @Published private(set) var offerings: Offerings?

    /// Set while a purchase/restore/network call is in flight.
    @Published private(set) var isBusy = false

    /// Surfaced to the UI when something goes wrong.
    @Published var errorMessage: String?

    // MARK: Derived state

    /// Whether the Pro entitlement is active on the RevenueCat side.
    private var proEntitlementActive: Bool {
        customerInfo?.entitlements[Constants.proEntitlementID]?.isActive == true
    }

    /// `true` when the user currently has Pro. Gate features on this — never on a
    /// specific product id, because entitlements abstract over monthly/yearly/lifetime.
    /// Also respects a locally-simulated cancellation (demo only).
    var isPro: Bool {
        proEntitlementActive && !demoCancelled
    }

    /// `true` when the user has the separate **Peloton** entitlement. This is an
    /// independent purchase path from Pro — buying Peloton doesn't grant Pro and
    /// vice versa (unless you attach the same products to both entitlements).
    var isPelotonUnlocked: Bool {
        (customerInfo?.entitlements[Constants.pelotonEntitlementID]?.isActive == true) && !pelotonCancelled
    }

    /// A one-line summary of everything the user is subscribed to.
    var membershipSummary: String {
        switch (isPro, isPelotonUnlocked) {
        case (true, true):   return "Cycla Pro + Peloton"
        case (true, false):  return proStatusDescription
        case (false, true):  return "Peloton nutrition"
        case (false, false):
            return (demoCancelled || pelotonCancelled) ? "Cancelled — resubscribe to restore access" : "Free plan"
        }
    }

    // MARK: Demo cancellation
    //
    // The Test Store (and StoreKit generally) has no in-app "cancel" — real
    // cancellation happens in the App Store and RevenueCat reflects it
    // automatically. For the demo we simulate it locally so the cancel flow
    // visibly returns the user to Free without leaving the app. It auto-clears
    // when the user re-subscribes.

    private static let demoCancelledKey = "cyclaDemoCancelled"

    @Published private(set) var demoCancelled = UserDefaults.standard.bool(forKey: SubscriptionManager.demoCancelledKey)

    /// Simulate cancelling the subscription (demo only).
    func cancelSubscription() {
        demoCancelled = true
        UserDefaults.standard.set(true, forKey: Self.demoCancelledKey)
    }

    /// Clear the simulated cancellation — called whenever the user re-subscribes.
    func clearDemoCancellation() {
        guard demoCancelled else { return }
        demoCancelled = false
        UserDefaults.standard.set(false, forKey: Self.demoCancelledKey)
    }

    // Peloton has its own independent simulated cancellation.
    private static let pelotonCancelledKey = "cyclaPelotonCancelled"

    @Published private(set) var pelotonCancelled = UserDefaults.standard.bool(forKey: SubscriptionManager.pelotonCancelledKey)

    func cancelPeloton() {
        pelotonCancelled = true
        UserDefaults.standard.set(true, forKey: Self.pelotonCancelledKey)
    }

    func clearPelotonCancellation() {
        guard pelotonCancelled else { return }
        pelotonCancelled = false
        UserDefaults.standard.set(false, forKey: Self.pelotonCancelledKey)
    }

    /// A human-friendly description of how the user unlocked Pro (for the profile screen).
    var proStatusDescription: String {
        if demoCancelled { return "Cancelled — resubscribe to restore Pro" }
        guard let entitlement = customerInfo?.entitlements[Constants.proEntitlementID],
              entitlement.isActive else {
            return "Free plan"
        }

        switch entitlement.periodType {
        case .trial:
            return "Pro — free trial"
        case .intro:
            return "Pro — intro offer"
        case .normal, .prepaid:
            if let expiry = entitlement.expirationDate {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                return "Pro — renews \(formatter.string(from: expiry))"
            }
            return "Pro — lifetime" // Non-consumable / lifetime purchases have no expiry.
        @unknown default:
            return "Pro"
        }
    }

    // MARK: Lifecycle

    /// Call once from the root view's `.task { }`.
    ///
    /// Loads offerings, then subscribes to the customer info stream for the
    /// lifetime of the app. The `for await` loop yields the current value
    /// immediately, so there's no separate "fetch on launch" step needed.
    func start() async {
        await loadOfferings()

        for await info in Purchases.shared.customerInfoStream {
            self.customerInfo = info
        }
    }

    // MARK: Offerings

    func loadOfferings() async {
        do {
            offerings = try await Purchases.shared.offerings()
        } catch {
            errorMessage = "Couldn't load subscription options: \(error.localizedDescription)"
        }
    }

    /// The offering to display in a paywall — either the one you named in
    /// `Constants`, or the dashboard's "current" offering.
    var displayOffering: Offering? {
        guard let offerings else { return nil }
        if let id = Constants.offeringIdentifier {
            return offerings.offering(identifier: id)
        }
        return offerings.current
    }

    /// Return a specific named offering, falling back to the current offering if
    /// that identifier isn't configured in the dashboard yet. This lets us ship
    /// tailored paywalls (welcome / peloton / retention) that degrade gracefully.
    func offering(id: String) -> Offering? {
        guard let offerings else { return nil }
        return offerings.offering(identifier: id) ?? offerings.current
    }

    var welcomeOffering: Offering? { offering(id: Constants.Offering.welcome) }
    var pelotonOffering: Offering? { offering(id: Constants.Offering.peloton) }
    var retentionOffering: Offering? { offering(id: Constants.Offering.retention) }

    // MARK: Account / identity

    /// The current RevenueCat App User ID (anonymous or your own).
    var appUserID: String { Purchases.shared.appUserID }

    /// `true` when the user hasn't been identified via `signIn`.
    var isAnonymous: Bool { Purchases.shared.isAnonymous }

    /// Where the user manages their subscription (App Store). `nil` on the Test
    /// Store / for users without a store-backed subscription.
    var managementURL: URL? { customerInfo?.managementURL }

    /// Identify the user with RevenueCat and attach subscriber attributes.
    /// In a real app you'd pass your backend's stable user id, not the raw email.
    func signIn(email: String) async {
        isBusy = true
        defer { isBusy = false }
        do {
            _ = try await Purchases.shared.logIn(email.lowercased())
            // Subscriber attributes power dashboards, targeting and integrations.
            Purchases.shared.attribution.setEmail(email)
            Purchases.shared.attribution.setDisplayName(email.components(separatedBy: "@").first)
        } catch {
            handle(error)
        }
    }

    /// Return to an anonymous user.
    func signOut() async {
        isBusy = true
        defer { isBusy = false }
        do {
            _ = try await Purchases.shared.logOut()
        } catch {
            handle(error)
        }
    }

    // MARK: Manage / cancel

    /// Open the OS subscription-management screen (App Store). On the Test Store
    /// there's nothing to open, so we surface a friendly message instead.
    func openManageSubscriptions() async {
        do {
            try await Purchases.shared.showManageSubscriptions()
        } catch {
            errorMessage = "Subscription management isn't available here. On a real device this opens your App Store subscriptions."
        }
    }

    // MARK: Purchasing

    /// Purchase a specific package. Returns `true` if the user is now Pro.
    ///
    /// Note: when you use RevenueCat's *Paywall UI* (`PaywallView` /
    /// `presentPaywallIfNeeded`), the SDK handles the purchase for you and this
    /// method isn't needed. It's here for the "roll your own paywall" case and to
    /// show correct error handling (including user cancellation).
    @discardableResult
    func purchase(_ package: Package) async -> Bool {
        isBusy = true
        defer { isBusy = false }

        do {
            let result = try await Purchases.shared.purchase(package: package)
            self.customerInfo = result.customerInfo
            if result.userCancelled { return false }
            let active = result.customerInfo.entitlements[Constants.proEntitlementID]?.isActive == true
            if active { clearDemoCancellation() }
            return active
        } catch {
            handle(error)
            return false
        }
    }

    /// Restore previous purchases (App Store requirement to offer this).
    @discardableResult
    func restorePurchases() async -> Bool {
        isBusy = true
        defer { isBusy = false }

        do {
            let info = try await Purchases.shared.restorePurchases()
            self.customerInfo = info
            let proActive = info.entitlements[Constants.proEntitlementID]?.isActive == true
            let pelotonActive = info.entitlements[Constants.pelotonEntitlementID]?.isActive == true
            if proActive { clearDemoCancellation() }
            if pelotonActive { clearPelotonCancellation() }
            let restored = proActive || pelotonActive
            if !restored {
                errorMessage = "No previous purchases were found to restore."
            }
            return restored
        } catch {
            handle(error)
            return false
        }
    }

    // MARK: Error handling

    /// Convert RevenueCat/StoreKit errors into user-facing messages, while
    /// silently ignoring user-initiated cancellations (never show those as errors).
    private func handle(_ error: Error) {
        if let rcError = error as? RevenueCat.ErrorCode {
            switch rcError {
            case .purchaseCancelledError:
                return // User tapped "Cancel" — not an error.
            default:
                errorMessage = rcError.localizedDescription
            }
        } else {
            errorMessage = error.localizedDescription
        }
    }
}
