# RevenueCat Integration Cheat Sheet — Cycla

## The whole integration in 4 moves
1. **Add SPM package** `github.com/RevenueCat/purchases-ios-spm` → products **RevenueCat** + **RevenueCatUI**.
2. **Configure once** at launch: `Purchases.configure(withAPIKey:)`.
3. **Wrap the SDK** in one service (`SubscriptionManager`) that exposes plain booleans.
4. **Gate features** on those booleans + drop in `PaywallView` / `CustomerCenterView`.
> The rest of the app never imports RevenueCat. Low surface area = low adoption/removal risk.

## Minimum viable integration (the 3 lines)
```swift
Purchases.configure(withAPIKey: "appl_or_test_key")            // 1. init
let info = try await Purchases.shared.customerInfo()           // 2. read state
if info.entitlements["pro"]?.isActive == true { /* unlock */ } // 3. gate
```

## Core mental model (the #1 thing to nail)
| Concept | = | In Cycla |
|---|---|---|
| **Product** | what you *sell* (SKU + price) | `monthly`, `yearly`, `lifetime`, `Peloton_Monthly/Yearly` |
| **Entitlement** | what you *unlock* (access level) | `testing account Pro`, `Peloton` |
| **Offering** | what you *present* (a paywall's packages) | `default`, `Peloton` |
- Gate features on **entitlements**, never product IDs → bundles/upgrades become trivial.
- One product can unlock **multiple** entitlements → that's how an all-access bundle works.

## Key APIs (all live in `SubscriptionManager.swift`)
```swift
Purchases.configure(withAPIKey:)               // launch
Purchases.shared.customerInfoStream            // live entitlement updates (AsyncSequence)
Purchases.shared.offerings()                   // fetch paywall data
customerInfo.entitlements["id"]?.isActive      // gate check
Purchases.shared.purchase(package:)            // buy (or let PaywallView do it)
Purchases.shared.restorePurchases()            // required by App Store
Purchases.shared.logIn(id) / logOut()          // identity
Purchases.shared.attribution.setEmail(...)     // subscriber attributes
Purchases.shared.showManageSubscriptions()     // deep-link to App Store mgmt
```

## RevenueCatUI (zero custom paywall code)
```swift
PaywallView(offering: o, displayCloseButton: true)      // manual present
.presentPaywallIfNeeded(requiredEntitlementIdentifier:) // declarative gate
CustomerCenterView()                                    // manage/cancel/refund/retention
.onPurchaseCompleted { info in } / .onRestoreCompleted  // hooks
```
Paywalls are **server-driven** → edit design in the dashboard, no app release, no code change.

## Where the money flows (RevenueCat never touches it)
```
User → Apple/Google/Stripe → (minus cut) → YOUR bank
                │  receipts / server notifications
                ▼
          RevenueCat → validates, sets entitlement, analytics
                ▼
      Apps check entitlement → unlock
```
- App Store / Play IAP = **15–30%** cut; store is merchant of record (handles tax).
- Web via **RevenueCat Billing** (Stripe under the hood) = **~2.9%**; **you** are merchant of record (you own tax/chargebacks).
- Payoff: **one entitlement across web + desktop + iOS + Android** — buy anywhere, use everywhere.
- RevenueCat charges a **SaaS fee on tracked revenue**, not a transaction cut.

## Test Store vs RevenueCat Billing
- **Test Store** = simulated purchases, dev only, no money, `test_` key. (What Cycla uses.)
- **RevenueCat Billing** = real web payments via Stripe.

## Objection one-liners
- *"We'll build it ourselves"* → happy path is easy; grace periods, billing retries, refunds, store API changes, cross-platform parity are permanent maintenance.
- *"Cost?"* → free to start; ROI = faster paywall iteration (conversion/LTV) + reclaimed eng time.
- *"Lock-in?"* → webhooks + exports; you own your data; tiny integration surface to remove.
- *"Why not Superwall/Adapty?"* → RevenueCat = full infra + paywalls + billing + analytics, not paywall-only.

## Cycla file map
- `CyclaApp.swift` → configure + inject
- `SubscriptionManager.swift` → **the only file that talks to the SDK** (isPro / isPelotonUnlocked)
- `Constants.swift` → API key, entitlement + offering IDs
- `PlansView` / `NutritionView` / `ProfileView` → gate on booleans + present paywalls
- `WelcomeOfferView` (first-run offer), `CancellationFlowView` (survey→retention→cancel), `ProGate` (`.requiresPro()`)

## 30-second pitch of this app
"Existing SwiftUI app. Integrating RevenueCat was: add the package, one `configure` call, a `SubscriptionManager` that turns `customerInfoStream` into `isPro`/`isPelotonUnlocked`, then gate features on those and drop in `PaywallView`/`CustomerCenterView`. Pro and Peloton are separate entitlements; paywalls are dashboard-designed so I can iterate without shipping."
