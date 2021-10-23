import Foundation

enum CategoryTypeEnum: Int, CaseIterable {
  case parent
  case child
}

extension CategoryTypeEnum {
  var description: String {
    switch self {
    case .parent:
      return "Parent"
    case .child:
      return "Child"
    }
  }
}

extension Array where Element == CategoryTypeEnum {
  var names: [String] {
    return self.map { (type) in
      return type.description
    }
  }
}
