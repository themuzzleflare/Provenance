import Foundation
import UIKit
import SwiftUI

enum TransactionStatusEnum: String, Codable {
  case held = "HELD"
  case settled = "SETTLED"
}

// MARK: - CustomStringConvertible

extension TransactionStatusEnum: CustomStringConvertible {
  var description: String {
    switch self {
    case .held:
      return "Held"
    case .settled:
      return "Settled"
    }
  }
}

// MARK: -

extension TransactionStatusEnum {
  var isSettled: Bool {
    switch self {
    case .held:
      return false
    case .settled:
      return true
    }
  }

  var uiImage: UIImage {
    switch self {
    case .held:
      return .clock
    case .settled:
      return .checkmarkCircle
    }
  }

  var image: Image {
    switch self {
    case .held:
      return .clock
    case .settled:
      return .checkmarkCircle
    }
  }

  var uiColour: UIColor {
    switch self {
    case .held:
      return .systemYellow
    case .settled:
      return .systemGreen
    }
  }

  var colour: Color {
    switch self {
    case .held:
      return .yellow
    case .settled:
      return .green
    }
  }

  var status: StatusEnum {
    switch self {
    case .held:
      return .held
    case .settled:
      return .settled
    }
  }
}
