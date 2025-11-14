import SwiftUI

extension DiaryEntry.Mood {
  var emoji: Image {
    switch self {
    case .cool: return Image("cool")
    case .love: return Image("love")
    case .sad: return Image("sad")
    case .angry: return Image("angry")
    case .happy: return Image("happy")
    }
  }

  var tintColor: Color {
    switch self {
    case .cool: return Color(red: 0.99, green: 0.56, blue: 0.2)
    case .love: return Color(red: 0.87, green: 0.28, blue: 0.33)
    case .sad: return Color(red: 0.38, green: 0.53, blue: 0.99)
    case .angry: return Color(red: 0.55, green: 0.56, blue: 0.6)
    case .happy: return Color(red: 0.33, green: 0.62, blue: 0.45)
    }
  }
}




