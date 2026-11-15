import DayCoachCore
import SwiftUI

/// The pomodoros of one day, with manual fixes: add a forgotten one, move one to
/// the right area, edit its note.
struct DayHistoryView: View {
    @Environment(AppModel.self) private var model
    @State private var addingManual = false
    @State private var editing: Pomodoro?

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
            if model.shownDayPomodoros.isEmpty {
                Text("No pomodoros on this day.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(model.shownDayPomodoros) { pomodoro in
                    PomodoroRow(pomodoro: pomodoro)
                        .contentShape(Rectangle())
                        .onTapGesture(count: 2) { editing = pomodoro }
                        .contextMenu {
                            Button("Edit…") { editing = pomodoro }
                            Button("Delete", role: .destructive) { model.deletePomodoro(pomodoro) }
                        }
                }
                .listStyle(.inset)
            }
        }
        .sheet(isPresented: $addingManual) {
            ManualPomodoroSheet()
        }
        .sheet(item: $editing) { pomodoro in
            EditPomodoroSheet(pomodoro: pomodoro)
        }
    }

    private var header: some View {
        HStack(spacing: 6) {
            Button { model.showDay(offsetBy: -1) } label: { Image(systemName: "chevron.left") }
                .help("Previous day")
            Button { model.showDay(offsetBy: 1) } label: { Image(systemName: "chevron.right") }
                .help("Next day")
                .disabled(model.isShowingToday)
            Text(model.isShowingToday ? "Pomodoros today" : model.shownDay.start.dayText)
                .font(.headline)
                .padding(.leading, 4)
            if !model.isShowingToday {
                Button("Today") { model.showToday() }
                    .controlSize(.small)
            }
            Spacer()
            Button {
                addingManual = true
            } label: {
                Label("Add by hand…", systemImage: "plus")
            }
            .help("Record a pomodoro you forgot to start")
        }
        .buttonStyle(.borderless)
    }
}

private struct PomodoroRow: View {
    @Environment(AppModel.self) private var model
    let pomodoro: Pomodoro

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Text("\(pomodoro.startedAt.timeText)–\(pomodoro.endedAt?.timeText ?? "")")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                AreaLabel(area: model.area(pomodoro.areaId))
                Spacer()
                if pomodoro.status == .interrupted {
                    Badge("Interrupted after \(Int(pomodoro.workedMinutes)) min")
                }
                if pomodoro.isManual {
                    Badge("Added by hand")
                }
            }
            if !pomodoro.note.isEmpty {
                Text(pomodoro.note)
                    .lineLimit(3)
                    .textSelection(.enabled)
            }
        }
        .padding(.vertical, 3)
    }
}

/// Records a forgotten pomodoro; it is marked as added by hand.
private struct ManualPomodoroSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var areaId: Int64?
    @State private var start = Date()
    @State private var minutes = 25
    @State private var note = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Add a pomodoro by hand").font(.title3.weight(.semibold))
            Form {
                Picker("Area", selection: $areaId) {
                    ForEach(model.activeAreas) { area in
                        Text(area.name).tag(Optional(area.id!))
                    }
                }
                DatePicker("Started at", selection: $start, in: ...Date(), displayedComponents: [.date, .hourAndMinute])
                    .environment(\.locale, interfaceLocale)
                Stepper("Length: \(minutes) minutes", value: $minutes, in: 1...600)
                TextField("Note", text: $note, axis: .vertical)
                    .lineLimit(3...6)
            }
            HStack {
                Spacer()
                Button("Cancel", role: .cancel) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Add") {
                    if let areaId {
                        model.addManualPomodoro(areaId: areaId, startedAt: start, minutes: minutes, note: note)
                    }
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(areaId == nil)
            }
        }
        .padding(20)
        .frame(width: 420)
        .onAppear {
            areaId = model.selectedAreaId ?? model.activeAreas.first?.id
            minutes = model.settings.workMinutes
            // Default to the last work slot that ended now, on the day being shown.
            let reference = model.isShowingToday ? Date() : model.shownDay.start.addingTimeInterval(5 * 3600)
            start = reference.addingTimeInterval(-TimeInterval(minutes * 60))
        }
    }
}

/// Corrects the area or the note of a pomodoro, or deletes it.
private struct EditPomodoroSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let pomodoro: Pomodoro
    @State private var areaId: Int64 = 0
    @State private var note = ""
    @State private var confirmingDelete = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Pomodoro").font(.title3.weight(.semibold))
                Text("\(pomodoro.startedAt.dayText), \(pomodoro.startedAt.timeText)–\(pomodoro.endedAt?.timeText ?? "")")
                    .foregroundStyle(.secondary)
                HStack {
                    if pomodoro.status == .interrupted { Badge("Interrupted") }
                    if pomodoro.isManual { Badge("Added by hand") }
                }
            }
            Form {
                Picker("Area", selection: $areaId) {
                    ForEach(selectableAreas) { area in
                        Text(area.isArchived ? "\(area.name) (archived)" : area.name).tag(area.id!)
                    }
                }
                TextField("Note", text: $note, axis: .vertical)
                    .lineLimit(3...8)
            }
            HStack {
                Button("Delete…", role: .destructive) { confirmingDelete = true }
                Spacer()
                Button("Cancel", role: .cancel) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Save") {
                    model.updatePomodoro(pomodoro, areaId: areaId, note: note.trimmingCharacters(in: .whitespacesAndNewlines))
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 420)
        .onAppear {
            areaId = pomodoro.areaId
            note = pomodoro.note
        }
        .confirmationDialog("Delete this pomodoro?", isPresented: $confirmingDelete) {
            Button("Delete", role: .destructive) {
                model.deletePomodoro(pomodoro)
                dismiss()
            }
        } message: {
            Text("It is removed from the history and no longer counts towards its area.")
        }
    }

    /// Active areas, plus the pomodoro's own area if it has been archived.
    private var selectableAreas: [Area] {
        model.areas.filter { !$0.isArchived || $0.id == pomodoro.areaId }
    }
}
