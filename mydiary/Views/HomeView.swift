import SwiftUI

struct HomeView: View {
  @ObservedObject var themeManager: ThemeManager
  @ObservedObject var subscriptionService: SubscriptionService
  let store: DiaryStore
  @State private var selectedTab: TabItem = .diary
  @State private var showRecordingSheet = false
  @State private var recordingCompleteURL: URL?

  enum TabItem: Int {
    case diary = 0
    case calendar = 1
    case stats = 2
    case more = 3
  }

  init(store: DiaryStore, themeManager: ThemeManager, subscriptionService: SubscriptionService) {
    self.store = store
    _themeManager = ObservedObject(wrappedValue: themeManager)
    _subscriptionService = ObservedObject(wrappedValue: subscriptionService)
  }

  var body: some View {
    ZStack(alignment: .bottom) {
      // Tab content
      Group {
        switch selectedTab {
        case .diary:
          DiaryTabView(
            store: store,
            themeManager: themeManager,
            subscriptionService: subscriptionService,
            onRecordButtonTap: { showRecordingSheet = true },
            recordingURL: recordingCompleteURL
          )
          .onChange(of: recordingCompleteURL) { _ in
            recordingCompleteURL = nil
          }
        case .calendar:
          CalendarTabView(store: store)
        case .stats:
          StatsTabView(store: store)
        case .more:
          MoreTabView(
            themeManager: themeManager,
            subscriptionService: subscriptionService
          )
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      
      // Custom Tab Bar
      customTabBar
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .sheet(isPresented: $showRecordingSheet, content: recordingSheet)
  }

  // MARK: - Custom Tab Bar
  
  private var customTabBar: some View {
    VStack(spacing: 0) {
      // Offer Banner (if not subscribed)
      if !subscriptionService.isSubscribed {
        offerBannerView
      }
      
      // Tab Bar
      HStack(spacing: 0) {
        // Diary tab
        tabButton(icon: "square.fill", label: "Diary", tab: .diary)
        
        Spacer()
        
        // Calendar tab
        tabButton(icon: "calendar", label: "Calendar", tab: .calendar)
        
        Spacer()
        
        // Central add button
        Button(action: { showRecordingSheet = true }) {
          Circle()
            .fill(Color.appAccent)
            .frame(width: 56, height: 56)
            .overlay(
              Image(systemName: "plus")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            )
            .shadow(color: Color.appAccent.opacity(0.5), radius: 8, x: 0, y: 4)
        }
        .offset(y: -8)
        
        Spacer()
        
        // Stats tab
        tabButton(icon: "chart.pie.fill", label: "Stats", tab: .stats)
        
        Spacer()
        
        // More tab
        tabButton(icon: "person.fill", label: "More", tab: .more)
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 12)
      .background(
        Color.appBackground
          .ignoresSafeArea(edges: .bottom)
      )
    }
  }
  
  private func tabButton(icon: String, label: String, tab: TabItem) -> some View {
    Button(action: {
      withAnimation {
        selectedTab = tab
      }
    }) {
      VStack(spacing: 4) {
        Image(systemName: icon)
          .font(.system(size: 20))
          .foregroundColor(selectedTab == tab ? .appAccent : .appText.opacity(0.6))
        Text(label)
          .font(.caption2)
          .foregroundColor(selectedTab == tab ? .appAccent : .appText.opacity(0.6))
      }
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
      
      Text("1d 23h 34m 46s")
        .font(.caption.bold())
        .foregroundColor(.black)
        .monospacedDigit()
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .background(Color.yellow)
  }

  // MARK: - Sheet Builders

  private func recordingSheet() -> some View {
    RecordingSessionSheet(
      recorder: AudioRecorder(),
      onCancel: {
        showRecordingSheet = false
      },
      onComplete: { url in
        showRecordingSheet = false
        recordingCompleteURL = url
      }
    )
    .presentationDetents([.fraction(0.5), .large])
    .presentationDragIndicator(.hidden)
  }
}

// MARK: - TabItem Extension

extension HomeView.TabItem: Hashable {}
