import SwiftUI

struct EntryView: View {
    @StateObject private var viewModel: EntryViewModel
    @StateObject private var player = AudioPlayer()
    @FocusState private var isEditing: Bool

    init(date: Date, store: DiaryStore) {
        _viewModel = StateObject(wrappedValue: EntryViewModel(date: date, store: store))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // MARK: - Header
                Text(viewModel.entry.title.isEmpty ? "Daily Entry" : viewModel.entry.title)
                    .font(.title2.bold())
                    .foregroundColor(.appText)
                    .padding(.top, 12)

                Text(viewModel.entry.date, style: .time)
                    .font(.subheadline)
                    .foregroundColor(.appText.opacity(0.6))

                // MARK: - Entries Today (unified list: audio + text on background)
                if !viewModel.entriesForDay.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Entries Today")
                            .font(.headline)
                            .foregroundColor(.appText)
                        ForEach(viewModel.entriesForDay, id: \.id) { e in
                            EntryInlineRow(entry: e)
                        }
                    }
                    .padding(.top, 8)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
         .background(Color(red: 0.99, green: 0.98, blue: 0.95).ignoresSafeArea())
         .navigationBarTitleDisplayMode(.inline)
         .toolbar {
             ToolbarItem(placement: .bottomBar) {
                HStack {
                     Button { Task { await viewModel.save() } } label: {
                         HStack(spacing: 6) {
                             Image(systemName: "tray.and.arrow.down")
                             Text("Save")
                         }
                         .font(.headline)
                         .foregroundColor(.green)
                     }
                    Spacer()
                    Button(action: { /* record new voice entry */ }) {
                        Image(systemName: "mic.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                            .background(Circle().fill(Color(red: 0.31, green: 0.52, blue: 0.26)))
                            .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 4)
                    }
                    Spacer()
                    ShareLink(item: viewModel.entry.text) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title2)
                            .foregroundColor(.green)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
        }
        .task { await viewModel.loadIfExists() }
         .contentShape(Rectangle())
         .onTapGesture { isEditing = false }
    }

    private func suggestionButton(_ text: String) -> some View {
        Button(action: { /* future AI response hook */ }) {
            Text(text)
                .font(.subheadline)
                .foregroundColor(Color(red: 0.31, green: 0.52, blue: 0.26))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(RoundedRectangle(cornerRadius: 12).stroke(Color(red: 0.31, green: 0.52, blue: 0.26), lineWidth: 1))
        }
    }

    private func timeString(_ t: TimeInterval) -> String {
        guard t.isFinite else { return "0:00" }
        let m = Int(t) / 60
        let s = Int(t) % 60
        return String(format: "%d:%02d", m, s)
    }
}

// Separate inline row with its own player so play state is isolated per entry
private struct EntryInlineRow: View {
    let entry: DiaryEntry
    @StateObject private var player = AudioPlayer()
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(entry.date, style: .time)
                .font(.caption)
                .foregroundColor(.appText.opacity(0.7))
            if let file = entry.audioFileName {
                let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                    .appendingPathComponent("DiaryEntries")
                    .appendingPathComponent(file)
                HStack(spacing: 10) {
                    Button(action: {
                        if player.duration == 0 { try? player.load(url: url) }
                        player.isPlaying ? player.pause() : player.play()
                    }) {
                        Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                            .foregroundColor(.green)
                    }
                    ProgressView(value: player.duration == 0 ? 0 : player.currentTime / max(player.duration, 0.001))
                }
            }
            Text(entry.text.isEmpty ? "(No text)" : entry.text)
                .foregroundColor(.black)
        }
    }
}

