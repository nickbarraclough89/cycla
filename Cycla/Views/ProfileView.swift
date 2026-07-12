import SwiftUI
import RevenueCat
import RevenueCatUI

struct ProfileView: View {
    @EnvironmentObject private var subscriptions: SubscriptionManager

    @State private var showProPaywall = false
    @State private var showPelotonPaywall = false
    @State private var showCustomerCenter = false
    @State private var cancelTarget: CancellationFlowView.Target?
    @State private var showSignIn = false
    @State private var showWelcomePreview = false
    @State private var showReferrer = false
    @State private var emailInput = ""

    /// Mirror of the first-run flag so we can reset it for testing.
    @AppStorage("hasSeenWelcomeOffer") private var hasSeenWelcomeOffer = false

    private var hasAnySubscription: Bool {
        subscriptions.isPro || subscriptions.isPelotonUnlocked
    }

    var body: some View {
        NavigationStack {
            List {
                // MARK: Status
                Section {
                    HStack(spacing: 14) {
                        Image(systemName: statusIcon)
                            .font(.largeTitle)
                            .foregroundStyle(hasAnySubscription ? .orange : .secondary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Cycla athlete").font(.headline)
                            Text(subscriptions.membershipSummary)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 6)
                }

                // MARK: Account (user identification)
                Section("Account") {
                    if subscriptions.isAnonymous {
                        Button {
                            showSignIn = true
                        } label: {
                            Label("Sign in", systemImage: "person.crop.circle.badge.plus")
                        }
                    } else {
                        Label(subscriptions.appUserID, systemImage: "person.crop.circle.badge.checkmark")
                            .font(.footnote)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Button(role: .destructive) {
                            Task { await subscriptions.signOut() }
                        } label: {
                            Label("Sign out", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    }
                }

                // MARK: Cycla Pro
                Section("Cycla Pro") {
                    if subscriptions.isPro {
                        Label("Active", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(.green)
                        Button(role: .destructive) {
                            cancelTarget = .pro
                        } label: {
                            Label("Cancel subscription", systemImage: "xmark.circle")
                        }
                    } else {
                        Button {
                            showProPaywall = true
                        } label: {
                            Label("Upgrade to Cycla Pro", systemImage: "crown.fill")
                        }
                        Text("Every training plan, structured workouts and race-day prep.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                // MARK: Peloton (separate subscription)
                Section("Peloton nutrition") {
                    if subscriptions.isPelotonUnlocked {
                        Label("Active", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(.green)
                        Button(role: .destructive) {
                            cancelTarget = .peloton
                        } label: {
                            Label("Cancel subscription", systemImage: "xmark.circle")
                        }
                    } else {
                        Button {
                            showPelotonPaywall = true
                        } label: {
                            Label("Unlock Peloton", systemImage: "bolt.heart.fill")
                        }
                        Text("Advanced periodised race nutrition. Sold separately from Pro.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                // MARK: Manage / restore
                Section {
                    if hasAnySubscription {
                        // Customer Center natively manages ALL of the user's
                        // subscriptions (Pro and Peloton) in one place.
                        Button {
                            showCustomerCenter = true
                        } label: {
                            Label("Manage subscriptions", systemImage: "gearshape")
                        }
                    }

                    // App Store requires a visible "Restore Purchases" action.
                    Button {
                        Task { await subscriptions.restorePurchases() }
                    } label: {
                        Label("Restore purchases", systemImage: "arrow.clockwise")
                    }
                    .disabled(subscriptions.isBusy)
                }

                // MARK: Referrals (Mention Me)
                Section("Referrals") {
                    Button {
                        showReferrer = true
                    } label: {
                        Label("Refer a friend", systemImage: "gift")
                    }
                    Text("Give £10, get £10 when a friend subscribes.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                // MARK: Testing helpers (remove for production)
                Section("Testing") {
                    Button {
                        showWelcomePreview = true
                    } label: {
                        Label("Preview welcome offer", systemImage: "sparkles")
                    }
                    Button {
                        hasSeenWelcomeOffer = false
                    } label: {
                        Label("Reset first-run welcome", systemImage: "arrow.counterclockwise")
                    }
                    .disabled(!hasSeenWelcomeOffer)
                }
            }
            .navigationTitle("Profile")
            .overlay {
                if subscriptions.isBusy {
                    ProgressView().controlSize(.large)
                }
            }
            .sheet(isPresented: $showProPaywall) {
                PaywallView(displayCloseButton: true)
                    .onPurchaseCompleted { _ in
                        subscriptions.clearDemoCancellation()
                        showProPaywall = false
                    }
            }
            .sheet(isPresented: $showReferrer) {
                ReferrerDashboardView(
                    email: subscriptions.isAnonymous ? "jane.doe@example.com" : subscriptions.appUserID,
                    firstname: "Cycla", surname: "Rider")
            }
            .sheet(isPresented: $showPelotonPaywall) {
                if let offering = subscriptions.pelotonOffering {
                    PaywallView(offering: offering, displayCloseButton: true)
                        .onPurchaseCompleted { _ in
                            subscriptions.clearPelotonCancellation()
                            showPelotonPaywall = false
                        }
                }
            }
            .sheet(isPresented: $showCustomerCenter) {
                CustomerCenterView()
            }
            .sheet(item: $cancelTarget) { target in
                CancellationFlowView(target: target)
            }
            .sheet(isPresented: $showWelcomePreview) {
                WelcomeOfferView { showWelcomePreview = false }
            }
            .alert("Sign in", isPresented: $showSignIn) {
                TextField("Email", text: $emailInput)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                Button("Sign in") {
                    let email = emailInput.trimmingCharacters(in: .whitespaces)
                    guard !email.isEmpty else { return }
                    Task { await subscriptions.signIn(email: email) }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Identify yourself with RevenueCat so purchases follow you across devices.")
            }
            .alert("Something went wrong",
                   isPresented: Binding(
                    get: { subscriptions.errorMessage != nil },
                    set: { if !$0 { subscriptions.errorMessage = nil } }
                   ),
                   actions: { Button("OK", role: .cancel) {} },
                   message: { Text(subscriptions.errorMessage ?? "") })
        }
    }

    private var statusIcon: String {
        if subscriptions.isPro { return "crown.fill" }
        if subscriptions.isPelotonUnlocked { return "bolt.heart.fill" }
        return "person.circle"
    }
}

#Preview {
    ProfileView()
        .environmentObject(SubscriptionManager())
}
