import DayCoachCore
import SwiftUI

/// Pomodoros done today per area against the budget, for example "Work 3 / 8".
/// Budgets can be exceeded: the app shows, it never blocks.
struct TodayCountersView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("Today").font(.headline)
                Text(model.today.start.dayText).foregroundStyle(.secondary)
            }
            ForEach(model.counterAreas) { area in
                CounterRow(
                    area: area,
                    worked: model.todayWorked[area.id ?? -1] ?? 0,
                    workMinutes: model.settings.workMinutes
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct CounterRow: View {
    let area: Area
    let worked: Double
    let workMinutes: Int

    var body: some View {
        let done = PomodoroCount.text(minutes: worked, workMinutes: workMinutes)
        let budget = PomodoroCount.text(minutes: Double(area.dailyBudgetMinutes), workMinutes: workMinutes)
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                AreaDot(color: area.color)
                Text(area.name)
                Spacer()
                Text("\(done) / \(budget)").monospacedDigit()
            }
            if area.dailyBudgetMinutes > 0 {
                ProgressView(value: min(worked, Double(area.dailyBudgetMinutes)), total: Double(area.dailyBudgetMinutes))
                    .tint(area.color.color)
                    .controlSize(.small)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(PomodoroCount.counter(
            name: area.name, workedMinutes: worked, budgetMinutes: area.dailyBudgetMinutes, workMinutes: workMinutes
        ))
    }
}
