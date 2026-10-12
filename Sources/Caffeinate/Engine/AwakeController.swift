import AppKit
import Observation

/// Single source of truth for the app: what is enabled, whether we are active, and for how long.
@MainActor
@Observable
final class AwakeController {
    static let shared = AwakeController()

    // MARK: Persisted preferences

    var modes: AwakeMode {
        didSet {
            if modes.isDisjoint(with: AwakeMode(AwakeMode.all)) { modes = oldValue; return }
            defaults.set(modes.rawValue, forKey: Keys.modes)
            if isActive { assertions.apply(modes) }
        }
    }

    var externalDisplayRule: Bool {
        didSet {
            defaults.set(externalDisplayRule, forKey: Keys.externalDisplayRule)
            evaluateExternalDisplayRule()
        }
    }

    var showCountdownInMenuBar: Bool {
        didSet { defaults.set(showCountdownInMenuBar, forKey: Keys.showCountdown) }
    }

    /// Duration used by "Keep Awake" and the toggle shortcut. `nil` = indefinite.
    var defaultDuration: TimeInterval? {
        didSet { defaults.set(defaultDuration ?? 0, forKey: Keys.defaultDuration) }
    }

    var lastCustomMinutes: Int {
        didSet { defaults.set(lastCustomMinutes, forKey: Keys.lastCustomMinutes) }
    }

    // MARK: Session state

    private(set) var isActive = false
    /// Length of the current timed session, `nil` when indefinite.
    private(set) var sessionDuration: TimeInterval?
    private(set) var endDate: Date?
    private(set) var remaining: TimeInterval?
    private(set) var startedByRule = false

    /// Incremented whenever something (e.g. a global shortcut) asks for the custom-duration window.
    private(set) var customDurationRequests = 0

    // MARK: Internals

    private let defaults = UserDefaults.standard
    private let assertions = SleepAssertions()
    private let displayMonitor = ExternalDisplayMonitor()
    private var timer: Timer?
    private var wakeObserver: NSObjectProtocol?

    private enum Keys {
        static let modes = "modes"
        static let externalDisplayRule = "externalDisplayRule"
        static let showCountdown = "showCountdownInMenuBar"
        static let defaultDuration = "defaultDuration"
        static let lastCustomMinutes = "lastCustomMinutes"
    }

    private init() {
        let storedModes = defaults.object(forKey: Keys.modes) as? Int
        modes = storedModes.map(AwakeMode.init(rawValue:)) ?? .default
        externalDisplayRule = defaults.bool(forKey: Keys.externalDisplayRule)
        showCountdownInMenuBar = defaults.object(forKey: Keys.showCountdown) as? Bool ?? true
        let storedDefault = defaults.double(forKey: Keys.defaultDuration)
        defaultDuration = storedDefault > 0 ? storedDefault : nil
        lastCustomMinutes = defaults.object(forKey: Keys.lastCustomMinutes) as? Int ?? 45

        displayMonitor.onChange = { [weak self] connected in
            self?.externalDisplayChanged(connected: connected)
        }

        wakeObserver = NotificationCenter.default.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }

        evaluateExternalDisplayRule()
    }

    // MARK: Actions

    /// Start (or restart) keeping the Mac awake. `nil` means indefinitely.
    func start(duration: TimeInterval?, byRule: Bool = false) {
        startedByRule = byRule
        assertions.apply(modes)
        isActive = true
        timer?.invalidate()
        timer = nil

        sessionDuration = duration
        if let duration {
            endDate = Date().addingTimeInterval(duration)
            remaining = duration
            let t = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
                MainActor.assumeIsolated { self?.tick() }
            }
            t.tolerance = 0.2
            RunLoop.main.add(t, forMode: .common)
            timer = t
        } else {
            endDate = nil
            remaining = nil
        }
    }

    func start(preset: DurationPreset) {
        start(duration: preset.seconds)
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        assertions.releaseAll()
        isActive = false
        sessionDuration = nil
        endDate = nil
        remaining = nil
        startedByRule = false
    }


    func toggle() {
        if isActive { stop() } else { start(duration: defaultDuration) }
    }

    func setMode(_ mode: AwakeMode, enabled: Bool) {
        var next = modes
        if enabled { next.insert(mode) } else { next.remove(mode) }
        modes = next
    }

    func requestCustomDuration() {
        customDurationRequests += 1
    }

    // MARK: Status text

    var statusText: String {
        guard isActive else { return "Sleep allowed" }
        if let remaining { return "Awake · \(DurationFormatter.spoken(remaining)) left" }
        return startedByRule ? "Awake · external display connected" : "Awake · indefinitely"
    }

    /// Countdown shown next to the icon, only in the final two minutes so the menu bar stays quiet.
    var menuBarText: String? {
        guard isActive, showCountdownInMenuBar, let remaining, remaining < 120 else { return nil }
        return DurationFormatter.compact(remaining)
    }

    // MARK: Private

    private func tick() {
        guard isActive, let endDate else { return }
        let left = endDate.timeIntervalSinceNow
        if left <= 0 {
            stop()
        } else {
            remaining = left
        }
    }

    private func externalDisplayChanged(connected: Bool) {
        guard externalDisplayRule else { return }
        if connected {
            if !isActive { start(duration: nil, byRule: true) }
        } else if startedByRule {
            stop()
        }
    }

    /// Called when the rule is toggled: apply the current display state immediately.
    private func evaluateExternalDisplayRule() {
        if externalDisplayRule {
            if displayMonitor.hasExternalDisplay && !isActive { start(duration: nil, byRule: true) }
        } else if startedByRule {
            stop()
        }
    }
}
