import Foundation

enum AccountTypeEnum: String, Codable {
  case saver = "SAVER"
  case transactional = "TRANSACTIONAL"
}

// MARK: - CustomStringConvertible

extension AccountTypeEnum: CustomStringConvertible {
  var description: String {
    switch self {
    case .saver:
      return "Saver"
    case .transactional:
      return "Transactional"
    }
  }
}

// MARK: -

extension AccountTypeEnum {
  var accountTypeOptionEnum: AccountTypeOptionEnum {
    switch self {
    case .saver:
      return .saver
    case .transactional:
      return .transactional
    }
  }
}
