import SwiftUI

/// Custom refresh indicator that replaces the default spinner.
/// Shows the AgriPulse logo spinning with a pulsing glow effect.
struct AgriPulseRefreshView: View {
    let isRefreshing: Bool

    @State private var rotation: Double = 0
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        if isRefreshing {
            HStack(spacing: 10) {
                // Spinning logo
                Image("AgriPulseLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 24, height: 24)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .rotationEffect(.degrees(rotation))
                    .scaleEffect(pulseScale)
                    .shadow(color: AgriPulseTheme.primary.opacity(0.4), radius: 8, x: 0, y: 0)

                Text("Refreshing...")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(AgriPulseTheme.mutedForeground.opacity(0.7))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(AgriPulseTheme.card.opacity(0.9))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(AgriPulseTheme.border.opacity(0.3), lineWidth: 1)
            )
            .transition(.move(edge: .top).combined(with: .opacity))
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    pulseScale = 1.1
                }
            }
            .onDisappear {
                rotation = 0
                pulseScale = 1.0
            }
        }
    }
}

/// ViewModifier that adds the custom refresh overlay to any scroll view.
struct AgriPulseRefreshOverlay: ViewModifier {
    let isRefreshing: Bool

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                AgriPulseRefreshView(isRefreshing: isRefreshing)
                    .padding(.top, 8)
                    .animation(.easeInOut(duration: 0.3), value: isRefreshing)
            }
    }
}

extension View {
    func agriPulseRefresh(isRefreshing: Bool) -> some View {
        modifier(AgriPulseRefreshOverlay(isRefreshing: isRefreshing))
    }
}
