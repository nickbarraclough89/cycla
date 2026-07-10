import SwiftUI
import RevenueCat
import RevenueCatUI

/// A one-time "first launch" offer. New users see a tailored paywall built from
/// the `welcome` offering in the RevenueCat dashboard (falling back to the
/// current offering if you haven't created a dedicated one yet).
///
/// Showing a specific offering to first-time users is a common growth lever —
/// pair it with an intro price / free trial on the products in that offering.
struct WelcomeOfferView: View {
    @EnvironmentObject private var subscriptions: SubscriptionManager

    /// Called when the offer is dismissed or a purchase completes, so the caller
    /// can mark the welcome flow as seen.
    let onFinish: () -> Void

    var body: some View {
        Group {
            if let offering = subscriptions.welcomeOffering {
                PaywallView(offering: offering, displayCloseButton: true)
                    .onPurchaseCompleted { _ in
                        subscriptions.clearDemoCancellation()
                        onFinish()
                    }
                    .onRestoreCompleted { _ in
                        subscriptions.clearDemoCancellation()
                        onFinish()
                    }
            } else {
                // Offerings still loading — show a lightweight branded splash.
                VStack(spacing: 16) {
                    Image(systemName: "bicycle.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.orange)
                    Text("Welcome to Cycla")
                        .font(.title.bold())
                    ProgressView()
                    Button("Maybe later", action: onFinish)
                        .padding(.top, 8)
                }
                .padding()
            }
        }
        // If the user swipes the sheet away, still mark it as seen.
        .interactiveDismissDisabled(false)
        .onDisappear(perform: onFinish)
    }
}
