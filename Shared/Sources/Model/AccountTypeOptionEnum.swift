import Foundation

enum AccountTypeOptionEnum: Int, CaseIterable {
  case transactional
  case saver
}

extension AccountTypeOptionEnum {
  var description: String {
    switch self {
    case .transactional:
      return "Transactional"
    case .saver:
      return "Saver"
    }
  }

  var accountTypeEnum: AccountTypeEnum {
    switch self {
    case .transactional:
      return .transactional
    case .saver:
      return .saver
    }
  }
}

extension Array where Element == AccountTypeOptionEnum {
  var names: [String] {
    return self.map { (type) in
      return type.description
    }
  }
}
