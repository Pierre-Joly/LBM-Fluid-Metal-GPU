import SwiftUI

struct ControlSlider: View {
    let title: String
    @Binding var value: Float
    let range: ClosedRange<Float>
    let format: FloatingPointFormatStyle<Float>
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let theme = AppTheme.current(colorScheme)
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(theme.textSecondary)
                Spacer()
                Text(value, format: format)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(theme.textTertiary)
            }
            Slider(
                value: Binding(
                    get: { Double(value) },
                    set: { value = Float($0) }
                ),
                in: Double(range.lowerBound)...Double(range.upperBound)
            )
            .tint(theme.accent)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(theme.border, lineWidth: 1)
        )
    }
}

struct ControlStepper: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let step: Int
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let stepValue = Double(step)
        let lowerBound = Double(range.lowerBound)
        let upperBound = Double(range.upperBound)
        let theme = AppTheme.current(colorScheme)
        let sliderBinding = Binding<Double>(
            get: { Double(value) },
            set: { newValue in
                let snapped = Int((newValue / stepValue).rounded()) * step
                let clamped = min(max(snapped, range.lowerBound), range.upperBound)
                value = clamped
            }
        )

        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(theme.textSecondary)
                Spacer()
                Text("\(value)")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(theme.textTertiary)
            }
            HStack(spacing: 10) {
                Stepper(
                    value: $value,
                    in: range,
                    step: step
                ) {
                    EmptyView()
                }
                .labelsHidden()
                Slider(
                    value: sliderBinding,
                    in: lowerBound...upperBound,
                    step: stepValue
                )
                .tint(theme.accent)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(theme.border, lineWidth: 1)
        )
    }
}

struct TransportControls: View {
    @Binding var isRunning: Bool
    @Binding var restartToken: Int
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let theme = AppTheme.current(colorScheme)
        HStack(spacing: 12) {
            Button {
                isRunning.toggle()
            } label: {
                Label(isRunning ? "Pause" : "Play", systemImage: isRunning ? "pause.fill" : "play.fill")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.white)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 14)
                    .background(
                        Capsule()
                            .fill(theme.accent)
                    )
            }
            .buttonStyle(.plain)

            Button {
                restartToken += 1
            } label: {
                Label("Restart", systemImage: "gobackward")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(theme.textSecondary)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 14)
                    .background(
                        Capsule()
                            .fill(theme.surface)
                    )
            }
            .buttonStyle(.plain)
        }
    }
}

struct InfoPill: View {
    let title: String
    let value: String
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let theme = AppTheme.current(colorScheme)
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .foregroundStyle(theme.textTertiary)
                .textCase(.uppercase)
                .tracking(1.2)
            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(theme.textPrimary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(theme.border, lineWidth: 1)
        )
    }
}
