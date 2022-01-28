import Foundation

struct ModifyCategories: Codable {
  /// The category to set on the transaction.
  /// Set this entire key to `null` de-categorize a transaction.
  var data: CategoryInputResourceIdentifier?

  init(category: CategoryResource? = nil) {
    self.data = category?.categoryInputResourceIdentifier
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(data, forKey: .data)
  }
}
