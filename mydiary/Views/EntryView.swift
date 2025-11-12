import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct EntryView: View {
  @Environment(\.dismiss) private var dismiss
  @StateObject private var viewModel: EntryViewModel
  @StateObject private var recorder = AudioRecorder()
  @FocusState private var isEditing: Bool
  @State private var entryBeingEdited: DiaryEntry?
  @State private var shareEntry: DiaryEntry?
  @State private var activityItems: [Any] = []
  @State private var isActivityPresented = false
  @State private var entryPendingDeletion: DiaryEntry?
  @State private var alertInfo: AlertInfo?
  @State private var selectedMoodFilter: DiaryEntry.Mood? = nil
  @State private var sortOption: SortOption = .reverseChronological
  @State private var showRecordingSheet = false
  @State private var isTranscribing = false
  @State private var isReviewSheetPresented = false
  @State private var reviewText: String = ""
  @State private var reviewMood: DiaryEntry.Mood = .neutral
  @State private var reviewTags: [String] = []
  @State private var pendingAudioURL: URL?
  
  init(date: Date, store: DiaryStore) {
    _viewModel = StateObject(wrappedValue: EntryViewModel(date: date, store: store))
  }
  
  private var displayedEntries: [DiaryEntry] {
    var entries = viewModel.entriesForDay
    if let filter = selectedMoodFilter {
      entries = entries.filter { $0.mood == filter }
    }
    switch sortOption {
    case .chronological:
      return entries.sorted { $0.date < $1.date }
    case .reverseChronological:
      return entries.sorted { $0.date > $1.date }
    case .mood:
      return entries.sorted {
        if $0.mood.sortOrder == $1.mood.sortOrder {
          return $0.date < $1.date
        }
        return $0.mood.sortOrder < $1.mood.sortOrder
      }
    }
  }
  
  private enum SortOption: CaseIterable, Identifiable {
    case chronological, reverseChronological, mood
    
    var id: Self { self }
    
    var title: String {
      switch self {
      case .chronological: return "Oldest First"
      case .reverseChronological: return "Newest First"
      case .mood: return "Mood Order"
      }
    }
    
    var systemImage: String {
      switch self {
      case .chronological: return "arrow.down.to.line"
      case .reverseChronological: return "arrow.up.to.line"
      case .mood: return "face.smiling"
      }
    }
  }
  
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        if isTranscribing {
          ProgressView("Transcribing...")
            .progressViewStyle(.circular)
            .padding(.top)
        }
        // MARK: - Entries Today (unified list: audio + text on background)
        entriesTodaySection
      }
      .padding(.horizontal)
      .padding(.bottom, 40)
    }
    .background(AppTheme.background.ignoresSafeArea())
    .navigationBarTitleDisplayMode(.inline)
    .navigationBarBackButtonHidden(true)
    .toolbar {
      ToolbarItem(placement: .navigationBarLeading) {
        Button(action: { dismiss() }) {
          HStack(spacing: 6) {
            Image(systemName: "arrow.left")
            Text("Back")
          }
          .font(.headline)
          .foregroundColor(.appText)
        }
      }
      ToolbarItem(placement: .bottomBar) {
        HStack {
          Spacer()
          Button(action: { showRecordingSheet = true }) {
            Image(systemName: "mic.fill")
              .font(.title)
              .foregroundColor(AppTheme.background)
              .padding()
              .background(Circle().fill(AppTheme.accent))
              .shadow(color: AppTheme.accent.opacity(0.25), radius: 6, x: 0, y: 4)
          }
          Spacer()
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
      }
    }
    .task { await viewModel.loadIfExists() }
    .contentShape(Rectangle())
    .onTapGesture { isEditing = false }
    .sheet(item: $entryBeingEdited) { entry in
      NavigationStack {
        EditEntrySheet(
          entry: entry,
          onSave: { updatedEntry in
            Task { await viewModel.save(entry: updatedEntry) }
            entryBeingEdited = nil
          },
          onDelete: {
            entryBeingEdited = nil
            entryPendingDeletion = entry
          }
        )
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") { entryBeingEdited = nil }
          }
        }
      }
    }
    .sheet(item: $shareEntry) { entry in
      ShareOptionsSheet(
        entry: entry,
        onOptionSelected: { option in
          handleShare(option: option, for: entry)
        }
      )
      .presentationDetents([.medium])
      .presentationDragIndicator(.visible)
    }
    .sheet(isPresented: $showRecordingSheet) {
      RecordingSessionSheet(
        recorder: recorder,
        onCancel: { showRecordingSheet = false },
        onComplete: { url in
          showRecordingSheet = false
          Task { await handleRecordingCompletion(with: url) }
        }
      )
      .presentationDetents([.fraction(0.55), .large])
      .presentationDragIndicator(.hidden)
    }
