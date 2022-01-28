import Foundation
import WidgetKit
import Alamofire

struct LatestTransactionEntry: TimelineEntry {
  let date: Date
  let transaction: LatestTransactionModel?
  let error: AFError?
}

// MARK: -

extension LatestTransactionEntry {
  static var placeholder: LatestTransactionEntry {
    return LatestTransactionEntry(date: Date(), transaction: .placeholder, error: nil)
  }
}

// MARK: -

extension Array where Element == LatestTransactionEntry {
  static func singleEntry(with entry: LatestTransactionEntry) -> [LatestTransactionEntry] {
    return [entry]
  }
}
