import SwiftUI

struct LaunchScreenView: View {
    @State private var animatePulse = false
    @State private var animateIcon = false

    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()

            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(Color.appSecondary.opacity(0.4))
                        .frame(width: 180, height: 180)
                        .scaleEffect(animatePulse ? 1.2 : 0.9)
                        .opacity(animatePulse ? 0 : 1)

                    Circle()
                        .fill(Color.appSecondary.opacity(0.6))
                        .frame(width: 140, height: 140)
                        .scaleEffect(animatePulse ? 1.05 : 0.95)

                    Image(systemName: "waveform.circle.fill")
                        .font(.system(size: 96))
                        .foregroundColor(Color.appAccent)
                        .scaleEffect(animateIcon ? 1 : 0.8)
                        .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 8)
                }
                .frame(width: 200, height: 200)

                VStack(spacing: 8) {
                    Text("My Diary AI")
                        .font(.system(size: 34, weight: .semibold, design: .rounded))
                        .foregroundColor(.appText)
                    Text("Recording your memories with care.")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.appText.opacity(0.6))
                }
            }
            .padding()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                animatePulse = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7, blendDuration: 0.3)) {
                animateIcon = true
            }
        }
    }
}

