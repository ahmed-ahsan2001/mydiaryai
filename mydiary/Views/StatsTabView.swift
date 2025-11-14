import SwiftUI

struct StatsTabView: View {
  @StateObject private var viewModel: HomeViewModel
  
  init(store: DiaryStore) {
    _viewModel = StateObject(wrappedValue: HomeViewModel(store: store))
  }
  
  var body: some View {
    ZStack {
      Color.appBackground
        .ignoresSafeArea()
      
      ScrollView {
        VStack(spacing: 24) {
          // Header
          HStack {
            Text("Statistics")
              .font(.title2.bold())
              .foregroundColor(.appText)
            Spacer()
          }
          .padding(.horizontal, 20)
          .padding(.top, 20)
          
          // Stats Cards
          VStack(spacing: 16) {
            statCard(
              title: "Total Entries",
              value: "\(viewModel.recentEntries.count)",
              icon: "book.fill",
              color: .appAccent
            )
            
            statCard(
              title: "This Week",
              value: "\(viewModel.weeklyCount)",
              icon: "flame.fill",
              color: .appAccent
            )
            
            statCard(
              title: "Total Words",
              value: "\(viewModel.totalWordCount)",
              icon: "textformat.alt",
              color: .appAccent
            )
            
            statCard(
              title: "Audio Duration",
              value: durationString(viewModel.totalAudioDuration),
              icon: "timer",
              color: .appAccent
            )
          }
          .padding(.horizontal, 20)
          
          Spacer()
        }
      }
    }
    .task {
      await viewModel.refresh()
    }
  }
  
  private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
    HStack(spacing: 16) {
      Image(systemName: icon)
        .font(.title2)
        .foregroundColor(color)
        .frame(width: 50, height: 50)
        .background(
          Circle()
            .fill(color.opacity(0.2))
        )
      
      VStack(alignment: .leading, spacing: 4) {
        Text(value)
          .font(.title.bold())
          .foregroundColor(.appText)
        Text(title)
          .font(.subheadline)
          .foregroundColor(.appText.opacity(0.7))
      }
      
      Spacer()
    }
    .padding()
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(Color.appSecondary.opacity(0.5))
    )
  }
  
  private func durationString(_ t: TimeInterval) -> String {
    guard t.isFinite && t > 0 else { return "0s" }
    let m = Int(t) / 60
    let s = Int(t) % 60
    if m > 0 { return "\(m)m \(s)s" } else { return "\(s)s" }
  }
}

