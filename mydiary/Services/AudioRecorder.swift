import AVFoundation
import Foundation
internal import Combine

final class AudioRecorder: NSObject, ObservableObject {
    @Published private(set) var isRecording: Bool = false
    private var recorder: AVAudioRecorder?
    private var recordedURL: URL?

    func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { allowed in
                continuation.resume(returning: allowed)
            }
        }
    }

    func startRecording() throws {
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
        recorder?.record()
        recordedURL = url
        isRecording = true
    }

    func stopRecording() -> URL? {
        recorder?.stop()
        isRecording = false
        return recordedURL
    }
}

extension AudioRecorder: AVAudioRecorderDelegate {}