#if canImport(UIKit)
    .sheet(isPresented: $isActivityPresented, onDismiss: { activityItems = [] }) {
      if !activityItems.isEmpty {
        ActivityView(activityItems: activityItems)
          .presentationDetents([.large])
      }
    }
#endif
    .sheet(isPresented: $isReviewSheetPresented) {
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
    .confirmationDialog(
      "Delete Entry?",
      isPresented: Binding(
        get: { entryPendingDeletion != nil },
        set: { if !$0 { entryPendingDeletion = nil } }
      ),
      titleVisibility: .visible,
      presenting: entryPendingDeletion
      
    ) { entry in
      Button("Delete", role: .destructive) {
        Task { await viewModel.delete(entry: entry) }
      }
      Button("Cancel", role: .cancel) { entryPendingDeletion = nil }
    }
    .alert(item: $alertInfo) { info in
      Alert(title: Text(info.title), message: info.message.map(Text.init), dismissButton: .default(Text("OK")))
    }
  }
  
  private func handleShare(option: ShareOptionsSheet.Option, for entry: DiaryEntry) {
    shareEntry = nil
    switch option {
    case .copy:
#if canImport(UIKit)
      UIPasteboard.general.string = entry.text
      alertInfo = AlertInfo(title: "Copied", message: "Entry copied to clipboard.")
#else
      alertInfo = AlertInfo(title: "Unavailable", message: "Copy not supported on this platform.")
#endif
    case .shareNote:
      let content = entry.text.isEmpty ? "No text available." : entry.text
      presentActivity(items: [content])
    case .sharePDF:
      if let pdfURL = viewModel.generatePDF(for: entry) {
        presentActivity(items: [pdfURL])
      } else {
        alertInfo = AlertInfo(title: "Error", message: "Unable to generate PDF right now.")
      }
    case .shareAudio:
      if let audioURL = viewModel.audioURL(for: entry) {
        presentActivity(items: [audioURL])
      } else {
        alertInfo = AlertInfo(title: "Audio Not Available", message: "No audio associated with this entry.")
      }
    }
  }
  
  private func presentActivity(items: [Any]) {
    activityItems = items
    if !items.isEmpty {
      isActivityPresented = true
    }
  }

  private func handleRecordingCompletion(with url: URL) async {
    await MainActor.run {
      isTranscribing = true
      alertInfo = nil
    }
    do {
      let transcript = try await transcribeAudio(at: url)
      await MainActor.run {
        reviewText = transcript
        reviewMood = .neutral
        reviewTags = []
        pendingAudioURL = url
        isTranscribing = false
        isReviewSheetPresented = true
      }
    } catch {
      await MainActor.run {
        isTranscribing = false
        alertInfo = AlertInfo(
          title: "Transcription Failed",
          message: (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        )
      }
      try? FileManager.default.removeItem(at: url)
    }
  }

  private func handleReviewCancel() {
    if let pendingAudioURL {
      try? FileManager.default.removeItem(at: pendingAudioURL)
    }
    pendingAudioURL = nil
    reviewTags = []
    reviewMood = .neutral
    reviewText = ""
    isReviewSheetPresented = false
  }

  private func handleReviewSave() {
    let audioURL = pendingAudioURL
    Task {
      await viewModel.saveEntry(
        text: reviewText,
        mood: reviewMood,
        tags: reviewTags,
        audioTempURL: audioURL
      )
      await MainActor.run {
        pendingAudioURL = nil
        reviewTags = []
        reviewMood = .neutral
        reviewText = ""
        isReviewSheetPresented = false
        alertInfo = AlertInfo(title: "Saved", message: "Entry saved to your day.")
      }
    }
  }

  private func transcribeAudio(at url: URL) async throws -> String {
    let whisper = OpenAIWhisperService()
    do {
      return try await whisper.transcribeAudio(fileURL: url)
    } catch {
      let speech = SpeechRecognizerService()
      let authorized = await speech.requestAuthorization()
      guard authorized else { throw error }
      return try await speech.transcribe(url: url)
    }
  }
  
  private struct AlertInfo: Identifiable {
    let id = UUID()
    let title: String
    let message: String?
  }
}

