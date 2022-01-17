import Foundation

struct CategoryInputResourceIdentifier: Codable, Identifiable {
  /// The type of this resource: `categories`
  var type = "categories"

  /// The unique identifier of the category, as returned by the `/categories` endpoint.
  var id: String
}
