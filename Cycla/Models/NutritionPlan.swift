import Foundation

/// A cycling nutrition plan. "Peloton" is the flagship advanced, Pro-only plan.
struct NutritionPlan: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let subtitle: String
    let systemImage: String
    /// Requires the separate `Peloton` entitlement (not Pro).
    let requiresPeloton: Bool
    let highlights: [String]
    let sampleDay: [NutritionItem]
}

struct NutritionItem: Identifiable, Hashable {
    let id = UUID()
    let time: String
    let meal: String
    let detail: String
}

extension NutritionPlan {
    static let samples: [NutritionPlan] = [
        NutritionPlan(
            title: "Everyday Fuelling",
            subtitle: "The basics of eating for the bike",
            systemImage: "fork.knife",
            requiresPeloton: false,
            highlights: [
                "Simple pre- and post-ride meals",
                "Hydration 101",
                "No tracking required"
            ],
            sampleDay: [
                NutritionItem(time: "Pre-ride", meal: "Porridge & banana", detail: "Slow-release carbs 60–90 min before."),
                NutritionItem(time: "On the bike", meal: "Water + a banana", detail: "Sip regularly, snack on longer rides."),
                NutritionItem(time: "Recovery", meal: "Yoghurt & berries", detail: "Protein + carbs within 30 min.")
            ]
        ),
        NutritionPlan(
            title: "Peloton",
            subtitle: "Advanced periodised race nutrition",
            systemImage: "bolt.heart.fill",
            requiresPeloton: true,
            highlights: [
                "Carb-periodised daily targets (g/kg)",
                "Race-week loading & taper protocol",
                "In-ride fuelling by intensity zone",
                "Gut-training progression plan",
                "Personalised hydration & sodium strategy"
            ],
            sampleDay: [
                NutritionItem(time: "Breakfast", meal: "High-carb loading", detail: "2.5 g/kg carbs, low fat, moderate protein."),
                NutritionItem(time: "Pre-session", meal: "Targeted top-up", detail: "1 g/kg carbs 90 min before key efforts."),
                NutritionItem(time: "In-ride", meal: "90 g carbs/hour", detail: "Glucose:fructose 2:1, dialled to zone."),
                NutritionItem(time: "Recovery", meal: "4:1 carb:protein", detail: "1.2 g/kg carbs + 0.3 g/kg protein."),
                NutritionItem(time: "Evening", meal: "Adaptive refuel", detail: "Adjust to next day's training load.")
            ]
        )
    ]
}
