import SwiftUI

struct RecordingReviewSheet: View {
  @Binding var text: String
  @Binding var mood: DiaryEntry.Mood
  @Binding var tags: [String]
  var onCancel: () -> Void
  var onSave: () -> Void

  @State private var tagInput: String = ""
  @FocusState private var isTextFocused: Bool

  private let moodColumns: [GridItem] = [
    GridItem(.adaptive(minimum: 120), spacing: 12)
  ]

  private let tagColumns: [GridItem] = [
    GridItem(.adaptive(minimum: 90), spacing: 8)
  ]

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        header
        transcriptionSection
        moodSection
        tagsSection
        footerButtons
      }
      .padding()
    }
    .background(AppTheme.background.ignoresSafeArea())
    .navigationTitle("Review Recording")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .cancellationAction) {
        Button("Discard", action: onCancel)
          .foregroundColor(.red)
      }
      ToolbarItem(placement: .confirmationAction) {
        Button("Save", action: onSave)
          .fontWeight(.semibold)
      }
    }
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Review your transcription")
        .font(.title2.weight(.semibold))
        .foregroundColor(.appHighlight)
      Text("Polish the text, add how you felt, and tag this moment before saving.")
        .font(.subheadline)
        .foregroundColor(.appText.opacity(0.7))
    }
  }

  private var transcriptionSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Transcribed Text")
        .font(.headline)
        .foregroundColor(.appText)
      TextEditor(text: $text)
        .focused($isTextFocused)
        .frame(minHeight: 200)
        .padding(12)
        .background(
          RoundedRectangle(cornerRadius: 14)
            .stroke(AppTheme.accent.opacity(0.15), lineWidth: 1)
            .background(
              RoundedRectangle(cornerRadius: 14)
                .fill(Color.white)
            )
        )
      Text("\(text.split { !$0.isLetter }.count) words")
        .font(.caption)
        .foregroundColor(.appText.opacity(0.5))
    }
  }

  private var moodSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Mood")
        .font(.headline)
        .foregroundColor(.appText)
      LazyVGrid(columns: moodColumns, spacing: 12) {
        ForEach(Array(DiaryEntry.Mood.allCases)) { option in
          Button {
            mood = option
          } label: {
            VStack(spacing: 8) {
              Text(option.emoji)
                .font(.largeTitle)
              Text(option.displayName)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.appText)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
              RoundedRectangle(cornerRadius: 16)
                .fill(option == mood ? option.tintColor.opacity(0.2) : AppTheme.secondary.opacity(0.35))
            )
            .overlay(
              RoundedRectangle(cornerRadius: 16)
                .stroke(option == mood ? option.tintColor : Color.clear, lineWidth: 2)
            )
          }
          .buttonStyle(.plain)
        }
      }
    }
  }

  private var tagsSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Tags")
        .font(.headline)
        .foregroundColor(.appText)

      HStack(spacing: 12) {
        TextField("Add a tag", text: $tagInput)
          .textFieldStyle(.roundedBorder)
          .submitLabel(.done)
          .onSubmit(addTag)
        Button(action: addTag) {
          Image(systemName: "plus.circle.fill")
            .font(.title2)
            .foregroundColor(AppTheme.accent)
        }
        .buttonStyle(.plain)
      }

      if tags.isEmpty {
        Text("No tags yet. Use tags to group similar memories.")
          .font(.caption)
          .foregroundColor(.appText.opacity(0.5))
      } else {
        LazyVGrid(columns: tagColumns, alignment: .leading, spacing: 8) {
          ForEach(tags, id: \.self) { tag in
            HStack(spacing: 6) {
              Text("#\(tag)")
                .font(.caption.weight(.medium))
                .foregroundColor(AppTheme.accent)
              Button {
                removeTag(tag)
              } label: {
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
                .fill(AppTheme.accent.opacity(0.15))
            )
          }
        }
      }
    }
  }

  private var footerButtons: some View {
    VStack(spacing: 12) {
      Button(action: onSave) {
        Text("Save Entry")
          .font(.headline)
          .foregroundColor(AppTheme.background)
          .frame(maxWidth: .infinity)
          .padding()
          .background(
            RoundedRectangle(cornerRadius: 16)
              .fill(AppTheme.accent)
          )
      }
      .buttonStyle(.plain)

      Button(action: onCancel) {
        Text("Discard Recording")
          .font(.subheadline)
          .foregroundColor(.red)
          .frame(maxWidth: .infinity)
          .padding(12)
          .background(
            RoundedRectangle(cornerRadius: 12)
              .fill(Color.red.opacity(0.08))
          )
      }
      .buttonStyle(.plain)
    }
  }

  private func addTag() {
    let normalized = tagInput
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .replacingOccurrences(of: "#", with: "")
      .lowercased()
    guard !normalized.isEmpty, !tags.contains(normalized) else {
      tagInput = ""
      return
    }
    tags.append(normalized)
    tagInput = ""
  }

  private func removeTag(_ tag: String) {
    tags.removeAll { $0 == tag }
  }
}

