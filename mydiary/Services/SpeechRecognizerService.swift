import Foundation
import Speech

enum SpeechRecognizerError: LocalizedError {
    case notAuthorized
    case unavailable
    case failed(String)

    var errorDescription: String? {
        switch self {
        case .notAuthorized: return "Speech recognition not authorized."
        case .unavailable: return "Speech recognizer unavailable for current locale."
        case .failed(let reason): return reason
        }
    }
}

struct SpeechRecognizerService {
    func requestAuthorization() async -> Bool {
        await withCheckedContinuation { cont in
            SFSpeechRecognizer.requestAuthorization { status in
                cont.resume(returning: status == .authorized)
            }
        }
    }

    func transcribe(url: URL, locale: Locale = Locale.current) async throws -> String {
        guard let recognizer = SFSpeechRecognizer(locale: locale), recognizer.isAvailable else {
            throw SpeechRecognizerError.unavailable
        }
        let request = SFSpeechURLRecognitionRequest(url: url)
        return try await withCheckedThrowingContinuation { cont in
            recognizer.recognitionTask(with: request) { result, error in
                if let error = error { cont.resume(throwing: SpeechRecognizerError.failed(error.localizedDescription)); return }
                if let result = result, result.isFinal {
                    cont.resume(returning: result.bestTranscription.formattedString)
                }
            }
        }
    }
}


