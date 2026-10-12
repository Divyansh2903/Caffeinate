import Foundation

enum DurationPreset: CaseIterable, Identifiable, Sendable {
    case minutes15, minutes30, hour1, hours2, hours4, hours8, indefinite

    var id: Self { self }

    /// Seconds, or `nil` for indefinite.
    var seconds: TimeInterval? {
        switch self {
        case .minutes15: 15 * 60
        case .minutes30: 30 * 60
        case .hour1: 60 * 60
        case .hours2: 2 * 60 * 60
        case .hours4: 4 * 60 * 60
        case .hours8: 8 * 60 * 60
        case .indefinite: nil
        }
    }

    var shortTitle: String {
        switch self {
        case .minutes15: "15m"
        case .minutes30: "30m"
        case .hour1: "1h"
        case .hours2: "2h"
        case .hours4: "4h"
        case .hours8: "8h"
        case .indefinite: "∞"
        }
    }

    var title: String {
        switch self {
        case .minutes15: "15 minutes"
        case .minutes30: "30 minutes"
        case .hour1: "1 hour"
        case .hours2: "2 hours"
        case .hours4: "4 hours"
        case .hours8: "8 hours"
        case .indefinite: "Indefinitely"
        }
    }
}

enum Durations {
    /// Seconds until the next occurrence of the given wall-clock time (today or tomorrow).
    static func secondsUntil(_ time: Date, from now: Date = Date()) -> TimeInterval? {
        let cal = Calendar.current
        let comps = cal.dateComponents([.hour, .minute], from: time)
        guard let next = cal.nextDate(after: now, matching: comps, matchingPolicy: .nextTime) else { return nil }
        let interval = next.timeIntervalSince(now)
        return interval > 0 ? interval : nil
    }
}

enum DurationFormatter {
    /// "1h 05m", "42m", "0:48" style compact remaining-time text.
    static func compact(_ interval: TimeInterval) -> String {
        let total = max(0, Int(interval.rounded(.up)))
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 { return String(format: "%dh %02dm", h, m) }
        if m > 0 { return "\(m)m" }
        return "0:\(String(format: "%02d", s))"
    }

    /// "1 hour 5 minutes left" for the menu status line.
    static func spoken(_ interval: TimeInterval) -> String {
        let total = max(0, Int(interval.rounded(.up)))
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        var parts: [String] = []
        if h > 0 { parts.append(h == 1 ? "1 hour" : "\(h) hours") }
        if m > 0 { parts.append(m == 1 ? "1 minute" : "\(m) minutes") }
        if h == 0 && m == 0 { parts.append(s == 1 ? "1 second" : "\(s) seconds") }
        return parts.joined(separator: " ")
    }
}
