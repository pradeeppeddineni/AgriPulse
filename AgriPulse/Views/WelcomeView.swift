import SwiftUI

struct WelcomeView: View {
    let onContinue: () -> Void

    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var buttonOpacity: Double = 0

    var body: some View {
        ZStack {
            // Background
            AgriPulseTheme.background
                .ignoresSafeArea()

            // Subtle radial glow
            RadialGradient(
                colors: [AgriPulseTheme.primary.opacity(0.08), Color.clear],
                center: .center,
                startRadius: 50,
                endRadius: 400
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Logo
                Image("AgriPulseLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 28))
                    .shadow(color: AgriPulseTheme.primary.opacity(0.3), radius: 20, y: 8)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)

                Spacer().frame(height: 32)

                // Title
                VStack(spacing: 8) {
                    Text("Welcome to")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(AgriPulseTheme.foreground)

                    Text("AgriPulse")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(AgriPulseTheme.primary)
                }
                .opacity(textOpacity)

                Spacer().frame(height: 16)

                Text("Real-time commodity intelligence\nfor Indian agricultural markets.")
                    .font(.system(size: 16))
                    .foregroundStyle(AgriPulseTheme.mutedForeground.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .opacity(textOpacity)

                Spacer()

                // Features
                VStack(alignment: .leading, spacing: 16) {
                    featureRow(icon: "newspaper.fill", title: "40+ Commodities", subtitle: "News from 50+ sources, filtered for relevance")
                    featureRow(icon: "bell.fill", title: "Breaking Alerts", subtitle: "Push notifications for market-moving news")
                    featureRow(icon: "lock.shield.fill", title: "Private & Secure", subtitle: "No ads, no tracking, all data stored locally")
                }
                .padding(.horizontal, 32)
                .opacity(textOpacity)

                Spacer()

                // Terms
                Text("By continuing, you agree to our Terms of Service\nand Privacy Policy.")
                    .font(.system(size: 11))
                    .foregroundStyle(AgriPulseTheme.mutedForeground.opacity(0.4))
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .padding(.bottom, 12)
                    .opacity(buttonOpacity)

                // Continue button
                Button(action: onContinue) {
                    Text("Continue")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(AgriPulseTheme.primaryForeground)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AgriPulseTheme.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .opacity(buttonOpacity)
            }
        }
        // Inherits color scheme from parent
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                textOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.6)) {
                buttonOpacity = 1.0
            }
        }
    }

    private func featureRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(AgriPulseTheme.primary)
                .frame(width: 36, height: 36)
                .background(AgriPulseTheme.primary.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 9))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AgriPulseTheme.foreground)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(AgriPulseTheme.mutedForeground.opacity(0.6))
            }
        }
    }
}

// MARK: - Splash Screen (brief flash on subsequent launches)

struct SplashView: View {
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0

    var body: some View {
        ZStack {
            AgriPulseTheme.background
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image("AgriPulseLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)

                Text("AgriPulse")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(AgriPulseTheme.foreground)
                    .opacity(logoOpacity)
            }
        }
        // Inherits color scheme from parent
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
        }
    }
}
