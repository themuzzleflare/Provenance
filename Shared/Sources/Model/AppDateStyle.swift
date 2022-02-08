import Foundation

enum AppDateStyle: Int, CaseIterable {
  case absolute
  case relative
}

// MARK: - CustomStringConvertible

extension AppDateStyle: CustomStringConvertible {
  var description: String {
    switch self {
    case .absolute:
      return "Absolute"
    case .relative:
      return "Relative"
    }
  }
}

// MARK: -

extension AppDateStyle {
  var dateStyle: DateStyleEnum {
    switch self {
    case .absolute:
      return .absolute
    case .relative:
      return .relative
    }
  }
}
