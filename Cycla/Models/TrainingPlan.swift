import Foundation

/// A cycling training plan (demo data only — Cycla is the cycling answer to Runna).
struct TrainingPlan: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let subtitle: String
    let weeks: Int
    let sessionsPerWeek: Int
    let level: Level
    let systemImage: String
    /// When `true`, this plan is only available to Pro subscribers.
    let isPro: Bool
    let workouts: [Workout]

    enum Level: String, CaseIterable {
        case beginner = "Beginner"
        case intermediate = "Intermediate"
        case advanced = "Advanced"
    }
}

struct Workout: Identifiable, Hashable {
    let id = UUID()
    let day: String
    let name: String
    let detail: String
    let durationMinutes: Int
}

extension TrainingPlan {
    /// Sample catalogue shown on the Plans tab. Two free plans, the rest are Pro.
    static let samples: [TrainingPlan] = [
        TrainingPlan(
            title: "Couch to 30km",
            subtitle: "Build the habit and your first big ride",
            weeks: 6,
            sessionsPerWeek: 3,
            level: .beginner,
            systemImage: "bicycle",
            isPro: false,
            workouts: [
                Workout(day: "Mon", name: "Easy spin", detail: "Zone 1–2, keep it conversational.", durationMinutes: 30),
                Workout(day: "Wed", name: "Cadence drills", detail: "6 × 1 min high cadence, 2 min easy.", durationMinutes: 40),
                Workout(day: "Sat", name: "Long ride", detail: "Steady endurance pace.", durationMinutes: 60)
            ]
        ),
        TrainingPlan(
            title: "Weekend Warrior",
            subtitle: "Get ready for your local club run",
            weeks: 8,
            sessionsPerWeek: 3,
            level: .beginner,
            systemImage: "figure.outdoor.cycle",
            isPro: false,
            workouts: [
                Workout(day: "Tue", name: "Tempo intervals", detail: "3 × 8 min at tempo, 4 min recovery.", durationMinutes: 50),
                Workout(day: "Thu", name: "Recovery ride", detail: "Very easy, flush the legs.", durationMinutes: 30),
                Workout(day: "Sun", name: "Group-pace ride", detail: "Endurance with a few surges.", durationMinutes: 90)
            ]
        ),
        TrainingPlan(
            title: "Century Builder",
            subtitle: "Train for your first 100-mile ride",
            weeks: 12,
            sessionsPerWeek: 4,
            level: .intermediate,
            systemImage: "flag.checkered",
            isPro: true,
            workouts: [
                Workout(day: "Tue", name: "Sweet-spot", detail: "2 × 20 min at 88–94% FTP.", durationMinutes: 70),
                Workout(day: "Thu", name: "VO2 max", detail: "5 × 3 min hard, 3 min easy.", durationMinutes: 60),
                Workout(day: "Sat", name: "Long endurance", detail: "Progressive long ride, fuel every 45 min.", durationMinutes: 180),
                Workout(day: "Sun", name: "Back-to-back", detail: "Endurance on tired legs.", durationMinutes: 120)
            ]
        ),
        TrainingPlan(
            title: "Climbing Specialist",
            subtitle: "Own the hills with threshold power",
            weeks: 10,
            sessionsPerWeek: 4,
            level: .advanced,
            systemImage: "mountain.2",
            isPro: true,
            workouts: [
                Workout(day: "Mon", name: "Threshold", detail: "3 × 12 min at FTP on a climb.", durationMinutes: 75),
                Workout(day: "Wed", name: "Over-unders", detail: "4 × (2 min over / 2 min under) FTP.", durationMinutes: 65),
                Workout(day: "Fri", name: "Standing efforts", detail: "8 × 1 min out-of-saddle climbs.", durationMinutes: 55),
                Workout(day: "Sun", name: "Hill repeats", detail: "6 × 5 min climbing at threshold.", durationMinutes: 100)
            ]
        ),
        TrainingPlan(
            title: "Crit Race Sharpener",
            subtitle: "Explosive power for race day",
            weeks: 6,
            sessionsPerWeek: 5,
            level: .advanced,
            systemImage: "bolt.fill",
            isPro: true,
            workouts: [
                Workout(day: "Mon", name: "Sprint starts", detail: "10 × 15 s max sprints, full recovery.", durationMinutes: 60),
                Workout(day: "Wed", name: "Anaerobic capacity", detail: "6 × 1 min all-out, 4 min easy.", durationMinutes: 55),
                Workout(day: "Fri", name: "Race simulation", detail: "Attacks every 3 min for 30 min.", durationMinutes: 70)
            ]
        )
    ]
}
