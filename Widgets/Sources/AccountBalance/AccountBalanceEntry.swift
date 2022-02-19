import Foundation
import WidgetKit
import Alamofire

struct AccountBalanceEntry: TimelineEntry {
  let date: Date
  let account: AccountBalanceModel?
  let error: AFError?
}

// MARK: -

extension AccountBalanceEntry {
  static var placeholder: AccountBalanceEntry {
    return AccountBalanceEntry(date: Date(), account: .placeholder, error: nil)
  }

  static var empty: AccountBalanceEntry {
    return AccountBalanceEntry(date: Date(), account: nil, error: nil)
  }
}
