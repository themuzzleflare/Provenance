import Foundation

enum AppDateStyle: Int, CaseIterable {
  case absolute
  case relative
}

// MARK: -

extension AppDateStyle {
  var description: String {
    switch self {
    case .absolute:
      return "Absolute"
    case .relative:
      return "Relative"
    }
  }

  var dateStyle: DateStyleEnum {
    switch self {
    case .absolute:
      return .absolute
    case .relative:
      return .relative
    }
  }
}
