import SwiftUI

/// Icon, title, one-line description and a small switch.
struct ModeRow: View {
    let symbol: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(isOn ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.secondary))
                .frame(width: 22)
                .animation(.snappy, value: isOn)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.callout)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .controlSize(.mini)
                .labelsHidden()
        }
        .padding(.vertical, 7)
        .contentShape(Rectangle())
        .onTapGesture { isOn.toggle() }
        .help(subtitle)
    }
}
