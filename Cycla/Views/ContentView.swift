import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var subscriptions: SubscriptionManager

    /// Persisted flag so the first-time welcome offer shows only once.
    @AppStorage("hasSeenWelcomeOffer") private var hasSeenWelcomeOffer = false
    @State private var showWelcome = false

    var body: some View {
        TabView {
            PlansView()
                .tabItem {
                    Label("Plans", systemImage: "list.bullet.rectangle")
                }

            NutritionView()
                .tabItem {
                    Label("Nutrition", systemImage: "fork.knife")
                }

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
        }
        .tint(.orange)
        // First-time user offer: present once on first launch.
        .sheet(isPresented: $showWelcome) {
            WelcomeOfferView {
                hasSeenWelcomeOffer = true
                showWelcome = false
            }
        }
        .task {
            if !hasSeenWelcomeOffer && !subscriptions.isPro {
                showWelcome = true
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(SubscriptionManager())
}
