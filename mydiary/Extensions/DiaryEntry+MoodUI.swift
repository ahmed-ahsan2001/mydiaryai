import SwiftUI

extension DiaryEntry.Mood {
  var emoji: String {
    switch self {
    case .excited: return "🤩"
    case .stressed: return "😣"
    case .sad: return "😞"
    case .neutral: return "🙂"
    case .peaceful: return "😌"
    }
  }

  var tintColor: Color {
    switch self {
    case .excited: return Color(red: 0.99, green: 0.56, blue: 0.2)
    case .stressed: return Color(red: 0.87, green: 0.28, blue: 0.33)
    case .sad: return Color(red: 0.38, green: 0.53, blue: 0.99)
    case .neutral: return Color(red: 0.55, green: 0.56, blue: 0.6)
    case .peaceful: return Color(red: 0.33, green: 0.62, blue: 0.45)
    }
  }
}