private extension EntryView {
  @ViewBuilder
  var entriesTodaySection: some View {
    if viewModel.entriesForDay.isEmpty {
      EmptyEntriesState(
        emoji: "📝",
        title: "No entries yet",
        message: "Start recording to capture today’s memories."
      )
      .padding(.top, 60)
    } else {
      VStack(alignment: .leading, spacing: 16) {
        headerBar
        MoodFilterBar(selection: $selectedMoodFilter)
        entriesContent
      }
      .padding(.top, 8)
    }
  }

  private var headerBar: some View {
    HStack(spacing: 16) {
      Text("Entries Today")
        .font(.headline)
        .foregroundColor(.appHighlight)
      Spacer()
      sortMenu
    }
  }

  private var sortMenu: some View {
    Menu {
      ForEach(SortOption.allCases) { option in
        Button {
          withAnimation(.easeInOut) { sortOption = option }
        } label: {
          sortMenuLabel(for: option)
        }
      }
    } label: {
      Label(sortOption.title, systemImage: "arrow.up.arrow.down")
        .font(.subheadline.weight(.medium))
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(
          Capsule().fill(AppTheme.secondary.opacity(0.4))
        )
    }
    .foregroundColor(.appText)
  }

  private func sortMenuLabel(for option: SortOption) -> some View {
    HStack {
      Image(systemName: option.systemImage)
      Text(option.title)
      Spacer()
      if option == sortOption {
        Image(systemName: "checkmark")
      }
    }
  }

  @ViewBuilder
  private var entriesContent: some View {
    if displayedEntries.isEmpty {
      EmptyEntriesState(
        emoji: "📝",
        title: "No entries for this mood",
        message: "Try another mood or start a new recording."
      )
      .frame(maxWidth: .infinity)
      .transition(.opacity)
    } else {
    LazyVStack(alignment: .leading, spacing: 14) {
      ForEach(displayedEntries, id: \.id) { entry in
        EntryInlineRow(
          entry: entry,
          onEdit: { _ in entryBeingEdited = entry },
          onShare: { _ in shareEntry = entry },
          onDelete: { _ in entryPendingDeletion = entry }
        )
      }
    }
    }
  }
}

// Separate inline row with its own player so play state is isolated per entry
private struct EntryInlineRow: View {
  let entry: DiaryEntry
  @StateObject private var player = AudioPlayer()
  var onEdit: (DiaryEntry) -> Void
  var onShare: (DiaryEntry) -> Void
  var onDelete: (DiaryEntry) -> Void
  
