import SwiftUI
import RevenueCat
import RevenueCatUI

struct PlansView: View {
    @EnvironmentObject private var subscriptions: SubscriptionManager

    @State private var selectedPlan: TrainingPlan?
    @State private var showPaywall = false

    private let plans = TrainingPlan.samples

    var body: some View {
        NavigationStack {
            List {
                if !subscriptions.isPro {
                    Section {
                        proUpsellBanner
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                    }
                }

                Section("Training plans") {
                    ForEach(plans) { plan in
                        Button {
                            open(plan)
                        } label: {
                            PlanRow(plan: plan, locked: plan.isPro && !subscriptions.isPro)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("Cycla")
            .navigationDestination(item: $selectedPlan) { plan in
                PlanDetailView(plan: plan)
            }
            // Manual paywall presentation: we decide *when* to show it (when a
            // locked plan is tapped). `PaywallView` automatically renders the
            // current offering configured in the RevenueCat dashboard.
            .sheet(isPresented: $showPaywall) {
                PaywallView(displayCloseButton: true)
                    // Dismiss automatically once the required entitlement is active.
                    .onPurchaseCompleted { _ in
                        subscriptions.clearDemoCancellation()
                        showPaywall = false
                    }
                    .onRestoreCompleted { customerInfo in
                        if customerInfo.entitlements[Constants.proEntitlementID]?.isActive == true {
                            subscriptions.clearDemoCancellation()
                            showPaywall = false
                        }
                    }
            }
        }
    }

    /// Free plans (or any plan when the user is Pro) open directly. A locked plan
    /// triggers the paywall instead.
    private func open(_ plan: TrainingPlan) {
        if plan.isPro && !subscriptions.isPro {
            showPaywall = true
        } else {
            selectedPlan = plan
        }
    }

    private var proUpsellBanner: some View {
        Button {
            showPaywall = true
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                Label("Unlock Cycla Pro", systemImage: "crown.fill")
                    .font(.headline)
                Text("Every training plan, structured workouts and race prep.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(
                LinearGradient(colors: [.orange, .pink],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

private struct PlanRow: View {
    let plan: TrainingPlan
    let locked: Bool

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: plan.systemImage)
                .font(.title2)
                .frame(width: 44, height: 44)
                .background(Color.orange.opacity(0.15))
                .foregroundStyle(.orange)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(plan.title).font(.headline)
                    if plan.isPro {
                        Text("PRO")
                            .font(.caption2.bold())
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.orange.opacity(0.2))
                            .foregroundStyle(.orange)
                            .clipShape(Capsule())
                    }
                }
                Text(plan.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                Text("\(plan.level.rawValue) · \(plan.weeks) weeks · \(plan.sessionsPerWeek)×/week")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            Image(systemName: locked ? "lock.fill" : "chevron.right")
                .font(.footnote)
                .foregroundStyle(locked ? .orange : .secondary)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

#Preview {
    PlansView()
        .environmentObject(SubscriptionManager())
}
