import DayCoachCore
import SwiftUI

extension AreaColor {
    var color: Color {
        switch self {
        case .red: .red
        case .orange: .orange
        case .yellow: .yellow
        case .green: .green
        case .teal: .teal
        case .blue: .blue
        case .purple: .purple
        case .pink: .pink
        }
    }

    var label: String { rawValue.capitalized }
}

/// The interface is in English only, dates included, whatever the system language.
let interfaceLocale = Locale(identifier: "en_GB")

extension Date {
    var timeText: String {
        formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits).locale(interfaceLocale))
    }

    var dayText: String {
        formatted(.dateTime.weekday(.wide).day().month(.wide).locale(interfaceLocale))
    }
}

struct AreaDot: View {
    let color: AreaColor
    var size: CGFloat = 10

    var body: some View {
        Circle().fill(color.color).frame(width: size, height: size)
    }
}

struct AreaLabel: View {
    let area: Area?

    var body: some View {
        HStack(spacing: 6) {
            AreaDot(color: area?.color ?? .blue)
            Text(area?.name ?? "Unknown area")
        }
    }
}

/// A small capsule badge, such as "Interrupted".
struct Badge: View {
    let text: String

    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.caption2.weight(.medium))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(.quaternary, in: Capsule())
    }
}
