import Foundation

enum AccountTypeOptionEnum: Int, CaseIterable {
  case transactional
  case saver
}

// MARK: - CustomStringConvertible

extension AccountTypeOptionEnum: CustomStringConvertible {
  var description: String {
    switch self {
    case .transactional:
      return "Transactional"
    case .saver:
      return "Saver"
    }
  }
}

// MARK: -

extension AccountTypeOptionEnum {
  var accountTypeEnum: AccountTypeEnum {
    switch self {
    case .transactional:
      return .transactional
    case .saver:
      return .saver
    }
  }
}

// MARK: -

extension Array where Element == AccountTypeOptionEnum {
  var names: [String] {
    return self.map { (type) in
      return type.description
    }
  }
}