    private static let tagColumns: [GridItem] = [
        GridItem(.adaptive(minimum: 80), spacing: 8)
    ]

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      headerSection
      audioSection
      noteSection
    }
    .padding(18)
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(AppTheme.secondary.opacity(0.35))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    )
  }
  
  private var headerSection: some View {
    HStack(alignment: .top) {
      VStack(alignment: .leading, spacing: 8) {
        HStack(spacing: 8) {
          MoodBadge(mood: entry.mood)
          Text(entry.date, style: .time)
            .font(.caption)
            .foregroundColor(.appText.opacity(0.6))
        }
        
        tagSection
      }
      
      Spacer(minLength: 0)
      
      Menu {
        Button { onEdit(entry) } label: {
          Label("Edit", systemImage: "pencil")
        }
        Button { onShare(entry) } label: {
          Label("Share", systemImage: "square.and.arrow.up")
        }
        Button(role: .destructive) { onDelete(entry) } label: {
          Label("Delete", systemImage: "trash")
        }
      } label: {
        Image(systemName: "ellipsis")
          .font(.headline)
          .foregroundColor(.appText.opacity(0.6))
          .padding(8)
          .background(
            RoundedRectangle(cornerRadius: 12)
              .fill(Color(.systemGray6))
          )
      }
    }
  }
  
  @ViewBuilder
  private var tagSection: some View {
    if !entry.tags.isEmpty {
            LazyVGrid(columns: Self.tagColumns, alignment: .leading, spacing: 8) {
        ForEach(entry.tags, id: \.self) { tag in
          TagChip(tag: tag)
        }
      }
    } else {
      Text("Add #tags to keep this moment organized.")
        .font(.caption)
        .foregroundColor(.appText.opacity(0.4))
    }
  }
  
  @ViewBuilder
  private var audioSection: some View {
    if let file = entry.audioFileName {
      audioPlayerView(for: file)
    }
  }
  
  private func audioPlayerView(for fileName: String) -> some View {
    let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    let url = directory.appendingPathComponent("DiaryEntries").appendingPathComponent(fileName)
    
    return VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 12) {
        Button {
          if player.duration == 0 { try? player.load(url: url) }
          player.isPlaying ? player.pause() : player.play()
        } label: {
          Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
            .font(.headline)
            .foregroundColor(AppTheme.background)
            .padding(12)
            .background(Circle().fill(AppTheme.accent))
        }
        
        VStack(alignment: .leading, spacing: 4) {
          Text("Audio note")
            .font(.subheadline.weight(.semibold))
            .foregroundColor(.appText)
          Text(durationLabel)
            .font(.caption)
            .foregroundColor(.appText.opacity(0.6))
        }
        Spacer()
      }
      
      ProgressView(value: progressValue)
        .progressViewStyle(.linear)
    }
    .padding(12)
    .background(
      RoundedRectangle(cornerRadius: 14)
        .fill(AppTheme.accent.opacity(0.08))
    )
  }
  
  private var noteSection: some View {
    Text(entry.text.isEmpty ? "No text captured yet." : entry.text)
      .font(.body)
      .foregroundColor(.appText)
  }
  
  private var progressValue: Double {
    guard player.duration > 0 else { return 0 }
    return min(1, max(0, player.currentTime / player.duration))
  }
  
  private var durationLabel: String {
    if let stored = entry.audioDurationSeconds, stored > 0 {
      return formattedDuration(stored)
    }
    if player.duration > 0 {
      return formattedDuration(player.duration)
    }
    return "Tap to play"
  }
  
  private func formattedDuration(_ time: TimeInterval) -> String {
    guard time.isFinite else { return "0:00" }
    let minutes = Int(time) / 60
    let seconds = Int(time) % 60
    return String(format: "%d:%02d", minutes, seconds)
  }
}

private struct EditEntrySheet: View {
  let entry: DiaryEntry
  var onSave: (DiaryEntry) -> Void
  var onDelete: () -> Void
  
  @State private var text: String
  @State private var mood: DiaryEntry.Mood
  @State private var tags: [String]
  @State private var tagInput: String = ""
    private static let moodColumns: [GridItem] = [
        GridItem(.adaptive(minimum: 120), spacing: 12)
    ]
    private static let tagColumns: [GridItem] = [
        GridItem(.adaptive(minimum: 100), spacing: 10)
    ]
  
  init(entry: DiaryEntry, onSave: @escaping (DiaryEntry) -> Void, onDelete: @escaping () -> Void) {
    self.entry = entry
    self.onSave = onSave
    self.onDelete = onDelete
    _text = State(initialValue: entry.text)
    _mood = State(initialValue: entry.mood)
    _tags = State(initialValue: entry.tags)
  }
  
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        VStack(alignment: .leading, spacing: 6) {
          Text(entry.date, style: .date)
            .font(.headline)
            .foregroundColor(.appText)
          Text(entry.date, style: .time)
            .font(.caption)
            .foregroundColor(.appText.opacity(0.5))
        }
        
        VStack(alignment: .leading, spacing: 12) {
          Text("Mood")
            .font(.headline)
            .foregroundColor(.appText)
                    LazyVGrid(columns: Self.moodColumns, spacing: 12) {
            ForEach(DiaryEntry.Mood.allCases) { option in
              Button {
                mood = option
              } label: {
                MoodSelectionCard(mood: option, isSelected: option == mood)
              }
              .buttonStyle(.plain)
            }
          }
        }
        
