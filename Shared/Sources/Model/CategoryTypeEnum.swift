import Foundation

enum CategoryTypeEnum: Int, CaseIterable {
  case parent
  case child
}

// MARK: - CustomStringConvertible

extension CategoryTypeEnum: CustomStringConvertible {
  var description: String {
    switch self {
    case .parent:
      return "Parent"
    case .child:
      return "Child"
    }
  }
}

// MARK: -

extension Array where Element == CategoryTypeEnum {
  var names: [String] {
    return self.map { (type) in
      return type.description
    }
  }
}
