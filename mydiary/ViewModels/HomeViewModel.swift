import Foundation
import AVFoundation
internal import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var recentEntries: [DiaryEntry] = []
    @Published var weeklyCount: Int = 0
    @Published var isTranscribing: Bool = false
    @Published var transcribedText: String = ""
    @Published var transcriptionError: String?
    @Published var totalWordCount: Int = 0
    @Published var totalAudioDuration: TimeInterval = 0

    private let store: DiaryStore
    private let whisper = OpenAIWhisperService()
    private let speech = SpeechRecognizerService()

    init(store: DiaryStore) {
        self.store = store
    }

    func refresh() async {
        do {
            let loaded = try await store.loadAll()
            let enriched = await enrich(entries: loaded)
            recentEntries = enriched
            recomputeAggregates(from: enriched)
            weeklyCount = try await store.weeklyCount()
        } catch { }
    }

    func save(text: String, mood: DiaryEntry.Mood, tags: [String], audioTempURL: URL?) async {
        var entry = DiaryEntry(date: Date(), text: text, mood: mood, tags: tags)
        if let audioTempURL {
            let fileName = "\(entry.id.uuidString).m4a"
            entry.audioFileName = fileName
            // copy into store directory
            let dest = store.audioURL(forEntryId: entry.id)
            try? FileManager.default.removeItem(at: dest)
            try? FileManager.default.copyItem(at: audioTempURL, to: dest)
            entry.audioDurationSeconds = audioDuration(at: dest)
            try? FileManager.default.removeItem(at: audioTempURL)
        }
        do { try await store.save(entry); await refresh() } catch { }
    }

    func transcribe(from audioURL: URL) async {
        isTranscribing = true
        defer { isTranscribing = false }
        do {
            let text = try await whisper.transcribeAudio(fileURL: audioURL)
            transcribedText = text
            transcriptionError = nil
        } catch {
            // Fallback to on-device Speech framework
            do {
                let authorized = await speech.requestAuthorization()
                guard authorized else { throw SpeechRecognizerError.notAuthorized }
                let text = try await speech.transcribe(url: audioURL)
                transcribedText = text
                transcriptionError = nil
            } catch {
                transcribedText = ""
                transcriptionError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            }
        }
    }

    private func enrich(entries: [DiaryEntry]) async -> [DiaryEntry] {
        var updated: [DiaryEntry] = []
        updated.reserveCapacity(entries.count)

        for var entry in entries {
            if entry.audioDurationSeconds == nil,
               let fileName = entry.audioFileName {
                let url = store.audioURL(for: fileName)
                let duration = audioDuration(at: url)
                if duration > 0 {
                    entry.audioDurationSeconds = duration
                    try? await store.save(entry)
                }
            }
            updated.append(entry)
        }
        return updated
    }

    private func recomputeAggregates(from entries: [DiaryEntry]) {
        totalWordCount = entries.reduce(0) { $0 + $1.wordCount }
        totalAudioDuration = entries.reduce(0) { $0 + max(0, $1.audioDurationSeconds ?? 0) }
    }

    private func audioDuration(at url: URL) -> TimeInterval {
        let asset = AVURLAsset(url: url)
        let seconds = CMTimeGetSeconds(asset.duration)
        return seconds.isFinite ? max(0, seconds) : 0
    }
}


