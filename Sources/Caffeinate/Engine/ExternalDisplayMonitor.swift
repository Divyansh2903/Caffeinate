import AppKit
import CoreGraphics

/// Tracks whether any non-built-in display is attached.
@MainActor
final class ExternalDisplayMonitor {
    private(set) var hasExternalDisplay: Bool
    private var observer: NSObjectProtocol?
    var onChange: ((Bool) -> Void)?

    init() {
        hasExternalDisplay = Self.detect()
        observer = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.refresh()
            }
        }
    }

    private func refresh() {
        let now = Self.detect()
        guard now != hasExternalDisplay else { return }
        hasExternalDisplay = now
        onChange?(now)
    }

    private static func detect() -> Bool {
        NSScreen.screens.contains { screen in
            guard let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
                return false
            }
            return CGDisplayIsBuiltin(CGDirectDisplayID(number.uint32Value)) == 0
        }
    }
}
