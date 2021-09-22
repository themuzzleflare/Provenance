import Foundation
import SwiftDate

func formatDate(for dateString: String, dateStyle: AppDateStyle) -> String {
  guard let date = dateString.toDate() else { return dateString }
  switch dateStyle {
  case .absolute:
    return date.toString(.dateTime(.short))
  case .relative:
    return date.toRelative()
  }
}
