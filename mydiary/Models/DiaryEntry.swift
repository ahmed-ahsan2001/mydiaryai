import Foundation

struct DiaryEntry: Identifiable, Codable, Hashable {
    enum Mood: String, Codable, CaseIterable, Identifiable {
        case cool, love, sad, angry, happy

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .cool: return "Cool"
            case .love: return "Love"
            case .sad: return "Sad"
            case .angry: return "Angry"
            case .happy: return "Happy"
            }
        }

        var sortOrder: Int {
            switch self {
            case .cool: return 0
            case .love: return 1
            case .sad: return 2
            case .angry: return 3
            case .happy: return 4
            }
        }
    }

    let id: UUID
    var title: String
    var date: Date
    var text: String
    var audioFileName: String?
    var mood: Mood
    var tags: [String]
    var audioDurationSeconds: TimeInterval?

    init(
        id: UUID = UUID(),
        title: String = "",
        date: Date = Date(),
        text: String = "",
        audioFileName: String? = nil,
        mood: Mood = .happy,
        tags: [String] = [],
        audioDurationSeconds: TimeInterval? = nil
    ) {
        self.id = id
        self.title = title
        self.date = date
        self.text = text
        self.audioFileName = audioFileName
        self.mood = mood
        self.tags = tags
        self.audioDurationSeconds = audioDurationSeconds
    }

    var wordCount: Int {
        text.split { !$0.isLetter }.count
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, date, text, audioFileName, mood, tags, audioDurationSeconds
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        date = try container.decode(Date.self, forKey: .date)
        text = try container.decodeIfPresent(String.self, forKey: .text) ?? ""
        audioFileName = try container.decodeIfPresent(String.self, forKey: .audioFileName)
        mood = try container.decodeIfPresent(Mood.self, forKey: .mood) ?? .happy
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        audioDurationSeconds = try container.decodeIfPresent(TimeInterval.self, forKey: .audioDurationSeconds)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(date, forKey: .date)
        try container.encode(text, forKey: .text)
        try container.encodeIfPresent(audioFileName, forKey: .audioFileName)
        try container.encode(mood, forKey: .mood)
        try container.encode(tags, forKey: .tags)
        try container.encodeIfPresent(audioDurationSeconds, forKey: .audioDurationSeconds)
    }
}

struct WeeklyProgress: Codable, Hashable {
    var weekStart: Date
    var entriesCount: Int
}


