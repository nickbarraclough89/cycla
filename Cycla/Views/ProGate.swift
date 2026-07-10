import SwiftUI
import RevenueCat
import RevenueCatUI

/// A reusable modifier that automatically shows the RevenueCat paywall whenever
/// the user does NOT have the Pro entitlement, and only reveals the wrapped
/// content once they do.
///
/// This uses `presentPaywallIfNeeded(requiredEntitlementIdentifier:)`, which is
/// the most declarative of RevenueCat's three presentation styles — you describe
/// the requirement and the SDK handles fetching offerings, showing/hiding the
/// paywall, and re-checking the entitlement after purchase/restore.
///
/// Usage:
/// ```swift
/// PremiumWorkoutView()
///     .requiresPro()
/// ```
struct ProGate: ViewModifier {
    func body(content: Content) -> some View {
        content
            .presentPaywallIfNeeded(
                requiredEntitlementIdentifier: Constants.proEntitlementID,
                purchaseCompleted: { customerInfo in
                    print("[Cycla] Purchase completed. Active: \(customerInfo.entitlements.active.keys)")
                },
                restoreCompleted: { customerInfo in
                    print("[Cycla] Restore completed. Active: \(customerInfo.entitlements.active.keys)")
                }
            )
    }
}

extension View {
    /// Gate a view behind the Cycla Pro entitlement. Shows a paywall automatically
    /// if the user isn't subscribed.
    func requiresPro() -> some View {
        modifier(ProGate())
    }
}
