import Foundation
import SwiftDate

typealias Utils = ProvenanceUtils

enum ProvenanceUtils {
  static func formatDate(for dateString: String, dateStyle: AppDateStyle = Store.provenance.appDateStyle) -> String {
    guard let date = dateString.toDate(region: .current) else { return dateString }
    switch dateStyle {
    case .absolute:
      return date.toString(.dateTime(.short))
    case .relative:
      return date.toRelative()
    }
  }

  static func formatDateHeaderText(for date: Date, dateStyle: AppDateStyle = Store.provenance.appDateStyle) -> String {
    switch dateStyle {
    case .absolute:
      return date.toString(.date(.medium))
    case .relative:
      let currentDate = DateInRegion()
      let newDate = date.dateBySet(hour: currentDate.hour, min: currentDate.minute, secs: currentDate.second)
      if let relativeDate = newDate?.toRelative() {
        return "\(relativeDate) (\(date.toString(.date(.short))))"
      } else {
        return date.toString(.date(.medium))
      }
    }
  }
}
