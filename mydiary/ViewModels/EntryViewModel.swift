import Foundation
import AVFoundation
#if canImport(UIKit)
import UIKit
#endif
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

    func saveEntry(text: String, mood: DiaryEntry.Mood, tags: [String], audioTempURL: URL?) async {
        var newEntry = DiaryEntry(date: entry.date, text: text, mood: mood, tags: tags)
        if let audioTempURL {
            let fileName = "\(newEntry.id.uuidString).m4a"
            newEntry.audioFileName = fileName
            let destination = store.audioURL(forEntryId: newEntry.id)
            do {
                try? FileManager.default.removeItem(at: destination)
                try FileManager.default.copyItem(at: audioTempURL, to: destination)
                let duration = audioDuration(at: destination)
                newEntry.audioDurationSeconds = duration > 0 ? duration : nil
                try FileManager.default.removeItem(at: audioTempURL)
            } catch {
                try? FileManager.default.removeItem(at: destination)
            }
        }
        try? await store.save(newEntry)
        if let all = try? await store.loadAll(on: entry.date) { self.entriesForDay = all }
    }

    func delete(entry: DiaryEntry) async {
        try? await store.delete(entry.id)
        if let all = try? await store.loadAll(on: entry.date) { self.entriesForDay = all }
    }

    func audioURL(for entry: DiaryEntry) -> URL? {
        guard let file = entry.audioFileName else { return nil }
        let url = store.audioURL(for: file)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    func addAudioEntry(from tempURL: URL) async {
        var newEntry = DiaryEntry(date: entry.date, text: "", mood: .happy)
        let fileName = "\(newEntry.id.uuidString).m4a"
        newEntry.audioFileName = fileName
        let destination = store.audioURL(forEntryId: newEntry.id)
        do {
            try? FileManager.default.removeItem(at: destination)
            try FileManager.default.copyItem(at: tempURL, to: destination)
            let duration = audioDuration(at: destination)
            newEntry.audioDurationSeconds = duration > 0 ? duration : nil
            try await store.save(newEntry)
            if let all = try? await store.loadAll(on: entry.date) { self.entriesForDay = all }
        } catch {
            try? FileManager.default.removeItem(at: destination)
        }
    }

#if canImport(UIKit)
    func generatePDF(for entry: DiaryEntry) -> URL? {
        let pageWidth: CGFloat = 612 // 8.5"
        let pageHeight: CGFloat = 792 // 11"
        let margin: CGFloat = 32
        let contentRect = CGRect(x: margin, y: margin, width: pageWidth - margin * 2, height: pageHeight - margin * 2)

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))
        let data = renderer.pdfData { ctx in
            ctx.beginPage()

            let title = entry.title.isEmpty ? "Diary Entry" : entry.title
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.preferredFont(forTextStyle: .title1),
                .foregroundColor: UIColor.label
            ]
            let bodyAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.preferredFont(forTextStyle: .body),
                .foregroundColor: UIColor.label
            ]

            let titleString = NSAttributedString(string: title + "\n", attributes: titleAttributes)
            let bodyString = NSAttributedString(string: entry.text, attributes: bodyAttributes)

            let combined = NSMutableAttributedString()
            combined.append(titleString)
            combined.append(bodyString)

            combined.draw(in: contentRect)
        }

        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("DiaryEntry-\(entry.id.uuidString).pdf")

        do {
            try data.write(to: fileURL, options: .atomic)
            return fileURL
        } catch {
            return nil
        }
    }
#else
    func generatePDF(for entry: DiaryEntry) -> URL? { nil }
#endif

    private func audioDuration(at url: URL) -> TimeInterval {
        let asset = AVURLAsset(url: url)
        let seconds = CMTimeGetSeconds(asset.duration)
        return seconds.isFinite ? seconds : 0
    }
}


