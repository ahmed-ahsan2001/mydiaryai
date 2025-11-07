import Foundation
internal import Combine

@MainActor
final class EntryViewModel: ObservableObject {
    @Published var entry: DiaryEntry
    @Published var audioURL: URL?
    @Published var entriesForDay: [DiaryEntry] = []
    private let store: DiaryStore

    init(date: Date, store: DiaryStore) {
        self.entry = DiaryEntry(date: date, text: "")
        self.store = store
    }

    func loadIfExists() async {
        if let existing = try? await store.load(on: entry.date) { self.entry = existing }
        if let fileName = entry.audioFileName {
            let url = store.audioURL(for: fileName)
            if FileManager.default.fileExists(atPath: url.path) { self.audioURL = url }
        }
        if let all = try? await store.loadAll(on: entry.date) { self.entriesForDay = all }
    }

    func save() async {
        try? await store.save(entry)
        if let all = try? await store.loadAll(on: entry.date) { self.entriesForDay = all }
    }

    func save(entry: DiaryEntry) async {
        try? await store.save(entry)
        if let all = try? await store.loadAll(on: entry.date) { self.entriesForDay = all }
    }

    func audioURL(for entry: DiaryEntry) -> URL? {
        guard let file = entry.audioFileName else { return nil }
        let url = store.audioURL(for: file)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }
}


