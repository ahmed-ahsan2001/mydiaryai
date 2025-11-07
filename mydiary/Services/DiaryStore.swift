import Foundation

actor DiaryStore {
    private let directory: URL
    private let indexFile: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private struct Index: Codable { var ids: [UUID] }

    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.directory = docs.appendingPathComponent("DiaryEntries", isDirectory: true)
        self.indexFile = directory.appendingPathComponent("index.json")
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        decoder.dateDecodingStrategy = .iso8601
        encoder.dateEncodingStrategy = .iso8601
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        if !FileManager.default.fileExists(atPath: indexFile.path) {
            try? Data("{\"ids\":[]}".utf8).write(to: indexFile)
        }
    }

    func save(_ entry: DiaryEntry) async throws {
        let file = fileURL(for: entry.id)
        let data = try encoder.encode(entry)
        try data.write(to: file, options: .atomic)
        try await upsertIndex(id: entry.id)
    }

    func loadAll() async throws -> [DiaryEntry] {
        let ids = try await readIndex()
        var entries: [DiaryEntry] = []
        for id in ids {
            let url = fileURL(for: id)
            if let data = try? Data(contentsOf: url), let entry = try? decoder.decode(DiaryEntry.self, from: data) {
                entries.append(entry)
            }
        }
        return entries.sorted { $0.date > $1.date }
    }

    func load(on date: Date) async throws -> DiaryEntry? {
        let all = try await loadAll()
        let cal = Calendar.current
        return all.first { cal.isDate($0.date, inSameDayAs: date) }
    }

    func loadAll(on date: Date) async throws -> [DiaryEntry] {
        let all = try await loadAll()
        let cal = Calendar.current
        return all.filter { cal.isDate($0.date, inSameDayAs: date) }
            .sorted { $0.date < $1.date }
    }

    func delete(_ id: UUID) async throws {
        try? FileManager.default.removeItem(at: fileURL(for: id))
        try await removeFromIndex(id: id)
    }

    func weeklyCount(for referenceDate: Date = Date()) async throws -> Int {
        let all = try await loadAll()
        let cal = Calendar.current
        guard let weekStart = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: referenceDate)) else { return 0 }
        let weekEnd = cal.date(byAdding: .day, value: 7, to: weekStart)!
        return all.filter { $0.date >= weekStart && $0.date < weekEnd }.count
    }

    private func fileURL(for id: UUID) -> URL { directory.appendingPathComponent("\(id.uuidString).json") }
    nonisolated func audioURL(for fileName: String) -> URL { directory.appendingPathComponent(fileName) }

    nonisolated func audioURL(forEntryId id: UUID) -> URL { directory.appendingPathComponent("\(id.uuidString).m4a") }

    private func readIndex() async throws -> [UUID] {
        let data = try Data(contentsOf: indexFile)
        let idx = try decoder.decode(Index.self, from: data)
        return idx.ids
    }

    private func writeIndex(_ ids: [UUID]) throws {
        let data = try encoder.encode(Index(ids: ids))
        try data.write(to: indexFile, options: .atomic)
    }

    private func upsertIndex(id: UUID) async throws {
        var ids = try await readIndex()
        if !ids.contains(id) { ids.append(id) }
        try writeIndex(ids)
    }

    private func removeFromIndex(id: UUID) async throws {
        var ids = try await readIndex()
        ids.removeAll { $0 == id }
        try writeIndex(ids)
    }
}


