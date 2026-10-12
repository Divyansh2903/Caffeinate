import SwiftUI

/// Preset chips plus an inline custom-duration editor.
struct DurationChips: View {
    @Environment(AwakeController.self) private var controller
    @Binding var customExpanded: Bool
    var onStart: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            FlowLayout(spacing: 6) {
                ForEach(DurationPreset.allCases) { preset in
                    Chip(title: preset.shortTitle, selected: isSelected(preset), help: preset.title) {
                        withAnimation(.snappy) { customExpanded = false }
                        controller.start(preset: preset)
                        onStart()
                    }
                }
                Chip(title: "Custom…", selected: customExpanded || isCustomSession, help: "Pick any duration or a time of day") {
                    withAnimation(.snappy) { customExpanded.toggle() }
                }
            }

            if customExpanded {
                CustomDurationEditor(onStart: onStart)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private func isSelected(_ preset: DurationPreset) -> Bool {
        guard controller.isActive, !controller.startedByRule else { return false }
        return controller.sessionDuration == preset.seconds
    }

    private var isCustomSession: Bool {
        guard controller.isActive, !controller.startedByRule, let duration = controller.sessionDuration else { return false }
        return !DurationPreset.allCases.contains { $0.seconds == duration }
    }
}

private struct Chip: View {
    let title: String
    let selected: Bool
    let help: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.callout.weight(.medium))
                .padding(.horizontal, 11)
                .padding(.vertical, 5)
                .background(
                    Capsule().fill(selected ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.quaternary))
                )
                .foregroundStyle(selected ? .white : .primary)
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .animation(.snappy, value: selected)
        .help(help)
    }
}

private struct CustomDurationEditor: View {
    @Environment(AwakeController.self) private var controller
    var onStart: () -> Void

    private enum Mode: String, CaseIterable, Identifiable {
        case duration = "For"
        case until = "Until"
        var id: Self { self }
    }

    private enum Unit: String, CaseIterable, Identifiable {
        case minutes, hours
        var id: Self { self }
    }

    @State private var mode: Mode = .duration
    @State private var amount: Int = 45
    @State private var unit: Unit = .minutes
    @State private var untilTime: Date = Date().addingTimeInterval(60 * 60)

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Picker("", selection: $mode) {
                    ForEach(Mode.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 110)

                switch mode {
                case .duration:
                    TextField("", value: $amount, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 48)
                        .onSubmit(start)
                    Stepper("", value: $amount, in: 1...999)
                        .labelsHidden()
                    Picker("", selection: $unit) {
                        ForEach(Unit.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .labelsHidden()
                case .until:
                    DatePicker("", selection: $untilTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.stepperField)
                        .labelsHidden()
                }
            }

            HStack {
                Text(summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                Spacer()
                Button("Start", action: start)
                    .keyboardShortcut(.defaultAction)
                    .disabled(seconds == nil)
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(.quaternary.opacity(0.6)))
        .onAppear {
            let minutes = controller.lastCustomMinutes
            if minutes >= 60, minutes % 60 == 0 {
                amount = minutes / 60
                unit = .hours
            } else {
                amount = minutes
                unit = .minutes
            }
        }
    }

    private var seconds: TimeInterval? {
        switch mode {
        case .duration:
            guard amount > 0 else { return nil }
            return TimeInterval(amount) * (unit == .hours ? 3600 : 60)
        case .until:
            return Durations.secondsUntil(untilTime)
        }
    }

    private var summary: String {
        guard let seconds else { return "Enter a duration." }
        let end = Date().addingTimeInterval(seconds)
        return "\(DurationFormatter.spoken(seconds)), until \(end.formatted(date: .omitted, time: .shortened))"
    }

    private func start() {
        guard let seconds else { return }
        if mode == .duration { controller.lastCustomMinutes = Int(seconds / 60) }
        controller.start(duration: seconds)
        onStart()
    }
}
