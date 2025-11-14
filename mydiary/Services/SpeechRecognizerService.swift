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

    func transcribe(url: URL, locale: Locale? = nil) async throws -> String {
        // Auto-detect language: try device's preferred language first, then fallback to current locale
        let preferredLocale = locale ?? Locale(identifier: Locale.preferredLanguages.first ?? Locale.current.identifier)
        
        // Try preferred locale first
        if let recognizer = SFSpeechRecognizer(locale: preferredLocale), recognizer.isAvailable {
            return try await performTranscription(recognizer: recognizer, url: url)
        }
        
        // Fallback to current locale if preferred is not available
        if let recognizer = SFSpeechRecognizer(locale: Locale.current), recognizer.isAvailable {
            return try await performTranscription(recognizer: recognizer, url: url)
        }
        
        // Last resort: try any available recognizer
        if let recognizer = SFSpeechRecognizer(), recognizer.isAvailable {
            return try await performTranscription(recognizer: recognizer, url: url)
        }
        
        throw SpeechRecognizerError.unavailable
    }
    
    private func performTranscription(recognizer: SFSpeechRecognizer, url: URL) async throws -> String {
        let request = SFSpeechURLRecognitionRequest(url: url)
        // Enable language detection by not specifying a language hint
        request.shouldReportPartialResults = false
        
        return try await withCheckedThrowingContinuation { cont in
            recognizer.recognitionTask(with: request) { result, error in
                if let error = error {
                    cont.resume(throwing: SpeechRecognizerError.failed(error.localizedDescription))
                    return
                }
                if let result = result, result.isFinal {
                    cont.resume(returning: result.bestTranscription.formattedString)
                }
            }
        }
    }
}


