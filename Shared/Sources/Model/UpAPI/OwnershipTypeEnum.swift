import Foundation

enum OwnershipTypeEnum: String, Codable {
  case individual = "INDIVIDUAL"
  case joint = "JOINT"
}

// MARK: - CustomStringConvertible

extension OwnershipTypeEnum: CustomStringConvertible {
  var description: String {
    switch self {
    case .individual:
      return "Individual"
    case .joint:
      return "Joint"
    }
  }
}
