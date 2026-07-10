import SwiftUI

struct PlanDetailView: View {
    let plan: TrainingPlan

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(plan.subtitle)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 16) {
                        stat("\(plan.weeks)", "weeks")
                        stat("\(plan.sessionsPerWeek)", "per week")
                        stat(plan.level.rawValue, "level")
                    }
                    .padding(.top, 4)
                }
                .padding(.vertical, 6)
            }

            Section("Sample week") {
                ForEach(plan.workouts) { workout in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(workout.day)
                                .font(.caption.bold())
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .background(Color.orange.opacity(0.15))
                                .foregroundStyle(.orange)
                                .clipShape(Capsule())
                            Text(workout.name).font(.headline)
                            Spacer()
                            Text("\(workout.durationMinutes) min")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Text(workout.detail)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .navigationTitle(plan.title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.headline)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
    }
}

#Preview {
    NavigationStack {
        PlanDetailView(plan: TrainingPlan.samples.first!)
    }
}
