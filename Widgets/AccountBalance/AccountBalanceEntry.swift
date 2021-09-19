import WidgetKit

struct AccountBalanceEntry: TimelineEntry {
  let date: Date
  let account: AccountBalanceModel?
  let error: NetworkError?
}

extension AccountBalanceEntry {
  static var placeholder: AccountBalanceEntry {
    return AccountBalanceEntry(date: Date(), account: .placeholder, error: nil)
  }
}
