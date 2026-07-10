# Cycla 🚴 — RevenueCat demo app

A minimal SwiftUI demo app (the cycling answer to Runna) showing a **complete, modern
RevenueCat integration**: SDK config, entitlement gating, offerings, a drop-in
**Paywall**, and the **Customer Center**.

> Demo only. The RevenueCat **Test Store** key is hard-coded in `Constants.swift`.
> Never ship a Test Store key to the App Store.

---

## 1. Open & build

```bash
open Cycla.xcodeproj
```

On first launch Xcode will resolve the Swift Package
(`https://github.com/RevenueCat/purchases-ios-spm.git`, pinned to `5.80.3`, "up to
next major"). Pick an iOS 16+ simulator and hit **Run**.

### Building from the command line
The command-line build needs the Xcode license accepted once:

```bash
sudo xcodebuild -license accept
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -project Cycla.xcodeproj -scheme Cycla \
  -destination 'generic/platform=iOS Simulator' \
  -configuration Debug build CODE_SIGNING_ALLOWED=NO
```

---

## 2. What's wired up (maps to the RevenueCat docs)

| Requirement | Where |
|---|---|
| Install via Swift Package | `Cycla.xcodeproj` references `purchases-ios-spm` → products **RevenueCat** + **RevenueCatUI** |
| Configure with API key | `CyclaApp.init()` → `Purchases.configure(withAPIKey:)` |
| Entitlement check: **testing account Pro** | `Constants.proEntitlementID` + `SubscriptionManager.isPro` |
| Customer info & purchases | `SubscriptionManager` (customerInfoStream, purchase, restore) |
| Products: lifetime / yearly / monthly | Configured in the dashboard; surfaced via Offerings + Paywall |
| Present a Paywall | `PaywallView` in `PlansView` & `ProfileView`; `presentPaywallIfNeeded` in `ProGate.swift` |
| Customer Center | `CustomerCenterView` in `ProfileView` |

### Added features (v2)
- **First-time welcome offer** — `WelcomeOfferView`, shown once on first launch via
  the `welcome` offering (falls back to current). Gated by an `@AppStorage` flag.
- **Nutrition tab + "Peloton" paywall** — `NutritionView`; the advanced **Peloton**
  plan shows a content-preview teaser with a pinned unlock bar that presents the
  `peloton` offering paywall.
- **Cancellation + retention flow** — `CancellationFlowView`: reason survey →
  retention "special offer to stay" → two routes (claim offer via the `retention`
  offering paywall, or continue to cancel via App Store subscription management).
  Records the cancellation reason as a RevenueCat subscriber attribute.
- **User identification** — Profile → Account: `Purchases.logIn` / `logOut` plus
  `attribution.setEmail` / `setDisplayName`.
- **Customer Center** — native subscription management (`CustomerCenterView`).

### Named offerings to create in the dashboard (optional, all fall back to current)
| Offering id | Used by |
|---|---|
| `welcome` | First-launch welcome offer |
| `peloton` | Peloton nutrition paywall |
| `retention` | "Special offer to stay" in the cancel flow |

### Key files
- `Constants.swift` – API key, entitlement id, product ids.
- `SubscriptionManager.swift` – `@MainActor ObservableObject`, single source of truth.
  Observes `Purchases.shared.customerInfoStream`, exposes `isPro`, `purchase`, `restore`.
- `CyclaApp.swift` – configures the SDK once, injects the manager, starts the stream.
- `Views/PlansView.swift` – catalogue; tapping a locked **PRO** plan shows the paywall.
- `Views/ProfileView.swift` – status, restore, **Customer Center** (Pro), upgrade (free).
- `Views/ProGate.swift` – reusable `.requiresPro()` modifier using `presentPaywallIfNeeded`.

---

## 3. RevenueCat dashboard setup (do this once)

The app is complete, but purchases only work after the dashboard is configured to
match. In [app.revenuecat.com](https://app.revenuecat.com):

1. **Products** – create/import three products with identifiers exactly:
   `lifetime`, `yearly`, `monthly` (App Store Connect for real IAPs, or use the
   built-in **Test Store** for pure in-simulator testing).
2. **Entitlement** – create an entitlement whose identifier is **`testing account Pro`**
   (must match `Constants.proEntitlementID` character-for-character, spaces included).
   Attach all three products to it.
3. **Offering** – create an Offering (e.g. `default`), mark it **Current**, and add
   three packages → Lifetime, Annual, Monthly, pointing at the products above.
4. **Paywall** – on that Offering, click **Add Paywall**, design it in the editor and
   publish. `PaywallView()` renders whatever you design here — no code changes needed.
5. **Customer Center** – enable it under **Tools → Customer Center** and configure the
   management/support options. `CustomerCenterView()` renders that config.

> Tip: if the entitlement identifier really does contain spaces, consider renaming it
> to something like `pro` in the dashboard and here — it avoids easy-to-miss typos.
> I kept it as you specified.

---

## 4. Testing purchases
- **Test Store** (fastest): no App Store Connect / StoreKit needed — purchases run
  entirely through RevenueCat. Good for demoing the paywall flow in the simulator.
- **StoreKit sandbox**: add a StoreKit configuration file / sandbox tester for
  end-to-end App Store behaviour.

After a successful purchase the `customerInfoStream` fires, `isPro` flips to `true`,
locked plans open, and the Profile tab switches to **Manage subscription**.
