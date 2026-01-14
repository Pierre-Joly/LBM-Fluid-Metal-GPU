import SwiftUI

struct SimulationSurface: View {
    let containerSize: CGSize
    @Binding var isRunning: Bool
    @Binding var restartToken: Int
    @Binding var substeps: Int
    @Binding var tau: Float
    @Binding var ma: Float
    @Binding var aoaDeg: Float
    @Binding var chordRatio: Float
    @Binding var speedMax: Float
    @Binding var gridResolutionX: Int
    @Binding var gridResolutionY: Int
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let theme = AppTheme.current(colorScheme)
        let aspect = CGFloat(gridResolutionX) / CGFloat(max(1, gridResolutionY))
        MetalView(
            isRunning: $isRunning,
            restartToken: $restartToken,
            substeps: $substeps,
            tau: $tau,
            ma: $ma,
            aoaDeg: $aoaDeg,
            chordRatio: $chordRatio,
            speedMax: $speedMax,
            gridResolutionX: $gridResolutionX,
            gridResolutionY: $gridResolutionY
        )
        .aspectRatio(aspect, contentMode: .fit)
        .frame(
            minWidth: min(520, containerSize.width * 0.6),
            maxWidth: .infinity,
            minHeight: min(520, containerSize.height * 0.7),
            maxHeight: .infinity
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(theme.border, lineWidth: 1)
        )
        .shadow(color: theme.shadow, radius: 20, x: 0, y: 12)
    }
}
