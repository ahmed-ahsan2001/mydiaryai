import SwiftUI

struct CalendarTabView: View {
  let store: DiaryStore
  
  var body: some View {
    NavigationStack {
      CalendarView(store: store)
    }
  }
}


