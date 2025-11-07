import Foundation

struct OpenAIWhisperService {
    enum WhisperError: LocalizedError {
        case missingAPIKey
        case invalidResponse(status: Int, body: String)
        case decoding

        var errorDescription: String? {
            switch self {
            case .missingAPIKey: return "Missing OPENAI_API_KEY. Set it in the scheme Environment Variables."
            case .invalidResponse(let status, let body): return "Whisper API failed (\(status)): \(body)"
            case .decoding: return "Failed to decode transcription response."
            }
        }
    }

    var apiKey: String { ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? "" }

    func transcribeAudio(fileURL: URL) async throws -> String {
        guard !apiKey.isEmpty else { throw WhisperError.missingAPIKey }
        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/audio/transcriptions")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        let model = "whisper-1"
        var body = Data()
        // model
        body.appendString("--\(boundary)\r\n")
        body.appendString("Content-Disposition: form-data; name=\"model\"\r\n\r\n")
        body.appendString("\(model)\r\n")
        // response_format (explicit json)
        body.appendString("--\(boundary)\r\n")
        body.appendString("Content-Disposition: form-data; name=\"response_format\"\r\n\r\n")
        body.appendString("json\r\n")
        // file
        let fileData = try Data(contentsOf: fileURL)
        body.appendString("--\(boundary)\r\n")
        body.appendString("Content-Disposition: form-data; name=\"file\"; filename=\"audio.m4a\"\r\n")
        body.appendString("Content-Type: audio/m4a\r\n\r\n")
        body.append(fileData)
        body.appendString("\r\n")
        body.appendString("--\(boundary)--\r\n")
        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let bodyString = String(data: data, encoding: .utf8) ?? "<no body>"
            throw WhisperError.invalidResponse(status: (response as? HTTPURLResponse)?.statusCode ?? -1, body: bodyString)
        }
        struct Resp: Decodable { let text: String }
        do {
            let decoded = try JSONDecoder().decode(Resp.self, from: data)
            return decoded.text
        } catch {
            throw WhisperError.decoding
        }
    }
}

private extension Data {
    mutating func appendString(_ string: String) {
        if let data = string.data(using: .utf8) { append(data) }
    }
}


