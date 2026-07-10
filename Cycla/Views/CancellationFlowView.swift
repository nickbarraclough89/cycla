import SwiftUI
import RevenueCat
import RevenueCatUI

/// A custom, fully-visible cancellation journey, reused for both subscriptions:
///   1. Reason survey  →  2. Retention "special offer to stay"  →  two routes:
///        • Claim the offer  → retention paywall (keeps them subscribed)
///        • Continue to cancel → simplified in-app cancellation
///
/// In production, RevenueCat's **Customer Center** does all of this natively.
struct CancellationFlowView: View {
    /// Which subscription is being cancelled.
    enum Target: String, Identifiable {
        case pro, peloton
        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .pro:     return "Cycla Pro"
            case .peloton: return "Peloton nutrition"
            }
        }

        var benefits: String {
            switch self {
            case .pro:     return "every training plan, structured workouts and race-day prep"
            case .peloton: return "the advanced Peloton periodised nutrition programme"
            }
        }
    }

    let target: Target

    @EnvironmentObject private var subscriptions: SubscriptionManager
    @Environment(\.dismiss) private var dismiss

    private enum Step { case survey, retentionOffer, confirmCancel }

    @State private var step: Step = .survey
    @State private var selectedReason: String?
    @State private var showRetentionPaywall = false

    private let reasons = [
        "Too expensive",
        "Not using it enough",
        "Missing features I want",
        "Just taking a break",
        "Something else"
    ]

    var body: some View {
        NavigationStack {
            Group {
                switch step {
                case .survey:          surveyStep
                case .retentionOffer:  retentionStep
                case .confirmCancel:   confirmStep
                }
            }
            .padding()
            .navigationTitle("Cancel \(target.displayName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            // Route A — the retention offer paywall.
            .sheet(isPresented: $showRetentionPaywall) {
                if let offering = subscriptions.retentionOffering {
                    PaywallView(offering: offering, displayCloseButton: true)
                        .onPurchaseCompleted { _ in
                            clearCancellation() // they stayed
                            showRetentionPaywall = false
                            dismiss()
                        }
                }
            }
        }
    }

    // MARK: Step 1 — survey

    private var surveyStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("We're sorry to see you thinking about leaving \(target.displayName). What's the main reason?")
                .font(.headline)

            VStack(spacing: 10) {
                ForEach(reasons, id: \.self) { reason in
                    Button {
                        selectedReason = reason
                    } label: {
                        HStack {
                            Text(reason)
                            Spacer()
                            if selectedReason == reason {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(.orange)
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()

            Button {
                if let reason = selectedReason {
                    Purchases.shared.attribution.setAttributes([
                        "cancellation_reason_\(target.rawValue)": reason
                    ])
                }
                step = .retentionOffer
            } label: {
                Text("Continue").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            .disabled(selectedReason == nil)
        }
    }

    // MARK: Step 2 — retention offer (both routes)

    private var retentionStep: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "gift.fill")
                .font(.system(size: 56))
                .foregroundStyle(.orange)
            Text("Wait — here's a special offer")
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            Text("Stay and keep \(target.benefits). We'd love for you to stay.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer()

            // Route A — accept the offer.
            Button {
                showRetentionPaywall = true
            } label: {
                Text("Claim my offer & stay").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)

            // Route B — proceed to cancel.
            Button(role: .destructive) {
                step = .confirmCancel
            } label: {
                Text("No thanks, continue to cancel").frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }

    // MARK: Step 3 — confirm cancellation

    private var confirmStep: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "hand.wave.fill")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            Text("Cancel \(target.displayName)")
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            Text("Are you sure? You'll lose access to \(target.benefits). You can resubscribe any time.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer()

            Button(role: .destructive) {
                // Simplified in-app cancellation (demo). Returns the user to Free
                // for this subscription immediately. In production you'd deep-link
                // to the App Store subscription settings instead.
                cancelNow()
                dismiss()
            } label: {
                Text("Confirm cancellation").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)

            Button("Keep my subscription") { dismiss() }
                .padding(.top, 4)
        }
    }

    // MARK: Actions per target

    private func cancelNow() {
        switch target {
        case .pro:     subscriptions.cancelSubscription()
        case .peloton: subscriptions.cancelPeloton()
        }
    }

    private func clearCancellation() {
        switch target {
        case .pro:     subscriptions.clearDemoCancellation()
        case .peloton: subscriptions.clearPelotonCancellation()
        }
    }
}
