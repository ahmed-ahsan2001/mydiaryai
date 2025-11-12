import SwiftUI

struct HomeView: View {
  @StateObject private var recorder = AudioRecorder()
  @StateObject private var player = AudioPlayer()
  @StateObject private var subService = SubscriptionService()
  @StateObject private var viewModel: HomeViewModel
  @State private var lastRecordingURL: URL?
  @State private var showRecordingSheet = false
  @State private var showSettings = false
  @State private var showCalendar = false
  @State private var animatePulse = false
  @State private var isReviewSheetPresented = false
  @State private var reviewText: String = ""
  @State private var reviewMood: DiaryEntry.Mood = .neutral
  @State private var reviewTags: [String] = []

  init(store: DiaryStore) {
    _viewModel = StateObject(wrappedValue: HomeViewModel(store: store))
  }

  var body: some View {
    NavigationStack {
      mainContent()
        .padding(.bottom, 24)
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("My Voice Diary")
        .toolbar { ToolbarItem(placement: .navigationBarLeading) { EmptyView() } }
    }
    .task { await viewModel.refresh() }
    .onAppear(perform: startPulse)
    .onChange(of: viewModel.transcribedText, perform: handleTranscriptChange)
    .sheet(isPresented: $showRecordingSheet, content: recordingSheet)
    .sheet(isPresented: $showCalendar, content: calendarSheet)
    .sheet(isPresented: $showSettings, content: settingsSheet)
    .sheet(isPresented: $isReviewSheetPresented, content: reviewSheet)
  }

  @ViewBuilder
  private func mainContent() -> some View {
    VStack(spacing: 28) {
      headerSection
      statsSection
      statusSection
      Spacer()
      actionBar
    }
  }

  private func statItem(title: String, value: String, icon: String) -> some View {
    VStack(spacing: 4) {
      Image(systemName: icon)
        .foregroundColor(.appHighlight)
      Text(value)
        .font(.headline)
        .foregroundColor(.appHighlight)
      Text(title)
        .font(.caption)
        .foregroundColor(.appText.opacity(0.5))
    }
    .frame(maxWidth: .infinity)
  }

  private var viewModelStore: DiaryStore { Mirror(reflecting: viewModel).children.first { $0.value is DiaryStore }?.value as! DiaryStore }

  private var headerSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      VStack(alignment: .leading, spacing: 4) {
        Text("Free Trial: 6 days left")
          .font(.headline)
          .foregroundColor(.appText)
        Text("Enjoy unlimited access to all features")
          .font(.subheadline)
          .foregroundColor(.appText.opacity(0.7))
      }
      .padding()
      .frame(maxWidth: .infinity)
      .background(AppTheme.secondary.opacity(0.45))
      .cornerRadius(16)
    }
    .padding(.horizontal)
  }

  private var statsSection: some View {
    HStack(spacing: 24) {
      statItem(title: "This Week", value: "\(viewModel.weeklyCount)", icon: "flame.fill")
      statItem(title: "Entries", value: "\(viewModel.recentEntries.count)", icon: "book.fill")
      statItem(title: "Words", value: "\(viewModel.totalWordCount)", icon: "textformat.alt")
      statItem(title: "Duration", value: durationString(viewModel.totalAudioDuration), icon: "timer")
    }
    .padding(.horizontal)
  }

  private var statusSection: some View {
    VStack(spacing: 8) {
      if viewModel.isTranscribing {
        ProgressView("Transcribing...")
          .padding(.horizontal)
      }
      if let err = viewModel.transcriptionError {
        Text(err)
          .font(.footnote)
          .foregroundColor(.red)
          .padding(.horizontal)
      }
    }
  }

  private var actionBar: some View {
    HStack {
      Button { showCalendar = true } label: {
        Image(systemName: "calendar")
          .font(.title2)
          .foregroundColor(.appHighlight)
          .padding()
          .background(
            Circle()
              .stroke(Color.appHighlight.opacity(0.7), lineWidth: 1.5)
          )
      }

      Spacer()

      Button(action: { showRecordingSheet = true }) {
        ZStack {
          Circle()
            .fill(Color.appAccent)
            .frame(width: 108, height: 108)
            .overlay(
              Circle()
                .stroke(Color.appAccent.opacity(0.3), lineWidth: 6)
                .scaleEffect(animatePulse ? 1.3 : 1)
                .opacity(animatePulse ? 0 : 1)
                .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: false), value: animatePulse)
            )
            .shadow(color: Color.appAccent.opacity(0.35), radius: 16, x: 0, y: 10)
          Image(systemName: "mic.fill")
            .font(.system(size: 36, weight: .bold))
            .foregroundColor(.white)
        }
      }
      .buttonStyle(.plain)

      Spacer()

      Button { showSettings = true } label: {
        Image(systemName: "gearshape")
          .font(.title2)
          .foregroundColor(.appHighlight)
          .padding()
          .background(
            Circle()
              .stroke(Color.appHighlight.opacity(0.7), lineWidth: 1.5)
          )
      }
    }
    .padding(.horizontal, 40)
  }

  private func durationString(_ t: TimeInterval) -> String {
    guard t.isFinite && t > 0 else { return "0s" }
    let m = Int(t) / 60
    let s = Int(t) % 60
    if m > 0 { return "\(m)m \(s)s" } else { return "\(s)s" }
  }

  private func startPulse() {
    withAnimation(Animation.easeInOut(duration: 1.6).repeatForever(autoreverses: false)) {
      animatePulse = true
    }
  }

  private func handleTranscriptChange(_ newValue: String) {
    guard !newValue.isEmpty else { return }
    reviewText = newValue
    reviewMood = .neutral
    reviewTags = []
    isReviewSheetPresented = true
  }

  // MARK: - Sheet Builders

  private func recordingSheet() -> some View {
    RecordingSessionSheet(
      recorder: recorder,
      onCancel: {
        showRecordingSheet = false
      },
      onComplete: { url in
        lastRecordingURL = url
        showRecordingSheet = false
        try? player.load(url: url)
        Task { await viewModel.transcribe(from: url) }
      }
    )
    .presentationDetents([.fraction(0.5), .large])
    .presentationDragIndicator(.hidden)
  }

  private func calendarSheet() -> some View {
    NavigationStack {
      CalendarView(store: viewModelStore)
    }
    .presentationDetents([.large])
  }

  private func settingsSheet() -> some View {
    NavigationStack {
      ProfileView(subscriptionService: subService)
    }
    .presentationDetents([.large])
  }

  private func reviewSheet() -> some View {
    NavigationStack {
      RecordingReviewSheet(
        text: $reviewText,
        mood: $reviewMood,
        tags: $reviewTags,
        onCancel: handleReviewCancel,
        onSave: handleReviewSave
      )
    }
    .presentationDetents([.large])
  }

  private func handleReviewCancel() {
    if let url = lastRecordingURL {
      try? FileManager.default.removeItem(at: url)
    }
    lastRecordingURL = nil
    viewModel.transcribedText = ""
    reviewTags = []
    isReviewSheetPresented = false
  }

  private func handleReviewSave() {
    Task {
      await viewModel.save(
        text: reviewText,
        mood: reviewMood,
        tags: reviewTags,
        audioTempURL: lastRecordingURL
      )
      await MainActor.run {
        viewModel.transcribedText = ""
        lastRecordingURL = nil
        reviewTags = []
        isReviewSheetPresented = false
      }
    }
  }
}
