import SwiftUI

struct BackgroundView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let theme = AppTheme.current(colorScheme)
        ZStack {
            LinearGradient(
                colors: [
                    theme.backgroundTop,
                    theme.backgroundMid,
                    theme.backgroundBottom
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(theme.accentSoft)
                .frame(width: 520, height: 520)
                .blur(radius: 70)
                .offset(x: -220, y: -200)

            RoundedRectangle(cornerRadius: 120, style: .continuous)
                .fill(theme.accent.opacity(0.14))
                .frame(width: 520, height: 320)
                .rotationEffect(.degrees(-12))
                .blur(radius: 50)
                .offset(x: 260, y: 220)
        }
        .ignoresSafeArea()
    }
}
