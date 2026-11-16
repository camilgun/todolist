import Foundation

/// How numbers of minutes are shown as pomodoros (ADR 0003: the pomodoro is only a display unit).
public enum PomodoroCount {
    /// The number of pomodoros `minutes` makes at the given work length:
    /// whole numbers are shown whole ("8"), fractions with one decimal ("7.6").
    public static func text(minutes: Double, workMinutes: Int) -> String {
        guard workMinutes > 0 else { return "0" }
        let tenths = (minutes / Double(workMinutes) * 10).rounded()
        if tenths.truncatingRemainder(dividingBy: 10) == 0 {
            return String(Int(tenths / 10))
        }
        return String(format: "%.1f", locale: Locale(identifier: "en_US_POSIX"), tenths / 10)
    }

    /// A counter such as "Work 3 / 8".
    public static func counter(name: String, workedMinutes: Double, budgetMinutes: Int, workMinutes: Int) -> String {
        let done = text(minutes: workedMinutes, workMinutes: workMinutes)
        let budget = text(minutes: Double(budgetMinutes), workMinutes: workMinutes)
        return "\(name) \(done) / \(budget)"
    }
}

public enum ClockText {
    /// A remaining time as "m:ss" ("24:13", "4:05"), rounding up to the next whole second
    /// so the display reaches "0:00" only at the end.
    public static func remaining(_ interval: TimeInterval) -> String {
        let seconds = max(0, Int(interval.rounded(.up)))
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}
