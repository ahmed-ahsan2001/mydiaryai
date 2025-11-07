import SwiftUI
import Speech

struct OnboardingView: View {
    var onContinue: () -> Void
    @StateObject private var recorder = AudioRecorder()
    @State private var micAllowed = false
    @State private var speechAllowed = false

    var body: some View {
        VStack(spacing: 24) {
            Text("MyDiary AI")
                .font(.largeTitle.bold())
                .foregroundColor(.appText)
            Text("Record your thoughts, auto-transcribed. Organize by calendar. Clean and private.")
                .multilineTextAlignment(.center)
                .foregroundColor(.appText.opacity(0.7))
            Image(systemName: "mic.circle.fill")
                .resizable().scaledToFit().frame(width: 120)
                .foregroundColor(AppTheme.accent)
            Button(action: requestPermissions) {
                Text(micAllowed && speechAllowed ? "Continue" : "Allow Mic + Speech")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 16).fill(AppTheme.secondary))
                    .foregroundColor(.white)
            }
            .padding(.horizontal)
        }
        .padding()
        .background(Color.appBackground.ignoresSafeArea())
        .onChange(of: micAllowed) { _ in maybeContinue() }
        .onChange(of: speechAllowed) { _ in maybeContinue() }
    }

    private func requestPermissions() {
        Task {
            micAllowed = await recorder.requestPermission()
            let status = await withCheckedContinuation { cont in
                SFSpeechRecognizer.requestAuthorization { cont.resume(returning: $0) }
            }
            speechAllowed = (status == .authorized)
        }
    }

    private func maybeContinue() {
        if micAllowed && speechAllowed { onContinue() }
    }
}


