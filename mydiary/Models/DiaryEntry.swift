import Foundation

struct DiaryEntry: Identifiable, Codable, Hashable {
    let id: UUID
    let title: String
    var date: Date
    var text: String
    var audioFileName: String?

  init(id: UUID = UUID(), title: String = "", date: Date = Date(), text: String = "", audioFileName: String? = nil) {
        self.id = id
        self.title = title
        self.date = date
        self.text = text
        self.audioFileName = audioFileName
    }
}

struct WeeklyProgress: Codable, Hashable {
    var weekStart: Date
    var entriesCount: Int
}


