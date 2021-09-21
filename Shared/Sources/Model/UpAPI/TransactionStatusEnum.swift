import Foundation

enum TransactionStatusEnum: String, Codable {
  case held = "HELD"
  case settled = "SETTLED"
}

extension TransactionStatusEnum {
  var status: Status {
    switch self {
    case .held:
      return .held
    case .settled:
      return .settled
    }
  }
}
