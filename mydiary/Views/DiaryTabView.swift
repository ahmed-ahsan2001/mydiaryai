import SwiftUI

struct DiaryTabView: View {
  @ObservedObject var themeManager: ThemeManager
  @ObservedObject var subscriptionService: SubscriptionService
  @StateObject private var viewModel: HomeViewModel
  @StateObject private var player = AudioPlayer()
  @State private var lastRecordingURL: URL?
  @State private var showThemeSelection = false
  @State private var showSearch = false
  @State private var showPaywall = false
  @State private var searchText = ""
  @State private var isReviewSheetPresented = false
  @State private var reviewText: String = ""
  @State private var reviewMood: DiaryEntry.Mood = .happy
  @State private var reviewTags: [String] = []
  @State private var countdownTime: TimeInterval = 0
  
  let onRecordButtonTap: () -> Void
  let recordingURL: URL?
  
  init(store: DiaryStore, themeManager: ThemeManager, subscriptionService: SubscriptionService, onRecordButtonTap: @escaping () -> Void, recordingURL: URL? = nil) {
    _viewModel = StateObject(wrappedValue: HomeViewModel(store: store))
    _themeManager = ObservedObject(wrappedValue: themeManager)
    _subscriptionService = ObservedObject(wrappedValue: subscriptionService)
    self.onRecordButtonTap = onRecordButtonTap
    self.recordingURL = recordingURL
  }

