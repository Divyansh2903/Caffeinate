import SwiftUI

@main
struct CaffeinateApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // SwiftUI requires at least one scene. This one is never inserted, so nothing opens at launch.
        // The status item, panel and settings window are all managed in AppKit.
        MenuBarExtra("Caffeinate", isInserted: .constant(false)) { EmptyView() }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: StatusItemController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide the Dock icon even when run as a bare binary without Info.plist (swift run).
        NSApp.setActivationPolicy(.accessory)
        statusItem = StatusItemController(controller: .shared)
        Shortcuts.register(.shared)
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool { true }
}
