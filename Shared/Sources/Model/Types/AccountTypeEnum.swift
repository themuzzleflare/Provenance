import Foundation

enum AccountTypeEnum: String, Codable, CaseIterable {
  case transactional = "TRANSACTIONAL"
  case saver = "SAVER"
}

extension AccountTypeEnum {
  var description: String {
    switch self {
    case .transactional:
      return "Transactional"
    case .saver:
      return "Saver"
    }
  }
}
