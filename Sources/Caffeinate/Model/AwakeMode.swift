import Foundation

/// The individual sleep-prevention behaviours, each mapping to one IOKit power assertion.
struct AwakeMode: OptionSet, Hashable, Sendable {
    let rawValue: Int

    /// `caffeinate -d`: prevent the display from sleeping (implies the system stays awake too).
    static let display = AwakeMode(rawValue: 1 << 0)
    /// `caffeinate -i`: prevent the system from idle sleeping. The display may still turn off.
    static let systemIdle = AwakeMode(rawValue: 1 << 1)
    /// `caffeinate -s`: prevent system sleep while on AC power, including lid-closed sleep on most Macs.
    static let systemOnAC = AwakeMode(rawValue: 1 << 2)

    static let all: [AwakeMode] = [.display, .systemIdle, .systemOnAC]
    static let `default`: AwakeMode = [.display]

    /// The IOPMAssertion type string used by `IOPMAssertionCreateWithName`.
    var assertionType: String {
        switch self {
        case .display: "PreventUserIdleDisplaySleep"
        case .systemIdle: "PreventUserIdleSystemSleep"
        case .systemOnAC: "PreventSystemSleep"
        default: ""
        }
    }

    var title: String {
        switch self {
        case .display: "Keep the screen on"
        case .systemIdle: "Keep the Mac running"
        case .systemOnAC: "Awake with the lid closed"
        default: ""
        }
    }

    var symbol: String {
        switch self {
        case .display: "display"
        case .systemIdle: "cpu"
        case .systemOnAC: "macbook"
        default: ""
        }
    }

    var help: String {
        switch self {
        case .display: "The screen never dims or turns off."
        case .systemIdle: "The screen may turn off, but downloads and tasks keep going."
        case .systemOnAC: "When plugged in, closing the lid won't put the Mac to sleep."
        default: ""
        }
    }
}
