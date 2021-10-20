import SwiftUI

extension TransactionColourEnum {
  var uiColour: UIColor {
    switch self {
    case .primaryLabel, .unknown:
      return .label
    case .green:
      return .greenColour
    }
  }

  var colour: Color {
    switch self {
    case .primaryLabel, .unknown:
      return .primary
    case .green:
      return .greenColour
    }
  }
}
