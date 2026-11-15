import DayCoachCore
import SwiftUI

/// The main window: the timer on top, today's counters, then the pomodoros of a day.
struct MainView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        VStack(spacing: 0) {
            if model.activeAreas.isEmpty {
                NoAreasView()
            } else {
                TimerPanel()
                    .padding(20)
                Divider()
                TodayCountersView()
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                Divider()
                DayHistoryView()
            }
        }
        .frame(minWidth: 440, minHeight: 560)
        .alert(
            "Something went wrong",
            isPresented: Binding(
                get: { model.errorMessage != nil },
                set: { if !$0 { model.errorMessage = nil } }
            )
        ) {
            Button("OK") {}
        } message: {
            Text(model.errorMessage ?? "")
        }
    }
}

private struct NoAreasView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        ContentUnavailableView {
            Label("No areas yet", systemImage: "square.grid.2x2")
        } description: {
            Text("Every pomodoro belongs to an area, such as Work or Personal, with a daily budget.")
        } actions: {
            Button("Create an area") {
                model.addArea()
                model.showSettings()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
