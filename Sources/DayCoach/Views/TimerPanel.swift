import DayCoachCore
import SwiftUI

/// Start, interrupt, the end-of-pomodoro note and the break. There is no pause button.
struct TimerPanel: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        switch model.status {
        case .idle:
            ReadyView(title: "Ready", subtitle: "Pick an area and start a pomodoro.")
        case .breakOver:
            ReadyView(title: "Break over", subtitle: "Start the next pomodoro when you're ready.")
        case .working(let pomodoro):
            WorkingView(pomodoro: pomodoro)
        case .awaitingNote(let pomodoro):
            NoteForm(pomodoro: pomodoro)
                .id(pomodoro.id)
        case .onBreak(let kind, let endsAt, _):
            BreakView(kind: kind, endsAt: endsAt)
        }
    }
}

private struct BigClock: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 56, weight: .light, design: .rounded))
            .monospacedDigit()
            .contentTransition(.numericText())
    }
}

private struct ReadyView: View {
    @Environment(AppModel.self) private var model
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.title2.weight(.semibold))
                Text(subtitle).foregroundStyle(.secondary)
            }
            AreaPicker()
            Button {
                model.startPomodoro()
            } label: {
                Label("Start pomodoro", systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .keyboardShortcut(.defaultAction)
            .disabled(model.selectedAreaId == nil)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// The active areas as selectable chips.
struct AreaPicker: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(model.activeAreas) { area in
                    let selected = area.id == model.selectedAreaId
                    Button {
                        model.selectedAreaId = area.id
                    } label: {
                        HStack(spacing: 6) {
                            AreaDot(color: area.color)
                            Text(area.name)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule().fill(selected ? area.color.color.opacity(0.22) : Color.secondary.opacity(0.1))
                        )
                        .overlay(Capsule().strokeBorder(selected ? area.color.color : .clear, lineWidth: 1.5))
                        .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selected ? .isSelected : [])
                }
                Button {
                    model.showSettings()
                } label: {
                    Label("Edit areas…", systemImage: "pencil")
                }
                .buttonStyle(.borderless)
                .help("Rename, recolour, archive or add areas (⌘,)")
            }
            // Room for the selected chip's border, which the scroll view would clip.
            .padding(2)
        }
    }
}

private struct WorkingView: View {
    @Environment(AppModel.self) private var model
    let pomodoro: Pomodoro
    @State private var confirmingInterrupt = false

    var body: some View {
        let elapsed = model.now.timeIntervalSince(pomodoro.startedAt)
        let total = TimeInterval(pomodoro.plannedMinutes * 60)
        VStack(alignment: .leading, spacing: 12) {
            AreaLabel(area: model.area(pomodoro.areaId))
                .font(.headline)
            BigClock(text: ClockText.remaining(total - elapsed))
            ProgressView(value: min(max(elapsed, 0), total), total: total)
                .tint(model.area(pomodoro.areaId)?.color.color)
            HStack {
                Text("Started at \(pomodoro.startedAt.timeText), ends at \(pomodoro.plannedEnd.timeText)")
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Interrupt", role: .destructive) { confirmingInterrupt = true }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .confirmationDialog(dialogTitle(elapsed: elapsed), isPresented: $confirmingInterrupt) {
            Button(elapsed < PomodoroTimer.mistakenStartSeconds ? "Discard" : "Interrupt", role: .destructive) {
                model.interrupt()
            }
            Button("Keep working", role: .cancel) {}
        } message: {
            Text(dialogMessage(elapsed: elapsed))
        }
    }

    private func dialogTitle(elapsed: TimeInterval) -> String {
        elapsed < PomodoroTimer.mistakenStartSeconds ? "Discard this pomodoro?" : "Interrupt this pomodoro?"
    }

    private func dialogMessage(elapsed: TimeInterval) -> String {
        if elapsed < PomodoroTimer.mistakenStartSeconds {
            return "It started less than a minute ago, so it is treated as a mistaken start and not recorded."
        }
        let minutes = Int(elapsed / 60)
        let areaName = model.area(pomodoro.areaId)?.name ?? "its area"
        return "The \(minutes) minutes worked count towards \(areaName), and it stays marked as interrupted."
    }
}

/// The end-of-pomodoro form. The break starts only when it is closed.
private struct NoteForm: View {
    @Environment(AppModel.self) private var model
    let pomodoro: Pomodoro
    @State private var note = ""
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Pomodoro done", systemImage: "checkmark.circle.fill")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.green)
                Spacer()
                AreaLabel(area: model.area(pomodoro.areaId))
            }
            Text("A short note on what you did. Your break starts when you close this form.")
                .foregroundStyle(.secondary)
            TextEditor(text: $note)
                .font(.body)
                .focused($focused)
                .frame(height: 90)
                .scrollContentBackground(.hidden)
                .padding(6)
                .background(.background, in: RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(.quaternary))
            HStack {
                Text("⌘↩ to save").font(.caption).foregroundStyle(.secondary)
                Spacer()
                Button("Save note and start break") {
                    model.saveNoteAndStartBreak(note)
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return, modifiers: .command)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear { focused = true }
    }
}

private struct BreakView: View {
    @Environment(AppModel.self) private var model
    let kind: BreakKind
    let endsAt: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(kind == .long ? "Long break" : "Break", systemImage: "cup.and.saucer.fill")
                .font(.headline)
            BigClock(text: ClockText.remaining(endsAt.timeIntervalSince(model.now)))
            Text("When it ends you'll get a notification; the next pomodoro never starts by itself.")
                .foregroundStyle(.secondary)
            AreaPicker()
            HStack {
                Button("Start next pomodoro now") { model.startPomodoro() }
                    .disabled(model.selectedAreaId == nil)
                Spacer()
                Button("End break") { model.endBreak() }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
