import Foundation

struct ErrorResponse: Codable {
  /// The list of errors returned in this response.
  var errors: [ErrorObject]
}

// MARK: - CustomStringConvertible

extension ErrorResponse: CustomStringConvertible {
  var description: String {
    return errors.description
  }
}
