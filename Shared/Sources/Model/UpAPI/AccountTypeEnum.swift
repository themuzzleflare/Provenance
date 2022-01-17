import Foundation

enum AccountTypeEnum: String, Codable {
  case saver = "SAVER"
  case transactional = "TRANSACTIONAL"
}

// MARK: -

extension AccountTypeEnum {
  var description: String {
    switch self {
    case .saver:
      return "Saver"
    case .transactional:
      return "Transactional"
    }
  }

  var accountTypeOptionEnum: AccountTypeOptionEnum {
    switch self {
    case .saver:
      return .saver
    case .transactional:
      return .transactional
    }
  }
}
