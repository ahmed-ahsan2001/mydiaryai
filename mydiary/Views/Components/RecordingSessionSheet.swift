import SwiftUI

struct RecordingSessionSheet: View {
    @ObservedObject var recorder: AudioRecorder
    let onCancel: () -> Void
    let onComplete: (URL) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var hasStarted = false
    @State private var errorMessage: String?
    @State private var didFinish = false

    var body: some View {
        VStack(spacing: 28) {
            Capsule()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 44, height: 5)
                .padding(.top, 12)

            Text("Recording your memories…")
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)
                .foregroundColor(.appText)
                .padding(.top, 8)

            WaveformView(levels: recorder.powerLevels)
                .frame(height: 90)
                .padding(.horizontal, 32)

            Text(formattedTime(recorder.currentTime))
                .font(.system(.title2, design: .monospaced).weight(.medium))
                .foregroundColor(.appText.opacity(0.7))

            HStack(spacing: 32) {
                ControlButton(
                    systemImage: "xmark",
                    foreground: Color.red.opacity(0.9),
                    background: Color.red.opacity(0.12)
                ) {
                    endRecording(save: false)
                }

                PrimaryRecordButton(isRecording: recorder.isRecording && !recorder.isPaused) {
                    endRecording(save: true)
                }

                ControlButton(
                    systemImage: recorder.isPaused ? "play.fill" : "pause.fill",
                    foreground: Color.blue.opacity(0.9),
                    background: Color.blue.opacity(0.12)
                ) {
                    togglePause()
                }
                .disabled(!recorder.isRecording)
                .opacity(recorder.isRecording ? 1 : 0.4)
            }
            .padding(.top, 8)

            if let message = errorMessage {
                Text(message)
                    .font(.footnote)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()
        }
        .padding(.bottom, 32)
        .background(Color(.systemBackground))
        .task { await startIfNeeded() }
        .onDisappear {
            guard !didFinish else { return }
            if let url = recorder.stopRecording() {
                try? FileManager.default.removeItem(at: url)
            }
        }
    }

    private func startIfNeeded() async {
        guard !hasStarted else { return }
        hasStarted = true
        let allowed = await recorder.requestPermission()
        guard allowed else {
            errorMessage = "Microphone access is required to record."
            didFinish = true
            onCancel()
            dismiss()
            return
        }
        do {
            try recorder.startRecording()
        } catch {
            errorMessage = error.localizedDescription
            didFinish = true
            onCancel()
            dismiss()
        }
    }

    private func endRecording(save: Bool) {
        guard let url = recorder.stopRecording() else {
            didFinish = true
            onCancel()
            dismiss()
            return
        }
        didFinish = true
        if save {
            onComplete(url)
        } else {
            try? FileManager.default.removeItem(at: url)
            onCancel()
        }
        dismiss()
    }

    private func togglePause() {
        guard recorder.isRecording else { return }
        if recorder.isPaused {
            recorder.resume()
        } else {
            recorder.pause()
        }
    }

    private func formattedTime(_ time: TimeInterval) -> String {
        guard time.isFinite else { return "00:00" }
        let totalSeconds = Int(time.rounded(.towardZero))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

private struct ControlButton: View {
    let systemImage: String
    let foreground: Color
    let background: Color
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.title2.weight(.semibold))
                .foregroundColor(foreground)
                .frame(width: 64, height: 64)
                .background(
                    Circle()
                        .fill(background)
                )
        }
        .buttonStyle(.plain)
    }
}

private struct PrimaryRecordButton: View {
    let isRecording: Bool
    var action: () -> Void

    @State private var animate = false

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .stroke(Color.blue.opacity(0.2), lineWidth: 2)
                    .frame(width: 116, height: 116)
                    .scaleEffect(animate ? 1.1 : 1)
                    .opacity(animate ? 0.2 : 0.4)
                Circle()
                    .fill(LinearGradient(
                        colors: [Color(red: 0.31, green: 0.52, blue: 0.96), Color(red: 0.39, green: 0.57, blue: 0.99)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 100, height: 100)
                    .shadow(color: Color.blue.opacity(0.3), radius: 10, x: 0, y: 10)
                Image(systemName: "checkmark")
                    .font(.title)
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(.plain)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}

private struct WaveformView: View {
    let levels: [Float]

    var body: some View {
        GeometryReader { geometry in
            HStack(alignment: .center, spacing: geometry.size.width / CGFloat(max(levels.count * 4, 1))) {
                ForEach(Array(levels.enumerated()), id: \.offset) { index, level in
                    Capsule()
                        .fill(LinearGradient(
                            colors: [Color(red: 0.43, green: 0.63, blue: 0.99), Color(red: 0.27, green: 0.43, blue: 0.90)],
                            startPoint: .bottom,
                            endPoint: .top
                        ))
                        .frame(
                            width: max(6, geometry.size.width / CGFloat(max(levels.count * 2, 8))),
                            height: max(16, CGFloat(level.clamped(to: 0...1)) * geometry.size.height)
                        )
                        .animation(.easeOut(duration: 0.15), value: levels)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
        }
    }
}

private extension Float {
    func clamped(to range: ClosedRange<Float>) -> Float {
        min(max(self, range.lowerBound), range.upperBound)
    }
}