        VStack(alignment: .leading, spacing: 12) {
          Text("Tags")
            .font(.headline)
            .foregroundColor(.appText)
          HStack(spacing: 12) {
            TextField("Add a tag", text: $tagInput)
              .textFieldStyle(.roundedBorder)
              .submitLabel(.done)
              .onSubmit(addTag)
            Button("Add") { addTag() }
              .buttonStyle(.borderedProminent)
              .tint(AppTheme.accent)
          }
          if tags.isEmpty {
            Text("No tags yet. Add #hashtags to group related memories.")
              .font(.caption)
              .foregroundColor(.appText.opacity(0.5))
          } else {
                        LazyVGrid(columns: Self.tagColumns, spacing: 10) {
              ForEach(tags, id: \.self) { tag in
                EditableTagChip(tag: tag) {
                  tags.removeAll { $0 == tag }
                }
              }
            }
          }
        }
        
        VStack(alignment: .leading, spacing: 12) {
          Text("Notes")
            .font(.headline)
            .foregroundColor(.appText)
          TextEditor(text: $text)
            .frame(minHeight: 220)
            .padding(12)
            .background(
              RoundedRectangle(cornerRadius: 14)
                .stroke(Color.appText.opacity(0.1), lineWidth: 1)
            )
          Text("\(text.split{ !$0.isLetter }.count) words")
            .font(.caption)
            .foregroundColor(.appText.opacity(0.5))
        }
        
        VStack(spacing: 12) {
          Button(role: .destructive) {
            onDelete()
          } label: {
            Text("Delete Entry")
              .frame(maxWidth: .infinity)
              .padding()
              .background(
                RoundedRectangle(cornerRadius: 12)
                  .fill(Color.red.opacity(0.12))
              )
          }
          
          Button {
            var updated = entry
            updated.text = text
            updated.mood = mood
            updated.tags = tags
            onSave(updated)
          } label: {
            Text("Save Changes")
              .font(.headline)
              .foregroundColor(.white)
              .frame(maxWidth: .infinity)
              .padding()
              .background(
                RoundedRectangle(cornerRadius: 12)
                  .fill(AppTheme.accent)
              )
          }
        }
      }
      .padding()
    }
    .navigationTitle("Edit Entry")
    .navigationBarTitleDisplayMode(.inline)
  }
  
  private func addTag() {
    let trimmed = tagInput.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }
    let normalized = trimmed.replacingOccurrences(of: "#", with: "").lowercased()
    guard !normalized.isEmpty, !tags.contains(normalized) else {
      tagInput = ""
      return
    }
    tags.append(normalized)
    tagInput = ""
  }
}

private struct ShareOptionsSheet: View {
  enum Option: CaseIterable, Identifiable {
    case copy, shareNote, sharePDF, shareAudio
    
    var id: Self { self }
    
    var title: String {
      switch self {
      case .copy: return "Copy to Clipboard"
      case .shareNote: return "Share Complete Note"
      case .sharePDF: return "Share PDF with Headings"
      case .shareAudio: return "Share Complete Audio"
      }
    }
    
    var systemImage: String {
      switch self {
      case .copy: return "doc.on.doc"
      case .shareNote: return "square.and.arrow.up"
      case .sharePDF: return "doc.richtext"
      case .shareAudio: return "waveform"
      }
    }
  }
  
  let entry: DiaryEntry
  var onOptionSelected: (Option) -> Void
  @Environment(\.dismiss) private var dismiss
  
  var body: some View {
    VStack(spacing: 24) {
      Capsule()
        .fill(Color.gray.opacity(0.3))
        .frame(width: 40, height: 4)
        .padding(.top, 12)
      
      VStack(alignment: .leading, spacing: 16) {
        Text("Share Entry")
          .font(.headline)
          .foregroundColor(.appText)
        ForEach(Option.allCases) { option in
          Button {
            dismiss()
            onOptionSelected(option)
          } label: {
            HStack(spacing: 16) {
              Image(systemName: option.systemImage)
                .font(.title3)
                .foregroundColor(AppTheme.accent)
                .frame(width: 32, height: 32)
              Text(option.title)
                .foregroundColor(.appText)
              Spacer()
              Image(systemName: "chevron.right")
                .font(.footnote)
                .foregroundColor(.appText.opacity(0.3))
            }
            .padding()
            .background(
              RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.secondary.opacity(0.35))
            )
          }
        }
      }
      .padding(.horizontal)
      
      Spacer()
    }
    .background(AppTheme.background)
  }
}

#if canImport(UIKit)
private struct ActivityView: UIViewControllerRepresentable {
  let activityItems: [Any]
  let applicationActivities: [UIActivity]? = nil
  
