import SwiftUI

/// Content of the menu bar popover.
struct PanelView: View {
    @Environment(AwakeController.self) private var controller
    var close: () -> Void

    @State private var customExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            VStack(alignment: .leading, spacing: 8) {
                sectionLabel("Keep awake for")
                DurationChips(customExpanded: $customExpanded, onStart: close)
            }

            VStack(alignment: .leading, spacing: 8) {
                sectionLabel("What to keep awake")
                modesCard
            }

            footer
        }
        .padding(16)
        .frame(width: 300)
        .onChange(of: controller.customDurationRequests) { _, _ in
            withAnimation(.snappy) { customExpanded = true }
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: controller.isActive ? "cup.and.saucer.fill" : "cup.and.saucer")
                .font(.system(size: 26, weight: .medium))
                .foregroundStyle(controller.isActive ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.secondary))
                .symbolEffect(.bounce, value: controller.isActive)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(controller.isActive ? "Awake" : "Sleeping normally")
                    .font(.title3.weight(.semibold))
                Text(subtitle)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .animation(.default, value: subtitle)
                if let detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .monospacedDigit()
                }
            }

            Spacer(minLength: 8)

            Toggle("", isOn: Binding(
                get: { controller.isActive },
                set: { _ in controller.toggle() }
            ))
            .toggleStyle(.switch)
            .labelsHidden()
            .help(controller.isActive ? "Allow sleep" : "Keep awake")
        }
    }

    private var subtitle: String {
        guard controller.isActive else { return "Pick a duration to start" }
        if let remaining = controller.remaining {
            return "\(DurationFormatter.compact(remaining)) left"
        }
        return controller.startedByRule ? "While the monitor is connected" : "Indefinitely"
    }

    private var detail: String? {
        guard controller.isActive, let end = controller.endDate else { return nil }
        return "Until \(end.formatted(date: .omitted, time: .shortened))"
    }

    // MARK: Modes

    private var modesCard: some View {
        VStack(spacing: 0) {
            ForEach(Array(AwakeMode.all.enumerated()), id: \.element.rawValue) { index, mode in
                if index > 0 { Divider() }
                ModeRow(
                    symbol: mode.symbol,
                    title: mode.title,
                    subtitle: mode.help,
                    isOn: Binding(
                        get: { controller.modes.contains(mode) },
                        set: { controller.setMode(mode, enabled: $0) }
                    )
                )
            }
            Divider()
            ModeRow(
                symbol: "display.2",
                title: "Auto-start with a monitor",
                subtitle: "Keeps awake while an external monitor is connected.",
                isOn: Binding(
                    get: { controller.externalDisplayRule },
                    set: { controller.externalDisplayRule = $0 }
                )
            )
        }
        .padding(.horizontal, 10)
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(.quaternary.opacity(0.6)))
    }

    // MARK: Footer

    private var footer: some View {
        HStack {
            if let shortcut = Shortcuts.description(for: .toggleAwake) {
                Text("\(shortcut) to toggle")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            Spacer()
            Button {
                close()
                StatusItemController.presentSettings()
            } label: {
                Image(systemName: "gearshape")
            }
            .help("Settings")
            Button {
                NSApp.terminate(nil)
            } label: {
                Image(systemName: "power")
            }
            .help("Quit Caffeinate")
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
        .font(.system(size: 14))
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
    }
}

