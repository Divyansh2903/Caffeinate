import AppKit
import SwiftUI

/// A single, lazily created Settings window.
@MainActor
enum SettingsWindow {
    private static var window: NSWindow?

    static func show() {
        let window = window ?? make()
        Self.window = window
        NSApp.activate(ignoringOtherApps: true)
        window.center()
        window.makeKeyAndOrderFront(nil)
    }

    private static func make() -> NSWindow {
        let host = NSHostingController(rootView: SettingsView().environment(AwakeController.shared))
        let window = NSWindow(contentViewController: host)
        window.title = "Caffeinate Settings"
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false
        window.isRestorable = false
        window.titlebarAppearsTransparent = false
        return window
    }
}
