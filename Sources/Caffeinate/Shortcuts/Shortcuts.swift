import Foundation
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let toggleAwake = Self("toggleAwake", default: .init(.k, modifiers: [.option, .command]))
    static let awake15 = Self("awake15Minutes")
    static let awake30 = Self("awake30Minutes")
    static let awake1h = Self("awake1Hour")
    static let awakeCustom = Self("awakeCustom")
}

@MainActor
enum Shortcuts {
    static func register(_ controller: AwakeController) {
        migrateLegacyDefault()
        KeyboardShortcuts.onKeyUp(for: .toggleAwake) { controller.toggle() }
        KeyboardShortcuts.onKeyUp(for: .awake15) { controller.start(preset: .minutes15) }
        KeyboardShortcuts.onKeyUp(for: .awake30) { controller.start(preset: .minutes30) }
        KeyboardShortcuts.onKeyUp(for: .awake1h) { controller.start(preset: .hour1) }
        KeyboardShortcuts.onKeyUp(for: .awakeCustom) { controller.requestCustomDuration() }
    }

    /// The package persists the first default it sees; move users off the old ⌃⌥⌘K once.
    private static func migrateLegacyDefault() {
        let key = "shortcutDefaultMigratedToOptionCommandK"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        UserDefaults.standard.set(true, forKey: key)
        let legacy = KeyboardShortcuts.Shortcut(.k, modifiers: [.control, .option, .command])
        if KeyboardShortcuts.getShortcut(for: .toggleAwake) == legacy {
            KeyboardShortcuts.reset(.toggleAwake)
        }
    }

    /// Human-readable shortcut for menu item titles, e.g. "⌃⌥⌘K".
    static func description(for name: KeyboardShortcuts.Name) -> String? {
        KeyboardShortcuts.getShortcut(for: name)?.description
    }
}
