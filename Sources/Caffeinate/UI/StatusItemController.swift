import AppKit
import SwiftUI

/// Owns the menu bar item and the popover panel.
@MainActor
final class StatusItemController: NSObject {
    private let controller: AwakeController
    private let statusItem: NSStatusItem
    private let popover = NSPopover()
    private var lastPanelRequest = 0

    init(controller: AwakeController) {
        self.controller = controller
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()

        popover.behavior = .transient
        popover.animates = true
        let panel = PanelView(close: { [weak self] in self?.closePanel() })
            .environment(controller)
        popover.contentViewController = NSHostingController(rootView: panel)

        if let button = statusItem.button {
            button.target = self
            button.action = #selector(handleClick(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.font = NSFont.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
            button.imagePosition = .imageLeading
        }

        lastPanelRequest = controller.customDurationRequests
        observeChanges { [weak self] in self?.render() }
    }

    private func render() {
        guard let button = statusItem.button else { return }
        let active = controller.isActive
        let image = NSImage(
            systemSymbolName: active ? "cup.and.saucer.fill" : "cup.and.saucer",
            accessibilityDescription: active ? "Caffeinate, awake" : "Caffeinate, sleep allowed"
        )
        image?.isTemplate = true
        button.image = image
        button.title = controller.menuBarText.map { " \($0)" } ?? ""

        if controller.customDurationRequests != lastPanelRequest {
            lastPanelRequest = controller.customDurationRequests
            showPanel()
        }
    }

    @objc private func handleClick(_ sender: Any?) {
        if NSApp.currentEvent?.type == .rightMouseUp {
            showContextMenu()
        } else if popover.isShown {
            closePanel()
        } else {
            showPanel()
        }
    }

    private func showPanel() {
        guard let button = statusItem.button, !popover.isShown else { return }
        NSApp.activate(ignoringOtherApps: true)
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
    }

    func closePanel() {
        popover.performClose(nil)
    }

    private func showContextMenu() {
        let menu = NSMenu()
        menu.addItem(withTitle: "Settings…", action: #selector(openSettings), keyEquivalent: ",").target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit Caffeinate", action: #selector(quit), keyEquivalent: "q").target = self
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func openSettings() {
        closePanel()
        Self.presentSettings()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    static func presentSettings() {
        SettingsWindow.show()
    }
}