  var body: some View {
    ZStack {
      // Main background
      Color.appBackground
        .ignoresSafeArea()
      
      VStack(spacing: 0) {
        // Custom Header
        headerView
          .padding(.horizontal, 20)
          .padding(.top, 8)
          .padding(.bottom, 16)
          .frame(maxWidth: .infinity)
        
        ScrollView(.vertical, showsIndicators: false) {
          VStack(spacing: 20) {
            // Scenic Card
            scenicCardView
              .padding(.horizontal, 16)
            
            // Date and Entry Section
            dateAndEntrySection
              .padding(.horizontal, 16)
            
            Spacer(minLength: 100)
          }
          .padding(.top, 8)
          .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
        
        Spacer()
        
        // Offer Banner
        if !subscriptionService.isSubscribed {
          offerBannerView
            .frame(maxWidth: .infinity)
        }
      }
      .frame(maxWidth: .infinity)
    }
    .id(themeManager.currentTheme.rawValue)
    .task { 
      await viewModel.refresh()
      startCountdown()
    }
    .onChange(of: viewModel.transcribedText, perform: handleTranscriptChange)
    .onChange(of: recordingURL) { newURL in
      if let url = newURL {
        lastRecordingURL = url
        Task {
          try? player.load(url: url)
          await viewModel.transcribe(from: url)
        }
      }
    }
    .sheet(isPresented: $showThemeSelection, content: themeSelectionSheet)
    .sheet(isPresented: $showPaywall, content: paywallSheet)
    .sheet(isPresented: $showSearch, content: searchSheet)
    .sheet(isPresented: $isReviewSheetPresented, content: reviewSheet)
  }

  // MARK: - Header View
  
  private var headerView: some View {
    HStack {
      Text("My Diary")
        .font(.title2.bold())
        .foregroundColor(.appText)
      
      Spacer()
      
      HStack(spacing: 16) {
        // Premium icon
        Button(action: { showPaywall = true }) {
          Image(systemName: "diamond.fill")
            .font(.title3)
            .foregroundColor(.yellow)
        }
        
        // Search icon
        Button(action: { showSearch = true }) {
          Image(systemName: "magnifyingglass")
            .font(.title3)
            .foregroundColor(.appText)
        }
      }
    }
  }

  // MARK: - Scenic Card View
  
  private var scenicCardView: some View {
    GeometryReader { geometry in
      ZStack {
        // Scenic background image - theme-specific
        Image(themeManager.currentTheme.scenicImageName)
          .resizable()
          .scaledToFill()
          .frame(width: geometry.size.width, height: 280)
          .clipped()
          .cornerRadius(24)
        
        // Floating buttons on scenic card
        VStack {
          HStack {
            Spacer()
            // Theme button (top right)
            Button(action: { showThemeSelection = true }) {
              Circle()
                .fill(Color.yellow)
                .frame(width: 44, height: 44)
                .overlay(
                  Image(systemName: "paintpalette.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 18))
                )
            }
            .padding(.trailing, 16)
            .padding(.top, 16)
          }
          
          Spacer()
          
          HStack {
            Spacer()
            // Share/Envelope button (bottom right)
            Button(action: { /* Share action */ }) {
              Circle()
                .fill(Color.yellow)
                .frame(width: 44, height: 44)
                .overlay(
                  Image(systemName: "envelope.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 18))
                )
            }
            .padding(.trailing, 16)
            .padding(.bottom, 16)
          }
        }
      }
    }
    .frame(height: 280)
  }

  // MARK: - Date and Entry Section
  
  private var dateAndEntrySection: some View {
    VStack(alignment: .leading, spacing: 16) {
      // Date display
      HStack {
        Text(formattedDate)
          .font(.headline)
          .foregroundColor(.appText)
        Text(formattedDay)
          .font(.subheadline)
          .foregroundColor(.appText.opacity(0.7))
        Spacer()
      }
      
      // Entry card
      VStack(spacing: 16) {
        Text("Let's add the first entry!")
          .font(.headline)
          .foregroundColor(.appText)
        
        Button(action: { onRecordButtonTap() }) {
          Circle()
            .fill(Color.appHighlight)
            .frame(width: 80, height: 80)
            .overlay(
              Image(systemName: "plus")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
            )
        }
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 24)
      .background(
        RoundedRectangle(cornerRadius: 16)
          .fill(Color.appSecondary.opacity(0.5))
      )
    }
  }

  // MARK: - Offer Banner
  
  private var offerBannerView: some View {
    HStack(spacing: 12) {
      HStack(spacing: 8) {
        Image(systemName: "book.fill")
          .foregroundColor(.pink)
        Image(systemName: "pencil")
          .foregroundColor(.pink)
      }
      
      VStack(alignment: .leading, spacing: 2) {
        Text("Limited Time Offer")
          .font(.caption.bold())
          .foregroundColor(.black)
        Text("PAY ONCE, KEEP FOREVER.")
          .font(.caption2)
          .foregroundColor(.black.opacity(0.7))
      }
      
      Spacer()
      
      Text(countdownString)
        .font(.caption.bold())
        .foregroundColor(.black)
        .monospacedDigit()
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .background(Color.yellow)
    .onTapGesture {
      showPaywall = true
    }
  }

  // MARK: - Helper Properties
  
  private var formattedDate: String {
    let formatter = DateFormatter()
    formatter.dateFormat = "d MMM yyyy"
    return formatter.string(from: Date())
  }
  
  private var formattedDay: String {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEEE"
    return formatter.string(from: Date())
  }
  
  private var countdownString: String {
    let totalSeconds = Int(countdownTime)
    let days = totalSeconds / 86400
    let hours = (totalSeconds % 86400) / 3600
    let minutes = (totalSeconds % 3600) / 60
    let seconds = totalSeconds % 60
    return String(format: "%dd %02dh %02dm %02ds", days, hours, minutes, seconds)
  }

  // MARK: - Helper Methods
  
  private func startCountdown() {
    // Set countdown to 1 day 
    countdownTime = 1
    
    Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
      if countdownTime > 0 {
        countdownTime -= 1
      } else {
        timer.invalidate()
      }
    }
  }
  

  private func handleTranscriptChange(_ newValue: String) {
    guard !newValue.isEmpty else { return }
    reviewText = newValue
    reviewMood = .happy
    reviewTags = []
    isReviewSheetPresented = true
  }

  // MARK: - Sheet Builders
  
  private func themeSelectionSheet() -> some View {
    NavigationStack {
      ThemeSelectionView(themeManager: themeManager, subscriptionService: subscriptionService)
    }
    .presentationDetents([.large])
  }
  
  private func paywallSheet() -> some View {
    NavigationStack {
      PaywallView(subscriptionService: subscriptionService)
    }
    .presentationDetents([.large])
  }
  
  private func searchSheet() -> some View {
    NavigationStack {
      VStack {
        TextField("Search entries...", text: $searchText)
          .textFieldStyle(.roundedBorder)
          .padding()
        Spacer()
        Text("Search functionality coming soon")
          .foregroundColor(.appText.opacity(0.5))
        Spacer()
      }
      .navigationTitle("Search")
      .navigationBarTitleDisplayMode(.inline)
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


