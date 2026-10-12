import KeyboardShortcuts
import ServiceManagement
import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettings()
                .tabItem { Label("General", systemImage: "gear") }
            ShortcutSettings()
                .tabItem { Label("Shortcuts", systemImage: "keyboard") }
        }
        .frame(width: 440)
        .padding(.bottom, 8)
    }
}

private struct GeneralSettings: View {
    @Environment(AwakeController.self) private var controller
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var loginError: String?

    var body: some View {
        @Bindable var controller = controller
        Form {
            Toggle("Launch at login", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { _, enabled in setLaunchAtLogin(enabled) }
            if let loginError {
                Text(loginError).font(.caption).foregroundStyle(.red)
            }

            Toggle("Show countdown in the menu bar during the last 2 minutes", isOn: $controller.showCountdownInMenuBar)

            Picker("Default duration", selection: $controller.defaultDuration) {
                ForEach(DurationPreset.allCases) { preset in
                    Text(preset.title).tag(preset.seconds)
                }
            }
            .help("Used by the Keep Awake menu item and the toggle shortcut.")

            Section("What to keep awake") {
                ForEach(AwakeMode.all, id: \.rawValue) { mode in
                    Toggle(
                        isOn: Binding(
                            get: { controller.modes.contains(mode) },
                            set: { controller.setMode(mode, enabled: $0) }
                        )
                    ) {
                        VStack(alignment: .leading) {
                            Label(mode.title, systemImage: mode.symbol)
                            Text(mode.help).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                Toggle(isOn: $controller.externalDisplayRule) {
                    VStack(alignment: .leading) {
                        Label("Auto-start with a monitor", systemImage: "display.2")
                        Text("Keeps awake while an external monitor is connected.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .onAppear { launchAtLogin = SMAppService.mainApp.status == .enabled }
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            loginError = nil
        } catch {
            loginError = error.localizedDescription
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }
}

private struct ShortcutSettings: View {
    var body: some View {
        Form {
            KeyboardShortcuts.Recorder("Toggle keep awake", name: .toggleAwake)
            KeyboardShortcuts.Recorder("Keep awake 15 minutes", name: .awake15)
            KeyboardShortcuts.Recorder("Keep awake 30 minutes", name: .awake30)
            KeyboardShortcuts.Recorder("Keep awake 1 hour", name: .awake1h)
            KeyboardShortcuts.Recorder("Custom duration…", name: .awakeCustom)
            Text("Shortcuts work from any app.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .formStyle(.grouped)
    }
}
