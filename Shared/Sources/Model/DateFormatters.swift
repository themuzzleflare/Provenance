import Foundation
import SwiftDate

func formatDate(for dateString: String, dateStyle: AppDateStyle) -> String {
  switch dateStyle {
  case .absolute:
    guard let date = dateString.toDate() else { return dateString }
    return date.toString(.dateTime(.medium))
  case .relative:
    guard let date = dateString.toDate() else { return dateString }
    return date.toString(.relative(style: nil))
  }
}
