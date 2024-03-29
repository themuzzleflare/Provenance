import Foundation

struct TagInputResourceIdentifier: Codable, Identifiable {
  /// The type of this resource: `tags`
  var type = "tags"

  /// The label of the tag, which also acts as the tag’s unique identifier.
  var id: String
}
