import Foundation

enum AppWidgets: Int, CaseIterable {
  case accountBalance = 0
  case latestTransaction = 1
}

extension AppWidgets {
  var kind: String {
    switch self {
    case .accountBalance:
      return "accountBalanceWidget"
    case .latestTransaction:
      return "latestTransactionWidget"
    }
  }
}