  func makeUIViewController(context: Context) -> UIActivityViewController {
    UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
  }
  
  func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif

private struct MoodFilterBar: View {
  @Binding var selection: DiaryEntry.Mood?

    private static let chipSpacing: CGFloat = 10
  
  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Self.chipSpacing) {
        FilterChip(
          title: "All",
          emoji: "✨",
          tint: AppTheme.secondary,
          isSelected: selection == nil
        ) {
          withAnimation(.easeInOut) { selection = nil }
        }
        
        ForEach(DiaryEntry.Mood.allCases) { mood in
          FilterChip(
            title: mood.displayName,
            emoji: mood.emoji,
            tint: mood.tintColor,
            isSelected: selection == mood
          ) {
            withAnimation(.easeInOut) {
              selection = selection == mood ? nil : mood
            }
          }
        }
      }
      .padding(.vertical, 4)
    }
  }
}

private struct FilterChip: View {
  let title: String
  let emoji: String
  let tint: Color
  let isSelected: Bool
  let action: () -> Void
  
  var body: some View {
    Button(action: action) {
      HStack(spacing: 6) {
        Text(emoji)
        Text(title)
          .font(.subheadline.weight(.medium))
      }
      .foregroundColor(isSelected ? .white : tint)
      .padding(.vertical, 8)
      .padding(.horizontal, 14)
      .background(
        Capsule()
          .fill(isSelected ? tint : tint.opacity(0.12))
      )
    }
    .buttonStyle(.plain)
  }
}

private struct MoodBadge: View {
  let mood: DiaryEntry.Mood
  
  var body: some View {
    HStack(spacing: 6) {
      Text(mood.emoji)
      Text(mood.displayName)
        .font(.caption.weight(.semibold))
        .foregroundColor(mood.tintColor)
    }
    .padding(.vertical, 6)
    .padding(.horizontal, 12)
    .background(
      Capsule()
        .fill(mood.tintColor.opacity(0.12))
    )
  }
}

private struct TagChip: View {
  let tag: String
  
  var body: some View {
    Text("#\(tag)")
      .font(.caption.weight(.medium))
      .foregroundColor(AppTheme.accent)
      .padding(.vertical, 6)
      .padding(.horizontal, 12)
      .background(
        Capsule()
          .fill(AppTheme.accent.opacity(0.12))
      )
  }
}

private struct EditableTagChip: View {
  let tag: String
  var onRemove: () -> Void
  
  var body: some View {
    HStack(spacing: 6) {
      Text("#\(tag)")
        .font(.caption.weight(.medium))
        .foregroundColor(AppTheme.accent)
      Button(action: onRemove) {
        Image(systemName: "xmark.circle.fill")
          .font(.caption)
          .foregroundColor(.appText.opacity(0.6))
      }
      .buttonStyle(.plain)
    }
    .padding(.vertical, 6)
    .padding(.horizontal, 10)
    .background(
      Capsule()
        .fill(AppTheme.accent.opacity(0.12))
    )
  }
}

private struct MoodSelectionCard: View {
  let mood: DiaryEntry.Mood
  let isSelected: Bool
  
  var body: some View {
    VStack(spacing: 8) {
      Text(mood.emoji)
        .font(.largeTitle)
      Text(mood.displayName)
        .font(.subheadline.weight(.medium))
        .foregroundColor(.appText)
    }
    .frame(maxWidth: .infinity)
    .padding()
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(isSelected ? mood.tintColor.opacity(0.18) : AppTheme.secondary.opacity(0.3))
    )
    .overlay(
      RoundedRectangle(cornerRadius: 16)
        .stroke(isSelected ? mood.tintColor : Color.clear, lineWidth: 2)
    )
  }
}

private struct EmptyEntriesState: View {
  let emoji: String
  let title: String
  let message: String

  var body: some View {
    VStack(spacing: 16) {
      Text(emoji)
        .font(.system(size: 48))
      Text(title)
        .font(.headline)
        .foregroundColor(.appText)
      Text(message)
        .font(.subheadline)
        .foregroundColor(.appText.opacity(0.6))
        .multilineTextAlignment(.center)
        .padding(.horizontal, 24)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 40)
    .background(
      RoundedRectangle(cornerRadius: 20)
        .fill(AppTheme.secondary.opacity(0.35))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    )
    .padding(.horizontal, 12)
  }
}

