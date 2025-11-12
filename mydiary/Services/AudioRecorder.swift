import AVFoundation
import Foundation
internal import Combine

final class AudioRecorder: NSObject, ObservableObject {
    @Published private(set) var isRecording: Bool = false
    @Published private(set) var isPaused: Bool = false
    @Published private(set) var currentTime: TimeInterval = 0
    @Published private(set) var powerLevels: [Float] = []

    private var recorder: AVAudioRecorder?
    private var recordedURL: URL?
    private var meterTimer: Timer?
    private let maxSamples = 12

    func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { allowed in
                continuation.resume(returning: allowed)
            }
        }
    }

    func startRecording() throws {
        stopMetering()
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
        try session.setActive(true)

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("recording_\(UUID().uuidString).m4a")
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        recorder = try AVAudioRecorder(url: url, settings: settings)
        recorder?.delegate = self
        recorder?.isMeteringEnabled = true
        recorder?.record()
        recordedURL = url
        isRecording = true
        isPaused = false
        currentTime = 0
        powerLevels = Array(repeating: 0.2, count: maxSamples)
        startMetering()
    }

    func stopRecording() -> URL? {
        recorder?.stop()
        isRecording = false
        isPaused = false
        stopMetering(reset: true)
        let url = recordedURL
        recordedURL = nil
        return url
    }

    func pause() {
        guard isRecording, !isPaused else { return }
        recorder?.pause()
        isPaused = true
        stopMetering()
    }

    func resume() {
        guard isRecording, isPaused else { return }
        recorder?.record()
        isPaused = false
        startMetering()
    }

    private func startMetering() {
        if powerLevels.isEmpty {
            powerLevels = Array(repeating: 0.2, count: maxSamples)
        }
        meterTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { [weak self] _ in
            guard let self, let recorder = self.recorder else { return }
            recorder.updateMeters()
            self.currentTime = recorder.currentTime
            let normalized = max(0, (recorder.averagePower(forChannel: 0) + 50) / 50)
            var updatedLevels = self.powerLevels
            if updatedLevels.count >= self.maxSamples {
                updatedLevels.removeFirst(updatedLevels.count - (self.maxSamples - 1))
            }
            updatedLevels.append(normalized.isFinite ? normalized : 0.1)
            self.powerLevels = updatedLevels
        }
    }

    private func stopMetering(reset: Bool = false) {
        meterTimer?.invalidate()
        meterTimer = nil
        if reset {
            currentTime = 0
            powerLevels = []
        }
    }
}

extension AudioRecorder: AVAudioRecorderDelegate {}


