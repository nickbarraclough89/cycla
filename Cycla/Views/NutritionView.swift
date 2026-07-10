import SwiftUI
import RevenueCat
import RevenueCatUI

struct NutritionView: View {
    @EnvironmentObject private var subscriptions: SubscriptionManager

    @State private var selectedPlan: NutritionPlan?
    @State private var showPelotonPaywall = false

    private let plans = NutritionPlan.samples

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Fuel your riding. Free basics for everyone — the advanced **Peloton** programme is a separate add-on.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Section("Nutrition plans") {
                    ForEach(plans) { plan in
                        Button {
                            open(plan)
                        } label: {
                            NutritionRow(plan: plan,
                                         locked: plan.requiresPeloton && !subscriptions.isPelotonUnlocked)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("Nutrition")
            .navigationDestination(item: $selectedPlan) { plan in
                NutritionDetailView(plan: plan)
            }
            // Locked Peloton opens its paywall directly — no interstitial.
            .sheet(isPresented: $showPelotonPaywall) {
                if let offering = subscriptions.pelotonOffering {
                    PaywallView(offering: offering, displayCloseButton: true)
                        .onPurchaseCompleted { _ in
                            subscriptions.clearPelotonCancellation()
                            showPelotonPaywall = false
                        }
                }
            }
        }
    }

    /// A locked Peloton plan goes straight to its paywall; anything the user can
    /// access opens the plan detail.
    private func open(_ plan: NutritionPlan) {
        if plan.requiresPeloton && !subscriptions.isPelotonUnlocked {
            showPelotonPaywall = true
        } else {
            selectedPlan = plan
        }
    }
}

private struct NutritionRow: View {
    let plan: NutritionPlan
    let locked: Bool

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: plan.systemImage)
                .font(.title2)
                .frame(width: 44, height: 44)
                .background(Color.green.opacity(0.15))
                .foregroundStyle(.green)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(plan.title).font(.headline)
                    if plan.requiresPeloton {
                        Text("PREMIUM")
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

/// Full plan content (shown when the plan is accessible).
private struct NutritionDetailView: View {
    let plan: NutritionPlan

    var body: some View {
        List {
            Section {
                ForEach(plan.highlights, id: \.self) { item in
                    Label(item, systemImage: "checkmark.seal.fill")
                        .foregroundStyle(.primary)
                }
            } header: {
                Text("What's included")
            }

            Section("A day on the plan") {
                ForEach(plan.sampleDay) { item in
                    VStack(alignment: .leading, spacing: 3) {
                        Text(item.time).font(.caption.bold()).foregroundStyle(.green)
                        Text(item.meal).font(.headline)
                        Text(item.detail).font(.subheadline).foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .navigationTitle(plan.title)
    }
}
