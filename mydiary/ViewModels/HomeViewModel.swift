import Foundation
internal import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var recentEntries: [DiaryEntry] = []
    @Published var weeklyCount: Int = 0
    @Published var isTranscribing: Bool = false
    @Published var transcribedText: String = ""
    @Published var transcriptionError: String?

    private let store: DiaryStore
    private let whisper = OpenAIWhisperService()
    private let speech = SpeechRecognizerService()

    init(store: DiaryStore) {
        self.store = store
    }

    func refresh() async {
        do {
            recentEntries = try await store.loadAll()
            weeklyCount = try await store.weeklyCount()
        } catch { }
    }

    func save(text: String, audioTempURL: URL?) async {
        var entry = DiaryEntry(date: Date(), text: text)
        if let audioTempURL {
            let fileName = "\(entry.id.uuidString).m4a"
            entry.audioFileName = fileName
            // copy into store directory
            let dest = store.audioURL(forEntryId: entry.id)
            try? FileManager.default.removeItem(at: dest)
            try? FileManager.default.copyItem(at: audioTempURL, to: dest)
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
}


