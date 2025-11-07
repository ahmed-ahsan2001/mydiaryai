import SwiftUI

struct HomeView: View {
    @StateObject private var recorder = AudioRecorder()
    @StateObject private var player = AudioPlayer()
    @StateObject private var subService = SubscriptionService()
    @StateObject private var viewModel: HomeViewModel
    @State private var lastRecordingURL: URL?
    @State private var showProfile = false
    @State private var showCalendar = false

    init(store: DiaryStore) {
        _viewModel = StateObject(wrappedValue: HomeViewModel(store: store))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
            // MARK: - Header
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Free Trial: 6 days left")
                        .font(.headline)
                        .foregroundColor(.green)
                    Text("Enjoy unlimited access to all features")
                        .font(.subheadline)
                        .foregroundColor(.appText.opacity(0.7))
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
            }
            .padding(.horizontal)

            // MARK: - Stats Row
            HStack(spacing: 24) {
                statItem(title: "This Week", value: "\(viewModel.weeklyCount)", icon: "flame.fill")
                statItem(title: "Entries", value: "\(viewModel.recentEntries.count)", icon: "book.fill")
                statItem(title: "Words", value: "\(wordCount(viewModel.transcribedText))", icon: "textformat.alt")
                statItem(title: "Duration", value: durationString(player.duration), icon: "timer")
            }
            .padding(.horizontal)

            // MARK: - Daily Check-In
            VStack(spacing: 12) {
                Text("Daily Check-In")
                    .font(.headline)
                    .foregroundColor(.appText)
                
                Text("Share a compliment you received recently, or you want to give someone?")
                    .font(.body)
                    .foregroundColor(.appText.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                HStack(spacing: 6) {
                    Circle().fill(.gray.opacity(0.3)).frame(width: 6, height: 6)
                    Circle().fill(.green).frame(width: 6, height: 6)
                    Circle().fill(.gray.opacity(0.3)).frame(width: 6, height: 6)
                }

                VStack(spacing: 4) {
                    Text("Checking in for the day")
                        .font(.headline)
                        .foregroundColor(.appText)
                    Text("November 06")
                        .font(.subheadline)
                        .foregroundColor(.appText.opacity(0.6))
                }
                .padding(.top, 12)
            }

            // Transcription status / result
            if viewModel.isTranscribing {
                ProgressView("Transcribing...")
                    .padding(.horizontal)
            }
            if let err = viewModel.transcriptionError {
                Text(err).font(.footnote).foregroundColor(.red).padding(.horizontal)
            }
            if !viewModel.transcribedText.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Transcription").font(.headline).foregroundColor(.appText)
                    Text(viewModel.transcribedText).foregroundColor(.appText)
                    HStack {
                        Button("Save to Journal") { Task { await viewModel.save(text: viewModel.transcribedText, audioTempURL: lastRecordingURL) } }
                        Spacer()
                        ShareLink(item: viewModel.transcribedText) { Label("Share", systemImage: "square.and.arrow.up") }
                    }
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(.white))
                .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
                .padding(.horizontal)
            }

            Spacer()

            // MARK: - Bottom Bar
            HStack {
                NavigationLink(isActive: $showProfile) { ProfileView(subscriptionService: subService) } label: { EmptyView() }
                    .hidden()
                Button(action: { showProfile = true }) {
                    Image(systemName: "person")
                        .font(.title2)
                        .foregroundColor(.green)
                        .padding()
                        .background(Circle().stroke(Color.green, lineWidth: 1))
                }

                Spacer()

                Button(action: toggleRecord) {
                    ZStack {
                        Circle().fill(Color.green).frame(width: 100, height: 100)
                        Image(systemName: recorder.isRecording ? "stop.fill" : "mic.fill")
                            .font(.largeTitle)
                            .foregroundColor(.white)
                    }
                }

                Spacer()

                NavigationLink(isActive: $showCalendar) { CalendarView(store: viewModelStore) } label: { EmptyView() }
                    .hidden()
                Button(action: { showCalendar = true }) {
                    Image(systemName: "calendar")
                        .font(.title2)
                        .foregroundColor(.green)
                        .padding()
                        .background(Circle().stroke(Color.green, lineWidth: 1))
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 24)
        }
        .background(Color(red: 0.99, green: 0.98, blue: 0.95).ignoresSafeArea()) // light beige tone
        .navigationTitle("My Journal")
        }
        .task { await viewModel.refresh() }
    }

    private func statItem(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(.green)
            Text(value)
                .font(.headline)
                .foregroundColor(.appText)
            Text(title)
                .font(.caption)
                .foregroundColor(.appText.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
    }

    private func toggleRecord() {
        if recorder.isRecording {
            if let url = recorder.stopRecording() {
                lastRecordingURL = url
                try? player.load(url: url)
                Task { await viewModel.transcribe(from: url) }
            }
        } else {
            Task {
                guard await recorder.requestPermission() else { return }
                try? recorder.startRecording()
            }
        }
    }

    private var viewModelStore: DiaryStore { Mirror(reflecting: viewModel).children.first { $0.value is DiaryStore }?.value as! DiaryStore }

    private func wordCount(_ text: String) -> Int {
        text.split{ !$0.isLetter }.count
    }

    private func durationString(_ t: TimeInterval) -> String {
        guard t.isFinite && t > 0 else { return "0s" }
        let m = Int(t) / 60
        let s = Int(t) % 60
        if m > 0 { return "\(m)m \(s)s" } else { return "\(s)s" }
    }
}

