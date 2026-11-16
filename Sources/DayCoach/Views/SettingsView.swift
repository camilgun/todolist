import DayCoachCore
import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            AreasSettings()
                .tabItem { Label("Areas", systemImage: "square.grid.2x2") }
            TimerSettings()
                .tabItem { Label("Timer", systemImage: "timer") }
        }
        .padding(20)
        .frame(minWidth: 520, minHeight: 440)
    }
}

// MARK: - Areas

private struct AreasSettings: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let archived = model.areas.filter(\.isArchived)
        VStack(alignment: .leading, spacing: 12) {
            List {
                Section("Areas") {
                    ForEach(model.activeAreas) { area in
                        AreaEditorRow(area: area)
                    }
                    if model.activeAreas.isEmpty {
                        Text("No areas yet.").foregroundStyle(.secondary)
                    }
                }
                if !archived.isEmpty {
                    Section("Archived") {
                        ForEach(archived) { area in
                            HStack {
                                AreaLabel(area: area)
                                Spacer()
                                Button("Restore") { model.setArchived(area, false) }
                            }
                        }
                    }
                }
            }
            HStack {
                Button {
                    model.addArea()
                } label: {
                    Label("Add area", systemImage: "plus")
                }
                Spacer()
                Text("Budgets are pomodoros a day; each day may exceed them.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct AreaEditorRow: View {
    @Environment(AppModel.self) private var model
    let area: Area
    @State private var name: String
    @FocusState private var nameFocused: Bool

    init(area: Area) {
        self.area = area
        _name = State(initialValue: area.name)
    }

    var body: some View {
        let work = model.settings.workMinutes
        let budget = Int((Double(area.dailyBudgetMinutes) / Double(work)).rounded())
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Saved as you type, so archiving the area or closing the window right
                // after typing keeps the name.
                TextField("Name", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .focused($nameFocused)
                    .onChange(of: name) { saveName() }
                    .onChange(of: nameFocused) { _, focused in if !focused { restoreNameIfEmpty() } }
                Button("Archive") { model.setArchived(area, true) }
                    .help("Hide the area; its pomodoros stay in the history")
            }
            HStack(spacing: 14) {
                HStack(spacing: 6) {
                    ForEach(AreaColor.allCases, id: \.self) { color in
                        Button {
                            var changed = area
                            changed.color = color
                            model.updateArea(changed)
                        } label: {
                            AreaDot(color: color, size: 16)
                                .overlay(Circle().strokeBorder(.primary, lineWidth: color == area.color ? 2 : 0))
                        }
                        .buttonStyle(.plain)
                        .help(color.label)
                    }
                }
                Spacer()
                Stepper(
                    "\(budget) pomodoros a day",
                    value: Binding(
                        get: { budget },
                        set: { newValue in
                            var changed = area
                            changed.dailyBudgetMinutes = max(0, newValue) * work
                            model.updateArea(changed)
                        }
                    ),
                    in: 0...40
                )
                .monospacedDigit()
            }
        }
        .padding(.vertical, 6)
    }

    /// An area needs a name: an emptied field goes back to the stored one when you leave it.
    private func restoreNameIfEmpty() {
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            name = area.name
        }
    }

    private func saveName() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != area.name else { return }
        var changed = area
        changed.name = trimmed
        model.updateArea(changed)
    }
}

// MARK: - Timer

private struct TimerSettings: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let settings = model.settings
        Form {
            Section {
                Stepper("Pomodoro: \(settings.workMinutes) minutes",
                        value: binding(\.workMinutes), in: AppSettings.workMinutesRange)
                Stepper("Short break: \(settings.shortBreakMinutes) minutes",
                        value: binding(\.shortBreakMinutes), in: AppSettings.breakMinutesRange)
                Stepper("Long break: \(settings.longBreakMinutes) minutes",
                        value: binding(\.longBreakMinutes), in: AppSettings.breakMinutesRange)
                Stepper("Long break every \(settings.longBreakEvery) pomodoros",
                        value: binding(\.longBreakEvery), in: AppSettings.longBreakEveryRange)
            } footer: {
                Text("Work is stored in minutes, so changing the pomodoro length changes how many pomodoros the counters and budgets show, not the work recorded.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Section {
                DatePicker("The day ends at", selection: dayStartBinding, displayedComponents: .hourAndMinute)
                    .environment(\.locale, interfaceLocale)
            } footer: {
                Text("Work after midnight and before this time counts for the previous day.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }

    private func binding(_ keyPath: WritableKeyPath<AppSettings, Int>) -> Binding<Int> {
        Binding(
            get: { model.settings[keyPath: keyPath] },
            set: { newValue in model.updateSettings { $0[keyPath: keyPath] = newValue } }
        )
    }

    private var dayStartBinding: Binding<Date> {
        let calendar = Calendar.current
        return Binding(
            get: {
                let minutes = model.settings.dayStartMinutes
                return calendar.date(bySettingHour: minutes / 60, minute: minutes % 60, second: 0, of: Date()) ?? Date()
            },
            set: { date in
                let parts = calendar.dateComponents([.hour, .minute], from: date)
                model.updateSettings { $0.dayStartMinutes = (parts.hour ?? 4) * 60 + (parts.minute ?? 0) }
            }
        )
    }
}
