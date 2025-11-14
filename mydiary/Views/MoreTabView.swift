import SwiftUI

struct MoreTabView: View {
  @ObservedObject var themeManager: ThemeManager
  @ObservedObject var subscriptionService: SubscriptionService
  
  var body: some View {
    ZStack {
      Color(hex: 0x1E3A5F)
        .ignoresSafeArea()
      
      ProfileView(themeManager: themeManager, subscriptionService: subscriptionService)
        .background(Color(hex: 0x1E3A5F))
    }
  }
}

